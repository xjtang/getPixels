# getPixels.R
# Version 1.0
# Main Function
#
# Project: Process Time Series of Individual Pixels
# By Xiaojing Tang
# Created On: 4/1/2016
# Last Update: 4/17/2016
#
# Usage:
#   1.Intstall sp, raster, and rgdal before using this script
#   2.Prepare Landsat image stacks
#   3.Run the function with correct input arguments
#
# Version 1.0 - 4/17/2016
#   This script grab time series of individual pixels from Landsat images
# 
# Created on Github on 4/1/2016, check Github Commits for updates afterwards.
#----------------------------------------------------------------

# Libraries and sourcing
library(sp)
library(raster)
library(rgdal)
library(png)
#----------------------------------------------------------------

# get_pixel
# Get time series of individual pixels from stack of images
#
# Input Arguments: 
#   pxlFile (String) - csv file that contains list of pixels to process
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
get_pixel <- function(pxlFile,imgFile,outPath){
  
  # check output path
  if(!file.exists(outPath)){
    dir.create(outPath)
  }
  
  # read pixel file
  pixel <- read.table(pxlFile,sep=',')
  
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
#   cropDate (Vector, Integer) - date range of creasting images
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
crop_pixel <- function(x,y,imgFile,outPath,cropSize=100,cropDate=c(1000000,3000000),
                       comp=c(5,4,3),stretch=c(0,5000)){
  
  # check output path
  if(!file.exists(outPath)){
    dir.create(outPath)
  }
  
  # read image file
  image <- read.table(imgFile,sep=',',stringsAsFactors=F,header=T)
  
  # filter image file
  image <- image[image[,1]>=cropDate[1],]
  image <- image[image[,1]<=cropDate[2],]
  
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
    
    # mark the pixel
    # preview[floor(cropSize/2)+1,floor(cropSize/2)+1,] <- c(1,0,0)
    center <- floor(cropSize/2)+1
    preview[c(center-7,center+7),(center-7):(center+7),] <- t(c(1,0,0))
    preview[(center-7):(center+7),c(center-7,center+7),] <- t(c(1,0,0))
    
    # export image
    outFile <- paste(outPath,'Pxl_',x,'_',y,'_',image[i,1],'.png',sep='')
    writePNG(preview,outFile)
    
  }
  
  # done
  
}
#--------------------------------------

# batcfh_crop_pixel
# batch crop pixels
#
# Input Arguments: 
#   pxlFile (String) - csv file that contains list of pixels to process
#   imgFile (String) - csv file that contains list of images
#   outFile (String) - path for output files
#   cropSize (Integer) - the size of the window (pixels)
#   cropDate (Vector, Integer) - date range of creasting images
#   comp (Vector, Integer) - composit of the output preview image
#   stretch (Vector, Integer) - stretch of the output preview image
#
# Output Arguments: 
#   r (Integer) - 0: Successful
#
# Usage: 
#   1.Prepare a csv file for list of pixels
#   2.Prepare a csv file for list of images
#   3.Run script to create preview images
#
batch_crop_pixel <- function(pxlFile,imgFile,outPath,cropSize=100,cropDate=c(1000000,3000000),
                       comp=c(5,4,3),stretch=c(0,5000)){
  
  # check output path
  if(!file.exists(outPath)){
    dir.create(outPath)
  }
  
  # read pixel file
  pixel <- read.table(pxlFile,sep=',')
  
  # crop each pixel
  for(i in 1:nrow(pixel)){
    
    # forge output path for this pixel
    pixelPath <- paste(outPath,'Pxl_',pixel[i,1],'_',pixel[i,2],'/',sep='')
    
    # crop pixel
    crop_pixel(pixel[i,1],pixel[i,2],imgFile,pixelPath,100,c(3,4,5),c(0,5000))
    
  }
  
  # done
  
}
#--------------------------------------

# locate_pixel
# locate pixel in landsat image
#
# Input Arguments: 
#   pxlFile (String) - csv file that contains list of pixels to process
#   outFile (String) - path for output files
#   UTM (Integer) - UTM zone (negative for south)
#   UL (Vector, Integer) - upper left corner coordinate
#   res (Integer) - resolution
#
# Output Arguments: 
#   r (Integer) - 0: Successful
#
# Usage: 
#   1.Prepare a csv file for list of pixels
#   2.Run script to locate pixel in landsat image
#
locate_pixel <- function(pxlFile,outFile,UTM,UL,res=30){
  
  # read pixel file
  pixel <- read.table(pxlFile,sep=',',stringsAsFactors=F,header=T)
  
  # initialize
  r <- matrix(0,nrow(pixel),3)
  
  # loop through pixel
  for(i in 1:nrow(pixel)){
    r[i,1] <- pixel[i,'ID']
    coor <- deg2utm(pixel[i,'LAT'],pixel[i,'LON'],UTM)
    r[i,3] <- ceiling((coor[1]-UL[1])/res)
    r[i,2] <- ceiling((UL[2]-coor[2])/res)
  }
  
  # export result
  write.table(r,outFile,sep=',',row.names=F,col.names=F) 
  
  # done
  
}
#----------------------------------------------------------------

# small tools
# degree to utm
deg2utm <- function(lat,lon,utm){
  # constants
  A0 = 6367449.146;
  B0 = 16038.42955;
  C0 = 16.83261333;
  D0 = 0.021984404;
  E0 = 0.000312705;
  a = 6378137;
  b = 6356752.314;
  k0 = 0.9996;
  e = 0.081819191;
  e2 = 0.006739497;
  # calculate
  utm2 <- abs(utm)
  lat2 <- deg2rad(lat)
  lon2 <- deg2rad(lon)
  dLonRad <- (lon-(6*utm2-183))*pi/180
  nu <- a/((1-(e*sin(lat2))^2)^0.5)
  ki <- k0*(A0*lat2-B0*sin(2*lat2)+C0*sin(4*lat2)-D0*sin(6*lat2)+E0*sin(8*lat2))
  kii <- nu*sin(lat2)*cos(lat2)/2
  kiii <- ((nu*sin(lat2)*cos(lat2)^3)/24)*(5-tan(lat2)^2+9*e2*cos(lat2)^2+4*e2^2*cos(lat2)^4)*k0
  kiv <- nu*cos(lat2)*k0
  kv <- cos(lat2)^3*(nu/6)*(1-tan(lat2)^2+e2*cos(lat2)^2)*k0
  # results
  x <- 500000+(kiv*dLonRad+kv*dLonRad^3)
  y <- (ki+kii*dLonRad*dLonRad+kiii*dLonRad^4)
  if(utm<0){y<-y+10000000}
  # done
  return(c(x,y))
}
#--------------------------------------
# degree to radian
deg2rad <- function(x){
  return(x*pi/180)
}
#--------------------------------------
# radian to degree
rad2deg <- function(x){
  return(x/pi*180)
}
#--------------------------------------

