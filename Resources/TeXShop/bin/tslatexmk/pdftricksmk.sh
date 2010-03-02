#! /bin/bash
# DO NOT EDIT OR COPY THIS FILE. TEXSHOP WILL AUTOMATICALLY UPDATE IT 
# pdftricksmk.sh : pst2pdf adapted to use latexmk
# PSTricks 2 PDF converter :
# Usage: 
#      pdftricksmk.sh 
# produces PDF files for all files of the form *-fig*.tex
#      pdftricksmk.sh <FILE> 
# only considers FILE-fig*.tex

# Modified from pst2pdf distributed with pdftricks.sty to use latexmk

# IT REQUIRES VERSION 3.21 OR HIGHER OF latexmk
# See http://www.phys.psu.edu/~collins/software/latexmk/versions.html
# The version on CTAN is not yet updated

# For each pdf file will only be made if the tex source is out-of-date
# This version of pst2pdf does not clean up generated files: they are
# needed by latexmk to determine whether or not the pdf file is
# out-of-date. 
#
#   To use this automatically with latexmk (linux/UNIX system assumed)
#      1. Install this script (pst2pdf_for_latexmk) somewhere in your PATH
#      2. Put a line like the following in an initialization file for latexmk:
#            $pdflatex = 'pdflatex %O %S; pdftricksmk.sh %B';

# 28 Sep 2007 Herb Schulz --- use latex->dvips->ps2pdf->pdfcrop processing of fig files to get correct bounding box and no rotation
# 27 Sep 2007 John Collins
# 26 Sep 2007 John Collins

Myname='Pdftricksmk.sh'
myname='pdftricksmk.sh'

echo "This is $myname modified to use latexmk, by John Collins (processing changed by HS)"

FILE=$1
if test -z $FILE; then
		FIGURES=`ls *-fig*.tex`;
else
		FIGURES=`ls -- $FILE-fig*.tex`;
fi


if test -z "$FIGURES"; then
   echo $Myname: No files to process
else
  echo $Myname: Using latexmk to process: $FIGURES 
#  ${LTMKBIN}/latexmk -pdfdvi -ps- -dvi- -e '$dvipdf = q/dvips -E -o %B.eps %S && epstopdf %B.eps --outfile=%D/'  $FIGURES
  ${LTMKBIN}/latexmk -pdfdvi -ps- -dvi- -e '$dvipdf = q/dvips -o %B.ps %S ; ps2pdf14 -dAutoRotatePages=\/None %B.ps ; pdfcrop %D ; \/bin\/mv %B-crop.pdf %D/'  $FIGURES
fi
