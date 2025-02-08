# [SC] cleaning the environment
rm(list=ls())

######################################################################
## [SC][TODO] indicate which files to include in analysis

# [SC] 
dataFile <- "/results.json"
# [SC] 
promptFile <- "/prompts.json"

## [SC][TODO] indicate which files to include in analysis
######################################################################

# [SC] some useful packages to import
# [SC] ggplot2 is for plotting graphs
# [SC] jsonlite is for handling json files
libraries <- c("ggplot2", "jsonlite", "rstudioapi")
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

# [SC] load a json file and convert it into a data.frame (a table)
# [SC] paste0 - concatenates two or more string, in this case, a path to the json file
promptDF <- as.data.frame(fromJSON(paste0(rootpath, promptFile)))
# [SC] colnames(promptDF) - returns a vector with column names (string)
# [SC] colnames(promptDF)[colnames(promptDF)=="name"] - get the index of the vector element that is "name"
# [SC] colnames(promptDF)[colnames(promptDF)=="name"] <- "prompt_name" - replace the vector value at the given index with "prompt_name"
colnames(promptDF)[colnames(promptDF)=="name"] <- "prompt_name"

# [SC] load results json file as data.frame
dataDF <- as.data.frame(fromJSON(paste0(rootpath, dataFile)))
# [SC] promptDF[,c("prompt_name", "cat", "subcat")] - create a subtable that includes the three columns
# [SC] merge(dataDF, promptDF[,c("prompt_name", "cat", "subcat")]) - merge the two tables by matching values of columns with similar names ("prompt_name")
dataDF <- merge(dataDF, promptDF[,c("prompt_name", "cat", "subcat")])

analyze <- function(){
  
  print("================ Pass@1 by models")
  # [SC] for each value of the model column, aggregate values of the is_correct column, the method of aggregation is calculating the mean
  # [SC] the aggregated values replace the original values of the is_correct column
  tempDF <- aggregate(is_correct ~ model, dataDF, mean)
  # [SC] round the values of is_correct to 3 decimal points
  tempDF$is_correct <- round(tempDF$is_correct, 3)
  # [SC] order the table by the values of the is_correct column
  tempDF <- tempDF[order(tempDF$is_correct),]
  print(tempDF)
  
  
  print("================ Pass@1 by prompts")
  tempDF <- aggregate(is_correct ~ prompt_name, dataDF, mean)
  tempDF$is_correct <- round(tempDF$is_correct, 3)
  tempDF <- tempDF[order(tempDF$is_correct),]
  print(tempDF)
  
  
  print("================ Pass@1 by categories")
  tempDF <- aggregate(is_correct ~ cat, dataDF, mean)
  tempDF$is_correct <- round(tempDF$is_correct, 3) 
  tempDF <- tempDF[order(tempDF$is_correct),]
  print(tempDF)
  
  
  print("================ Pass@1 by subcategories")
  tempDF <- aggregate(is_correct ~ subcat, dataDF, mean)
  tempDF$is_correct <- round(tempDF$is_correct, 3)
  tempDF <- tempDF[order(tempDF$is_correct),]
  print(tempDF)
}


analyze()

