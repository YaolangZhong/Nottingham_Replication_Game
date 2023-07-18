## relate MPU to macro uncertainty

library(dplyr)
library(sandwich)
library(lubridate)
library(xtable)

load("data/mpu.RData")
mpu <- rename(mpu,
              mpu = mpu10, f = f10)

## monthly uncertainty
datam <- mpu %>%
    mutate(ym = as.numeric(format(date, "%Y%m"))) %>%
    group_by(ym) %>%
    summarize(mpu = mean(mpu), f = mean(f), .groups="drop") %>%
    ungroup

## quarterly uncertainty
dataq <- mpu %>%
    mutate(yq = 10*year(date) + quarter(date)) %>%
    group_by(yq) %>%
    summarize(mpu = mean(mpu), f = mean(f), .groups="drop") %>%
    ungroup

## JLN macro uncertainty
jln <- read.csv("data/MacroUncertainty_JLN.csv") %>% as_tibble %>%
    mutate(date = seq.Date(as.Date("1960-07-01"), by="month", len=n()),
           ym = as.numeric(format(date, "%Y%m"))) %>%
    select(-Date)
datam <- left_join(datam, jln)

## real time macro uncertainty - Rogers-Xu
rtmu <- read.csv("data/real_time_MU_RX.csv", sep=";", dec=",", col.names=c("date", "mu")) %>% as_tibble %>%
    mutate(date = as.Date(date),
           ym = year(date)*100+month(date))
datam <- left_join(datam, rtmu)

## SPF forecast dispersion
spf <- read.csv("data/SPF_Dispersion_PGDP_D2.csv", sep=";", dec=",", na.string="#N/A", skip=9) %>% as_tibble %>%
    mutate(year = as.numeric(substr(Survey_Date.T.,1,4)),
           quarter = as.numeric(substr(Survey_Date.T.,6,6))) %>%
    filter(year >= 1990) %>%
    mutate(yq = year*10 + quarter) %>%
    rename(PGDPD2T = PGDP_D2.T.,
           PGDPD2T1 = PGDP_D2.T.1.,
           PGDPD2T2 = PGDP_D2.T.2.,
           PGDPD2T3 = PGDP_D2.T.3.,
           PGDPD2T4 = PGDP_D2.T.4.) %>%
    select(yq, starts_with("PGDPD2"))
dataq <- left_join(dataq, spf)

tbl <- data.frame(matrix(NA, 8, 5))
tbl[,1] <- c("Intercept", "", "Slope", "", "$R^2$", "Observations", "Sample", "")
colnames(tbl) <- c("", "JLN", "JLN", "Rogers-Xu", "SPF PGDP")
mods <- list(lm(mpu ~ h.12, datam),
             lm(mpu ~ h.12, datam %>% filter(year(date) >= 1999)),
             lm(mpu ~ mu, datam),
             lm(mpu ~ PGDPD2T4, dataq))
for (j in 1:4) {
    m <- mods[[j]]
    se <- sqrt(diag(NeweyWest(m)))
    tbl[c(1,3), 1+j] <- sprintf("%4.2f", m$coef)
    tbl[c(2,4), 1+j] <- sprintf("[%4.2f]", abs(m$coef/se))
    tbl[5, 1+j] <- round(summary(m)$r.squared,2)
    tbl[6, 1+j] <- length(resid(m))
}
tbl[7, 2:4] <- c("Monthly")
tbl[7, 5] <- c("Quarterly")
range(datam$ym[!is.na(datam$h.12)])
tbl[8, 2] <- c("1990:M1--2020:M6")
tbl[8, 3] <- c("1999:M1--2020:M6")
range(datam$ym[!is.na(datam$mu)])
tbl[8, 4] <- c("1999:M9--2018:10")
range(dataq$yq[!is.na(dataq$PGDPD2T4)])
tbl[8, 5] <- c("1990:Q1--2020:Q1")
print(tbl)

print(xtable(tbl),
      include.rownames=FALSE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=4,
      file="output/table_B1.tex", booktabs = TRUE)
