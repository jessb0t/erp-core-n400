# ERP CORE Stats and Plots
# Author: Jessica M. Alexander

# SET UP: build dataframe with participant IDs, mean amplitudes, sex, and response time
library(readxl)
library(gt)
library(webshot)
library(ggplot2)
library(broom)
library(gridExtra)

today <- Sys.Date()
today <- format(today, "%Y%m%d")

# Define subjects
subjects <- c(1:39)

# Establish directories
maindir <- "/Users/jalexand/github/erp-core-n400"
meanAmplitudes <- paste(maindir, "/results/n400_meanAmplitudes_20220409.csv", sep="", collapse=NULL)
behavior <- paste(maindir, "/data/raw-behavior/", sep="", collapse=NULL)
demographics <- paste(maindir, "/data/demo/Participant_Demographics.xlsx", sep="", collapse=NULL)

# Read in amplitude and demographic data
amplitudes <- read.csv(file=meanAmplitudes, stringsAsFactors=FALSE)
demo <- read_excel(demographics, sheet=NULL)

# Drop rejected participants from demographics data
demo <- demo[subjects,]

# Use amplitudes df as main df, append participant sex and age from demographics df, add empty vector for response time
df <- amplitudes
df$sex <- demo$Sex
df$age <- demo$Age
df$deltaLogRT <- vector(mode="numeric", length=39)

# Extract participant delta RT (unrelated minus related, for correct trials only) from behavior file and add to main df
listBehavFiles <- list.files(behavior)
for (i in subjects){
  fileparts <- unlist(strsplit(listBehavFiles[i], "-"))
  id <- as.numeric(fileparts[1])
  subBehavior <- read.csv(file=paste(behavior, listBehavFiles[i], sep="", collapse=NULL), stringsAsFactors=FALSE)
  subBehaviorCorr <- na.omit(subBehavior[subBehavior$Response==201,])
  subBehaviorCorrUnrelated <- subBehaviorCorr[subBehaviorCorr$Condition=="Unrelated",]
  subBehaviorCorrRelated <- subBehaviorCorr[subBehaviorCorr$Condition=="Related",]
  deltaLogRT <- log10(mean(subBehaviorCorrUnrelated$RT)) - log10(mean(subBehaviorCorrRelated$RT))
  whichRow <- df$id==id
  df$deltaLogRT[whichRow] <- deltaLogRT
}

# DEMOGRAPHICS TABLE: create table with demographic information
demo_table <- data.frame(matrix(ncol=2, nrow=2))
colnames(demo_table) <- c("datapoint", "content")
demo_table[1,1] <- "age"
demo_table[2,1] <- "sex"

meanAge <- round(mean(df$age),2)
sdAge <- round(sd(df$age),2)
minAge <- min(df$age)
maxAge <- max(df$age)
ageContent <- paste("mean: ", meanAge, ", sd: ", sdAge, ", range: ", minAge, "-", maxAge, sep="", collapse=NULL)
demo_table[1,2] <- ageContent

noMale <- sum(df$sex=="M")
noFemale <- sum(df$sex=="F")
percMale <- round(noMale/length(df$sex)*100,1)
percFemale <- round(noFemale/length(df$sex)*100,1)
sexContent <- paste(noMale, " M (", percMale, "%), ", noFemale, " F (", percFemale, "%)", sep="", collapse=NULL)
demo_table[2,2] <- sexContent

demo_table %>%
  gt() %>%
    tab_header(
      title = "N400 from ERP CORE",
      subtitle = "Participant Demographics"
    ) %>%
  tab_style(cell_text(color="white"), cells_column_labels()
    ) %>%
  tab_options(column_labels.padding=0, heading.align="left") %>%
  gtsave(paste("n400_demoTable_", today, ".png", sep="", collapse=NULL), path="/Users/jalexand/github/erp-core-n400/results/")

# Duplicate main df and replace "M/F" with "all", then factorize for visual display in plotSexRT and plotSexAmp
dupDF <- df
dupDF$sex <- rep("all", length(dupDF$sex))
dupDF <- rbind(df, dupDF)
dupDF$sex <- as.factor(dupDF$sex)


# CHECKING ASSUMPTIONS
# Separate groups into separate dataframes
dfMale <- dupDF[dupDF$sex=="M",]
dfFemale <- dupDF[dupDF$sex=="F",]
dfAll <- dupDF[dupDF$sex=="all",]

# Add column for residuals against group mean
dfMale$residDeltaLogRT <- mean(dfMale$deltaLogRT)-dfMale$deltaLogRT
dfMale$residAmp <- mean(dfMale$amplitudesUnrelMinusRel)-dfMale$amplitudesUnrelMinusRel
dfFemale$residDeltaLogRT <- mean(dfFemale$deltaLogRT)-dfFemale$deltaLogRT
dfFemale$residAmp <- mean(dfFemale$amplitudesUnrelMinusRel)-dfFemale$amplitudesUnrelMinusRel
dfAll$residDeltaLogRT <- mean(dfAll$deltaLogRT)-dfAll$deltaLogRT
dfAll$residAmp <- mean(dfAll$amplitudesUnrelMinusRel)-dfAll$amplitudesUnrelMinusRel

# Plot histograms of residuals (unstandardized and standardized)
histoResidMaleRT <- ggplot(data=dfMale, aes(x=residDeltaLogRT)) + geom_histogram(binwidth=0.02)
histoResidFemaleRT <- ggplot(data=dfFemale, aes(x=residDeltaLogRT)) + geom_histogram(binwidth=0.02)
histoResidAllRT <- ggplot(data=dfAll, aes(x=residDeltaLogRT)) + geom_histogram(binwidth=0.02)

histoStndResidMaleRT <- ggplot(data=dfMale, aes(x=residDeltaLogRT/sd(residDeltaLogRT))) + geom_histogram(binwidth=0.5)
histoStndResidFemaleRT <- ggplot(data=dfFemale, aes(x=residDeltaLogRT/sd(residDeltaLogRT))) + geom_histogram(binwidth=0.5)
histoStndResidAllRT <- ggplot(data=dfAll, aes(x=residDeltaLogRT/sd(residDeltaLogRT))) + geom_histogram(binwidth=0.5)

histoResidMaleAmp <- ggplot(data=dfMale, aes(x=residAmp)) + geom_histogram(binwidth=0.2)
histoResidFemaleAmp <- ggplot(data=dfFemale, aes(x=residAmp)) + geom_histogram(binwidth=0.2)
histoResidAllAmp <- ggplot(data=dfAll, aes(x=residAmp)) + geom_histogram(binwidth=0.2)

histoStndResidMaleAmp <- ggplot(data=dfMale, aes(x=residAmp/sd(residAmp))) + geom_histogram(binwidth=0.2)
histoStndResidFemaleAmp <- ggplot(data=dfFemale, aes(x=residAmp/sd(residAmp))) + geom_histogram(binwidth=0.2)
histoStndResidAllAmp <- ggplot(data=dfAll, aes(x=residAmp/sd(residAmp))) + geom_histogram(binwidth=0.2)

# Plot values versus residuals
plotRTvresidDeltaLogRTMale <- ggplot(data=dfMale, aes(x=deltaLogRT, y=residDeltaLogRT)) + geom_point()
plotRTvresidDeltaLogRTFemale <- ggplot(data=dfFemale, aes(x=deltaLogRT, y=residDeltaLogRT)) + geom_point()
plotRTvresidDeltaLogRTAll <- ggplot(data=dfAll, aes(x=deltaLogRT, y=residDeltaLogRT)) + geom_point()

plotAmpvResidAmpMale <- ggplot(data=dfMale, aes(x=amplitudesUnrelMinusRel, y=residAmp)) + geom_point()
plotAmpvResidAmpFemale <- ggplot(data=dfFemale, aes(x=amplitudesUnrelMinusRel, y=residAmp)) + geom_point()
plotAmpvResidAmpAll <- ggplot(data=dfAll, aes(x=amplitudesUnrelMinusRel, y=residAmp)) + geom_point()

# STATISTICS
deltaLogRTv0 <- t.test(df$deltaLogRT, mu=0, alternative="two.sided", conf.level=0.95)
deltaAmpv0 <- t.test(df$amplitudesUnrelMinusRel, mu=0, alternative="two.sided", conf.level=0.95)
sexDeltaLogRT <- t.test(deltaLogRT ~ sex, data=df, alternative="two.sided", conf.level=0.95)
sexDeltaAmp <- t.test(amplitudesUnrelMinusRel ~ sex, data=df, alternative="two.sided", conf.level=0.95)
deltaLogRTvAmp <- lm(deltaLogRT ~ amplitudesUnrelMinusRel, data=df)
deltaLogRTvAmp %>%
  glance()


# PLOTS
plotDeltas1 <- ggplot(data=df, aes(x=amplitudesUnrelMinusRel)) +
  geom_density(kernel="gaussian", fill="#a0da39", color="#a0da39", alpha=0.5) +
  xlim(-3,1) +
  theme_classic() +
  labs(x=expression(paste("N400 Amplitude Delta ( ", mu, "V)")), y="Density")
plotDeltas2 <- ggplot(data=df, aes(x=deltaLogRT)) +
  geom_density(kernel="gaussian", fill="#365c8d", color="#365c8d", alpha=0.5) +
  xlim(-3,1) +
  theme_classic() +
  labs(x="Response Time Delta (ms, log-transformed)", y="Density")
plotDeltas <- grid.arrange(plotDeltas1, plotDeltas2, nrow = 2,
                           top="ERP CORE N400: Density Plot\nN400 Amplitude Delta and Response Time Delta")
ggsave(paste("plotDeltas_", today, ".png", sep="", collapse=NULL), path="/Users/jalexand/github/erp-core-n400/results/",
       plot=plotDeltas, dpi=300, height=87, width=157, units="mm")

plotSexRT <- ggplot(data=dupDF, aes(x=sex, y=deltaLogRT, fill=sex)) + geom_boxplot(show.legend=FALSE) + theme_minimal() +
  scale_fill_manual(values=c("#fde725", "#5ec962", "#21918c")) +
  scale_x_discrete(labels=c("All Participants", "Female Group", "Male Group")) +
  labs(x="Participant Sex", y="Response Time Delta\n(ms, log-transformed)",
       title="ERP CORE N400: Response Time", subtitle="All Participants, Female Group, and Male Group")
ggsave(paste("plotSexRT_", today, ".png", sep="", collapse=NULL), path="/Users/jalexand/github/erp-core-n400/results/",
       plot=plotSexRT, dpi=300, height=87, width=157, units="mm")

plotSexAmp <- ggplot(data=dupDF, aes(x=sex, y=amplitudesUnrelMinusRel, fill=sex)) + geom_boxplot(show.legend=FALSE) + theme_minimal() +
  scale_fill_manual(values=c("#fde725", "#5ec962", "#21918c")) +
  scale_x_discrete(labels=c("All Participants", "Female Group", "Male Group")) +
  labs(x="Participant Sex", y=expression(paste("N400 Amplitude Delta ( ", mu, "V)")),
       title="ERP CORE N400: ERP Amplitude", subtitle="All Participants, Female Group, and Male Group")
ggsave(paste("plotSexAmp_", today, ".png", sep="", collapse=NULL), path="/Users/jalexand/github/erp-core-n400/results/",
       plot=plotSexAmp, dpi=300, height=87, width=157, units="mm")

plotDeltaLogRTvAmp <- ggplot(data=df, aes(x=amplitudesUnrelMinusRel, y=deltaLogRT, color=sex)) + geom_point() + theme_minimal() +
  geom_smooth(method="lm") +
  scale_color_manual(name="Sex:", labels=c("Female", "Male"), values=c("#5ec962", "#21918c")) +
  theme(legend.position="top") +
  labs(x=expression(paste("N400 Amplitude Delta ( ", mu, "V)")), y="Response Time Delta\n (ms, log-transformed)",
       title="Mean N400 Amplitude versus Response Time", subtitle="Unrelated Minus Related Condition")
ggsave(paste("plotDeltaLogRTvAmp_", today, ".png", sep="", collapse=NULL), path="/Users/jalexand/github/erp-core-n400/results/",
       plot=plotDeltaLogRTvAmp, dpi=300, height=87, width=157, units="mm")