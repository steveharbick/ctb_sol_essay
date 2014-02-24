
training<-read.csv(paste(wd_path,'/Input/frompems/',item,'.tsv',sep=""), header=TRUE, 
                   sep = "\t", fileEncoding="windows-1252",quote="")

# discard Final Scores that are not numeric
for (Response_id in c("A","B","C")) {
  eval(parse(text=paste("
  training[,Response_name_",Response_id,"]<-
  as.numeric(as.character(training[,Response_name_",Response_id,"]))"
                        ,sep="")))
  eval(parse(text=paste("
  training<-training[!is.na(training[,Response_name_",Response_id,"]),]"
                        ,sep="")))  
}


# convert EssayText to character format
EssayText <-as.character(training$Item_Response) 
Nrows<-length(EssayText)

# get score to be modelled
for (Response_id in c("A","B","C")) {
  eval(parse(text=paste("
  y",Response_id,"<-training[,Response_name_",Response_id,"]"
                        ,sep="")))  
}

# store data
Store(EssayText,Nrows,yA,yB,yC)

