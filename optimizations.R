# script used to run the portfolio optimizations

# Set the directory to save the optimization results
results.dir <- "optimization_results"

# mix of blue, green, and red hues
my_colors <- c("#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99", "#e31a1c")

# Load the packages
library(PortfolioAnalytics)
library(foreach)

# for running via Rscript
library(methods)

# load the data
source("data_prep.R")


##### Example 3 #####
# Example 3 will consider three portfolios
# - minES
# - minES with component contribution limit
# - minES with equal risk contribution

funds <- colnames(R)
portf.init <- portfolio.spec(funds)
portf.init <- add.constraint(portf.init, type="weight_sum", 
                             min_sum=0.99, max_sum=1.01)

portf.init <- add.constraint(portf.init, type="box", 
                             min=0.05, max=1)

# Set multiplier=0 so that it is calculated, but does not affect the optimization
portf.init <- add.objective(portf.init, type="return", 
                            name="mean", multiplier=0)

# Add objective to minimize expected shortfall
portf.minES <- add.objective(portf.init, type="risk", name="ES")

# Add risk budget objective with upper limit on percentage contribution
portf.minES.RB <- add.objective(portf.minES, type="risk_budget", 
                                name="ES", max_prisk=0.3)

# Add risk budget objective to minimize concentration of percentage component
# contribution to risk. Concentration is defined as the Herfindahl-Hirschman
# Index (HHI). $\sum_i x_i^2$
portf.minES.EqRB <- add.objective(portf.minES, type="risk_budget", 
                                  name="ES", min_concentration=TRUE)

# Add risk budget objective to minES portfolio with multiplier=0 so that it
# is calculated, but does not affect optimization
portf.minES <- add.objective(portf.minES, type="risk_budget", 
                             name="ES", multiplier=0)

# Combine the portfolios so we can make a single call to 
# optimize.portfolio
portf <- combine.portfolios(list(minES=portf.minES, 
                                 minES.RB=portf.minES.RB, 
                                 minES.EqRB=portf.minES.EqRB))

print(paste('constructing random portfolios at',Sys.time()))
rp = random_portfolios(portfolio=portf.init, permutations=5000)
print(paste('done constructing random portfolios at',Sys.time()))

cat("Example 3: running minimum ES optimizations\n")
if(file.exists(paste(results.dir, "opt.minES.rda", sep="/"))){
  cat("file already exists\n")
} else {
  # Run the optimization
  opt.minES <- optimize.portfolio(R, portf, optimize_method="random", 
                                  rp=rp, trace=TRUE, message=TRUE)
  cat("opt.minES complete. Saving results to ", results.dir, "\n")
  save(opt.minES, file=paste(results.dir, "opt.minES.rda", sep="/"))
}

# Now we want to evaluate the optimization through time

# Rebalancing parameters
# Set rebalancing frequency
rebal.freq <- "quarters"
# Training Period
training <- 120
# Trailing Period
trailing <- 72

cat("Example 3: running minimum ES backtests\n")
if(file.exists(paste(results.dir, "bt.opt.minES.rda", sep="/"))){
  cat("file already exists\n")
} else {
  # Backtest
  bt.opt.minES <- optimize.portfolio.rebalancing(R, portf,
                                                 optimize_method="random", 
                                                 rebalance_on=rebal.freq, 
                                                 training_period=training, 
                                                 rolling_window=trailing,
                                                 rp=rp, message=TRUE)
  cat("bt.opt.minES complete. Saving results to ", results.dir, "\n")
  save(bt.opt.minES, file=paste(results.dir, "bt.opt.minES.rda", sep="/"))
}

##### Example 4 #####

# Simple function to compute the moments used in CRRA
crra.moments <- function(R, ...){
  out <- list()
  out$mu <- colMeans(R)
  out$sigma <- cov(R)
  out$m3 <- PerformanceAnalytics:::M3.MM(R)
  out$m4 <- PerformanceAnalytics:::M4.MM(R)
  out
}


# Fourth order expansion of CRRA expected utility
CRRA <- function(R, weights, lambda, sigma, m3, m4){
  weights <- matrix(weights, ncol=1)
  M2.w <- t(weights) %*% sigma %*% weights
  M3.w <- t(weights) %*% m3 %*% (weights %x% weights)
  M4.w <- t(weights) %*% m4 %*% (weights %x% weights %x% weights)
  term1 <- 0.5 * lambda * M2.w
  term2 <- (1 / 6) * lambda * (lambda + 1) * M3.w
  term3 <- (1 / 24) * lambda * (lambda + 1) * (lambda + 2) * M4.w
  out <- -term1 + term2 - term3
  out
}

# test the CRRA function
portf.crra <- portfolio.spec(funds)
portf.crra <- add.constraint(portf.crra, type="weight_sum", 
                             min_sum=0.99, max_sum=1.01)

portf.crra <- add.constraint(portf.crra, type="box", 
                             min=0.05, max=0.4)

portf.crra <- add.objective(portf.crra, type="return", 
                            name="CRRA", arguments=list(lambda=10))

print(paste('constructing random portfolios at',Sys.time()))
rp.crra <- random_portfolios(portfolio=portf.crra, permutations=5000)
print(paste('done constructing random portfolios at',Sys.time()))

# I just want these for plotting
# Set multiplier=0 so that it is calculated, but does not affect the optimization
portf.crra <- add.objective(portf.crra, type="return", name="mean", multiplier=0)
portf.crra <- add.objective(portf.crra, type="risk", name="ES", multiplier=0)
portf.crra <- add.objective(portf.crra, type="risk", name="StdDev", multiplier=0)

cat("Example 4: running maximum CRRA optimization\n")
if(file.exists(paste(results.dir, "opt.crra.rda", sep="/"))){
  cat("file already exists\n")
} else {
  # Run the optimization
  opt.crra <- optimize.portfolio(R, portf.crra, optimize_method="random", 
                                 rp=rp.crra, trace=TRUE,
                                 momentFUN="crra.moments")
  cat("opt.crra complete. Saving results to ", results.dir, "\n") 
  save(opt.crra, file=paste(results.dir, "opt.crra.rda", sep="/"))
}

cat("Example 4: running maximum CRRA backtest\n")
if(file.exists(paste(results.dir, "bt.opt.crra.rda", sep="/"))){
  cat("file already exists\n")
} else {
  # Run the optimization with rebalancing
  bt.opt.crra <- optimize.portfolio.rebalancing(R, portf.crra,
                                                optimize_method="random",
                                                rp=rp.crra, trace=TRUE,
                                                momentFUN="crra.moments",
                                                rebalance_on=rebal.freq, 
                                                training_period=training, 
                                                rolling_window=trailing)
  cat("bt.opt.crra complete. Saving results to ", results.dir, "\n")
  save(bt.opt.crra, file=paste(results.dir, "bt.opt.crra.rda", sep="/"))
}
