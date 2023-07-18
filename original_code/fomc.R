## MPU on FOMC days

library(dplyr)
library(tidyr)
library(lubridate)
library(xtable)
library(sandwich)

## FOMC announcements
fomc <- read.csv("data/fomc_tight.csv", na.string=".") %>% as_tibble %>%
    rename(date = Date) %>%
    mutate(date = as.Date(date, "%m/%d/%Y"),
           meeting = 1) %>%
    filter(year(date) >= 1994) %>%
    select(date, Unscheduled, meeting)

## constant maturity uncertainty measure
load("data/mpu.RData")
data <- mpu %>%
    mutate(dmpu = c(NA, diff(mpu10))) %>%  ## daily changes in one-year measure
    left_join(fomc) %>%
    mutate(meeting = replace_na(meeting, 0),
           Unscheduled = replace_na(Unscheduled, 0),
           ym = year(date)*100 + month(date)) %>%
    select(date, meeting, Unscheduled, dmpu, ym)
fomc <- data %>% filter(meeting==1)
range(fomc$date)

cat("# meetings with largest declines in uncertainty (as in Table 3)\n")
data %>% filter(meeting==1) %>%
    select(date, dmpu, Unscheduled) %>%
    arrange(dmpu) %>%
    print(n=10)
cat("# meetings with largest increases in uncertainty (as in Table 3)\n")
data %>% filter(meeting==1) %>%
    select(date, dmpu, Unscheduled) %>%
    arrange(-dmpu) %>%
    print(n=5)

##################################################
## Table C.1 -- changes in MPU/RNV for each contract
l <- load("data/mpu_contracts.RData")
data <- results %>% as_tibble %>%
    select(date, exp, contract, mpu) %>%
    mutate(rnv = mpu^2,
           j = as.numeric(substr(contract, 3, 4)),
           ym = year(date)*100 + month(date)) %>%
    group_by(exp) %>%
    mutate(dmpu = mpu - lag(mpu),
           dv = rnv - lag(rnv)) %>%
    ungroup %>%
    filter(ym <= 200706 | ym >= 200907, # exclude crisis
           ym >= 199401 & ym <= 202009) %>% # sample period
    left_join(fomc %>% select(date, meeting, Unscheduled)) %>%
    mutate(meeting = replace_na(meeting, 0),
           Unscheduled = replace_na(Unscheduled, 0)) %>%
    filter(Unscheduled == 0) %>% select(-Unscheduled) # exclude unscheduled meetings

J <- 6 # number of contracts to include in analysis
cat("Sample period:", format(range(data$date)), "\n")
cat("# Summary statistics for changes in variances on FOMC meetings\n")
nms <- c("Mean", "$t$-statistic", "Median", "Standard deviation", "Fraction negative", "Observations")
tbl <- matrix(NA, length(nms), J)
rownames(tbl) <- nms
colnames(tbl) <- paste0("ED", 1:J)
for (j_ in 1:J) {
    x <- data %>% filter(j == j_, meeting == 1) %>% pull(dv)
    nobsna <- sum(is.na(x)); x <- na.omit(x); nobs <- length(x)
    mod <- lm(x~1); v <- vcovHC(mod, type="HC0"); tstat <- mod$coef/sqrt(v)
    tbl[,j_] <- c(mean(x), tstat, median(x), sd(x), sum(x>0)/nobs, nobs)
}
print(round(tbl,3))
cat("# Square roots of (neg) mean/median of variance changes:\n")
print(round(sqrt(-tbl[c(1,3),]), 3))
cat("# Summary statistics for changes in MPU around FOMC meetings\n")
tbl2 <- matrix(NA, nrow(tbl), ncol(tbl))
rownames(tbl2) <- rownames(tbl); colnames(tbl2) <- colnames(tbl)
for (j_ in 1:J) {
    x <- data %>% filter(j == j_, meeting == 1) %>% pull(dmpu)
    x <- na.omit(x); nobs <- length(x)
    mod <- lm(x~1); v <- vcovHC(mod, type="HC0"); tstat <- mod$coef/sqrt(v)
    tbl2[,j_] <- c(mean(x), tstat, median(x), sd(x), sum(x>0)/nobs, nobs)
}
print(round(tbl2,3))
sink("output/table_C1.tex")
cat("& ED1 & ED2 & ED3 & ED4 & ED5 & ED6 \\\\ \n")
cat("\\midrule \n")
cat("\\multicolumn{4}{l}{\\emph{Changes in conditional variance}}\\\\ \n")
print(xtable(tbl[1:4,], digi=3),
      include.rownames=TRUE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\midrule \n")
cat("\\multicolumn{4}{l}{\\emph{Changes in $SRU$}}\\\\ \n")
print(xtable(tbl2[1:4,], digi=3),
      include.rownames=TRUE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\midrule \n")
cat("Observations",sprintf("& %d", tbl[6,]), "\\\\ \n")
cat("Fraction negative",sprintf("& %4.2f", tbl[5,]), "\\\\ \n")
sink()

## Table C.2: dummy regressions -- compare to days without FOMC
tbl <- data.frame(matrix(NA, 6, 1+J))
colnames(tbl) <- c("", paste0("ED", 1:J))
tbl[,1] <- c("Constant", "", "FOMC dummy", "", "$R^2$", "Observations")
tbl2 <- tbl
regstats <- function(mod) {
    b <- mod$coef; tstat <- b / sqrt(diag(sandwich::vcovHC(mod)))
    c(sprintf("%5.3f", b[1]),
      sprintf("[%4.2f]", tstat[1]),
      sprintf("%5.3f", b[2]),
      sprintf("[%4.2f]", tstat[2]),
      sprintf("%5.3f", summary(mod)$r.squared),
      length(mod$residuals))
}
for (j_ in 1:J) {
    regdat <- data %>% filter(j == j_)
    mod <- lm(dv ~ meeting, regdat)
    tbl[,j_+1] <- regstats(mod)
    mod2 <- lm(dmpu ~ meeting, regdat)
    tbl2[,j_+1] <- regstats(mod2)
}
cat("# Change in varianc due to FOMC meetings (if no jumps on other days, negative is mean jump variance)\n")
print(tbl)
cat("# Jump volatility - square root of negative dummy coefficient:\n")
print(round(sqrt(-as.numeric(tbl[3,-1])),3))
cat("# Decline in MPU due to FOMC meetings\n")
print(tbl2)
## now produce a nice table for appendix -- top panel d.RNV, bottom panel d.MPU
sink("output/table_C2.tex")
cat("& ED1 & ED2 & ED3 & ED4 & ED5 & ED6 \\\\ \n")
cat("\\midrule \n")
cat("\\multicolumn{4}{l}{\\emph{Changes in conditional variance}}\\\\ \n")
print(xtable(tbl[1:5,]),
      include.rownames=FALSE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\emph{Memo}: estimated jump vol.", sprintf("& %5.3f", sqrt(-as.numeric(tbl[3,-1]))), "\\\\ \n")
cat("\\midrule \n")
cat("\\multicolumn{4}{l}{\\emph{Changes in $SRU$}}\\\\ \n")
print(xtable(tbl2[1:5,]),
      include.rownames=FALSE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\midrule \n")
cat("Observations",sprintf("& %s", tbl[6,-1]), "\\\\ \n")
sink()

## Table D.5 -- rampup
regdat <- data %>%
    rename(FOMC = meeting) %>%
    group_by(exp) %>%
    mutate(dmpu = 100*dmpu,
           D1 = lag(FOMC),
           D2 = lag(FOMC, 2),
           D3 = lag(FOMC, 3),
           D4 = lag(FOMC, 4),
           D5 = lag(FOMC, 5),
           D6 = lag(FOMC, 6),
           D7 = lag(FOMC, 7),
           D8 = lag(FOMC, 8),
           D9 = lag(FOMC, 9),
           D10 = lag(FOMC, 10),
           D11 = lag(FOMC, 11),
           D12 = lag(FOMC, 12),
           D13 = lag(FOMC, 13),
           D14 = lag(FOMC, 14),
           D15 = lag(FOMC, 15),
           D16 = lag(FOMC, 16),
           D17 = lag(FOMC, 17),
           D18 = lag(FOMC, 18),
           D19 = lag(FOMC, 19),
           D20 = lag(FOMC, 20),
           D21 = lag(FOMC, 21),
           D22 = lag(FOMC, 22),
           D23 = lag(FOMC, 23),
           D24 = lag(FOMC, 24),
           D25 = lag(FOMC, 25),
           W1 = D1 + D2 + D3 + D4 + D5,
           W2 = D6 + D7 + D8 + D9 + D10,
           W3 = D11 + D12 + D13 + D14 + D15,
           W4 = D16 + D17 + D18 + D19 + D20,
           W5 = D21 + D22 + D23 + D24 + D25) %>%
    ungroup
## this ignores unscheduled meeting that may have occured but are deleted from data set -- further analysis showed this does not matter
regs <- c("FOMC", paste0("W", 1:5))
fmla <- formula(paste("dmpu ~", paste(regs, collapse="+")))
tbl <- data.frame(matrix(NA, 4+length(regs)*2, 1+J))
colnames(tbl) <- c("", paste0("ED", 1:J))
tbl[,1] <- c(t(cbind(c("Constant", regs), "")), "$R^2$", "Observations")
regstats <- function(mod) {
    b <- mod$coef; tstat <- b / sqrt(diag(sandwich::vcovHC(mod)))
    c(t(cbind(sprintf("%4.2f", b), sprintf("[%4.2f]", tstat))),
      sprintf("%5.3f", summary(mod)$r.squared), length(mod$residuals))
}
for (j_ in 1:J)
    tbl[,j_+1] <- regstats(lm(fmla, regdat %>% filter(j == j_)))
print(tbl)
sink("output/table_D5.tex")
cat("& ED1 & ED2 & ED3 & ED4 & ED5 & ED6 \\\\ \n")
cat("\\midrule \n")
print(xtable(head(tbl, -2)),
      include.rownames=FALSE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\midrule \n")
print(xtable(tail(tbl, 2)),
      include.rownames=FALSE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
sink()
