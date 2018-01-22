# hVISA Classifier

This is a graphical program that enables classification between hVISA (defined by BHI-agar), VISA, and vancomycin-susceptible S. aureus using MALDI-TOF MS data.  

Please download it by pushing "Clone or download" -> "Download ZIP" at the right in this GitHub homepage.

After downloading and unzipping in your C drive, please double-click "run.vbs".  The following window will appear in your web-browser.  

According to the texts in the window, please specify 
1) path to a folder of MALDI-TOF MS data of each sample to be classified (e.g, "C:\hVISAclassifier\example_data" to specify "example_data" folder included in the package)

2) path to a .RData database file of spectra data (e.g., "C:\hVISAclassifier\spectraDB.RData" to specify "spectraDB.RData" file included in the package). 

![Alt text](http://yahara.hustle.ne.jp/projects/hVISAclassifier/hVISAclassifier_main_window1.png "hVISAclassifier_main_window1")

Push the "Analyze" button.  The program will be running as below.


![Alt text](http://yahara.hustle.ne.jp/projects/hVISAclassifier/hVISAclassifier_main_window3.png "hVISAclassifier_main_window3")

When it finishes running, an output CSV file will be created.  Its name and path will be automatically displayed in the window.

![Alt text](http://yahara.hustle.ne.jp/projects/hVISAclassifier/hVISAclassifier_main_window4.png "hVISAclassifier_main_window4")

Please push "Display CSV" button.  Prediction for each sample will be displayed as below.

![Alt text](http://yahara.hustle.ne.jp/projects/hVISAclassifier/hVISAclassifier_main_window5.png "hVISAclassifier_main_window5")

Alternatively, You can specify a path to a directory of raw spectra data to conduct learning and create .RData database file by yourself using your reference dataset.  Within this directory, you can further choose to store data in the "VISA", "hVISA" or "VSSA" subdirectories. The raw spectral data are imported into the software, compressed into another database file, and processed by the algorithm to construct a machine-learning classifier after selecting another combination of peaks that were most effective at classifying the samples.  In that case, .RData file will be created in the same folder as that of the raw spectra data you specified.

Currently, the software can import the spectral data of MALDI-TOF MS instruments made by Bruker.
