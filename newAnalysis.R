# [SC] cleaning the environment
rm(list=ls())

######################################################################
## [SC][TODO] indicate which files to include in analysis

# [SC] 
dataFile <- "/results.json"
# [SC] 
dataFileTen <- "/pass10results.json"

## [SC][TODO] indicate which files to include in analysis
######################################################################

# [SC] some useful packages to import
# [SC] ggplot2 is for plotting graphs
# [SC] jsonlite is for handling json files
libraries <- c("ggplot2", "jsonlite", "rstudioapi", "stringr")
# [SC] (Download and) import necessary packages
for(mylibrary in libraries){
  ## [SC] installing gplots package
  if (!(mylibrary %in% rownames(installed.packages()))) {
    if (mylibrary == "ggradar"){
      devtools::install_github("ricardo-bion/ggradar", dependencies = TRUE)
    }
    else {
      install.packages(mylibrary)
    }
  }
  library(mylibrary, character.only = TRUE)
}

# [SC] set the working directory to the parent folder of this script
rootpath <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(rootpath)


# [SC] a function to calculate standard error
se <- function(x) { 
  x <- x[!is.na(x)]
  
  return(sd(x)/sqrt(length(x)))
}

calcPassK <- function(c){
  n <- 10
  k <- 10
  if (n - c < k) return(1)
  return(round(1 - (choose(n-c,k)/choose(n,k)), 3))
}


analyze <- function(){
  dataTenDF <- as.data.frame(fromJSON(paste0(rootpath, dataFileTen)))
  dataTenDF <- cbind(dataTenDF, passTen=NA)
  dataTenDF <- cbind(dataTenDF, passTRate=dataTenDF$correct_count/10)
  for (rowIndex in 1:nrow(dataTenDF)){
    dataTenDF$passTen[rowIndex] <- calcPassK(dataTenDF$correct_count[rowIndex])
  }
  
  dataDF <- as.data.frame(fromJSON(paste0(rootpath, dataFile)))
  colnames(dataDF)[colnames(dataDF)=="is_correct"] <- "passOne"
  
  ylimV <- 1.0
  
  print("================ Pass@k by prompts")
  tempTenDF <- aggregate(passTen ~ prompt_name, dataTenDF, mean)
  tempTenDF$passTen <- round(tempTenDF$passTen, 3)
  tempDF <- aggregate(passOne ~ prompt_name, dataDF, mean)
  tempDF$passOne <- round(tempDF$passOne, 3)
  print(paste0(nrow(tempDF), " ", nrow(tempTenDF)))
  tempDF <- merge(tempDF, tempTenDF)
  print(nrow(tempDF))
  tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)

  tempTenDF <- aggregate(passTRate ~ prompt_name, dataTenDF, mean)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  tempDF <- merge(tempDF, tempTenDF)

  tempTenDF <- aggregate(passTRate ~ prompt_name, dataTenDF, se)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
  tempDF <- merge(tempDF, tempTenDF)
  
  tempDF <- cbind(tempDF, common=NA, version=NA)
  for(rowIndex in 1:nrow(tempDF)){
    res <- str_match(tempDF$prompt_name[rowIndex], "(?<common>.+)\\s(?<version>v\\d+)$")
    if (!is.na(res[2])){
      tempDF$common[rowIndex] <- res[2]
      tempDF$version[rowIndex] <- res[3]
    }
    else{
      res <- str_match(tempDF$prompt_name[rowIndex], "(?<common>.+)\\s(?<version>\\d+)$")
      if (!is.na(res[2])){
        tempDF$common[rowIndex] <- res[2]
        tempDF$version[rowIndex] <- res[3]
      }
    }
  }

  tempDF <- tempDF[order(tempDF$common),]
  print(tempDF)
  
  
  par(mfrow=c(2,1))
  tempDF <- merge(tempDF, data.frame(common=unique(tempDF$common), commonId=1:length(unique(tempDF$common))))
  plot(tempDF$commonId, tempDF$passOne, type="p", ylim=c(0, 1)
       , xlab="Prompts with same questions", ylab="Accuracy/SD", main="pass@1 variance based on statement order")
  subTempDF <- aggregate(passOne ~ commonId, tempDF, sd)
  lines(subTempDF$commonId, subTempDF$passOne, type="l")
  plot(tempDF$commonId, tempDF$passTen, type="p", ylim=c(0, 1)
       , xlab="Prompts with same questions", ylab="Accuracy/SD", main="pass@10 variance based on statement order")
  subTempDF <- aggregate(passTen ~ commonId, tempDF, sd)
  lines(subTempDF$commonId, subTempDF$passTen, type="l")
  par(mfrow=c(1,1))
  

  promptDF <- aggregate(passOne ~ common, tempDF, mean)
  colnames(promptDF)[colnames(promptDF)=="passOne"] <- "pass"
  promptDF <- cbind(promptDF, passK="passOne")
  prompTenDF <- aggregate(passTen ~ common, tempDF, mean)
  colnames(prompTenDF)[colnames(prompTenDF)=="passTen"] <- "pass"
  prompTenDF <- cbind(prompTenDF, passK="passTen")
  promptDF <- rbind(promptDF, prompTenDF)
  print(promptDF)
  
  promptPlot <- ggplot(promptDF, aes(x=common, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title=paste0("Prompt mean pass@k"), x="Prompts", y = "Mean pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16)
    )
  print(promptPlot)
  
  
  print("================ Pass@k by models")
  tempTenDF <- aggregate(passTen ~ model, dataTenDF, mean)
  tempTenDF$passTen <- round(tempTenDF$passTen, 3)
  tempDF <- aggregate(passOne ~ model, dataDF, mean)
  tempDF$passOne <- round(tempDF$passOne, 3)
  print(paste0(nrow(tempDF), " ", nrow(tempTenDF)))
  tempDF <- merge(tempDF, tempTenDF)
  print(nrow(tempDF))
  tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)
  
  tempTenDF <- aggregate(passTRate ~ model, dataTenDF, mean)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  tempDF <- merge(tempDF, tempTenDF)
  
  tempTenDF <- aggregate(passTRate ~ model, dataTenDF, se)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
  tempDF <- merge(tempDF, tempTenDF)
  
  tempDF <- tempDF[order(tempDF$passOne),]
  print(tempDF)
  
  longTempDF <- reshape(tempDF[,c("passOne", "passTen", "model")],
                        direction = "long",
                        varying = c("passOne", "passTen"),
                        v.names = "pass",
                        timevar = "passK",
                        times=c("passOne", "passTen"))
  modelPlot <- ggplot(longTempDF, aes(x=model, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title=paste0("Model pass@k"), x="Models", y = "Pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16)
    )
  print(modelPlot)


  print("================ Pass@k by categories")
  tempTenDF <- aggregate(passTen ~ cat, dataTenDF, mean)
  tempTenDF$passTen <- round(tempTenDF$passTen, 3)
  tempDF <- aggregate(passOne ~ cat, dataDF, mean)
  tempDF$passOne <- round(tempDF$passOne, 3)
  print(paste0(nrow(tempDF), " ", nrow(tempTenDF)))
  tempDF <- merge(tempDF, tempTenDF)
  print(nrow(tempDF))
  tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)

  tempTenDF <- aggregate(passTRate ~ cat, dataTenDF, mean)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  tempDF <- merge(tempDF, tempTenDF)

  tempTenDF <- aggregate(passTRate ~ cat, dataTenDF, se)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
  tempDF <- merge(tempDF, tempTenDF)

  tempDF <- tempDF[order(tempDF$passOne),]
  print(tempDF)
  
  longTempDF <- reshape(tempDF[,c("passOne", "passTen", "cat")],
                        direction = "long",
                        varying = c("passOne", "passTen"),
                        v.names = "pass",
                        timevar = "passK",
                        times=c("passOne", "passTen"))
  promptPlot <- ggplot(longTempDF, aes(x=cat, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title=paste0("Category pass@k"), x="Category", y = "Pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16)
    )
  print(promptPlot)


  print("================ Pass@k by subcategories")
  tempTenDF <- aggregate(passTen ~ subcat, dataTenDF, mean)
  tempTenDF$passTen <- round(tempTenDF$passTen, 3)
  tempDF <- aggregate(passOne ~ subcat, dataDF, mean)
  tempDF$passOne <- round(tempDF$passOne, 3)
  print(paste0(nrow(tempDF), " ", nrow(tempTenDF)))
  tempDF <- merge(tempDF, tempTenDF)
  print(nrow(tempDF))
  tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)

  tempTenDF <- aggregate(passTRate ~ subcat, dataTenDF, mean)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  tempDF <- merge(tempDF, tempTenDF)

  tempTenDF <- aggregate(passTRate ~ subcat, dataTenDF, se)
  tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
  colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
  tempDF <- merge(tempDF, tempTenDF)

  tempDF <- tempDF[order(tempDF$passOne),]
  print(tempDF)
  
  longTempDF <- reshape(tempDF[,c("passOne", "passTen", "subcat")],
                        direction = "long",
                        varying = c("passOne", "passTen"),
                        v.names = "pass",
                        timevar = "passK",
                        times=c("passOne", "passTen"))
  promptPlot <- ggplot(longTempDF, aes(x=subcat, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title=paste0("Sub-category pass@k"), x="Sub-category", y = "Pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16)
    )
  print(promptPlot)
}


analyze()

