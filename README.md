# hVISAclassifier

This is a graphical program that enables classification between hVISA and vancomycin-susceptible S. aureus using MALDI-TOF MS data.  

Please download it by pushing "Clone or download" -> "Download ZIP" at the right in this GitHub homepage.

After downloading and unzipping in your C drive, please double-click "run.vbs".  The following window will appear in your web-browser.  

According to the texts in the window, please specify 
1) path to a directory of MALDI-TOF MS data of each sample to be classified (e.g, "C:\hVISAclassifier\example_data" to specify "example_data" folder included in the package)

2) path to a .RData database file of spectra data (e.g., "C:\hVISAclassifier\spectraDB.RData" to specify "spectraDB.RData" file included in the package). 

![Alt text](http://yahara.hustle.ne.jp/projects/lftp_tmp/hVISAclassifier_main_window1.png "hVISAclassifier_main_window1")

Push the "Analyze" button.  The program will be running as below.


![Alt text](http://yahara.hustle.ne.jp/projects/lftp_tmp/hVISAclassifier_main_window3.png "hVISAclassifier_main_window3")

When it finishes running, an output CSV file will be created.  Its name and path will be automatically displayed in the window.

![Alt text](http://yahara.hustle.ne.jp/projects/lftp_tmp/hVISAclassifier_main_window4.png "hVISAclassifier_main_window4")

Please push "Display CSV" button.  Prediction for each sample will be displayed as below.

![Alt text](http://yahara.hustle.ne.jp/projects/lftp_tmp/hVISAclassifier_main_window5.png "hVISAclassifier_main_window5")


