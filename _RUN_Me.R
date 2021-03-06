
#####################################################################
#####################################################################
# load packages
#####################################################################
#####################################################################

library(SOAR) # to store data that will be used by all models
library(Matrix) # to handle sparse matrix
library(tau) # for n-grams
library(RTextTools) # to stem words

#####################################################################
#####################################################################
# set and store working directory
#####################################################################
#####################################################################

wd_path<-"~/Documents/asap3_essay"
setwd(wd_path)
Store(wd_path) 

#####################################################################
#####################################################################
# set and store parameters to are used for all items
#####################################################################
#####################################################################

# training version
Version="V1"
Store(Version)

# item list
item_list=
  c("5_56196_TB_56196_1",
    "5_56274_TB_56274_1",
    "6_55103_TB_55103_1",
    "6_55927_TB_55927_1",
    "8_53045_TB_53045_1")
Store(item_list)

# name of response to be modelled
Response_name_A="Final_Score_A"
Response_name_B="Final_Score_B"
Response_name_C="Final_Score_C"
Store(Response_name_A,
      Response_name_B,
      Response_name_C)

# nb of cores for parallel processing
nb_cores=5
# nb of folds for cross validation
nb_folds_training=5
Store(nb_cores,nb_folds_training)

source("_SETTING.R")
source("_VOCAB.R")

#####################################################################
#####################################################################
# inform if it is a TRAIN or TEST RUN
#####################################################################
#####################################################################

RUN_TYPE = "TRAIN"
Store(RUN_TYPE)

print("############################################################")
print(RUN_TYPE) 
#####################################################################

for (item in item_list) {
  print("############################################################")
  print(paste("Item:",item))
  print("############################################################")
  Store(item)
  
  print("############################################################")
  print("# Read data")
  #####################################################################
  source("_READ_ONE_TRAIN_FILE.R")
  
  print("############################################################")
  print("# Generate Proxies")
  print("############################################################")
  
  source("_PROXIES.R")
  
  print("############################################################")
  print("# Convert numbers into string")
  print("############################################################")
  
  source("_NUMBERS.R")
  
  print("############################################################")
  print("# Generate Document Term Matrix")
  print("############################################################")
  
  print("# based on word n-grams")
  source("_DTM_WORDS.R")
  
  print("############################################################")
  print("# based on character n-grams")
  nb_char_grams_max=nb_char_grams_max1
  source("_DTM_CHARS.R")
  nb_char_grams_max=nb_char_grams_max2
  source("_DTM_CHARS.R")
  
  gc()
  print("############################################################")
  print("# Feature selection")
  print("############################################################")
  
  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    eval(parse(text=paste("y<-y",Response_id,sep="")))
    Store(y, Response_id)    

    seed=2013 ; Store(seed)
    for (DTM_name in c(paste("_DTM_Words_",nb_word_grams_max,"grams",sep=""))) {
      print(DTM_name)
      seed=2013+seed ; Store(seed)
      load(paste("Working_files/",Version,"_",item,DTM_name,".RData",sep=""))
      x=data.frame(bin_mat)
      source("_FEATURE_SEL_wGLMNET.R")  
      print("############################################################")
    }  
    
    for (DTM_name in c(paste("_DTM_Chars_",nb_char_grams_max1,"grams",sep=""),
                       paste("_DTM_Chars_",nb_char_grams_max2,"grams",sep=""))) {
      print(DTM_name)
      seed=2013+seed ; Store(seed)
      load(paste("Working_files/",Version,"_",item,DTM_name,".RData",sep=""))
      x=data.frame(bin_mat)
      source("_FEATURE_SEL_wRF.R")  
      print("############################################################")
    }  
  }
  
  gc()
  print("############################################################")
  print("# Principal Component Analysis")
  print("############################################################")
  
  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    for (DTM_name in c(paste("_Small_DTM_Chars_",nb_char_grams_max1,"grams",sep=""),
                     paste("_Small_DTM_Chars_",nb_char_grams_max2,"grams",sep=""))) {
    print(DTM_name)
    load(paste("Working_files/",Version,"_",Response_id,
               "_",item,DTM_name,".RData",sep=""))
    source("_PCA.R")
    }
  }
      
  gc()
  print("############################################################")
  print("# Train Trees with Doc Term Matrix and PROXIES")
  print("############################################################")

  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    eval(parse(text=paste("y<-y",Response_id,sep="")))
    Store(y, Response_id)    
    
    for (DTM_name in c(paste("_Small2_DTM_Words_",nb_word_grams_max,"grams",sep=""))) {
      load(paste("Working_files/",Version,"_",Response_id,
                 "_",item,DTM_name,".RData",sep=""))
      load(paste("Working_files/",Version,"_",item,"_PROXIES.RData",sep=""))
      for (i in 1:length(x)) x[[i]]<-data.frame(x[[i]],PROXIES[,-1])
      DTM_name<-paste(DTM_name,"_PROXIES",sep="")
      print(DTM_name)
      GBM_interaction.depth=12
      source("_TRAIN_TREES.R")  
    }
  }  
  gc()
  print("############################################################")
  print("# Train SVM, GLMNET with Doc Term Matrix and PROXIES")
  print("############################################################")

  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    eval(parse(text=paste("y<-y",Response_id,sep="")))  
    Store(y, Response_id)    
    
    for (DTM_name in c(paste("_Small_DTM_Chars_",nb_char_grams_max1,"grams",sep=""),
                       paste("_Small_DTM_Chars_",nb_char_grams_max2,"grams",sep=""),
                       paste("_PCA_Small_DTM_Chars_",nb_char_grams_max1,"grams",sep=""),
                       paste("_PCA_Small_DTM_Chars_",nb_char_grams_max2,"grams",sep=""),
                       paste("_Small2_DTM_Words_",nb_word_grams_max,"grams",sep=""))) {
      load(paste("Working_files/",Version,"_",Response_id,
                 "_",item,DTM_name,".RData",sep=""))
      load(paste("Working_files/",Version,"_",item,"_PROXIES.RData",sep=""))
      source("CV_RIDIT.R")
      PROXIES_RIDIT<-CV_RIDIT(PROXIES,K,5)
      save(PROXIES_RIDIT,file=paste("Working_files/",Version,"_",Response_id,
                                    "_",item,"_PROXIES_RIDIT.RData",sep=""))
      for (i in 1:length(x)) x[[i]]<-data.frame(x[[i]],PROXIES_RIDIT$x[[i]][,-1])
      DTM_name<-paste(DTM_name,"_PROXIES",sep="")
      print(DTM_name)
      source("_TRAIN_NONTREES.R")  
    }
  }    
  gc()
  print("############################################################")
  print("# Group Individual Models")
  print("############################################################")

  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    eval(parse(text=paste("y<-y",Response_id,sep="")))  
    Store(y, Response_id)    
    
    Mod2Blend=data.frame(y=y)
    
    for (DTM_name in c(paste("DTM_Words_",nb_word_grams_max,"grams",sep=""))) {
      print(DTM_name)
      load(paste("Working_files/",Version,"_",Response_id,
                 "_",item,"_GLMNET_4fs_",DTM_name,".RData",sep=""))
      Mod2Blend<-data.frame(Mod2Blend,GLMNET_4fs$yhatV)
      names(Mod2Blend)[ncol(Mod2Blend)]<-paste(DTM_name,c("GLMNET_4fs"),sep="_")
    }
    
    for (DTM_name in c(paste("DTM_Chars_",nb_char_grams_max1,"grams",sep=""),
                       paste("DTM_Chars_",nb_char_grams_max2,"grams",sep=""))) {
      print(DTM_name)
      load(paste("Working_files/",Version,"_",Response_id,
                 "_",item,"_RF_4fs_",DTM_name,".RData",sep=""))
      Mod2Blend<-data.frame(Mod2Blend,RF_4fs$yhatV)
      names(Mod2Blend)[ncol(Mod2Blend)]<-paste(DTM_name,c("RF_4fs"),sep="_")
    }
    
    for (DTM_name in c(paste("Small2_DTM_Words_",nb_word_grams_max,"grams_PROXIES",sep=""))) {
      print(DTM_name)
      load(paste("Working_files/",Version,"_",Response_id,
                 "_",item,"_Trees_w_",DTM_name,".RData",sep=""))
      Mod2Blend<-data.frame(Mod2Blend,RF$yhatV,GBM$yhatV)
      names(Mod2Blend)[ncol(Mod2Blend)+(-1:0)]<-paste(DTM_name,c("RF","GBM"),sep="_")
    }
    
    for (DTM_name in c(paste("Small2_DTM_Words_",nb_word_grams_max,"grams_PROXIES",sep=""),
                       paste("Small_DTM_Chars_",nb_char_grams_max1,"grams_PROXIES",sep=""),
                       paste("PCA_Small_DTM_Chars_",nb_char_grams_max1,"grams_PROXIES",sep=""),
                       paste("Small_DTM_Chars_",nb_char_grams_max2,"grams_PROXIES",sep=""),
                       paste("PCA_Small_DTM_Chars_",nb_char_grams_max2,"grams_PROXIES",sep=""))) {
      print(DTM_name)
      load(paste("Working_files/",Version,"_",Response_id,
                 "_",item,"_NonTrees_w_",DTM_name,".RData",sep=""))
      Mod2Blend<-cbind(Mod2Blend,
                       GLMNET$yhatV,
                       SVM_lin$yhatV,
                       SVM_rad$yhatV)
      names(Mod2Blend)[ncol(Mod2Blend)+(-2:0)]<-
        paste(DTM_name,c("GLMNET","SVM_lin","SVM_rad"),sep="_")
    }
    save(Mod2Blend,file=paste("Working_files/",Version,"_",Response_id,
                              "_",item,"_Mod2Blend.RData",sep=""))
  }
  print("############################################################")
}

gc()
print("############################################################")
print("# Blend")
#####################################################################

source("CV_NNLS.R")
source("_KFolds.R")

for (item in item_list) {
  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    load(paste("Working_files/",Version,"_",Response_id,
             "_",item,"_Mod2Blend.RData",sep=""))
    Kb<-Kfolds(896,nb_folds_training,nrow(Mod2Blend))
    NNLS<-CV_NNLS(x=Mod2Blend[,-1],y=Mod2Blend$y,
                  K=Kb,nb_cores=nb_cores,seed=9867)
    print(item)
    save(NNLS,Kb,file=paste("Working_files/",Version,"_",Response_id,
                            "_",item,"_NNLS.RData",sep=""))  
  }
}
gc()
print("############################################################")
print("# Adjust to optimize Kappa scores")
#####################################################################

source("CV_ADJ.R")
source("_KFolds.R")

for (item in item_list) {
  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    load(paste("Working_files/",Version,"_",Response_id,
             "_",item,"_Mod2Blend.RData",sep=""))
    load(paste("Working_files/",Version,"_",Response_id,
               "_",item,"_NNLS.RData",sep=""))
    Kc<-Kfolds(896,nb_folds_training,length(NNLS$yhatV))
    ADJ1<-CV_ADJ(x=NNLS$yhatV,y=Mod2Blend$y,K=Kc,d=1,nb_cores=nb_cores,seed=seed)
    save(ADJ1,Kc,file=paste("Working_files/",Version,"_",Response_id,
                            "_",item,"_ADJ1.RData",sep=""))  
    print(item)
  }
}

for (item in item_list) {
  for (Response_id in c("A","B","C")) {
    print(paste("Response",Response_id))
    load(paste("Working_files/",Version,"_",Response_id,
             "_",item,"_Mod2Blend.RData",sep=""))
    load(paste("Working_files/",Version,"_",Response_id,
               "_",item,"_NNLS.RData",sep=""))
    Kc<-Kfolds(896,nb_folds_training,length(NNLS$yhatV))
    ADJ2<-CV_ADJ(x=NNLS$yhatV,y=Mod2Blend$y,K=Kc,d=2,nb_cores=nb_cores,seed=seed)
    save(ADJ2,Kc,file=paste("Working_files/",Version,"_",Response_id,
                            "_",item,"_ADJ2.RData",sep=""))  
    print(item)
  }
}