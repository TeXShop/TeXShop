#!/usr/bin/env python
##
## This is file `run-sagetex-if-necessary.py',
## generated with the docstrip utility.
##
## The original source files were:
##
## scripts.dtx  (with options: `ifnecessaryscript')
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

# given a filename f, examines f.sagetex.sage and f.sagetex.sout and
# runs Sage if necessary.

import hashlib
import sys
import os
import re
import subprocess
from six import PY3

# CHANGE THIS AS APPROPRIATE
path_to_sage = os.path.expanduser('~/bin/sage')
# or try to auto-find it:
# path_to_sage = subprocess.check_output(['which', 'sage']).strip()
# or just tell me:
# path_to_sage = '/usr/local/bin/sage'

if sys.argv[1].endswith('.sagetex.sage'):
    src = sys.argv[1][:-13]
else:
    src = os.path.splitext(sys.argv[1])[0]

usepackage = r'usepackage(\[.*\])?{sagetex}'
uses_sagetex = False

# if it does not use sagetex, obviously running sage is unnecessary
with open(src + '.tex') as texf:
    for line in texf:
        if line.strip().startswith(r'\usepackage') and re.search(usepackage, line):
            uses_sagetex = True
            break

if not uses_sagetex:
    print(src + ".tex doesn't seem to use SageTeX, exiting.")
    sys.exit(0)

# if something goes wrong, assume we need to run Sage
run_sage = True
ignore = r"^( _st_.goboom|print\('SageT| ?_st_.current_tex_line)"

try:
    with open(src + '.sagetex.sage', 'r') as sagef:
        h = hashlib.md5()
        for line in sagef:
            if not re.search(ignore, line):
                if PY3:
                    h.update(bytearray(line,'utf8'))
                else:
                    h.update(bytearray(line))
except IOError:
    print('{0}.sagetex.sage not found, I think you need to typeset {0}.tex first.'.format(src))
    sys.exit(1)

try:
    with open(src + '.sagetex.sout', 'r') as outf:
        for line in outf:
            m = re.match('%([0-9a-f]+)% md5sum', line)
            if m:
                print('computed md5:', h.hexdigest())
                print('sagetex.sout md5:', m.group(1))
                if h.hexdigest() == m.group(1):
                    run_sage = False
                    break
except IOError:
    pass

if run_sage:
    print('Need to run Sage on {0}.'.format(src))
    sys.exit(subprocess.call([path_to_sage, src + '.sagetex.sage']))
else:
    print('Not necessary to run Sage on {0}.'.format(src))
