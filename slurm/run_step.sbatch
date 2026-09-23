#!/bin/bash
#SBATCH --job-name=palaeo-step
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x-%j.out
set -euo pipefail
if [ "$#" -ne 2 ]; then
  printf 'Usage: sbatch slurm/run_step.sbatch steps/03_climate.R config/local.R\n' >&2
  exit 2
fi
cd "${SLURM_SUBMIT_DIR:?Submit from the student_palaeo repository root}"
# If your cluster requires modules, load its R module here before submitting.
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
Rscript "$1" "$2"
