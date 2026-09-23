auc <- function(pos,bg) {n<-length(pos); m<-length(bg); if(!n||!m)return(NA_real_); (sum(rank(c(pos,bg))[seq_len(n)])-n*(n+1)/2)/(n*m)}
boyce <- function(pos,bg) {
  breaks<-unique(as.numeric(quantile(bg,seq(0,1,length.out=11)))); if(length(breaks)<4)return(NA_real_)
  breaks[c(1,length(breaks))]<-c(-Inf,Inf)
  pb<-cut(pos,breaks,labels=FALSE); bb<-cut(bg,breaks,labels=FALSE); nb<-length(breaks)-1
  ratios<-(tabulate(pb,nb)/length(pos))/(tabulate(bb,nb)/length(bg))
  mids<-vapply(seq_len(nb),function(i)mean(bg[bb==i]),numeric(1)); ok<-is.finite(ratios)&is.finite(mids)
  if(sum(ok)<3||length(unique(ratios[ok]))<2)return(NA_real_)
  suppressWarnings(cor(mids[ok],ratios[ok],method="spearman"))
}
sample_background <- function(grid,n,age_range) {
  grid<-grid[grid$state=="land",]
  times<-sort(unique(grid$age_ka)); pool_times<-times[times>=age_range[1]&times<=age_range[2]]
  if(!length(pool_times)) pool_times<-times[which.min(abs(times-mean(age_range)))]
  pieces<-lapply(seq_along(pool_times),function(i) {
    z<-grid[grid$age_ka==pool_times[i],]; size<-min(nrow(z),n%/%length(pool_times)+as.integer(i<=n%%length(pool_times)))
    z[sample.int(nrow(z),size,prob=z$area_weight),,drop=FALSE]
  }); do.call(rbind,pieces)
}
fold_id <- function(x,spec) {
  xx<-x$longitude*cos(spec$ref_lat*pi/180)*111.195; yy<-x$latitude*111.195
  paste(floor(xx/spec$block_km),floor(yy/spec$block_km),sep="_")
}
fit_model <- function(type,pr,bg,vars,features="lq",regmult=2) {
  center<-vapply(bg[vars],mean,numeric(1)); scale<-vapply(bg[vars],sd,numeric(1))
  if(any(!is.finite(scale)|scale==0))stop("Constant background predictor; revise predictor set.")
  z<-function(x) as.data.frame(sweep(sweep(as.matrix(x[vars]),2,center,"-"),2,scale,"/"))
  pz<-z(pr); bz<-z(bg)
  if(type=="MaxEnt") {
    response<-c(rep(1,nrow(pz)),rep(0,nrow(bz))); data<-rbind(pz,bz)
    f<-maxnet::maxnet.formula(response,data,classes=features)
    model<-maxnet::maxnet(response,data,f=f,regmult=regmult,addsamplestobackground=TRUE)
  } else {
    mu<-colMeans(pz); cv<-cov(pz); ridge<-max(mean(diag(cv))*1e-6,1e-8)
    model<-list(mu=mu,inverse=solve(cv+diag(ridge,length(vars))))
  }; list(type=type,model=model,center=center,scale=scale,vars=vars)
}
predict_model <- function(fit,x) {
  z<-as.data.frame(sweep(sweep(as.matrix(x[fit$vars]),2,fit$center,"-"),2,fit$scale,"/"))
  if(fit$type=="MaxEnt") {
    if(!length(fit$model$betas)) return(rep(1-exp(-exp(fit$model$entropy+fit$model$alpha)),nrow(x)))
    return(as.numeric(predict(fit$model,z,type="cloglog",clamp=TRUE)))
  }
  delta<-sweep(as.matrix(z),2,fit$model$mu,"-"); exp(-.5*pmax(0,rowSums((delta%*%fit$model$inverse)*delta)))
}
site_scores <- function(x,scores) as.numeric(tapply(scores,x$site_id,mean))
evaluate <- function(fit,train,test,bg,q) {
  threshold<-as.numeric(quantile(site_scores(train,predict_model(fit,train)),q))
  positive<-site_scores(test,predict_model(fit,test)); negative<-predict_model(fit,bg)
  c(auc=auc(positive,negative),boyce=boyce(positive,negative),omission=mean(positive<threshold),tss=mean(positive>=threshold)+mean(negative<threshold)-1)
}
validation <- function(type,x,bg,vars,features,regmult,q) {
  do.call(rbind,lapply(sort(unique(x$fold)),function(k) {
    train<-x[x$fold!=k,]; test<-x[x$fold==k,]; train_bg<-bg[bg$fold!=k,]; test_bg<-bg[bg$fold==k,]
    if(nrow(train)<length(vars)+2||!nrow(test_bg)||!nrow(test)) stop("Fold too small; review step 05 map and reduce folds/predictors if justified.")
    fit<-fit_model(type,train,train_bg,vars,features,regmult)
    data.frame(fold=k,t(evaluate(fit,train,test,test_bg,q)))
  }))
}
projection <- function(fit,x) {
  score<-rep(NA_real_,nrow(x)); score[x$state=="ice"]<-0
  ok<-x$state=="land"; score[ok]<-predict_model(fit,x[ok,]); score
}
area_summary <- function(grid,score,threshold,region=rep("Whole study area",nrow(grid))) {
  groups<-split(seq_len(nrow(grid)),paste(grid$age_ka,region,sep="|"))
  do.call(rbind,lapply(groups,function(ii) {
    ii<-ii[grid$state[ii] %in% c("land","ice")]; if(!length(ii))return(NULL)
    w<-grid$area_weight[ii]; available<-grid$state[ii]=="land"
    data.frame(age_ka=grid$age_ka[ii[1]],region=region[ii[1]],suitable_pct=100*sum(w*available*(score[ii]>=threshold))/sum(w),ice_pct=100*sum(w*!available)/sum(w))
  }))
}
