# getPixels.R
# Version 1.0
# Main Function
#
# Project: Get Pixel Time Series from Landsat Images
# By Xiaojing Tang
# Created On: 4/01/2016
# Last Update: 4/01/2016
#
# Input Arguments: 
#   pixFile (String) - csv file that contains list of pixels to process
#   imgFile (String) - csv file that contains list of images
#   outFile (String) - path for output files
#
# Output Arguments: 
#   r (Integer) - 0: Successful
#
# Usage: 
#   1.Intstall sp, raster, and rgdal before using this script
#   2.Prepare Landsat image stacks
#   3.Prepare a csv file for list of images
#   4.Prepare a csv file for list of pixels to grab
#   5.Run script to grab pixel time series
#
# Version 1.0 - 8/27/2013
#   This script grab time series of individual pixels from Landsat images
# 
# Created on Github on 4/1/2014, check Github Commits for updates afterwards.
#----------------------------------------------------------------

# Libraries and sourcing
library(sp)
library(raster)
library(rgdal)
#--------------------------------------

# main function
get_pixel <- function(pixFile,imgFile,outPath){
  
  # check output path
  if(!file.exists(outPath)){
    dir.create(outPath)
  }
  
  # read pixel file
  pixel <- read.table(pixFile,sep=',')
  
  # read image file
  image <- read.table(imgFile,sep=',',stringsAsFactors=F)
  
  # initialize output 
  nband <- nlayers(stack(image[1,3]))
  nimage <- nrow(image)
  npixel <- nrow(pixel)
  r <- array(0,c(nimage,nband+1,npixel))
  
  # loop through images
  for(i in 1:nimage){
    # get date
    r[i,1,] <- image[i,1]
    # get each pixel
    for(j in 1:nrow(pixel)){
      # get current pixel
      img <- stack(image[i,3])
      r[i,2:(nband+1),j] <- getValuesBlock(img,pixel[j,1],1,pixel[j,2],1)
    }
  }
  
  # write output  
  for(i in 1:npixel){
    write.table(r[,,i],paste(outPath,'pixel_',pixel[i,1],'_',pixel[i,2],'.csv',sep=''),
                sep=',',row.names=F,col.names=F) 
  }
  
  # done
  return(0)
}
#--------------------------------------