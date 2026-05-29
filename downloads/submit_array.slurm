#!/bin/bash
# =============================================================================
# 
#
# Use this when you want to run many similar jobs in parallel — e.g. a grid
# search where each combination of hyperparameters is an independent run.
#
# This is the natural cluster pattern for embarrassingly parallel work and is
# what makes the cluster genuinely faster than your laptop for grid searches.
#
# Submit with:    sbatch <your_filename>.slurm
# =============================================================================

# ----- SLURM directives -------------------------------------------------------

#SBATCH --job-name=grid_search
#SBATCH --output=logs/%x_%A_%a.out      # %A=array job id, %a=array task id
#SBATCH --error=logs/%x_%A_%a.err

#SBATCH --time=00:30:00                 # PER TASK, not total
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G

# Array specification: run tasks 0..19 (20 tasks total)
#SBATCH --array=0-19

# Throttle concurrent tasks (optional). Use %N to cap concurrency:
# #SBATCH --array=0-19%5                # at most 5 tasks running at once

# ----- Environment setup ------------------------------------------------------
set -euo pipefail

mkdir -p logs results

source ~/elja_env/bin/activate

echo "Array job:      $SLURM_ARRAY_JOB_ID"
echo "Task ID:        $SLURM_ARRAY_TASK_ID"
echo "Running on:     $(hostname)"
echo "-------------------------------------------"

# ----- Define the parameter grid ---------------------------------------------
# Build a flat list of hyperparameter combinations.
# $SLURM_ARRAY_TASK_ID selects which row this task runs.

# Example: SVM grid search with C ∈ {0.01, 0.1, 1, 10, 100} × γ ∈ {0.001, 0.01, 0.1, 1}
# That's 5 × 4 = 20 combinations, matching --array=0-19 above.

C_VALUES=(0.01 0.1 1 10 100)
GAMMA_VALUES=(0.001 0.01 0.1 1)

# Decode the task ID into (C_idx, gamma_idx).
N_GAMMA=${#GAMMA_VALUES[@]}
C_IDX=$(( SLURM_ARRAY_TASK_ID / N_GAMMA ))
GAMMA_IDX=$(( SLURM_ARRAY_TASK_ID % N_GAMMA ))

C=${C_VALUES[$C_IDX]}
GAMMA=${GAMMA_VALUES[$GAMMA_IDX]}

echo "Running with C=$C, gamma=$GAMMA"
echo "-------------------------------------------"

# ----- Your actual job --------------------------------------------------------
# Each task writes its own result file, identified by the task ID. After all
# tasks finish, aggregate the results in a separate small script (or notebook).

python train_svm.py \
    --C "$C" \
    --gamma "$GAMMA" \
    --output "results/result_${SLURM_ARRAY_TASK_ID}.json"

echo "-------------------------------------------"
echo "Task finished:  $(date)"

# =============================================================================
# Aggregating results after all array tasks complete:
#
#   python -c "
#   import json, glob, pandas as pd
#   rows = [json.load(open(f)) for f in glob.glob('results/result_*.json')]
#   df = pd.DataFrame(rows).sort_values('score', ascending=False)
#   print(df.head(10))
#   df.to_csv('results/summary.csv', index=False)
#   "
#
# Why arrays beat a single big job:
#   - Tasks schedule independently — short ones run as soon as a slot opens
#   - Failed tasks don't kill the others
#   - You can rerun individual tasks: sbatch --array=7 <script>.slurm
#   - SLURM's scheduler is much happier with many short jobs than one huge one
# =============================================================================
