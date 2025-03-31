# [SC] cleaning the environment
rm(list=ls())

######################################################################
## [SC][TODO] indicate which files to include in analysis
dataFile <- "/results.json"
dataFileTen <- "/pass10results.json"
######################################################################

# [SC] import useful packages
libraries <- c("ggplot2", "jsonlite", "rstudioapi", "stringr")
for(mylibrary in libraries){
  if (!(mylibrary %in% rownames(installed.packages()))) {
    if (mylibrary == "ggradar"){
      devtools::install_github("ricardo-bion/ggradar", dependencies = TRUE)
    } else {
      install.packages(mylibrary)
    }
  }
  library(mylibrary, character.only = TRUE)
}

# [SC] set the working directory
rootpath <- getwd()
setwd(rootpath)

# [SC] create directory to save plots
dir.create("plots", showWarnings = FALSE)

# [SC] helper functions
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

# [SC] main analysis function
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
  
  tempTenDF <- aggregate(passTen ~ prompt_name, dataTenDF, mean)
  tempTenDF$passTen <- round(tempTenDF$passTen, 3)
  tempDF <- aggregate(passOne ~ prompt_name, dataDF, mean)
  tempDF$passOne <- round(tempDF$passOne, 3)
  tempDF <- merge(tempDF, tempTenDF)
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
    } else {
      res <- str_match(tempDF$prompt_name[rowIndex], "(?<common>.+)\\s(?<version>\\d+)$")
      if (!is.na(res[2])){
        tempDF$common[rowIndex] <- res[2]
        tempDF$version[rowIndex] <- res[3]
      }
    }
  }
  tempDF <- tempDF[order(tempDF$common),]

  # [SC] Base R plots — saved to PNG
  png("plots/variance_plots.png", width = 1000, height = 800)
  par(mfrow=c(2,1))
  tempDF <- merge(tempDF, data.frame(common=unique(tempDF$common), commonId=1:length(unique(tempDF$common))))
  plot(tempDF$commonId, tempDF$passOne, type="p", ylim=c(0, 1),
       xlab="Prompts with same questions", ylab="Accuracy/SD", main="pass@1 variance based on statement order")
  subTempDF <- aggregate(passOne ~ commonId, tempDF, sd)
  lines(subTempDF$commonId, subTempDF$passOne, type="l")
  plot(tempDF$commonId, tempDF$passTen, type="p", ylim=c(0, 1),
       xlab="Prompts with same questions", ylab="Accuracy/SD", main="pass@10 variance based on statement order")
  subTempDF <- aggregate(passTen ~ commonId, tempDF, sd)
  lines(subTempDF$commonId, subTempDF$passTen, type="l")
  dev.off()
  par(mfrow=c(1,1))

  # [SC] ggplot — pass@k by prompts
  promptDF <- aggregate(passOne ~ common, tempDF, mean)
  colnames(promptDF)[colnames(promptDF)=="passOne"] <- "pass"
  promptDF <- cbind(promptDF, passK="passOne")
  prompTenDF <- aggregate(passTen ~ common, tempDF, mean)
  colnames(prompTenDF)[colnames(prompTenDF)=="passTen"] <- "pass"
  prompTenDF <- cbind(prompTenDF, passK="passTen")
  promptDF <- rbind(promptDF, prompTenDF)
  
  promptPlot <- ggplot(promptDF, aes(x=common, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title="Prompt mean pass@k", x="Prompts", y = "Mean pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16))
  ggsave("plots/prompt_pass_k.png", promptPlot, width = 10, height = 6, dpi = 300)

    # [SC] pass@k by model
    tempTenDF <- aggregate(passTen ~ model, dataTenDF, mean)
    tempTenDF$passTen <- round(tempTenDF$passTen, 3)
    tempDF <- aggregate(passOne ~ model, dataDF, mean)
    tempDF$passOne <- round(tempDF$passOne, 3)
    tempDF <- merge(tempDF, tempTenDF)
    tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)
    tempTenDF <- aggregate(passTRate ~ model, dataTenDF, mean)
    tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
    tempDF <- merge(tempDF, tempTenDF)
    tempTenDF <- aggregate(passTRate ~ model, dataTenDF, se)
    tempTenDF$passTRate <- round(tempTenDF$passTRate, 3)
    colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
    tempDF <- merge(tempDF, tempTenDF)

    # Clean up model names
    tempDF$model_clean <- ifelse(
    tempDF$model == "gpt-4o",
    "gpt-4o",
    sub("/[^/]*$", "", tempDF$model)
    )

    tempDF <- tempDF[order(tempDF$passOne),]

    longTempDF <- reshape(tempDF[,c("passOne", "passTen", "model_clean")],
                        direction = "long",
                        varying = c("passOne", "passTen"),
                        v.names = "pass",
                        timevar = "passK",
                        times=c("passOne", "passTen"))

    modelPlot <- ggplot(longTempDF, aes(x=model_clean, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title="Model pass@k", x="Models", y = "Pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
            axis.title = element_text(size = 14),
            legend.text = element_text(size = 12),
            plot.title = element_text(size = 16))

    ggsave("plots/model_pass_k.png", modelPlot, width = 10, height = 6, dpi = 300)


  # [SC] pass@k by category
  tempTenDF <- aggregate(passTen ~ cat, dataTenDF, mean)
  tempDF <- aggregate(passOne ~ cat, dataDF, mean)
  tempDF <- merge(tempDF, tempTenDF)
  tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)
  tempTenDF <- aggregate(passTRate ~ cat, dataTenDF, mean)
  tempDF <- merge(tempDF, tempTenDF)
  tempTenDF <- aggregate(passTRate ~ cat, dataTenDF, se)
  colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
  tempDF <- merge(tempDF, tempTenDF)
  tempDF <- tempDF[order(tempDF$passOne),]

  longTempDF <- reshape(tempDF[,c("passOne", "passTen", "cat")],
                        direction = "long",
                        varying = c("passOne", "passTen"),
                        v.names = "pass",
                        timevar = "passK",
                        times=c("passOne", "passTen"))
  catPlot <- ggplot(longTempDF, aes(x=cat, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title="Category pass@k", x="Category", y = "Pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16))
  ggsave("plots/category_pass_k.png", catPlot, width = 10, height = 6, dpi = 300)

  # [SC] pass@k by subcategory
  tempTenDF <- aggregate(passTen ~ subcat, dataTenDF, mean)
  tempDF <- aggregate(passOne ~ subcat, dataDF, mean)
  tempDF <- merge(tempDF, tempTenDF)
  tempDF <- cbind(tempDF, passDelta=tempDF$passTen-tempDF$passOne)
  tempTenDF <- aggregate(passTRate ~ subcat, dataTenDF, mean)
  tempDF <- merge(tempDF, tempTenDF)
  tempTenDF <- aggregate(passTRate ~ subcat, dataTenDF, se)
  colnames(tempTenDF)[colnames(tempTenDF)=="passTRate"]="passTRateSE"
  tempDF <- merge(tempDF, tempTenDF)
  tempDF <- tempDF[order(tempDF$passOne),]

  longTempDF <- reshape(tempDF[,c("passOne", "passTen", "subcat")],
                        direction = "long",
                        varying = c("passOne", "passTen"),
                        v.names = "pass",
                        timevar = "passK",
                        times=c("passOne", "passTen"))
  subcatPlot <- ggplot(longTempDF, aes(x=subcat, y=pass, fill=passK)) + ylim(0, ylimV) + 
    geom_bar(position="dodge", stat="identity", alpha=0.7) +
    labs(title="Sub-category pass@k", x="Sub-category", y = "Pass@k") +
    coord_flip() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16))
  ggsave("plots/subcategory_pass_k.png", subcatPlot, width = 10, height = 6, dpi = 300)


    # [SC] pass@k by prompt engineering
    peDF <- dataDF
    peDF$base_name <- gsub("\\sv\\d+$", "", peDF$prompt_name)
    peDF$is_concept <- grepl(" - Concept Prompt$", peDF$base_name)
    peDF$clean_base <- gsub(" - Concept Prompt$", "", peDF$base_name)

    concept_rows <- peDF[peDF$is_concept == TRUE, ]
    base_rows    <- peDF[peDF$is_concept == FALSE, ]

    agg_concept <- aggregate(passOne ~ clean_base, concept_rows, mean)
    agg_base    <- aggregate(passOne ~ clean_base, base_rows, mean)

    pe_compare <- merge(agg_concept, agg_base, by = "clean_base", suffixes = c("_concept", "_base"))
    pe_compare$delta_passOne <- round(pe_compare$passOne_concept - pe_compare$passOne_base, 3)

    pe_long <- reshape(
    pe_compare[, c("clean_base", "passOne_base", "passOne_concept")],
    direction = "long",
    varying = list(c("passOne_base", "passOne_concept")),
    v.names = "passOne",
    timevar = "prompt_type",
    times = c("Base", "Concept")
    )

    pe_plot <- ggplot(pe_long, aes(x = clean_base, y = passOne, fill = prompt_type)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    labs(title = "Effect of Prompt Engineering (pass@1)",
        x = "Prompt Base", y = "pass@1") +
    coord_flip() +
    theme(axis.text = element_text(size = 10),
            axis.title = element_text(size = 14),
            legend.text = element_text(size = 12),
            plot.title = element_text(size = 16))

    ggsave("plots/prompt_engineering_effect_pass1.png", pe_plot, width = 10, height = 6, dpi = 300)

    # pass@10 by prompt engineering
    peDF_10 <- dataTenDF
    peDF_10$base_name <- gsub("\\sv\\d+$", "", peDF_10$prompt_name)
    peDF_10$is_concept <- grepl(" - Concept Prompt$", peDF_10$base_name)
    peDF_10$clean_base <- gsub(" - Concept Prompt$", "", peDF_10$base_name)

    concept_rows_10 <- peDF_10[peDF_10$is_concept == TRUE, ]
    base_rows_10    <- peDF_10[peDF_10$is_concept == FALSE, ]

    agg_concept_10 <- aggregate(passTen ~ clean_base, concept_rows_10, mean)
    agg_base_10    <- aggregate(passTen ~ clean_base, base_rows_10, mean)

    pe_compare_10 <- merge(agg_concept_10, agg_base_10, by = "clean_base", suffixes = c("_concept", "_base"))
    pe_compare_10$delta_passTen <- round(pe_compare_10$passTen_concept - pe_compare_10$passTen_base, 3)

    pe_long_10 <- reshape(
    pe_compare_10[, c("clean_base", "passTen_base", "passTen_concept")],
    direction = "long",
    varying = list(c("passTen_base", "passTen_concept")),
    v.names = "passTen",
    timevar = "prompt_type",
    times = c("Base", "Concept")
    )

    pe_plot_10 <- ggplot(pe_long_10, aes(x = clean_base, y = passTen, fill = prompt_type)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    labs(title = "Effect of Prompt Engineering (pass@10)",
        x = "Prompt Base", y = "pass@10") +
    coord_flip() +
    theme(axis.text = element_text(size = 10),
            axis.title = element_text(size = 14),
            legend.text = element_text(size = 12),
            plot.title = element_text(size = 16))

    ggsave("plots/prompt_engineering_effect_pass10.png", pe_plot_10, width = 10, height = 6, dpi = 300)



  # Prompt engineering pass@10
  peDF_model <- dataTenDF
  peDF_model$base_name <- gsub("\\sv\\d+$", "", peDF_model$prompt_name)
  peDF_model$is_concept <- grepl(" - Concept Prompt$", peDF_model$base_name)
  peDF_model$clean_base <- gsub(" - Concept Prompt$", "", peDF_model$base_name)
  peDF_model$prompt_type <- ifelse(peDF_model$is_concept, "Concept", "Base")

  peDF_model$model_clean <- ifelse(
    peDF_model$model == "gpt-4o",
    "gpt-4o",
    sub("/[^/]*$", "", peDF_model$model)
  )

  agg_model <- aggregate(passTen ~ model_clean + prompt_type, data = peDF_model, FUN = mean)

  model_compare <- reshape(
    agg_model,
    timevar = "prompt_type",
    idvar = "model_clean",
    direction = "wide"
  )
  model_compare$delta_passTen <- round(model_compare$passTen.Concept - model_compare$passTen.Base, 3)

  delta_plot <- ggplot(model_compare, aes(x = reorder(model_clean, delta_passTen), y = delta_passTen, fill = delta_passTen > 0)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    labs(title = "Model-wise Effect of Prompt Engineering (pass@10)",
        x = "Model", y = "Δ pass@10 (Concept - Base)") +
    coord_flip() +
    scale_fill_manual(values = c("TRUE" = "seagreen3", "FALSE" = "tomato"),
                      labels = c("Negative Impact", "Positive Impact"),
                      name = "Effect") +
    theme(axis.text = element_text(size = 10),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 12),
          plot.title = element_text(size = 16))

  ggsave("plots/model_prompt_engineering_delta_pass10.png", delta_plot, width = 10, height = 6, dpi = 300)


  # Albums size analysis
  albums_size_df <- dataTenDF[grepl("^Albums size \\d+$", dataTenDF$prompt_name), ]
  albums_size_df$size <- as.integer(gsub("^Albums size (\\d+)$", "\\1", albums_size_df$prompt_name))

  avg_by_size <- aggregate(passTen ~ size, data = albums_size_df, FUN = mean)

  plot1 <- ggplot(avg_by_size, aes(x = factor(size), y = passTen)) +
    geom_bar(stat = "identity", fill = "skyblue", alpha = 0.8) +
    labs(title = "Effect of Albums Size on pass@10 (All Models)",
        x = "Albums Size", y = "Mean pass@10") +
    theme_minimal() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16))

  ggsave("plots/albums_size_pass10_overall.png", plot1, width = 8, height = 5, dpi = 300)


  albums_size_df$model_clean <- ifelse(
    albums_size_df$model == "gpt-4o",
    "gpt-4o",
    sub("/[^/]*$", "", albums_size_df$model)
  )

  avg_by_model_size <- aggregate(passTen ~ model_clean + size, data = albums_size_df, FUN = mean)

  plot2 <- ggplot(avg_by_model_size, aes(x = factor(size), y = passTen, fill = model_clean)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
    labs(title = "Effect of Albums Size on pass@10 (Per Model)",
        x = "Albums Size", y = "Mean pass@10", fill = "Model") +
    theme_minimal() +
    theme(axis.text = element_text(size = 10),
          axis.title = element_text(size = 14),
          legend.text = element_text(size = 10),
          plot.title = element_text(size = 16))

  ggsave("plots/albums_size_pass10_per_model.png", plot2, width = 10, height = 6, dpi = 300)



  # real vs fictional data 

  albums_subset <- dataTenDF[grepl("^Albums v\\d+$|^Real Albumn v\\d+$", dataTenDF$prompt_name), ]
  albums_subset$data_type <- ifelse(grepl("^Albums v\\d+$", albums_subset$prompt_name), "Fictional", "Real")

  overall_comp <- aggregate(passTen ~ data_type, albums_subset, mean)

  plot_rf <- ggplot(overall_comp, aes(x = data_type, y = passTen, fill = data_type)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    labs(title = "Real vs Fictional Albums (pass@10 across all models)",
        x = "Data Type", y = "Mean pass@10") +
    theme_minimal() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16),
          legend.position = "none")

  ggsave("plots/real_vs_fiction_albums_overall_pass10.png", plot_rf, width = 6, height = 4, dpi = 300)

  albums_subset$model_clean <- ifelse(
    albums_subset$model == "gpt-4o",
    "gpt-4o",
    sub("/[^/]*$", "", albums_subset$model)
  )

  model_comp <- aggregate(passTen ~ model_clean + data_type, data = albums_subset, FUN = mean)

  model_wide <- reshape(model_comp,
                        timevar = "data_type",
                        idvar = "model_clean",
                        direction = "wide")

  model_wide$delta_passTen <- round(model_wide$passTen.Real - model_wide$passTen.Fictional, 3)

  delta_plot <- ggplot(model_wide, aes(x = reorder(model_clean, delta_passTen), y = delta_passTen, fill = delta_passTen > 0)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    labs(title = "Model-wise Δ pass@10: Real - Fictional Albums",
        x = "Model", y = "Δ pass@10") +
    coord_flip() +
    scale_fill_manual(values = c("TRUE" = "seagreen3", "FALSE" = "tomato"),
                      labels = c("Fictional > Real", "Real > Fictional"),
                      name = "Which Performed Better") +
    theme_minimal() +
    theme(axis.text = element_text(size = 10),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16))

  ggsave("plots/real_vs_fiction_albums_modelwise_pass10.png", delta_plot, width = 10, height = 6, dpi = 300)


  # Inferene prompts

  chain_types <- c("Baseline No Inference", "1-chain Inference Prompt", "2-chain Inference Prompt")
  pattern <- paste0("^(", paste(chain_types, collapse = "|"), ") v\\d+$")
  all_inference_df <- dataTenDF[grepl(pattern, dataTenDF$prompt_name), ]
  all_inference_df$reasoning_type <- sub(" v\\d+$", "", all_inference_df$prompt_name)

  all_inference_df$data_type <- ifelse(grepl("^Fictional", all_inference_df$reasoning_type), "Fictional", "Real")

  all_inference_df$reasoning_clean <- gsub("^Fictional ", "", all_inference_df$reasoning_type)


  agg_all <- aggregate(passTen ~ reasoning_clean, data = all_inference_df, mean)

  plot_all <- ggplot(agg_all, aes(x = reasoning_clean, y = passTen)) +
    geom_bar(stat = "identity", fill = "steelblue", alpha = 0.8) +
    labs(title = "Reasoning Difficulty (pass@10 across all prompts)",
        x = "Reasoning Type", y = "Mean pass@10") +
    theme_minimal() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16))

  ggsave("plots/reasoning_baseline_vs_chain_all_pass10.png", plot_all, width = 8, height = 5, dpi = 300)

  dataTenDF$data_type <- ifelse(grepl("^Fictional", dataTenDF$prompt_name), "Fictional", "Real")


  real_vs_fiction <- aggregate(passTen ~ data_type, dataTenDF, mean)

  plot_rf <- ggplot(real_vs_fiction, aes(x = data_type, y = passTen, fill = data_type)) +
    geom_bar(stat = "identity", alpha = 0.85) +
    labs(title = "Real vs Fictional Inference Prompts (pass@10)",
        x = "Data Type", y = "Mean pass@10") +
    theme_minimal() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16),
          legend.position = "none")

  ggsave("plots/inference_real_vs_fictional_pass10.png", plot_rf, width = 6, height = 4, dpi = 300)



  # Syntax error severity v1 to v8
  syntax_df <- dataTenDF[grepl("^Mythical Creatures Habitat Name Syntax Incorrect v\\d+$", dataTenDF$prompt_name), ]
  syntax_df$severity <- as.integer(sub("^Mythical Creatures Habitat Name Syntax Incorrect v(\\d+)$", "\\1", syntax_df$prompt_name))

  agg_severity <- aggregate(passTen ~ severity, data = syntax_df, FUN = mean)

  plot_syntax <- ggplot(agg_severity, aes(x = severity, y = passTen)) +
    geom_line(color = "firebrick", size = 1.5) +
    geom_point(color = "firebrick", size = 3) +
    labs(title = "Effect of RDF Syntax Errors on Model Accuracy (pass@10)",
        x = "Syntax Error Severity (v1 → v8)", y = "Mean pass@10") +
    theme_minimal() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16))

  ggsave("plots/syntax_severity_effect_pass10.png", plot_syntax, width = 8, height = 5, dpi = 300)

  # Heatmap
  dataTenDF$model_clean <- ifelse(
    dataTenDF$model == "gpt-4o",
    "gpt-4o",
    sub("/[^/]*$", "", dataTenDF$model)
  )

  heatmap_df <- aggregate(passTen ~ model_clean + cat, data = dataTenDF, mean)

  heatmap_plot <- ggplot(heatmap_df, aes(x = cat, y = model_clean, fill = passTen)) +
    geom_tile(color = "white") +
    scale_fill_gradient(low = "tomato", high = "seagreen3") +
    labs(title = "Model × Category Performance (pass@10)",
        x = "Category", y = "Model", fill = "pass@10") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
          axis.text.y = element_text(size = 10),
          axis.title = element_text(size = 14),
          plot.title = element_text(size = 16))

  ggsave("plots/model_category_heatmap_pass10.png", heatmap_plot, width = 10, height = 6, dpi = 300)


}


analyze()
