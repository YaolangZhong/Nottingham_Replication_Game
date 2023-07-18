## compare different market-based interest rate uncertainty measures

library(dplyr)
library(lubridate)
library(xtable)
library(ggplot2)
library(tidyr)

## measures from Bloomberg
setwd("/Users/yaolangzhong/Nottingham_Replication/original_code/")
load("data/bloomberg_uncertainty.RData")
bb <- data %>% as_tibble %>%
    arrange(date) %>%
    rename(SWIV = USSN011) %>%
    mutate(SWIV = SWIV/100, SRVIX = SRVIX/100, MOVE = MOVE/100)
## TYVIX: 01/01/2002 discontinued 5/18/2020

## mpu
load("data/mpu10.RData")
data <- mpu10 %>%
    rename(mpu = mpu10, bpvol = bpvol10, normal = normal10) %>%
    select(-f10, -normal)

## Bundick's data
bun <- read.csv("data/bundick.csv") %>% as_tibble %>%
    mutate(date = make_date(year, month, day)) %>%
    select(date, edx4q)

## Swanson's data - Swanson and Williams
swan <- read.delim("data/swanson.txt", header=FALSE) %>% as_tibble %>%
    mutate(date = as.Date(V1, "%Y  %m  %d"),
           swan = V4 - V2) %>%
    na.omit %>%
    select(date, swan)

## TIV - 1982-2018, but from 2016-01-20 equal to TYVIX
tiv <- read.csv("data/tiv.csv", na.strings="#N/A") %>% as_tibble %>%
    rename(date = Date, TIV = TIV_10y) %>%
    mutate(date = as.Date(date, format  = "%m/%d/%Y")) %>%
    select(date, TIV)

## combine data
data <- data %>%
    left_join(bun) %>%
    left_join(swan) %>%
    left_join(bb) %>%
    left_join(tiv)

## combine TIV and TYVIX
data %>% select(date, TIV, TYVIX) %>%
    filter(date < make_date(2016, 01, 20)) %>%
    na.omit %>% with(cor(TIV, TYVIX))
## from 2016/01/20 Philippe just used the TYVIX
data %>% select(date, TIV, TYVIX) %>%
    filter(date >= make_date(2016, 01, 20)) %>%
    na.omit %>% with(cor(TIV, TYVIX))
data$TIV <- rowMeans(cbind(data$TIV, data$TYVIX), na.rm=TRUE)
data$TYVIX <- NULL

## FOMC announcement days
fomc <- read.csv("data/fomc_tight.csv") %>% as_tibble %>%
    rename(date = Date) %>%
    mutate(date = ifelse(date=="3/15/2020", "3/16/2020", date),
           date = as.Date(date, format="%m/%d/%Y")) %>%
    select(date) %>%
    mutate(fomc = 1)

## summary stats for appendix
## E(u), var(u), E(du), var(du), starts, ends, nobs
nms <- names(data)[-1]
nms_long <- c("SRU", "BP vol", "Bundick", "Swanson", "Swaption IV", "SRVIX", "MOVE", "TIV/TYVIX")
changes <- data %>%
    mutate(across(all_of(nms), ~(.x - lag(.x)))) %>%
    left_join(fomc) %>%
    mutate(fomc = replace_na(fomc, 0))

tbl <- data %>% summarise(across(all_of(nms), mean, na.rm=TRUE)) %>%
    add_row(data %>% summarise(across(all_of(nms), sd, na.rm=TRUE))) %>%
    add_row(changes %>% summarise(across(all_of(nms), sd, na.rm=TRUE))) %>%
    add_row(data %>% summarise(across(all_of(nms), ~sum(!is.na(.x))))) %>%
    t
colnames(tbl) <- c("Elev", "SDlev", "SDch", "nobs")
tbl <- as_tibble(tbl) %>%
    mutate(name = nms,
           long = nms_long)
tbl$starts <- sapply(nms, function(nm)
    data %>% select(date, all_of(nm)) %>% na.omit %>% summarise(min = min(format(date))) %>% as.character
    )
tbl$ends <- sapply(nms, function(nm)
    data %>% select(date, all_of(nm)) %>% na.omit %>% summarise(max = max(format(date))) %>% as.character
    )
formdate <- function(d) paste0(sprintf("%02d", month(d)), "/", year(d))
tbl$period <- sapply(nms, function(nm)
    data %>% select(date, all_of(nm)) %>% na.omit %>% summarise(paste(formdate(min(date)), formdate(max(date)), sep="-")) %>% as.character
    )
tbl$cor.mpu <- cor(data$mpu, data[nms], use="pairwise.complete") %>% as.numeric
tbl$cor.dmpu <- cor(changes$mpu, changes[nms], use="pairwise.complete") %>% as.numeric
tbl <- tbl %>%
    select(-starts, -ends) %>%
    relocate(name, long, Elev, SDlev, SDch, cor.mpu, cor.dmpu, period, nobs) %>%
    print
tbl <- select(tbl, -name)

cat("Correlations of changes on all days:\n")
round(cor(changes$mpu, changes[nms], use="pairwise.complete"), 3)

cat("Correlations of changes on FOMC days only:\n")
print(round(cor(changes$mpu[changes$fomc==1], changes[changes$fomc==1,nms], use="pairwise.complete"), 3))

print(xtable(tbl, digits = c(0,3,3,3,3,3,3,0,0)),
      include.rownames=FALSE, include.colnames=FALSE, only.contents=TRUE,
      sanitize.text.function=function(x){x}, hline.after=NULL,
      file="output/table_1.tex")

## figure for appendix
pdat <- data %>%
    select(date, mpu, edx4q, swan) %>%
    filter(year(date) >= 1994,
           year(date) <= 2008) %>%
    rename(SRU = mpu, Bundick = edx4q, Swanson = swan) %>%
    pivot_longer(!date, names_to = "series", values_to = "y") %>%
    mutate(series = factor(series, levels = c("SRU", "Bundick", "Swanson")))

ggplot(pdat) +
    geom_line(aes(x=date, y=y, color=series)) +
    theme_bw() +
    theme(legend.position = c(0.8, 0.8),
          legend.background = element_rect(colour="black"),
          plot.margin=grid::unit(c(0,0,0,0), "mm"),
          legend.title = element_blank()) +
    scale_color_manual(values = c("black", "red", "chartreuse4")) +
    ylim(0,max(pdat$y, na.rm=TRUE)) +
    xlab("") + ylab("Percent")
ggsave("output/figure_A2.pdf", width=6, height=4)





############### Synthesize ################

####### PCA #########
pca_series = na.omit(data[,c('mpu', 'edx4q', 'swan')]) %>%rename(SRU = mpu, Bundick = edx4q, Swanson = swan)
pca_result <- prcomp(pca_series)

print(summary(pca_result))
pca_components <- pca_result$x
pca_loadings <- pca_result$rotation
PC1 = -pca_components[, "PC1"]
pca_data <- data %>%
  select(date, mpu, edx4q, swan) %>%
  na.omit() %>%
  rename(SRU = mpu, Bundick = edx4q, Swanson = swan) %>%
  cbind(PC1)

# pivot the data to a longer format
pdat <- pca_data %>%
  pivot_longer(cols = -date, names_to = "series", values_to = "y")
# plot
global_min = min(pdat$y, na.rm = TRUE)
global_max = max(pdat$y, na.rm = TRUE)
ggplot(pdat) +
  geom_line(aes(x=date, y=y, color=series)) +
  theme_bw() +
  theme(legend.position = c(0.8, 0.8),
        legend.background = element_rect(colour="black"),
        plot.margin=grid::unit(c(0,0,0,0), "mm"),
        legend.title = element_blank()) +
  scale_color_manual(values = c("black", "red", "chartreuse4", "blue")) +
  ylim(global_min, global_max) +
  xlab("") + ylab("Percent")

ggsave("output/figure_A2_PCA.pdf", width=6, height=4)

####### Factor Analysis #########
# Prepare the data
library(psych)
factor_series <- na.omit(data[,c('mpu', 'edx4q', 'swan')])
# Perform factor analysis
factor_result <- psych::fa(factor_series, nfactors = 1)
# Get factor scores
factor_scores <- psych::factor.scores(factor_series, factor_result)$scores

# Bind the factor scores to the data
factor_data <- data %>%
  select(date, mpu, edx4q, swan) %>%
  na.omit() %>%
  rename(SRU = mpu, Bundick = edx4q, Swanson = swan) %>%
  cbind(Factor1 = factor_scores[,1])


# pivot the data to a longer format
pdat <- factor_data %>%
  pivot_longer(cols = -date, names_to = "series", values_to = "y")
# plot
global_min = min(pdat$y, na.rm = TRUE)
global_max = max(pdat$y, na.rm = TRUE)
ggplot(pdat) +
  geom_line(aes(x=date, y=y, color=series)) +
  theme_bw() +
  theme(legend.position = c(0.8, 0.8),
        legend.background = element_rect(colour="black"),
        plot.margin=grid::unit(c(0,0,0,0), "mm"),
        legend.title = element_blank()) +
  scale_color_manual(values = c("black", "red", "chartreuse4", "blue")) +
  ylim(global_min, global_max) +
  xlab("") + ylab("Percent")

ggsave("output/figure_A2_FA.pdf", width=6, height=4)
