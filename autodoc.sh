#!/bin/sh
PROJECT_DIR=~/Projects/TeXShop
DOCDIR=$PROJECT_DIR/Documentation

autodoc -allclasses -force -tree -format html -destination $DOCDIR -project $PROJECT_DIR
cd $DOCDIR
mv NSString+NSStringTextFinding.html NSStringTextFinding.html


