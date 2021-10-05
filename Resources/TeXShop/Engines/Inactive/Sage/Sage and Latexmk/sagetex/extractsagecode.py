#!/usr/bin/env python
##
## This is file `extractsagecode.py',
## generated with the docstrip utility.
##
## The original source files were:
##
## scripts.dtx  (with options: `extractscript')
## 
## This is a generated file. It is part of the SageTeX package.
## 
## Copyright (C) 2008--2015 by Dan Drake <dr.dan.drake@gmail.com>
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by the
## Free Software Foundation, either version 2 of the License, or (at your
## option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
## Public License for more details.
## 
## You should have received a copy of the GNU General Public License along
## with this program.  If not, see <http://www.gnu.org/licenses/>.
## 
import sys
import time
import getopt
import os.path
from sagetexparse import SageCodeExtractor

def usage():
  print("""Usage: %s [-h|--help] [-o|--overwrite] inputfile [outputfile]

Extracts Sage code from `inputfile'.

`inputfile' can include the .tex extension or not. If you provide
`outputfile', the results will be written to a file of that name,
otherwise the result will be printed to stdout.

Specify `-o' or `--overwrite' to overwrite the file if it exists.

See the SageTeX documentation for more details.""" % sys.argv[0])

try:
  opts, args = getopt.getopt(sys.argv[1:], 'ho', ['help', 'overwrite'])
except getopt.GetoptError as err:
  print(str(err))
  usage()
  sys.exit(2)

overwrite = False
for o, a in opts:
  if o in ('-h', '--help'):
    usage()
    sys.exit()
  elif o in ('-o', '--overwrite'):
    overwrite = True

if len(args) == 0 or len(args) > 2:
  print('Error: wrong number of arguments. Make sure to specify options first.\n')
  usage()
  sys.exit(2)

if len(args) == 2 and (os.path.exists(args[1]) and not overwrite):
  print('Error: %s exists and overwrite option not specified.' % args[1])
  sys.exit(1)

src, ext = os.path.splitext(args[0])
sagecode = SageCodeExtractor(src)
header = """\
# This file contains Sage code extracted from %s%s.
# Processed %s.

""" % (src, ext, time.strftime('%a %d %b %Y %H:%M:%S', time.localtime()))

if len(args) == 2:
  dest = open(args[1], 'w')
else:
  dest = sys.stdout

dest.write(header)
dest.write(sagecode.result)
