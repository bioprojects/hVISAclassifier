CreateObject("Wscript.Shell").Run "R-Portable\App\R-Portable\bin\i386\R.exe CMD BATCH --vanilla --slave runShinyApp.R shinyLog.log", 0, False
