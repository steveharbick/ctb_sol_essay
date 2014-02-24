# check if test prediction distributions consistent with training

Response_id="C"  
par(mfrow=c(3,2))
par(mar=c(1,1,3,1))
for (item in item_4valid) {
  load(paste("Working_files/",Version,"_",Response_id,"_",item,"_NNLS.RData",sep=""))
  load(paste("Working_files/",Version,"_",Response_id,"_H_",item,"_NNLS.RData",sep=""))
  plot(density(NNLS$yhatV),main=paste(item))
  lines(density(NNLS_H),col=2)
}

par(mfrow=c(3,2))
par(mar=c(1,1,3,1))
for (item in item_4valid) {
  load(paste("Working_files/",Version,"_",Response_id,"_",item,"_ADJ1.RData",sep=""))
  load(paste("Working_files/",Version,"_",Response_id,"_H_",item,"_ADJ1.RData",sep=""))
  plot(density(ADJ1$yhatV),main=paste(item))
  lines(density(ADJ1_H),col=2)
}

