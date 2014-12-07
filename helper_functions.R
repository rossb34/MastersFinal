quarterlyReturns <- function(R){
  ep_qtr <- index(R[endpoints(R, "quarters")])
  # print(ep_qtr)
  out <- vector("numeric", length=(length(ep_qtr)-1))
  for(i in 1:(length(ep_qtr)-1)){
    from <- ep_qtr[i]+1
    to <- ep_qtr[i+1]
    out[i] <- prod(1 + R[paste(from, to, sep="/")]) - 1
  }
  out <- xts(out, ep_qtr[-1])
  colnames(out) <- colnames(R)
  return(out)
}

rebalanceWeights <- function(weights, rebalance_dates){
  tmp_list <- list()
  for(i in 1:length(rebalance_dates)){
    tmp_list[[rebal_dates[i]]] <- weights
  }
  xts(do.call(rbind, tmp_list), order.by=rebalance_dates)
}

IR <- function(Ra, Rb){
  # Ra: asset Returns
  # Rb: benchmark Returns
  # indexing and endpoints based on benchmark returns
  ep <- endpoints(Rb, "years")
  ep <- ep[ep > 0]
  Rb.idx <- index(Rb)
  out <- vector("numeric", length(ep)-1)
  idx <- out
  for(i in 2:length(ep)){
    from <- Rb.idx[ep[i-1] + 1]
    to <- Rb.idx[ep[i]]
    tmp.Rb <- Rb[paste(from,to,sep="/")]
    tmp.Ra <- Ra[paste(from,to,sep="/")]
    out[i-1] <- ActivePremium(Ra = tmp.Ra, Rb = tmp.Rb) / StdDev.annualized(tmp.Ra - tmp.Rb)
    # out[i-1] <- InformationRatio(Ra=tmp.Ra, Rb=tmp.Rb, scale=52)
    idx[i-1] <- to
  }
  ir <- xts(out, as.Date(idx))
  colnames(ir) <- colnames(Ra)
  ir
}

# library(quantmod)
# getSymbols(Symbols="SPY", from="2011-12-30")
# head(SPY)
# SPY.ret <- ROC(x=Ad(SPY), n=1, type="discrete", na.pad=FALSE)
# # calculate quarterly returns given daily data
# SPY.qtr <- SPY[endpoints(x=SPY, on="quarters")]
# ROC(Ad(SPY.qtr), 1, "discrete")
# SPY.qtr
# index(SPY.ret[endpoints(SPY.ret, on="quarters")])
# ep.qtr <- index(SPY.ret[endpoints(SPY.ret, on="quarters")])
# from <- ep.qtr[1]+1
# to <- ep.qtr[2]
# prod(1 + SPY.ret[paste(from, to, sep="/")]) - 1
# quarterlyReturns(SPY.ret)
