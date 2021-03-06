# analyze
doAnalyze <- function(prediction_dir, spectraRDataDB_File, spectraRawDB_dir, crossValidationFlag, output) {


  ##############################################################################
  # definition
  ##############################################################################

#  flag_plot_discriminatory_peaks <- F

  ##
  ## directory containing data you would like to classify
  ## 
  prediction_dir <- prediction_dir
  
  ##
  ## spectra data for learning (either of them)
  ##
  spectraRDataDB_File <- spectraRDataDB_File
  spectraRawDB_dir    <- spectraRawDB_dir

  ##################################
  # global option
  ##################################

  ##
  ## cross-valiation switch
  ## 
  flag_cross_validation <- crossValidationFlag
  
  ##################################
  # global option
  # (no need to change)
  ##################################

  ##
  ## specify classes
  ## that must be included in file or directory name of each sample
  ##
  ## pattern matching on each file name will be conducted in this order
  ##
  c_class   <- c("VSSA", "hVISA", "VISA") 

  ##############################################################################
  # library and options
  ##############################################################################

  #options(max.print=111)

  library(MALDIquant)
  library(MALDIquantForeign)
  library(varSelRF)

  ##############################################################################
  # main
  ##############################################################################

  returnMessage <- list()
  outCsvFileName <- ""

  ############################
  # data for prediction
  ############################
  spectraD1 <- list()  
  if (dir.exists(prediction_dir)) {
    spectraD1  <- importBrukerFlex(prediction_dir, verbose=FALSE)
  }

  ############################
  # database for training
  ############################
  spectraD0 <- list()
  if (file.exists(spectraRDataDB_File)) {
    load(spectraRDataDB_File)
  } else if (dir.exists(spectraRawDB_dir)) {
    spectraD0 <- importBrukerFlex(spectraRawDB_dir, verbose=FALSE)

    #separateDatabaseDir <- strsplit(spectraRawDB_dir, "\\\\|/")[[1]]
    #separateDatabaseDir <- rev(separateDatabaseDir)[1]
    save(
      #spectraD0, file=sprintf("hVISAclassifier_spectra_%s.RData",separateDatabaseDir)
      spectraD0, file=sprintf("%s.RData",spectraRawDB_dir)
    )

  } else {
    stop("Please specify either a path to a .RData file of spectra data or that to a directory of raw spectra data")
  }
  
  # -------------------------------
  # prepare spectraDcat 
  #         feature2Matrix
  # -------------------------------
  spectraDcat <- list()
  feature2Matrix <- matrix()
  
  if (length(spectraD1) > 0) {
    spectraD1   <- importBrukerFlex(prediction_dir, verbose=FALSE)
    spectraDcat <- c(spectraD0, spectraD1)
  } else {
    spectraDcat <- spectraD0
  }
  
  ## transform intensities
  spectraDcatForPeakCalling <- transformIntensity(spectraDcat, method="sqrt")
  ## smooth spectra
  spectraDcatForPeakCalling <- smoothIntensity(spectraDcatForPeakCalling, method="MovingAverage")
  ## baseline correction
  spectraDcatForPeakCalling <- removeBaseline(spectraDcatForPeakCalling)
  
  ## detect peaks
  peaks <- detectPeaks(spectraDcatForPeakCalling)
  
  #featureMatrixBeforeWarp <- intensityMatrix(peaks)
  
  ## check peaks and set cl_D0
  cl_D0 <- c()
  c_sampleFNames <- c()
  for (i in 1:length(spectraD0)) {
    #plot(spectra[[i]])
    #points(peaks[[i]])
    #top10 <- intensity(peaks[[i]]) %in% sort(intensity(peaks[[i]]), decreasing=TRUE)[1:10]
    #labelPeaks(peaks[[i]], index=top10)
    
    # --------------------------------------------
    # set eachSampleClass for this individual i
    # --------------------------------------------
    
    eachSampleFName <- spectraD0[[i]]@metaData$file
    eachSampleClass <- ""
    
    arr_parts_sampleFName <- unlist(strsplit(eachSampleFName,"\\\\|/"))
    
    for (i in (length(arr_parts_sampleFName)-4):1) {
      # VSSA?
      if (length(grep(c_class[1], arr_parts_sampleFName[i])) == 1) {
        if (eachSampleClass == "") {
          eachSampleClass <- c_class[1]
        } else {
          stop(
            sprintf("Error: both phentoypes are found in your file path %s", eachSampleFName)
          )
        }
      # hVISA?
      } else if (length(grep(c_class[2], arr_parts_sampleFName[i])) == 1) {
        if (eachSampleClass == "") {
          eachSampleClass <- c_class[2]
        } else {
          stop(
            sprintf("Error: both phentoypes are found in your file path %s", eachSampleFName)
          )
        }
      # VISA?
      } else if (length(grep(c_class[3], arr_parts_sampleFName[i])) == 1) {
        if (eachSampleClass == "") {
          eachSampleClass <- c_class[3]
        } else {
          stop(
            sprintf("Error: both phentoypes are found in your file path %s", eachSampleFName)
          )
        }
      }
      
      if ( sum(c_class %in% eachSampleClass) == 1 ) {
        break
      }
    }
    
    if (eachSampleClass == "") {
      print(sprintf("Error: eachSampleClass is empty for i=%s, name=%s", i, eachSampleFName))
    }
    cl_D0 <- c(cl_D0, eachSampleClass)
    c_sampleFNames <- c(c_sampleFNames, eachSampleFName)
  }
  stopifnot(length(cl_D0) == length(spectraD0))
  cl_D0 <- as.factor(cl_D0)
  
  ## calculate warping functions (using LOWESS based basic function [default])
  #w <- determineWarpingFunctions(peaks, plot=TRUE, plotInteractive=TRUE)
  w <- determineWarpingFunctions(peaks, plot=FALSE)
  
  peaks_warpped        <- warpMassPeaks(peaks, w) 
  peaks_warpped_binned <- binPeaks(peaks_warpped) 
  
  featureMatrix <- intensityMatrix(peaks_warpped_binned)
  
  #
  # create feature2Matrix from featureMatrix
  #
  feature2Matrix <- featureMatrix[,]
  for (i in 1:nrow(feature2Matrix)) {
    for (j in 1:ncol(feature2Matrix)) {
      if (is.na(feature2Matrix[i,j])) {
        feature2Matrix[i,j] <- 0
      }
    }
  }

  #
  # if test data are specified, 
  # move them from the feature2Matrix to testMatrix => testDf
  #
  testMatrix <- matrix()
  feature2MatrixWithTest <- feature2Matrix
  
  if (length(spectraD1) > 0) {
    test_row_from <- nrow(feature2MatrixWithTest) - length(spectraD1) + 1
    test_row_to   <- nrow(feature2MatrixWithTest) 
    
    testMatrix     <- feature2MatrixWithTest[ c(test_row_from:test_row_to), ]
    feature2Matrix <- feature2MatrixWithTest[-c(test_row_from:test_row_to), ]
  }

  ##################################
  # feature selection
  ##################################
  
  set.seed(111)
  rf.vs1 <- varSelRF(feature2Matrix, cl_D0, vars.drop.frac = 0.18) # reducing the value improves discrimination (but 0.15 takes much longer time)
  rf.vs1

  df_selectedVars     <- data.frame(feature2Matrix[,which(colnames(feature2Matrix) %in% rf.vs1$selected.vars)])
  dim(df_selectedVars)
#  write.table(df_selectedVars, file="C://df_selectedVars.txt", sep="\t")
#
#  df_feature2Matrix <- data.frame(feature2Matrix)
#  df_feature2Matrix$cl_D0 <- cl_D0
#  write.table(df_feature2Matrix, file="C://df_feature2Matrix.txt", sep="\t")
#  write.table(data.frame(apply(df_feature2Matrix[cl_D0==c_class[1], -ncol(df_feature2Matrix)], 2, mean, na.rm=T)), file="C://df_average_spectra_class1_VSSA.txt",  sep="\t")
#  write.table(data.frame(apply(df_feature2Matrix[cl_D0==c_class[2], -ncol(df_feature2Matrix)], 2, mean, na.rm=T)), file="C://df_average_spectra_class2_hVISA.txt", sep="\t")
#  write.table(data.frame(apply(df_feature2Matrix[cl_D0==c_class[3], -ncol(df_feature2Matrix)], 2, mean, na.rm=T)), file="C://df_average_spectra_class3_VISA.txt",  sep="\t")


#  if (flag_plot_discriminatory_peaks) {
#    #
#    # confirm statistically significant differences in the peaks
#    # between the two groups
#    #
#    for (j in 1:ncol(df_selectedVars)) {
#      print(
#        wilcox.test(
#          df_selectedVars[cl_D0==c_class[1], j]
#          ,df_selectedVars[cl_D0==c_class[2], j]
#        )
#      )
#      boxplot(
#        df_selectedVars[cl_D0==c_class[1],  j]
#        , df_selectedVars[cl_D0==c_class[2],  j]
#        , ylim=c(0, 50)
#        , xlab=c("VSSA", "hVISA")
#        , main=names(df_selectedVars)[j]
#      )
#    }
#  }

  #################################################
  # validation
  #################################################

  #####################################
  # validation by test data if specified
  #####################################  
  if (length(spectraD1) > 0) {
  
    set.seed(111)
    rf.classify <- randomForest(cl_D0 ~ ., data=df_selectedVars, seed=111)
    
    testDf     <- data.frame(testMatrix[,which(colnames(testMatrix) %in% rf.vs1$selected.vars)])
    c_predicted <- predict(rf.classify, newdata = testDf)
    
    c_testSampleNames <- c()
    for (i in 1:length(spectraD1)) {
      c_testSampleNames <- c(c_testSampleNames, spectraD1[[i]]@metaData$file)
    }
    
    df_testPredicted <- data.frame(sample=c_testSampleNames, prediction=c_predicted)
    
    separatePredictionDir <- strsplit(prediction_dir, "\\\\|/")[[1]]
    separatePredictionDir <- rev(separatePredictionDir)[1]
    
    outCsvFileName <- sprintf("prediction_of_%s_out.csv", separatePredictionDir)
    
    write.csv(
      df_testPredicted
      , file=outCsvFileName
      , quote=F, row.names=F
    )
    
    returnMessage <- c(returnMessage, list(outCsvFileName))
    
  } 

  #####################################
  # cross validation
  #####################################  
  if (flag_cross_validation) {
        
    c_predicted <- c()
    list_leaveOneOut <- list()
    for (i in 1:nrow(feature2Matrix)) {
      print(i)
      
      cl_leaveOneOut <- cl_D0[-i]
      
      df_leaveOneOut_selectedVars <- df_selectedVars[-i,]
      df_newfeature2Matrix        <- df_selectedVars[i, ]
      
      dim(df_leaveOneOut_selectedVars) 
      #print(df_leaveOneOut_selectedVars)

      set.seed(111)

      # training by using the selected peaks
      rf.leaveOneOut.classify <- randomForest(cl_leaveOneOut ~ ., data=df_leaveOneOut_selectedVars, seed=111)
      print(rf.leaveOneOut.classify)
      list_leaveOneOut[[i]] <- rf.leaveOneOut.classify
      
      # prediction
      predicted <- predict(rf.leaveOneOut.classify, newdata = df_newfeature2Matrix)
      
      c_predicted <- c(c_predicted, as.character(predicted))
      
    }
    
    # row:    truth
    # column: prediction
    table(cl_D0, c_predicted)
    
    df_leaveOneOut_table <- data.frame(truth=cl_D0, prediction=c_predicted, sample=c_sampleFNames)
    df_leaveOneOut_table$correct <- ifelse(df_leaveOneOut_table$truth == df_leaveOneOut_table$prediction, 1, 0)
    df_leaveOneOut_table[df_leaveOneOut_table[,1]!=df_leaveOneOut_table[,2], ]

    if (file.exists(spectraRDataDB_File)) {
      DBstr <-  strsplit(spectraRDataDB_File, "\\\\|/")[[1]]
    } else if (dir.exists(spectraRawDB_dir)) {
      DBstr <- strsplit(spectraRawDB_dir, "\\\\|/")[[1]]
    }
    DBstr <- rev(DBstr)[1]
    DBstr <- sub(".RData", "", DBstr)
    
    outCsvFileName <- sprintf("crossValidation_%s_out.csv", DBstr)
    
    write.csv(
      df_leaveOneOut_table
      , file=outCsvFileName
      , quote=F, row.names=F
    )
    
    returnMessage <- c(returnMessage, list(outCsvFileName))
    
    round(prop.table(
      table(df_leaveOneOut_table[,1:2])
      , margin=1), 2
    )
   
  }

  if (length(returnMessage) > 0) {
    return(returnMessage)
  } else {
    return(paste0("No CSV file was specified and created in -> ", getwd(), " directory"))
  }

}
