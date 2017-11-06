library(shiny)

#options(shiny.maxRequestSize=10*1024^2)

source("./analyze.R")

script <- "
var image = new Image();
image.src = '/shared/ajax-loader.gif';

$(function() {
  
  var preDir = window.localStorage.getItem('predir');
  var lrnFile = window.localStorage.getItem('lrnfile');
  var lrnDir = window.localStorage.getItem('lrndir');
  var csvFile = window.localStorage.getItem('csvfile');
  
  $('#predictionDir').val(preDir);
  $('#learnedFile').val(lrnFile);
  $('#learnedDir').val(lrnDir);
  $('#csvFile').val(csvFile);
  
  var dispMessageOld = '';
  var predDirOld = '';
  var speFileOld = '';
  var speDirOld = '';
  var crossValidationOld = '';
  
  $('#hiddenVal').css('display', 'none');
  
  $('#doButton').on('mousedown', function() {
    var dispMessage = $('#messageArea').text();
    var preDir = $('#predictionDir').val();
    var speFile = $('#learnedFile').val();
    var speDir = $('#learnedDir').val();
    var crossValidation = $('#crossValidationFlag').prop('checked');
    
    // counterplan to show message
    var hiddenVal = $('#hiddenVal').val();
    $('#hiddenVal').val(hiddenVal == '' ? ' ' : '').change();
    
      $('#messageArea').text('running ...');
      
      predDirOld = preDir;
      speFileOld = speFile;
      speDirOld = speDir;
      crossValidationOld = crossValidation;
    
    window.localStorage.setItem('predir', $('#predictionDir').val());
    window.localStorage.setItem('lrnfile', $('#learnedFile').val());
    window.localStorage.setItem('lrndir', $('#learnedDir').val());
    
  });
  
  $('#dispCSV').on('click', function() {
    window.localStorage.setItem('csvfile', $('#csvFile').val());
  });
  
})
"



# ui setting
ui <- shinyUI(
  fluidPage(
    tags$head(tags$script(script)),

    titlePanel("hVISA Classifier"),

    sidebarLayout(
      sidebarPanel(

        textInput('hiddenVal', '', value = ''), 

        textInput('predictionDir', 'Path to a directory of data for prediction'), 

        tags$hr(),

        textInput('learnedFile',   'Path to a .RData file of spectra data'), 
        textInput('learnedDir',    'or to a directory of raw spectra data'), 

        tags$hr(),

        # switch cross validation flag value
        checkboxInput('crossValidationFlag', 'Cross validation', FALSE),

        # do analyze
        actionButton('doButton', 'Analyze'), 

        tags$hr(),

        textInput('csvFile', 'Path to an output CSV to be displayed'), 

        # display CSV file data
        actionButton('dispCSV', 'Display CSV')

      ),
      mainPanel(
        textOutput('messageArea'),
        tableOutput('contents'),
        plotOutput('graph')
      )
    )
  )
)



duSubmit <- function(predictionDir, learningFile, learningDir, crossValidationFlag, input, output, session) {
  
  fileNameList <- doAnalyze(predictionDir, learningFile, learningDir, crossValidationFlag, output)
  
  return(dispCreateCsvMessage(fileNameList, input, output, session))
}



dispCreateCsvMessage <- function(fileNameList, input, output, session) {
  
  defMessage <- "create CSV file -> "
  
  if (is.null(fileNameList)) {
    return()
  } else if (length(fileNameList) == 0) {
    return(paste0("under ", getwd(), " directory"))
  } else {
    returnMessage <- defMessage
    for (fileName in fileNameList) {
      if (returnMessage != defMessage) {
        returnMessage <- paste0(returnMessage, " , ")
      } else {
        observe ({
          csvFilePath <- paste0(getwd(), "/", fileName)
          updateTextInput(session, "csvFile", value=csvFilePath)
        })
      }
      returnMessage <- paste0(returnMessage, " ", fileName)
    }
    return(returnMessage)
  }
}



# validate before analyze
isExistsInputValue <- function(dbFile, dbDir) {
  if (!file.exists(dbFile) & !dir.exists(dbDir)) {
    return(0)
  }
  return(1)
}



# display error message(CSV file error)
dispErrorMessage <- function(input, output) {
  output$messageArea <- renderText({
    input$dispCSV
    
    isolate ({
      msg <- "Error : File does not exist"
    })
    
    return(msg)
  })
}



# server side process
server <- shinyServer(function(input, output, session) {

  # analyze
  output$messageArea <- renderText({
    input$doButton
    
    if (input$doButton == 0) {
      return()
    }
    
    isolate({
      hiddenVal <- input$hiddenVal
      predictionDir <- input$predictionDir
      learnedFile <- input$learnedFile
      learnedDir <- input$learnedDir
      crossValidationFlag <- input$crossValidationFlag
    })
    
    if (is.null(predictionDir)) {
      predictionDir <- ""
    }
    if (is.null(learnedFile)) {
      learnedFile <- ""
    }
    if (is.null(learnedDir)) {
      learnedDir <- ""
    }
    
    if (!isExistsInputValue(learnedFile, learnedDir)) {
      "Error : Please specify either learned_database or database_dir"
    } else {
      paste0(hiddenVal, duSubmit(predictionDir, learnedFile, learnedDir, crossValidationFlag, input, output, session))
    }
    
  })

  # display csv data
  output$contents <- renderTable({
    input$dispCSV
    
    if (input$dispCSV == 0) {
      return()
    }
    
    isolate({
      inFile <- input$csvFile
    })
    
    if (is.null(inFile) || inFile == "") {
      return("Please select CSV file")
    } else {
      if (!file.exists(inFile)) {
        return("Error : File does not exist")
      } else {
        return(read.csv(inFile))
      }
    }
  
  })
  

  session$onSessionEnded(function(){
    stopApp()
    q("no")
  })

})

shinyApp(ui, server)

