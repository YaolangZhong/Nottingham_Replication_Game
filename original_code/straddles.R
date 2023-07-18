## summary stats for straddle returns on FOMC days

library(dplyr)
library(lubridate)
library(xtable)

## returns of Eurodollar option ATM straddles around FOMC announcements
load("data/straddle_returns_fomc.RData")
data <- data %>%
    mutate(ym = year(date)*100 + month(date)) %>%
    filter(year(date) >= 1994,            # start in 1994
           ym <= 200706 | ym >= 200907)   # exclude crisis

return_stats <- function(R) {
    skew <- mean((R-mean(R))^3)/sd(R)^3
    kurt <- mean((R-mean(R))^4)/sd(R)^4
    mod <- lm(R ~ 1)
    tstat <- mod$coef/sqrt(sandwich::vcovHC(mod, type="HC"))
    c(sprintf("%4.1f", mean(R)),
      round(c(median(R), sd(R), skew, kurt, tstat,
              abs(sqrt(8)*mean(R))/sd(R)), 1),
      round(length(R)))
}

tbl <- matrix(NA, 8, 6)
colnames(tbl) <- paste0("ED", 1:6)
rownames(tbl) <- c("Mean", "Median", "SD", "Skewness", "Kurtosis", "$t$-statistic", "Sharpe ratio", "Observations")
tbl2 <- tbl
## spread <- 0.015
for (j_ in 1:6) {
    tmp <- data %>% filter(j == j_)
    ## (1) relative returns
    tbl[,j_] <- return_stats(na.omit(tmp$Rrel))
    ## (2) absolute returns
    tbl2[,j_] <- return_stats(na.omit(tmp$Rabs))
}
print(tbl)
print(tbl2)

sink("output/table_C3.tex")
cat("& ED1 & ED2 & ED3 & ED4 & ED5 & ED6 \\\\ \n")
cat("\\midrule \n")
cat("\\multicolumn{6}{l}{\\emph{Relative returns}}\\\\ \n")
print(xtable(tbl[1:7,]),
      include.rownames=TRUE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\midrule \n")
cat("\\multicolumn{6}{l}{\\emph{Absolute returns}}\\\\ \n")
print(xtable(tbl2[1:7,]),
      include.rownames=TRUE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL)
cat("\\midrule \n")
cat("Observations",sprintf("& %s", tbl[8,]), "\\\\ \n")
sink()
