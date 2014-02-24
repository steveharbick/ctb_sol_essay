gc()
print("############################################################")
print("# Store CV pearson score for individual models")
#####################################################################

for (Response_id in c("A","B","C")) {
  print(paste("Response",Response_id))
  item=item_list[1]
  load(paste("Working_files/",Version,"_",Response_id,
             "_",item,"_Mod2Blend.RData",sep=""))
  CV_pearson<-data.frame(Model=c(names(Mod2Blend)[2:ncol(Mod2Blend)],"Blend"))
  
  for (item in item_list) {
    print(item)
    load(paste("Working_files/",Version,"_",Response_id,
               "_",item,"_Mod2Blend.RData",sep=""))
    for (Model in CV_pearson$Model) {
      if (Model=="Blend") {
        load(paste("Working_files/",Version,"_",Response_id,
                   "_",item,"_NNLS.RData",sep=""))  
        CV_pearson[CV_pearson$Model=="Blend",paste("I",item,sep="")]<-cor(Mod2Blend$y,NNLS$yhatV,method="pearson")      
      } else CV_pearson[CV_pearson$Model==Model,paste("I",item,sep="")]<-cor(Mod2Blend$y,Mod2Blend[,Model],method="pearson")   
    }
  }
  CV_pearson$All<-rowSums(CV_pearson[,-1])
  eval(parse(text=paste("CV_pearson_",Response_id,"<-CV_pearson",sep="")))
  eval(parse(text=paste("Store(CV_pearson_",Response_id,")",sep="")))
}  
gc()
CV_pearson_A
CV_pearson_B
CV_pearson_C

print("############################################################")
print("# Store CV SQWKappa score for individual models")
#####################################################################
for (Response_id in c("A","B","C")) {
  print(paste("Response",Response_id))
  source("_Kappa.R")
  item=item_list[1]
  load(paste("Working_files/",Version,"_",Response_id,
             "_",item,"_Mod2Blend.RData",sep=""))
  CV_SQWKappa<-data.frame(Model=c(names(Mod2Blend)[2:ncol(Mod2Blend)],"Blend","Adjust1","Adjust2"))
  
  for (item in item_list) {
    print(item)
    load(paste("Working_files/",Version,"_",Response_id,
               "_",item,"_Mod2Blend.RData",sep=""))
    for (Model in CV_SQWKappa$Model) {
      if (Model=="Adjust1") {
        load(paste("Working_files/",Version,"_",Response_id,
                   "_",item,"_ADJ1.RData",sep=""))  
        CV_SQWKappa[CV_SQWKappa$Model==Model,paste("I",item,sep="")]<-SQWKappa(Mod2Blend$y,ADJ1$yhatV)      
      } else if (Model=="Adjust2") {
        load(paste("Working_files/",Version,"_",Response_id,
                   "_",item,"_ADJ2.RData",sep=""))  
        CV_SQWKappa[CV_SQWKappa$Model==Model,paste("I",item,sep="")]<-SQWKappa(Mod2Blend$y,ADJ2$yhatV)      
      } else if (Model=="Blend") {
        load(paste("Working_files/",Version,"_",Response_id,"_",item,"_NNLS.RData",sep=""))  
        CV_SQWKappa[CV_SQWKappa$Model==Model,paste("I",item,sep="")]<-SQWKappa(Mod2Blend$y,NNLS$yhatV)      
      } else CV_SQWKappa[CV_SQWKappa$Model==Model,paste("I",item,sep="")]<-SQWKappa(Mod2Blend$y,Mod2Blend[,Model])   
    }
  }
  CV_SQWKappa$All<-rowSums(CV_SQWKappa[,-1])
  eval(parse(text=paste("CV_SQWKappa_",Response_id,"<-CV_SQWKappa",sep="")))
  eval(parse(text=paste("Store(CV_SQWKappa_",Response_id,")",sep="")))
}  
gc()
CV_SQWKappa_A
CV_SQWKappa_B
CV_SQWKappa_C


