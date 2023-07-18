## analyze and plot LIBOR and OIS
library(xtable)

## load LIBOR-OIS spread
data <- read.csv("data/libor_ois.csv")[,1:3]
names(data)[2:3] <- c("libor", "ois")
data$spread <- 100*(data$libor - data$ois)
data$date <- as.Date(data$date, "%m/%d/%Y")
data$yyyymm <- as.numeric(format(data$date, "%Y%m"))
data <- subset(data, yyyymm >= 200200)
cat("Date range:", format(range(data$date)), "\n")

## load uncertainty
dat2 <- read.csv("data/mpu.csv")
dat2$date <- as.Date(dat2$date)
dat2$yyyymm <- as.numeric(format(dat2$date, "%Y%m"))
cat("MPU date range:", format(range(dat2$date)), "\n")

tbl <- matrix(NA, 3, 3)
colnames(tbl) <- c("Mean", "SD", "Avg MPU")
rownames(tbl) <- c("1/2002-6/2007", "7/2007-6/2009", "7/2009-10/2019")
for (i in 1:3) {
    from <- switch(i, 200201, 200707, 200907)
    to <- switch(i, 200706, 200906, 201712)
    ind <- data$yyyymm>=from & data$yyyymm<=to
    tbl[i,1:2] <- c(mean(data$spread[ind]), sd(data$spread[ind]))
    cat("SD of one year changes:\n")
    print(sd(diff(data$spread[ind], lag=250)))
    ind2 <- dat2$yyyymm>=from & dat2$yyyymm<=to
    tbl[i, 3] <- 100*mean(dat2$mpu10[ind], na.rm=TRUE)
}
print(round(tbl))
print(xtable(tbl, digits=0),
      only.contents=TRUE, include.colnames=FALSE, file="output/table_A1.tex")

pdf("output/figure_A1.pdf", width=6, height=7, pointsize=10)
date1 <- as.Date("2007-07-01"); date2 <- as.Date("2009-06-30")
par(mfrow=c(2,1), mar=c(3,4,0.5,0.5))
## top panel: LIBOR and OIS
cols <- c("black", "blue", "darkred")
yrange <- range(0,data$libor, data$ois, na.rm=TRUE)
plot(data$date, data$libor, type="l", col=cols[1], ylim=yrange, xlab="", ylab="Percent", xaxs = "i", yaxs = "i")
polygon(c(date1, date1, date2, date2), c(yrange, rev(yrange)), density=NA, col=adjustcolor("gray",alpha.f=0.5), border=NA)
lines(data$date, data$libor, col=cols[1])
lines(data$date, data$ois, col=cols[2])
legend("topright", c("LIBOR", "3m OIS rate"), col=cols, lty=1)
## bottom panel: spread
yrange <- range(0, data$spread)
plot(data$date, data$spread, col=cols[3], ylim=yrange, type="l", xaxs="i", yaxs = "i", ylab="Basis points")
polygon(c(date1, date1, date2, date2), c(yrange, rev(yrange)), density=NA, col=adjustcolor("gray",alpha.f=0.5), border=NA)
lines(data$date, data$spread, col=cols[3])
legend("topright", c("LIBOR-OIS spread"), col=cols[3], lty=1)
dev.off()
