#!/bin/bash
#SBATCH --account=rpp-aevans-ab
#SBATCH --mail-user=adam.trefonides@mcgill.ca
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=ALL
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G
#SBATCH --time=0-20:00:00
#SBATCH --output=slurm_out/%x-%j.out

# --time is set with the assumption that these runs should take 
# no more than 21 hours with some slop.

# This version of the script mounts a loop device mounted ext3 image
# and initiates a sing shell, and does /not/ run tractoflow

 if test $# -lt 1 ; then
    echo "Usage: $0 [XXXXX] where XXXXX is a number from 00000 - 10000"
    echo "      corresponding to the fake_BIDS directory name"
     exit 2
   fi

export FB=$1

# In case I forgot to clear $SINGULARITY_BIND
export SINGULARITY_BIND=""

# Work directory 
TASK_ROOT=/lustre03/project/6008063/atrefo/sherbrooke/TF_RUN

# Writable 20G ext3 image file for output
OUT_IMAGE=${TASK_ROOT}/ext3_images/TF_raw/TF-raw-${FB}.img

# Ouput directory, this is the mounted ext3 image inside the container:

OUT_ROOT=/TF_OUT/${FB}

# Current fake BIDS
BIDS_DIR="$TASK_ROOT/fake_bids/dwi_subs-${FB}"

# Check that the working dirs are there
cd $TASK_ROOT || exit
cd $BIDS_DIR || exit

SING_TF_IMAGE=$TASK_ROOT/tractoflow.sif

# UKBB squashfs files
UKBB_SQUASHFS_DIR=/project/6008063/neurohub/ukbb/imaging
UKBB_SQUASHFS="
  neurohub_ukbb_dwi_ses2_0_bids.squashfs
  neurohub_ukbb_dwi_ses2_1_bids.squashfs
  neurohub_ukbb_dwi_ses2_2_bids.squashfs
  neurohub_ukbb_flair_ses2_0_bids.squashfs
  neurohub_ukbb_rfmri_ses2_0_bids.squashfs
  neurohub_ukbb_rfmri_ses2_1_bids.squashfs
  neurohub_ukbb_rfmri_ses2_2_bids.squashfs
  neurohub_ukbb_rfmri_ses2_3_bids.squashfs
  neurohub_ukbb_rfmri_ses2_4_bids.squashfs
  neurohub_ukbb_rfmri_ses2_5_bids.squashfs
  neurohub_ukbb_rfmri_ses2_6_bids.squashfs
  neurohub_ukbb_t1_ses2_0_bids.squashfs
  neurohub_ukbb_t1_ses3_0_bids.squashfs
  neurohub_ukbb_participants.squashfs
  neurohub_ukbb_t1_ses2_0_jsonpatch.squashfs
"
# Prepared DWI simlink dir with the generated B0 files
DWI_SQUASHFS_DIR=${TASK_ROOT}/squash_tractoflow
DWI_SQUASHFS="
  dwipipeline.squashfs
"

SING_BINDS=" -H ${OUT_ROOT} -B $DWI_SQUASHFS_DIR -B $TASK_ROOT -B ${OUT_IMAGE}:${OUT_ROOT}:image-src=/upper "
UKBB_OVERLAYS=$(echo "" $UKBB_SQUASHFS | sed -e "s# # --overlay $UKBB_SQUASHFS_DIR/#g")
DWI_OVERLAYS=$(echo "" $DWI_SQUASHFS | sed -e "s# # --overlay $DWI_SQUASHFS_DIR/#g")

# NOTE: singularity version 3.7.1-1.el7 
module load singularity/3.7

SINGULARITYENV_NXF_CLUSTER_SEED=$(shuf -i 0-16777216 -n 1) singularity -v shell --cleanenv $SING_BINDS $UKBB_OVERLAYS $DWI_OVERLAYS $SING_TF_IMAGE \
#  nextflow run /tractoflow/main.nf        \
#  --bids          ${BIDS_DIR}             \
#  --output_dir    ${OUT_ROOT}             \
#  -w              ${OUT_ROOT}/work        \
#  --dti_shells    "1 1000"                \
#  --fodf_shells   "0 1000 2000"           \
#  --step          0.5                     \
#  --mean_frf      false                   \
#  --set_frf       true                    \
#  --save_seeds    false                   \
#  -profile        fully_reproducible      \
#  -resume                                 \
#  -with-report    report.html             \
#  -with-timeline  timeline.html           \
#  --processes     4                       \
#  --processes_brain_extraction_t1 1       \
#  --processes_denoise_dwi         2       \
#  --processes_denoise_t1          2       \
#  --processes_eddy                1       \
#  --processes_fodf                2       \
#  --processes_registration        1       \

# previous blank line intentional

