# getPixels.R
# Version 1.0
# Main Function
#
# Project: Process Time Series of Individual Pixels
# By Xiaojing Tang
# Created On: 4/1/2016
# Last Update: 4/6/2016
#
# Usage:
#   1.Intstall sp, raster, and rgdal before using this script
#   2.Prepare Landsat image stacks
#   3.Run the function with correct input arguments
#
# Version 1.0 - 4/6/2016
#   This script grab time series of individual pixels from Landsat images
# 
# Created on Github on 4/1/2016, check Github Commits for updates afterwards.
#----------------------------------------------------------------

# Libraries and sourcing
library(sp)
library(raster)
library(rgdal)
library(png)
#--------------------------------------

# get_pixel
# Get time series of individual pixels from stack of images
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
#   1.Prepare a csv file for list of images
#   2.Prepare a csv file for list of pixels to grab
#   3.Run script to grab pixel time series
#
get_pixel <- function(pixFile,imgFile,outPath){
  
  # check output path
  if(!file.exists(outPath)){
    dir.create(outPath)
  }
  
  # read pixel file
  pixel <- read.table(pixFile,sep=',')
  
  # read image file
  image <- read.table(imgFile,sep=',',stringsAsFactors=F,header=T)
  
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

# crop_pixel
# crop a window around a pixel and create preview images
#
# Input Arguments: 
#   x (Integer) - row of the pixel to crop
#   y (Integer) - col of the pixel to crop

#   imgFile (String) - csv file that contains list of images
#   outFile (String) - path for output files
#   cropSize (Integer) - the size of the window (pixels)
#   comp (Vector, Integer) - composit of the output preview image
#   stretch (Vector, Integer) - stretch of the output preview image
#
# Output Arguments: 
#   r (Integer) - 0: Successful
#
# Usage: 
#   1.Prepare a csv file for list of images
#   2.Run script to create preview images
#
crop_pixel <- function(x,y,imgFile,outPath,cropSize=100,
                       comp=c(3,4,5),stretch=c(0,5000)){
  
  # check output path
  if(!file.exists(outPath)){
    dir.create(outPath)
  }
  
  # read image file
  image <- read.table(imgFile,sep=',',stringsAsFactors=F)
  
  # initilize
  img <- stack(image[1,3])
  nband <- nlayers(img)
  nline <- nrow(img)
  nsamp <- ncol(img)
  nimage <- nrow(image)
  preview <- array(0,c(cropSize,cropSize,3))
  
  # loop through images
  for(i in 1:nimage){
    
    # calculate boundary
    if(x<=cropSize){
      x1 <- 1
    }else if(x>=(nline-cropSize)){
      x1 <- (nline-cropSize)
    }else{
      x1 <- x-floor(cropSize/2)
    }
    if(y<=cropSize){
      y1 <- 1
    }else if(y>=(nsamp-cropSize)){
      y1 <- (nsamp-cropSize)
    }else{
      y1 <- y-floor(cropSize/2)
    }
    
    # get values
    img <- stack(image[i,3])
    r <- getValuesBlock(img,x1,cropSize,y1,cropSize)
    
    # finalize image
    for(j in 1:3){
      preview[,,j] <- matrix(r[,comp[j]],nrow=cropSize,ncol=cropSize,byrow=TRUE)
    }
    preview <- (preview-stretch[1])/(stretch[2]-stretch[1])
    preview[preview<0] <- 0
    preview[preview>1] <- 1
    
    # export image
    outFile <- paste(outPath,'Pxl_',x,'_',y,'_',image[i,1],'.csv',sep='')
    writePNG(preview,outFile)
    
  }
  
  # done
  
}

