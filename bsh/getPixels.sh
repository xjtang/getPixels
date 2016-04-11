#!/bin/bash

# Submit qsub job 

# Specify which shell to use
#$ -S /bin/bash

# Run for 48 hours
#$ -l h_rt=24:00:00

# Forward my current environment
#$ -V

# Give this job a name
#$ -N getPixles

# Join standard output and error to a single file
#$ -j y

# Name the file where to redirect standard output and error
#$ -o getPixels.qlog

# Now let's keep track of some information just in case anything goes wrong

echo "=========================================================="
echo "Starting on : $(date)"
echo "Running on node : $(hostname)"
echo "Current directory : $(pwd)"
echo "Current job ID : $JOB_ID"
echo "Current job name : $JOB_NAME $1"
echo "Task index number : $SGE_TASK_ID"
echo "=========================================================="

# Run the bash script
module load R_earth/3.1.0
R --slave --vanilla --quiet --no-save  <<EEE
source('/usr3/graduate/xjtang/Documents/getPixels/getPixels.R')
get_pixel('$1','$2','$3')
EEE

echo "=========================================================="
echo "Finished on : $(date)"
echo "=="
