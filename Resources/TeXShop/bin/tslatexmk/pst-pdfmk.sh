#! /bin/zsh
# DO NOT EDIT OR COPY THIS FILE. TEXSHOP WILL AUTOMATICALLY UPDATE IT 
# pst-pdfmk.sh : pst-pdf converter using latexmk
# PST-PDF converter :
# Usage: 
#      pdftricksmk.sh <BASEFILENAME> 
# only considers BASEFILENAME-pics.tex

# IT REQUIRES VERSION 3.21 OR HIGHER OF latexmk
# See http://www.phys.psu.edu/~collins/software/latexmk/versions.html
# The version on CTAN is not yet updated

# For each pdf file will only be made if the tex source is out-of-date
# This version of pst-pdfmk.sh does not clean up generated files: they are
# needed by latexmk to determine whether or not the pdf file is
# out-of-date. 
#
#   To use this automatically with latexmk (linux/UNIX system assumed)
#      1. Install this script (pst-pdfmk.sh) somewhere in your PATH
#      2. Put a line like the following in an initialization file for latexmk:
#            $pdflatex = 'pst-pdfmk.sh %B; pdflatex %O %S';

# 05 Oct 2007 Herb Schulz --- use latex->dvips->ps2pdf->pdfcrop processing of fig files to get correct bounding box and no rotation
# 27 Sep 2007 John Collins (for pdftricks)
# 26 Sep 2007 John Collins (for pdftricks)

Myname='Pst-pdfmk.sh'
myname='pst-pdfmk.sh'

echo "This is $myname modified to use latexmk, by Herb Schulz from John Collins"

#FILE=$1
#if test -z $FILE; then
#		FIGURES=`ls *-fig*.tex`;
#else
#		FIGURES=`ls -- $FILE-fig*.tex`;
#fi


if test -z "$1.tex"; then
   echo $Myname: No files to process
else
  echo $Myname: Using latexmk to process: $1 
  cp "$1.tex" "$1-pics.tex"
#  cp "$1.aux" "$1-pics.aux"
#  ${LTMKBIN}/latexmk -pdfdvi -ps- -dvi- -e '$latex = q/latex --shell-escape/; $dvipdf = q/dvips -o %B.ps %S ; ps2pdf -dAutoRotatePages=\/None -dALLOWPSTRANSPARENCY %B.ps %D; pdfcrop %D ; \/bin\/mv %B-crop.pdf %D/' "$1-pics.tex"
#${LTMKBIN}/latexmk -pdfps -r "${TSBIN}/latexmkrc" "$1-pics.tex"
  ${LTMKBIN}/latexmk -pdfdvi -ps- -dvi- ${xargarray} -e '$dvipdf = q/dvips -o %B.ps %S ; ps2pdf -dAutoRotatePages=\/None ${gstransparencyarg} %B.ps %D; pdfcrop %D ; \/bin\/mv %B-crop.pdf %D/' "$1-pics.tex"
 rm "$1-pics.tex"
fi
