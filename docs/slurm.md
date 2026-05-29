# SLURM Cluster Tutorial

This tutorial is for students and researchers who need to run Python jobs on a
SLURM-managed cluster. The examples use the Elja hostname and environment paths,
but the workflow is general SLURM: adapt the hostname, partition names, modules,
and environment path to match the cluster you are using.

---

## First-time setup

### 1. Generate an SSH key (one-time, on your laptop)

```bash
ssh-keygen -t ed25519 -C "your.email@university.edu"
# Press Enter to accept default location (~/.ssh/id_ed25519)
# Choose a passphrase or leave empty
```

### 2. Send your **public** key to the cluster admin

```bash
cat ~/.ssh/id_ed25519.pub
# Copy the output and email it to: [admin contact]
# NEVER send the private key (id_ed25519 without .pub)
```

### 3. Add a convenience entry to `~/.ssh/config`

```
Host elja
    HostName cluster.address.example.edu
    User your_username
    IdentityFile ~/.ssh/id_ed25519
```

Now `ssh elja` is enough to log in.

### 4. Verify

```bash
ssh elja
hostname    # should print the login node name
exit
```

---

## The five SLURM commands you actually need

| Command | What it does |
|---|---|
| `sbatch job.slurm` | Submit a batch job. Returns a job ID. |
| `squeue -u $USER` | Show your queued and running jobs. |
| `scancel <job_id>` | Cancel a job (queued or running). |
| `sacct -j <job_id>` | Job history, including completed jobs. |
| `srun --pty bash` | Open an interactive shell on a compute node. |

For interactive GPU debugging:
```bash
srun --gres=gpu:1 --cpus-per-task=4 --mem=16G --time=1:00:00 --pty bash
```

---

## Create your Python environment

Create the environment once, then activate the same environment in every
interactive session and SLURM job that needs it.

```bash
# Log in to the cluster first
ssh elja

# If the cluster uses environment modules, load Python before creating the env.
# Use `module avail python` if you need to see available versions.
module load python/3.11

# Create a virtual environment in your home directory
python -m venv ~/elja_env

# Activate it
source ~/elja_env/bin/activate

# Make sure pip itself is current inside the env
python -m pip install --upgrade pip setuptools wheel
```

Install packages while the environment is active:

```bash
# From a project directory with requirements.txt
python -m pip install -r requirements.txt

# Or install packages directly
python -m pip install numpy pandas scikit-learn matplotlib
```

Check that the environment is the one being used:

```bash
which python
python -m pip list
python -c "import sys; print(sys.executable)"
```

When you submit jobs, activate the environment in the job script before running
Python:

```bash
module load python/3.11
source ~/elja_env/bin/activate
python my_script.py
```

Do not install packages inside every SLURM job. Install or update the environment
once, then let jobs only activate and use it.

---

## Downloadable job templates

Use these as starting points for your own jobs:

- <a href="/downloads/submit_cpu.slurm" download>CPU job template</a>
- <a href="/downloads/submit_gpu.slurm" download>GPU job template</a>
- <a href="/downloads/submit_array.slurm" download>Array job template</a>

The templates are copied as downloadable files and are not rendered as pages.

---

## Minimal CPU job script

```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --output=logs/%x_%j.out      # %x = job name, %j = job ID
#SBATCH --error=logs/%x_%j.err
#SBATCH --time=01:00:00              # HH:MM:SS — be realistic
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Environment setup
source ~/elja_env/bin/activate       # or: module load python/3.11

# Run
python my_script.py
```

Submit with: `sbatch job.slurm`

---

## Minimal GPU job script

```bash
#!/bin/bash
#SBATCH --job-name=cnn_train
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --gres=gpu:1                 # request 1 GPU
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

source ~/elja_env/bin/activate

# Verify GPU is visible — fail loudly if not
nvidia-smi
python -c "import torch; assert torch.cuda.is_available(), 'No GPU!'"

python train_cnn.py
```

---

## File transfer

```bash
# Laptop → cluster
scp my_data.csv elja:~/project/

# Cluster → laptop
scp elja:~/project/results.json .

# Whole directory
scp -r elja:~/project/results/ ./local_results/
```

For larger or syncing workflows, use `rsync`:
```bash
rsync -avz ~/project/ elja:~/project/
```

---

## The good-citizen rules

1. **Request what you need, not the max.** Asking for 64 CPUs and 256 GB when you need 4 and 8 makes you wait longer *and* blocks others.
2. **Set realistic time limits.** If your job runs 30 minutes, ask for 1 hour, not 24. SLURM schedules short jobs faster.
3. **Cancel failed jobs.** Don't leave broken jobs sitting in the queue.
4. **Don't hoard GPUs.** Especially for interactive sessions — close them when you're not actively using them.
5. **Don't poll `squeue` in a loop.** A watch every few seconds is enough; tighter loops hammer the scheduler.
6. **Test small before submitting big.** Run on a subset locally or in an interactive session before launching a 12-hour sweep.

---

## Top three troubleshooting cases

### Job stuck in `PD` (pending) state forever

```bash
squeue -j <job_id> -o "%i %T %r"   # shows reason
```

Usually one of:
- Requesting more resources than any node has (`PartitionConfig`)
- Asking for a GPU when none are free (`Resources`)
- Hit your user/group fair-share limit (`AssocGrp...`)

**Fix:** lower resource request or wait. Don't resubmit repeatedly — that won't help.

### Job fails immediately, empty or weird output

Check the `.err` file first:
```bash
cat logs/my_job_12345.err
```

Most common causes:
- Virtual environment not activated → `ModuleNotFoundError`
- Wrong working directory → `FileNotFoundError`
- `#SBATCH` directives parsed as bash comments because of a typo (e.g., `# SBATCH` with a space)

### Training runs but is incredibly slow on a "GPU" job

You forgot to verify the GPU. PyTorch falls back to CPU silently. Always include:

```python
import torch
assert torch.cuda.is_available(), "CUDA not available — check --gres in SLURM script"
device = torch.device("cuda")
model = model.to(device)
```

## One-line emergency commands

```bash
scancel -u $USER              # cancel all your jobs (use with care)
squeue -u $USER -h | wc -l    # how many jobs do I have running/queued
sinfo -o "%P %a %l %D %t"     # what nodes/partitions exist and their state
sacct -j <jobid> -o JobID,State,Elapsed,MaxRSS,ReqMem   # post-mortem on a job
```
