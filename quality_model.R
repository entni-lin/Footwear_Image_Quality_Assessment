aic <- function(fit){ #AIC in lrm is LR(Chi square) - 2*d.f. # check pp.204 by F.E. Harrel
  round(fit$stats['Model L.R.'] - 2*fit$stats['d.f.'],2)}
library(dplyr)
library(caret)
library(MASS)
library(car)
library(rms)
library(nnet)
library(tidyr)
library(DescTools)

## PART A: data preparation
### The original csv file includes features used to fit the model is not provided, 
### but the RData which contains two trained and best models is provided.

### Please download the RData from the repository and load the Rdata using line 17 (the next line)
load(file = "quality_assessment_models.RData")

### Illustration of the data preparation steps
setwd("/Users/lily2/Downloads/model/laypersons")
# read in all image features
dat <- read.csv('all_image_features_lay_updated.csv', header=T, sep = ',') 
# drop the bounding ratio
dat <- dat[,-13]
# remove outliers?
dat <- dat[-347,] #702RB3

dat$quality_label <- as.factor(dat$quality_label)
## Standatdize (scale) for all features
dat$wavelet_global_std <- (dat$wavelet_global - mean(dat$wavelet_global))/sd(dat$wavelet_global)
dat$wavelet_local_std <- (dat$wavelet_local - mean(dat$wavelet_local))/sd(dat$wavelet_local)
dat$texture_energy_std <- (dat$texture_energy - mean(dat$texture_energy))/sd(dat$texture_energy)
dat$texture_entropy_std <- (dat$texture_entropy - mean(dat$texture_entropy))/sd(dat$texture_entropy)
dat$texture_homogeneity_std <- (dat$texture_homogeneity - mean(dat$texture_homogeneity))/sd(dat$texture_homogeneity)
dat$texture_contrast_std <- (dat$texture_contrast - mean(dat$texture_contrast))/sd(dat$texture_contrast)
dat$totality_percentage_of_white_std <- (dat$totality_percentage_of_white - mean(dat$totality_percentage_of_white))/sd(dat$totality_percentage_of_white)
dat$totality_perimeter_std <- (dat$totality_perimeter - mean(dat$totality_perimeter))/sd(dat$totality_perimeter)
dat$spatial_inf_stdev_std <- (dat$spatial_inf_stdev - mean(dat$spatial_inf_stdev))/sd(dat$spatial_inf_stdev)
dat$frequency_mean_1500_std <- (dat$frequency_mean_1500 - mean(dat$frequency_mean_1500))/sd(dat$frequency_mean_1500)

levels(dat$quality_label) <- c("Very poor","Poor","Moderate","Good","Excellent")
dat$quality_label <- ordered(dat$quality_label, levels=c("Very poor","Poor","Moderate","Good","Excellent"))

# set up for PCAs
X <- data.frame(
  wavelet_global_std               = dat$wavelet_global_std,
  wavelet_local_std                = dat$wavelet_local_std,
  texture_energy_std               = dat$texture_energy_std,
  texture_contrast_std             = dat$texture_contrast_std,
  texture_entropy_std              = dat$texture_entropy_std,
  texture_homogeneity_std          = dat$texture_homogeneity_std,
  totality_percentage_of_white_std = dat$totality_percentage_of_white_std,
  totality_perimeter_std           = dat$totality_perimeter_std,
  spatial_inf_stdev_std            = dat$spatial_inf_stdev_std,
  frequency_mean_1500_std          = dat$frequency_mean_1500_std
)

#Compute PCs of the data: 
pca.model<-prcomp(X, center=F, scale=F)

#Plot histogram of PC variances:
plot(pca.model)

#Look at numerical values of PC variances:
summary(pca.model)

#Pick dimension
Mpc     <- 10                                            
Zpc     <- predict(pca.model)[,1:Mpc] #Grab PCA scores
dim(Zpc)

# Prepare the PCs and quality labels for the polr regression
quality_label <- dat$quality_label
image.name <- dat$filename
image.id <- dat$imageID
dat.red       <- data.frame(image.id, image.name, quality_label, Zpc)
dim(dat.red)
colnames(dat.red)


dat$quality_label2 <- factor(dat$quality_label, ordered = FALSE)
dat$quality_label2 <- relevel(dat$quality_label2, ref = "Very poor")
dat.red$quality_label2 <- factor(dat.red$quality_label, ordered = FALSE)
dat.red$quality_label2 <- relevel(dat.red$quality_label2, ref = "Very poor")


## PART B: Fit models
# best model 1: multinomial logistic regression + 10 image features (5 knots transformed on wavelet global, wavelet local, si, frequency)
m1 <- multinom(quality_label2 ~ rcs(wavelet_global_std,5) + rcs(wavelet_local_std,5) +
                 texture_contrast_std + texture_entropy_std + texture_homogeneity_std + 
                 texture_energy_std + totality_percentage_of_white_std + totality_perimeter_std + 
                 rcs(spatial_inf_stdev_std,5) + rcs(frequency_mean_1500_std,5), data = dat, maxit = 3000)


# best model 2: multinational logistic regression + 7 out of 10 PCs (5 knots transformed on PC2, PC3, PC4, PC5, PC6, PC7)
m2 <- multinom(quality_label2~ PC1 + rcs(PC2,5) + rcs(PC3,5) +
                  rcs(PC4,5) +  rcs(PC5,5) + rcs(PC6,5) +
                  rcs(PC7,5), data = dat.red, maxit = 3000)

### save two models
#save(m1, m2, file="quality_assessment_models.RData")


## PART C: Examine the preformance of models 
### Note: dat/dat.red ((original data with 10 image features/PCs)) are not provided

# best model 1 vs. best model 2
G <- -2 * (logLik(m2)[1] - logLik(m1)[1])
## manually input and replace the df of two models
AIC(m1)
AIC(m2)

### HOOCV for the best model: m2 outperforms m1
cv.info.1 <- c()

for (i in 1:nrow(dat)){
# model 2: multinational logistic regression + 7 out of 10 PCs (5 knots transformed on PC2, PC3, PC4, PC5, PC6, PC7)
# (5 knots transformed on PC2, PC3, PC5, PC7, PC9)
#m2 <- multinom(quality_label2~ PC1 + rcs(PC2,5) + rcs(PC3,5) +
#                   rcs(PC4,5) +  rcs(PC5,5) + rcs(PC6,5) +
#                   rcs(PC7,5), data = dat.red, maxit = 3000)
pred.m2 <- predict(m2, dat.red[i,])
dif.cv.1  <- as.numeric(pred.m2) - as.numeric(dat.red$quality_label2[i])
# Store prediction results
cv.info.row.1 <- data.frame(pred.m2, dat.red$quality_label2[i], as.numeric(pred.m2), as.numeric(dat.red$quality_label2[i]), dif.cv.1)
cv.info.1 <- rbind(cv.info.1, cv.info.row.1)
}

colnames(cv.info.1) <- c("Prediction","Observation","Prediction.n","Observation.n", "Deviation")
cv.info.1$Prediction <- ordered(cv.info.1$Prediction, levels=c("Very poor","Poor","Moderate","Good","Excellent"))
cv.info.1$Observation <- ordered(cv.info.1$Observation, levels=c("Very poor","Poor","Moderate","Good","Excellent"))

write.csv(cv.info.1,file = "mul_best_model.csv")

cv.info.2 <- cv.info.1 |> dplyr::group_by(Deviation) |> mutate(count = n())
# best model figures
p1 = cv.info.2 %>% 
  ggplot(aes(x=Deviation, y=count))+
  geom_bar(stat="identity",position = "dodge")+
  scale_x_continuous(breaks = seq(-2,3,1), lim = c(-2.5,3.5))+
  ylab("Frequency")+
  xlab("Deviation (Prediction - Observation)")+
  geom_text(aes(label = count),vjust=-0.25)
ggsave("/Users/lily2/Desktop/deviation_frequency_table.png", plot = p1, width = 9, height = 6, dpi = 400)
cv.info.1.2 <- cv.info.1 %>% group_by(Observation,Prediction) %>% 
  summarise(Total = n() ,.groups="keep") %>% 
  group_by(Observation) %>% mutate(big_total=sum(Total)) %>% mutate(Percentage = Total/big_total)
cv.info.1.2$Prediction <- factor(cv.info.1.2$Prediction, levels = c("Excellent","Good","Moderate","Poor","Very poor"))
cv.info.1.2 %>% 
  ggplot(aes(fill=Prediction, y=Percentage, x=Observation)) + 
  geom_bar(position="stack", stat="identity")+
  scale_fill_brewer("Prediction",palette="RdYlBu",direction = -1)+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  geom_text(aes(label = scales::percent(Percentage, accuracy = .1)), position = position_stack(vjust = 0.5), size = 2) +
  scale_x_discrete(limits = c("Very poor", "Poor", "Moderate","Good","Excellent"))+
  xlab("Observation")+
  ylab("Prediction (%)")

cor(cv.info.1$Observation.n,cv.info.1$Prediction.n)^2 #R^2
cm <- confusionMatrix(cv.info.1$Observation,cv.info.1$Prediction)
cm

sub.cv.1 <- rbind(subset(cv.info.1, Prediction=="Very poor" & Observation=="Poor"),
                   subset(cv.info.1, Prediction=="Poor" & Observation=="Very poor"),
                   subset(cv.info.1, Prediction=="Good" & Observation=="Excellent"),
                   subset(cv.info.1, Prediction=="Excellent" & Observation=="Good")
)

new.acc.1 <- (length(which(cv.info.1$Deviation==0)) + nrow(sub.cv.1))/469
new.acc.1
