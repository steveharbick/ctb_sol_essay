# function to transform into ridit score
#####################################################################

CV_RIDIT<-function(x,K,nb_cores) {
  library(foreach)
  library(doMC)
  registerDoMC(nb_cores)
  out<-list()
  out$ECDF<-foreach (i = 1:length(K)) %dopar% {
    out<-list()
    for (j in 1:ncol(x)) out[[j]]<-ecdf(x[-K[[i]],j])
    out
  }  
  apply_ridit_one<-function(x,Fn) ((Fn(x-1e-15)+(Fn(x)-Fn(x-1e-15))/2)-0.5)*2
  out$x<-foreach (i = 1:length(K)) %dopar% {
    out_x<-x
    for (j in 1:ncol(x)) out_x[,j]<-apply_ridit_one(x[,j],out$ECDF[[i]][[j]])
    out_x
  }    
  out
}

APPLY_RIDIT<-function(ECDF,x,K,nb_cores) {
  library(foreach)
  library(doMC)
  registerDoMC(nb_cores)
  out<-list()
  out$ECDF<-ECDF  
  apply_ridit_one<-function(x,Fn) ((Fn(x-1e-15)+(Fn(x)-Fn(x-1e-15))/2)-0.5)*2
  out$x<-foreach (i = 1:length(ECDF)) %dopar% {
    out_x<-x
    for (j in 1:ncol(x)) out_x[,j]<-apply_ridit_one(x[,j],out$ECDF[[i]][[j]])
    out_x
  }    
  out
}
