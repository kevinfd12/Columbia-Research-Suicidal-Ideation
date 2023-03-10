---
title: "Project Draft 0 inflated"
author: "Kevin Diaz Gochez"
date: "6/25/2021"
output:
  html_document:
    keep_md: true
---

```{r setup, include=FALSE}
library(knitr)
library(skimr)
library(psych)
library(tidyverse)
library(glmnet)
library(mice)
library(Rcpp)
library(splines)
```


```{r cars}
baseline2021<-read_csv("C:/Users/kevin/Desktop/BEST program/Project/baseline2021.csv")
longitudinal2021<- read_csv("C:/Users/kevin/Desktop/BEST program/Project/longitudinal2021.csv")

```


```{r pressure, echo=FALSE}
#subsets
#BASELINE
ATT.BL= baseline2021 %>%
  filter(bl_group=="ATT")

DEP.BL=baseline2021 %>%
  filter(bl_group=="DEP")

IDE.BL=baseline2021 %>%
  filter(bl_group=="IDE")

#LONGITUDINAL
ATT=longitudinal2021 %>%
  filter(Group=="ATT" & VISIT=="B")

DEP=longitudinal2021 %>%
  filter(Group=="DEP" & VISIT=="B")

IDE=longitudinal2021 %>%
  filter(Group=="IDE" & VISIT=="B")
```


```{r}

#I want to calculate statistics on the groups before the 0s are removed
#they are referred to as full, because these are the groups with Visit = B but include 0s
ATT_fullCurr <- describe(ATT$SSI_current)
IDE_fullCurr <- describe(IDE$SSI_current)
DEP_fullCurr <- describe(DEP$SSI_current)

ATT_fullWor <- describe(ATT$SSI_current)
IDE_fullWor <- describe(IDE$SSI_current)
DEP_fullWor<- describe(DEP$SSI_current)

ATT_fullCurr
IDE_fullCurr
DEP_fullCurr

ATT_fullWor
IDE_fullWor
DEP_fullWor

```

```{r}
#These are totals for before the 0s are removed
Full_currentIdeation = ATT_fullCurr$n + IDE_fullCurr$n + DEP_fullCurr$n
Full_currentIdeation

Full_worstIdeation = ATT_fullWor$n + IDE_fullWor$n + DEP_fullWor$n
Full_worstIdeation
```

```{r}
#These are 0 inflated histograms
par(mfrow=c(1,3))
hist(longitudinal2021$SSI_current, breaks = c(0,1,5,10,15,20,25,30,35,40), main= "Longitudinal Current")
hist(ATT$SSI_current , breaks = c(0,1,5,10,15,20,25,30,35,40), main= "ATT Current") 
hist(IDE$SSI_current , breaks = c(0,1,5,10,15,20,25,30,35,40), main= "IDE Current") 

hist(longitudinal2021$SSI_worst , breaks = c(0,1,5,10,15,20,25,30,35,40), main= "Longitudinal Worst") 
hist(ATT$SSI_worst , breaks = c(0,1,5,10,15,20,25,30,35,40), main= "ATT Worst") 
hist(IDE$SSI_worst , breaks = c(0,1,5,10,15,20,25,30,35,40),  main= "IDE Worst")

```

```{r}

longitudinalbl=longitudinal2021%>%
  filter(VISIT=="B")

#can merge by id or sort (longitudinal is only including the basleine values)

bl_longitudinal_2021<- merge(baseline2021,longitudinalbl,by="ID")

ATT.BL=bl_longitudinal_2021 %>%
  filter(Group=="ATT") 

DEP.BL=bl_longitudinal_2021%>%
  filter(Group=="DEP")

IDE.BL= bl_longitudinal_2021 %>%
  filter(Group=="IDE") 


ATT_IDE.BL= bl_longitudinal_2021 %>%
  filter(Group=="IDE"|Group=="ATT")

```

```{r}
#This line of code is to make sure all of the numerical columns are numerical. 
#We dont want them to be factors and be left out by accident. 
str(bl_longitudinal_2021)
```

```{r}
#this is removing ID because it isnt relevant for what we want. 
cleaned_bl_longitudinal_2021 = bl_longitudinal_2021 %>%
  select(-ID)%>%
  select_if(is.numeric)
```



```{r} 
#I started removing qualitative after 164
cleaned_bl_longitudinal_2021 <- cleaned_bl_longitudinal_2021[-c(1:5,58:61,64:84,87:109,111,117:157,159:164,7:12,59,113)]
sum(is.na(cleaned_bl_longitudinal_2021))
```


```{r}
location = which(names(cleaned_bl_longitudinal_2021) == "SSI_current")
location.other <- which(names(cleaned_bl_longitudinal_2021) != "SSI_current")
```

```{r}
myCorr_Curr <- cor(cleaned_bl_longitudinal_2021[-c(location,50)], cleaned_bl_longitudinal_2021$SSI_current, method = "spearman", use = "pairwise.complete.obs" )
myCorr_Curr
```


```{r}
sink("datout2.txt")
cor(cleaned_bl_longitudinal_2021[-c(location,50)], cleaned_bl_longitudinal_2021$SSI_current, method = "spearman", use = "pairwise.complete.obs" )
sink()

```

```{r}
PC = apply(cleaned_bl_longitudinal_2021[-c(location,50),drop=F], 2, function(x) { cor.test(cleaned_bl_longitudinal_2021$SSI_current, x, method = "spearman")
})

#How can I pull out the parameter? 
Values <- sapply(PC, "[[",  "p.value")
Values
```

```{r}
myCorr_Current <- as.data.frame(myCorr_Curr)
Values <- as.data.frame(Values)

myCorr_Current
Values
Merged_Curr <- merge(myCorr_Current, Values, by = 'row.names', all=TRUE)
Merged_Curr
```

```{r}
Merged_Curr <- Merged_Curr[Merged_Curr$V1 > 0.3 & Merged_Curr$Values < 0.05 | Merged_Curr$V1 < -0.3 & Merged_Curr$Values < 0.05, ]
row.names(Merged_Curr) <- Merged_Curr$Row.names
Merged_Curr
```

```{r}
location = which(names(cleaned_bl_longitudinal_2021) == "SSI_worst")
location.other <- which(names(cleaned_bl_longitudinal_2021) != "SSI_worst")
```

```{r}
#This is option 1 for calculating the correlations. The problem here is that it wont give us the P-values. 
myCorr_Wor <- cor(cleaned_bl_longitudinal_2021[-c(location,49)], cleaned_bl_longitudinal_2021$SSI_worst, method = "spearman", use = "pairwise.complete.obs" )
myCorr_Wor
```

```{r}
sink("datout.txt")
cor(cleaned_bl_longitudinal_2021[-c(location,49)], cleaned_bl_longitudinal_2021$SSI_worst, method = "spearman", use = "pairwise.complete.obs" )
sink()

```

```{r}
PC = apply(cleaned_bl_longitudinal_2021[-c(location,49),drop=F], 2, function(x) { cor.test(cleaned_bl_longitudinal_2021$SSI_worst, x, method = "spearman")
})

#How can I pull out the parameter? 
Values <- sapply(PC, "[[",  "p.value")
Values
```
```{r}

myCorr_Worst <- as.data.frame(myCorr_Wor)
Values <- as.data.frame(Values)

myCorr_Worst
Values
Merged_Wor <- merge(myCorr_Worst, Values, by = 'row.names', all=TRUE)
Merged_Wor
```

```{r}
Merged_Wor <- Merged_Wor[Merged_Wor$V1 > 0.3 & Merged_Wor$Values < 0.05 | Merged_Wor$V1 < -0.3 & Merged_Wor$Values < 0.05,]
row.names(Merged_Wor) <- Merged_Wor$Row.names
Merged_Wor
```

```{r}
#jpeg("C:/Users/kevin/Desktop/BEST program/Better Images/staupxtra_psyhos_num", width = 480, height = 480)
hist(cleaned_bl_longitudinal_2021$staupxtra_psyhos_num, main="Histogram of psychiatric hospitalizations",
xlab="psychiatric hospitalizations")
#dev.off()
```
```{r}
#jpeg("C:/Users/kevin/Desktop/BEST program/Better Images/BHS_score", width = 480, height = 480)
hist(cleaned_bl_longitudinal_2021$BHS_score,main="Histogram of Beck Hopelessness Scale",
xlab="BHS score")
#dev.off()
```

```{r}
#jpeg("C:/Users/kevin/Desktop/BEST program/Better Images/Ham17", width = 480, height = 480)
hist(cleaned_bl_longitudinal_2021$HAM_17items,main="Histogram of Hamilton Depression Rating Scale",
xlab="Ham_17items")
#dev.off()
```

```{r}
#jpeg("C:/Users/kevin/Desktop/BEST program/Better Images/image1", width = 480, height = 480)
par(mar=c(8,8,1,1))
plot(abs(myCorr_Curr), xaxt = "n", xlab='',
ylab="Current Ideation")
axis(1, at=1:54, labels = row.names(myCorr_Wor),  las=2)
text(52,Merged_Curr$V1[1],"Hopelessness",cex = 1, pos = 2)
text(49,Merged_Curr$V1[2],"Hamilton Depression",cex = 1, pos = 2)
text(1,Merged_Curr$V1[3],"Number of Hospitalizations",cex = 1, pos = 4) + abline(h = 0.3, col = "red", lty = 3, lwd = 2)
#dev.off()
```



```{r}
#jpeg("C:/Users/kevin/Desktop/BEST program/Better Images/image2", width = 480, height = 480)
par(mar=c(8,8,1,1))
plot(abs(myCorr_Wor), xaxt = "n", xlab='', ylab="Worst Ideation")
axis(1, at=1:54, labels = row.names(myCorr_Wor),  las=2)
text(55,Merged_Wor$V1[1],"Hopelessness",cex = 1, pos = 1)
text(52,Merged_Wor$V1[2],"Hamilton Depression",cex = 1, pos = 3)
text(1,Merged_Wor$V1[3],"Number of hospitalizations",cex = 1, pos = 4)+ abline(h = 0.3, col = "red", lty = 3, lwd = 2)
#dev.off()
```


```{r}
#I will have to remove SSI_worst because its being plotted against itself.(also SSI_current)
par(cex.axis=0.9,mar=c(8,8,1,1))
plot(Merged_Curr$V1,
     xaxt = "n", xlab='Row.names') + abline(h = 0.3, col = "red", lty = 3, lwd = 2)
axis(1, at=1:3, labels = row.names(Merged_Curr),  las=2)
```

```{r}
#I will have to remove SSI_current because its being plotted against itself. (also SSI_Worst) 
par(cex.axis=0.9,mar=c(8,8,1,1))
plot(Merged_Wor$V1, xaxt = "n", xlab='Variable names') + abline(h = 0.3, col = "red", lty = 3, lwd = 2)
axis(1, at=1:3, labels = row.names(Merged_Wor),  las=2)
#Can we use chi square for group comparisons?
```

```{r}
library(npreg)
par(mfrow=c(1,3))

complete_obs <- cleaned_bl_longitudinal_2021 %>% drop_na(HAM_17items, staupxtra_psyhos_num, BHS_score, SSI_current)

plot(cleaned_bl_longitudinal_2021$BHS_score,cleaned_bl_longitudinal_2021$SSI_current,xlab="BHS_score",ylab="SSI_Current") 
SS1 <- smooth.spline(complete_obs$HAM_17items, complete_obs$SSI_current)
lines(SS1, col=2)

plot(cleaned_bl_longitudinal_2021$HAM_17items,cleaned_bl_longitudinal_2021$SSI_current,xlab="HAM_17items",ylab="SSI_Current") 
SS2 <- smooth.spline(complete_obs$HAM_17items, complete_obs$SSI_current)
lines(SS2, col=2)

plot(cleaned_bl_longitudinal_2021$staupxtra_psyhos_num,cleaned_bl_longitudinal_2021$SSI_current,xlab="staupxtra_psyhos_num",ylab="SSI_Current")
SS3 <- smooth.spline(complete_obs$HAM_17items, complete_obs$SSI_current)
lines(SS3, col=2)


#Smoothing_spline
#SS <- smooth.spline(complete_obs$staupxtra_psyhos_num, complete_obs$SSI_current)
#lines(SS, col=2)

```

```{r}
par(mfrow=c(1,3))
plot(cleaned_bl_longitudinal_2021$BHS_score,cleaned_bl_longitudinal_2021$SSI_worst,xlab="BHS_score",ylab="SSI_Worst") 
plot(cleaned_bl_longitudinal_2021$HAM_17items,cleaned_bl_longitudinal_2021$SSI_worst,xlab="HAM_17items",ylab="SSI_Worst")
plot(cleaned_bl_longitudinal_2021$staupxtra_psyhos_num,cleaned_bl_longitudinal_2021$SSI_worst,xlab="staupxtra_psyhos_num",ylab="SSI_Worst")
```

```{r}
#The question I need to answer:
#you have a wealth of variables and how do you communicate that? 
#Answer: I am looking at variables that show a moderate correlation between SSI_Current and SSI_Worst. Therefore the value I chose is 0.3 which is represented by the dotted line above. I decided to include some predictors above 0.2 as well because although they have a smaller correlation, these are some of the more interesting predictors (since several of the ones above 0.3 are variations of sis) On the other hand, there arent any variables negatively correlated above 0.3 so I also brought it down to 0.2. Everything is statistically significant at 0.05. 
```

```{r}
#I cant use the entire dataset because of NA values and I also cant do Na.omit so instead I'm trying something different. 
#I kept the response variable in as well. 
set.seed(12)
lassoData_curr <- mice(cleaned_bl_longitudinal_2021, m=5)



#Do I scale this data?
#Should I make this a binary outcome variable?
#how would I do this? 
```

```{r}
finish_imputed_data <- complete(lassoData_curr,1)
```

```{r}
finish_imputed_data <- finish_imputed_data %>% mutate(NewC = ifelse(staupxtra_psyhos_num > 20,20, staupxtra_psyhos_num))
```

```{r}
#Im gonna create a scaled dataset for lasso later 
scaled_data <- cbind(scale(finish_imputed_data[c(1:48,51:57)]), finish_imputed_data[c(49,50)])
scaled_data <- scaled_data[,-1]
```

```{r}
#Train Set 80/20
#Lets start with SSI_Current in the 118 column
size <- floor(0.8 * nrow(scaled_data))

train_indices <- sample(seq_len(nrow(scaled_data)), size = size)

train <- scaled_data[train_indices, ]
xtrain <- train[,c(1:54)]
ytrain <- train[,55]

test <- scaled_data[-train_indices,]
xtest <- test[,c(1:54)]
ytest <- test[,55]
sum(is.na(finish_imputed_data))
#Remember that y test only has SSI_current
```

```{r}
set.seed(123)
lambdalasso <- cv.glmnet(as.matrix(xtrain), (ytrain>0), type.measure = "mse", alpha=1)
lambdalasso
```

```{r}
#I really dont get this part, does the lambda value matter? I know that its the tuning parameter but Im still a bit iffy. 
#lmLasso <- glmnet(xtrain,ytrain, alpha=1)
set.seed(124)
lmLasso <- glmnet(as.matrix(xtrain), (ytrain>0), alpha = 1, lambda = 0.05692, family = "binomial")
```

```{r}
coef(lmLasso)
```
```{r}
predicted_lasso <- predict(lmLasso, s = lambdalasso$lambda.min, newx = as.matrix(xtrain))
mean((predicted_lasso - ytest)^2)

#I want to look closer at the highest coefficients to see if they match up with what I got earlier. 
```


Should we calculate MSE, SSE, and SST? 











