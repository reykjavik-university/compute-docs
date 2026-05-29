#!/bin/bash
# =============================================================================
# GPU job template
#
# Use this template for any neural-network training (CNN, RNN, transformer).
# Submit with:    sbatch <your_filename>.slurm
# =============================================================================

# ----- SLURM directives -------------------------------------------------------

#SBATCH --job-name=gpu_job
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err

#SBATCH --time=02:00:00                 # GPUs are scarce — keep this tight
#SBATCH --gres=gpu:1                    # request exactly 1 GPU
#SBATCH --cpus-per-task=4               # CPU workers for data loading
#SBATCH --mem=16G                       # RAM. Big enough for your dataset in memory.

# If your cluster has a dedicated GPU partition, set it here:
# #SBATCH --partition=gpu

# To request a specific GPU type (only if you actually need it):
# #SBATCH --gres=gpu:rtx2080ti:1

# ----- Environment setup ------------------------------------------------------
set -euo pipefail

mkdir -p logs

source ~/elja_env/bin/activate
# or: module load python/3.11 cuda/11.8

echo "Job started:    $(date)"
echo "Running on:     $(hostname)"
echo "Job ID:         $SLURM_JOB_ID"
echo "Working dir:    $(pwd)"
echo "GPUs visible:   $CUDA_VISIBLE_DEVICES"
echo "-------------------------------------------"

# ----- GPU sanity check -------------------------------------------------------
# This block FAILS the job immediately if no GPU is actually available.
# Without it, PyTorch silently falls back to CPU and you wait hours wondering
# why your CNN trains so slowly.

echo "GPU diagnostics:"
nvidia-smi

python - <<'PY'
import torch
assert torch.cuda.is_available(), "CUDA is not available — check --gres in the SLURM script"
print(f"PyTorch:        {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"CUDA version:   {torch.version.cuda}")
print(f"Device count:   {torch.cuda.device_count()}")
print(f"Device name:    {torch.cuda.get_device_name(0)}")
PY

echo "-------------------------------------------"

# ----- Your actual training run ----------------------------------------------
# Replace this line with your training command.

python train.py \
    --device cuda \
    --num-workers "$SLURM_CPUS_PER_TASK" \
    --output-dir "outputs/$SLURM_JOB_ID"

# ----- Cleanup ----------------------------------------------------------------
echo "-------------------------------------------"
echo "Job finished:   $(date)"
