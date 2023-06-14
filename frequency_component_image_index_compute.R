#install.packages("bigmemory")
#install.packages("biganalytics")
library(bigmemory)
library(biganalytics)


## first of all, to find the maximum magnitude of frequency components from each image

df <- read.csv(file = paste0("X:/Lily/pHD_research/feature_extraction/all_features/frequency_component/frequency_components_max_min_magnitudes.csv"),header =T,sep = ",")
max.col <- as.numeric(df[,2])
mean.max <- mean(max.col)
median.max <- median(max.col)


# Read the filenames of all magnitudes files:
fnames <- list.files(path = "X:/Lily/pHD_research/feature_extraction/all_features/frequency_component/all_magnitudes/")

# Set up a loop to try several thresh
thresh.seq <- c(1000,1500,2000)
for (i in 1:length(thresh.seq)){
  aa = Sys.time()
  thresh_mean <- mean.max/thresh.seq[i]
  thresh_median <- median.max/thresh.seq[i]
  
  
  kept.freqs.mean <- rep(list(NULL), length(fnames))
  kept.freqs.median <- rep(list(NULL), length(fnames))
  
  freq.lengs <- numeric(length(fnames))
  
  # Loop over the files and extraxt the maxes:
  for(j in 1:length(fnames)) {
    print(paste("STARTING file:", fnames[j]))
    # 1. read in all csv files: 
    dat <- read.big.matrix(filename = paste0("X:/Lily/pHD_research/feature_extraction/all_features/frequency_component/all_magnitudes/",fnames[j]), sep=",", type="double")
    freq.lengs[j] <- length(dat)
    
    #2. search for how many frequency components are above the threshold (threshold has not decided yet) and store them
    dat.t <- as.matrix(dat)
    kept.freqs.mean[[j]] <- dat[which(dat.t > thresh_mean)]
    kept.freqs.median[[j]] <- dat[which(dat.t > thresh_median)]
    #print(length(kept.freqs.mean[[j]]))
    #print(length(kept.freqs.median[[j]]))
    
    
    print(paste("DONE file:", fnames[j]))
  }
  
  # 3. count the frequency components from step 3, and divide the total number of frequency components
  ## gsub to remove unwant characters to print out in the file
  sapply(1:length(fnames), function(xx)write.table(cbind(gsub('_magnitudes.csv','',fnames[xx]),{length(kept.freqs.mean[[xx]])/freq.lengs[xx]},{length(kept.freqs.median[[xx]])/freq.lengs[xx]}), file=paste0("X:/Lily/pHD_research/feature_extraction/all_features/frequency_component/","frequency_component_index_",thresh.seq[i],".csv"),sep = ",",append = TRUE, row.names = FALSE, col.names = FALSE))
  
  bb = Sys.time()
  print(paste0("Finish threshold: ",thresh.seq[i]," in ", round(as.numeric(difftime(time1 = bb, time2 = aa, units = "mins")),3), " Mins"))
}
