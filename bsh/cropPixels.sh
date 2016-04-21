#!/bin/bash

# Submit job to crop pixel
# Input Arguments: 
#   -cSize crop size (optional)
#   -cDate crop date range (optional)
#   -comp compisot (optional)
#   -stch stretch (optional)
#   -f pixel file (batch)
#   -p pixel coordinate (single process)
#   1.Image file
#   2.Output path

# Specify which shell to use
#$ -S /bin/bash

# Run for 48 hours
#$ -l h_rt=48:00:00

# Forward my current environment
#$ -V

# Give this job a name
#$ -N cropPixles

# Join standard output and error to a single file
#$ -j y

# Name the file where to redirect standard output and error
#$ -o cropPixels.qlog

# Now let's keep track of some information just in case anything goes wrong

echo "=========================================================="
echo "Starting on : $(date)"
echo "Running on node : $(hostname)"
echo "Current directory : $(pwd)"
echo "Current job ID : $JOB_ID"
echo "Current job name : $JOB_NAME cropPixles"
echo "Task index number : $SGE_TASK_ID"
echo "=========================================================="

# parse input arguments
cSize=100
cDate1=1000000
cDate2=3000000
comp1=5
comp2=4
comp3=3
stretch1=0
stretch2=5000
mark=T

while [[ $# > 0 ]]; do

	InArg="$1"

	case $InArg in
		-cSize)
			cSize=$2
			shift
			;;
		-cDate)
			cDate1=$2
			cDate2=$3
			shift
			shift
			;;
		-comp)
			comp1=$2
			comp2=$3
			comp3=$4
			shift
			shift
			shift
			;;
		-stch)
			stretch1=$2
			stretch2=$3
			shift
			shift
			;;
		-d)
			mark=$2
			shift
			;;
		-f)
			FUNC=batch
			cFile=$2
			shift
			;;
		-p)
			FUNC=single
			cPixel1=$2
			cPixel2=$3
			shift
			shift
			;;
		*)
			iFile=$1
			oPath=$2
			break
		esac

		shift

done

if [ $FUNC = "single" ]; then
		COMMAND='crop_pixel('$cPixel1','$cPixel2',"'$iFile'","'$oPath'",'$cSize,'c('$cDate1','$cDate2'),c('$comp1','$comp2','$comp3'),c('$stretch1','$stretch2'),'$mark')'
elif [ $FUNC = "batch" ]; then
		COMMAND='batch_crop_pixel("'$cFile'","'$iFile'","'$oPath'",'$cSize,'c('$cDate1','$cDate2'),c('$comp1','$comp2','$comp3'),c('$stretch1','$stretch2'),'$mark')'
else
		echo 'unknown option'
fi

echo $COMMAND

# Run the bash script
module load R_earth/3.1.0
R --slave --vanilla --quiet --no-save  <<EEE
source('/usr3/graduate/xjtang/Documents/getPixels/getPixels.R')
$COMMAND
EEE

echo "=========================================================="
echo "Finished on : $(date)"
echo "=="
