#!/bin/bash
# =============================================================================
# CPU job template
#
# Copy this file, rename it for your job, and edit the marked sections below.
# Submit with:    sbatch <your_filename>.slurm
# Check status:   squeue -u $USER
# Cancel:         scancel <job_id>
# =============================================================================

# ----- SLURM directives -------------------------------------------------------
# IMPORTANT: lines starting with #SBATCH are SLURM directives, NOT bash comments.
# A space between # and SBATCH (i.e. "# SBATCH") makes SLURM ignore the line.

#SBATCH --job-name=cpu_job              # shows up in squeue
#SBATCH --output=logs/%x_%j.out         # stdout: %x=job-name, %j=job-id
#SBATCH --error=logs/%x_%j.err          # stderr in a separate file

#SBATCH --time=01:00:00                 # HH:MM:SS — request what you need + buffer
#SBATCH --cpus-per-task=4               # CPU cores. Match this to n_jobs in your code.
#SBATCH --mem=8G                        # RAM. Estimate generously but not absurdly.

# Uncomment if your cluster requires specifying a partition:
# #SBATCH --partition=cpu

# Email notifications (optional):
# #SBATCH --mail-type=END,FAIL
# #SBATCH --mail-user=you@university.edu

# ----- Environment setup ------------------------------------------------------
set -euo pipefail                       # fail loudly on any error

# Make sure the logs directory exists (SLURM does NOT create it for you).
mkdir -p logs

# Activate your Python environment. Adapt to whatever you use.
source ~/elja_env/bin/activate
# Alternatives, depending on cluster setup:
#   module load python/3.11
#   conda activate dmml

# Print useful diagnostics to the log
echo "Job started:    $(date)"
echo "Running on:     $(hostname)"
echo "Job ID:         $SLURM_JOB_ID"
echo "Working dir:    $(pwd)"
echo "Python:         $(which python)"
echo "CPUs allocated: $SLURM_CPUS_PER_TASK"
echo "-------------------------------------------"

# ----- Your actual job --------------------------------------------------------
# Edit this line (or block) for your specific task.

python my_script.py --cpus "$SLURM_CPUS_PER_TASK"

# Examples of more complex invocations:
#   python -m grid_search --dataset digits --kernel rbf
#   python train.py --config configs/svm_baseline.yaml

# ----- Cleanup ----------------------------------------------------------------
echo "-------------------------------------------"
echo "Job finished:   $(date)"
