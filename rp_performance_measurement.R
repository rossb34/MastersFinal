# Performance Measurement via Random Portfolios
library(PortfolioAnalytics)
source("helper_functions.R")

# Set the directory to save the optimization results
results.dir <- "performance_results"

fig.height <- 450
fig.width <- 950

##### Data #####
# Weekly returns from 1997-01-07 to 2010-12-28 of 15 large cap, 15 mid cap, 
# and 5 small cap stocks from CRSP data set.
source("data_prep.R")
n.assets <- NCOL(equity.data)

##### Constraints ####
# minimum weight of any asset is 2%
# maximum weight of any asset is 20%
# box constraints: 0.02 <= w_i <= 0.2
# sum of weights equal to 1 (0.99 <= \sum_{i=1}^N w_i <= 1.01)
init.portf <- portfolio.spec(colnames(equity.data))
init.portf <- add.constraint(init.portf, type="weight_sum", 
                             min_sum=0.99, max_sum=1.01)
init.portf <- add.constraint(init.portf, type="box",
                             min=0.01, max=0.2)
init.portf <- add.constraint(init.portf, type="group", 
                             groups=list(1:15, 16:30, 31:35), 
                             group_min=c(0.1, 0.1, 0), 
                             group_max=c(0.5, 0.5, 0.1), 
                             group_labels=c("Large", "Mid", "Small"))

##### Generate Random Portfolios #####
k <- 500
# add 1 to k because the first rp is the equal weight portfolio which I am
# using as a benchmark
cat("generating rp\n")
if(file.exists(paste(results.dir, "rp.rda", sep="/"))){
  cat("file already exists\n")
  load(file=paste(results.dir, "rp.rda", sep="/"))
} else {
  rp <- random_portfolios(init.portf, k+3)
  rp <- rp[-1,]
  cat("rp complete. Saving results to ", results.dir, "\n")
  save(rp, file=paste(results.dir, "rp.rda", sep="/"))
}

##### Benchmarks #####
eqwt.benchmark <- rep(1 / n.assets, n.assets)
names(eqwt.benchmark) <- colnames(equity.data)

set.seed(1234)
rp1.benchmark <- randomize_portfolio(init.portf)
names(rp1.benchmark) <- colnames(equity.data)

set.seed(4)
rp2.benchmark <- randomize_portfolio(init.portf)
names(rp2.benchmark) <- colnames(equity.data)

# compute weekly returns of benchmarks
# assume weights are held fixed over time (i.e. rebalancing period is same as periodicity of data)
# all.equal(equity.data %*% eqwt.benchmark,
#           coredata(Return.rebalancing(equity.data, eqwt.benchmark, rebalance_on = "weeks")),
#           check.attributes = F)
eqwt.benchmark.ret <- Return.rebalancing(equity.data, eqwt.benchmark, rebalance_on="weeks")
rp1.benchmark.ret <- Return.rebalancing(equity.data, rp1.benchmark, rebalance_on="weeks")
rp2.benchmark.ret <- Return.rebalancing(equity.data, rp2.benchmark, rebalance_on="weeks")


##### RP Returns #####
# the Burns paper is not very clear about this so I will make some assumptions
# for computing returns of the random portfolios.
# hold fixed?
# drift?
# rebalance?

cat("computing weekly returns of random portfolios\n")
if(file.exists(paste(results.dir, "rp.ret.rda", sep="/"))){
  cat("file already exists\n")
  load(file=paste(results.dir, "rp.ret.rda", sep="/"))
} else {
  # weekly returns of random portfolios
  rp.ret.list <- list()
  for(i in 1:NROW(rp)){
    rp.ret.list[[i]] <- xts(equity.data %*% rp[i,], index(equity.data))
    # rp.ret.list[[i]] <- Return.rebalancing(equity.data, rp[i,], rebalance_on="weeks")
  }
  rp.ret <- do.call(cbind, rp.ret.list)
  cat("computation complete. Saving results to ", results.dir, "\n")
  save(rp.ret, file=paste(results.dir, "rp.ret.rda", sep="/"))
}

cat("computing quarterly information ratios\n")
if(file.exists(paste(results.dir, "ir.rda", sep="/"))){
  cat("file already exists\n")
  load(file=paste(results.dir, "ir.rda", sep="/"))
} else {
  # quarterly information ratios for each benchmark
  ir.qtr.eqwt <- list()
  ir.qtr.rp1 <- list()
  ir.qtr.rp2 <- list()
  for(i in 1:NCOL(rp.ret)){
    ir.qtr.eqwt[[i]] <- IR(rp.ret[,i], eqwt.benchmark.ret)
    ir.qtr.rp1[[i]] <- IR(rp.ret[,i], rp1.benchmark.ret)
    ir.qtr.rp2[[i]] <- IR(rp.ret[,i], rp2.benchmark.ret)
  }
  ir.eqwt <- do.call(cbind, ir.qtr.eqwt)
  ir.rp1 <- do.call(cbind, ir.qtr.rp1)
  ir.rp2 <- do.call(cbind, ir.qtr.rp2)
  cat("information ratio computation complete. Saving results to ", results.dir, "\n")
  save(ir.eqwt, ir.rp1, ir.rp2, file=paste(results.dir, "ir.rda", sep="/"))
}



# ActivePremium(rp.ret[,i], rp2.benchmark.ret)
# TrackingError(rp.ret[,i], rp2.benchmark.ret)
# StdDev.annualized(rp.ret[,i] - rp2.benchmark.ret)

# percentage of random portfolios with positive IR
# equal weight benchmark
eqwt.a <- xts(apply(ir.eqwt[,1:250], 1, function(z) sum(z > 0)) / 250, as.Date(index(ir.eqwt)))
eqwt.b <- xts(apply(ir.eqwt[,251:500], 1, function(z) sum(z > 0)) / 250, as.Date(index(ir.eqwt)))
plot(eqwt.a, ylim=c(0,1), main="Equal Weight Benchmark")
lines(eqwt.b, col="red")
legend("topright", legend = c("RP Group 1", "RP Group 2"), col=c("black", "red"), lty=c(1,1))

# rp1 benchmark
rp1.a <- xts(apply(ir.rp1[,1:250], 1, function(z) sum(z > 0)) / 250, as.Date(index(ir.rp1)))
rp1.b <- xts(apply(ir.rp1[,251:500], 1, function(z) sum(z > 0)) / 250, as.Date(index(ir.rp1)))
plot(rp1.a, ylim=c(0,1), main="RP1 Benchmark")
lines(rp1.b, col="red")
legend("topright", legend = c("RP Group 1", "RP Group 2"), col=c("black", "red"), lty=c(1,1))

# rp2 benchmark
rp2.a <- xts(apply(ir.rp2[,1:250], 1, function(z) sum(z > 0)) / 250, as.Date(index(ir.rp2)))
rp2.b <- xts(apply(ir.rp2[,251:500], 1, function(z) sum(z > 0)) / 250, as.Date(index(ir.rp2)))
plot(rp2.a, ylim=c(0,1), main="RP2 Benchmark")
lines(rp2.b, col="red")
legend("topright", legend = c("RP Group 1", "RP Group 2"), col=c("black", "red"), lty=c(1,1))

png(paste(results.dir, "ir.png", sep="/"), height = fig.height, width = fig.width)
plot(xts(apply(ir.eqwt, 1, function(z) sum(z > 0)) / 500, as.Date(index(ir.eqwt))), 
     ylim=c(0,1), ylab="Probability of Positive Information Ratio", main="Benchmark Outperformance")
lines(xts(apply(ir.rp1, 1, function(z) sum(z > 0)) / 500, as.Date(index(ir.rp1))), col="red")
lines(xts(apply(ir.rp2, 1, function(z) sum(z > 0)) / 500, as.Date(index(ir.rp2))), col="blue")
legend("topright", legend = c("Equal Weight", "RP 1", "RP 2"), 
       col=c("black", "red", "blue"), lty=c(1,1,1), bty="n")
abline(h = 0.5, lty=2)
dev.off()

##### Zero-Skill Managers #####
# generate 10000 random portfolios
zm.portf <- portfolio.spec(colnames(R))
zm.portf <- add.constraint(zm.portf, type="weight_sum", 
                           min_sum=0.99, max_sum=1.01)
zm.portf <- add.constraint(zm.portf, type="box",
                           min=0, max=0.4)

# Generate Random Portfolios
k <- 10000
# add 1 to k because the first rp is the equal weight portfolio which I am
# using as a benchmark
rp.zm <- random_portfolios(zm.portf, k+1)
# rp.zm <- rp.zm[-1,]

# rebalancing period
rebal.on <- "years"
ep <- endpoints(R, rebal.on)
ep <- ep[ep > 0]
rebal.dates <- index(R[ep])

# generate weights for the zero skill managers
n.zm <- 1000
zm <- list()
for(i in 1:n.zm){
  zm[[i]] <- list()
  # random sample of rp weights
  tmp.weights <- xts(rp.zm[sample.int(n=NROW(rp.zm), size=length(ep)),], as.Date(rebal.dates))
  zm[[i]]$weights <- tmp.weights
  zm[[i]]$returns <- Return.rebalancing(R, tmp.weights)
}
zm.ret <- do.call(cbind, lapply(zm, function(x) x$returns))
zm.ret <- cbind(Return.rebalancing(R, weights=rep(1 / NCOL(R), NCOL(R)), rebalance_on = rebal.on), zm.ret)

#chart.CumReturns(zm.ret, colorset=c("black", rep("gray", NCOL(zm.ret)-1)), 
#                 legend.loc = NULL, main="Zero Skill Manager Returns", 
#                 ylab="Cumulative Return")


png(paste(results.dir, "zsm.png", sep="/"), height = fig.height, width = fig.width)
charts.PerformanceSummary(zm.ret, colorset=c("black", rep("gray", NCOL(zm.ret)-1)), 
                          legend.loc = NULL, main="Zero Skill Manager Returns")
dev.off()

sr.zm <- SharpeRatio.annualized(zm.ret)
sr.zm[1]
quantile(sr.zm[-1])

png(paste(results.dir, "zsm_den.png", sep="/"), height = fig.height, width = fig.width)
par(mfrow=c(1,2))
plot(density(sr.zm[-1]), main="Density")
qqnorm(sr.zm[-1])
qqline(sr.zm[-1])
par(mfrow=c(1,1))
dev.off()
