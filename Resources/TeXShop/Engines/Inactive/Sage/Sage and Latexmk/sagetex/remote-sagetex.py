#!/usr/bin/env python
##
## This is file `remote-sagetex.py',
## generated with the docstrip utility.
##
## The original source files were:
##
## remote-sagetex.dtx  (with options: `remotesagetex')
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
from __future__ import print_function
import json
import sys
import time
import re
import urllib
import hashlib
import os
import os.path
import shutil
import getopt
from contextlib import closing

#########################################################################
# You can provide a filename here and the script will read your login   #
# information from that file. The format must be:                       #
#                                                                       #
# server = 'http://foo.com:8000'                                        #
# username = 'my_name'                                                  #
# password = 's33krit'                                                  #
#                                                                       #
# You can omit one or more of those lines, use " quotes, and put hash   #
# marks at the beginning of a line for comments. Command-line args      #
# take precedence over information from the file.                       #
#########################################################################
login_info_file = None       # e.g. '/home/foo/Private/sagetex-login.txt'

usage = """Process a SageTeX-generated .sage file using a remote Sage server.

Usage: {0} [options] inputfile.sage

Options:

    -h, --help:         print this message
    -s, --server:       the Sage server to contact
    -u, --username:     username on the server
    -p, --password:     your password
    -f, --file:         get login information from a file

If the server does not begin with the four characters `http', then
`https://' will be prepended to the server name.

You can hard-code the filename from which to read login information into
the remote-sagetex script. Command-line arguments take precedence over
the contents of that file. See the SageTeX documentation for formatting
details.

If any of the server, username, and password are omitted, you will be
asked to provide them.

See the SageTeX documentation for more details on usage and limitations
of remote-sagetex.""".format(sys.argv[0])

server, username, password = (None,) * 3

try:
    opts, args = getopt.getopt(sys.argv[1:], 'hs:u:p:f:',
                    ['help', 'server=', 'user=', 'password=', 'file='])
except getopt.GetoptError as err:
    print(str(err), usage, sep='\n\n')
    sys.exit(2)

for o, a in opts:
    if o in ('-h', '--help'):
        print(usage)
        sys.exit()
    elif o in ('-s', '--server'):
        server = a
    elif o in ('-u', '--user'):
        username = a
    elif o in ('-p', '--password'):
        password = a
    elif o in ('-f', '--file'):
        login_info_file = a

if len(args) != 1:
    print('Error: must specify exactly one file. Please specify options first.',
          usage, sep='\n\n')
    sys.exit(2)

jobname = os.path.splitext(args[0])[0]
traceback_str = 'Exception in SageTeX session {0}:'.format(time.time())
def parsedotsage(fn):
    with open(fn, 'r') as f:
        inline = re.compile(r" _st_.inline\((?P<num>\d+), (?P<code>.*)\)")
        plot = re.compile(r" _st_.plot\((?P<num>\d+), (?P<code>.*)\)")
        goboom = re.compile(r" _st_.goboom\((?P<num>\d+)\)")
        pausemsg = re.compile(r"print.'(?P<msg>SageTeX (un)?paused.*)'")
        blockbegin = re.compile(r"_st_.blockbegin\(\)")
        ignore = re.compile(r"(try:)|(except):")
        in_comment = False
        in_block = False
        cmds = []
        for line in f.readlines():
            if line.startswith('"""'):
                in_comment = not in_comment
            elif not in_comment:
                m = pausemsg.match(line)
                if m:
                    cmds.append({'type': 'pause',
                                 'msg': m.group('msg')})
                m = inline.match(line)
                if m:
                    cmds.append({'type': 'inline',
                                 'num': m.group('num'),
                                 'code': m.group('code')})
                m = plot.match(line)
                if m:
                    cmds.append({'type': 'plot',
                                 'num': m.group('num'),
                                 'code': m.group('code')})
                m = goboom.match(line)
                if m:
                    cmds[-1]['goboom'] = m.group('num')
                    if in_block:
                        in_block = False
                if in_block and not ignore.match(line):
                    cmds[-1]['code'] += line
                if blockbegin.match(line):
                    cmds.append({'type': 'block',
                                 'code': ''})
                    in_block = True
    return cmds
debug = False
class RemoteSage:
    def __init__(self, server, user, password):
        self._srv = server.rstrip('/')
        sep = '___S_A_G_E___'
        self._response = re.compile('(?P<header>.*)' + sep +
                                   '\n*(?P<output>.*)', re.DOTALL)
        self._404 = re.compile('404 Not Found')
        self._session = self._get_url('login',
                                    urllib.urlencode({'username': user,
                                    'password':
                                    password}))['session']
        self._codewrap = """try:
{{0}}
except:
    print('{0}')
    traceback.print_exc()""".format(traceback_str)
        self.do_block("""
    import traceback
    def __st_plot__(counter, _p_, format='notprovided', **kwargs):
        if format == 'notprovided':
            formats = ['eps', 'pdf']
        else:
            formats = [format]
        for fmt in formats:
            plotfilename = 'plot-%s.%s' % (counter, fmt)
            _p_.save(filename=plotfilename, **kwargs)""")

    def _encode(self, d):
        return 'session={0}&'.format(self._session) + urllib.urlencode(d)

    def _get_url(self, action, u):
        with closing(urllib.urlopen(self._srv + '/simple/' + action +
                                    '?' + u)) as h:
            data = self._response.match(h.read())
            result = json.loads(data.group('header'))
            result['output'] = data.group('output').rstrip()
        return result

    def _get_file(self, fn, cell, ofn=None):
        with closing(urllib.urlopen(self._srv + '/simple/' + 'file' + '?' +
                     self._encode({'cell': cell, 'file': fn}))) as h:
            myfn = ofn if ofn else fn
            data = h.read()
            if not self._404.search(data):
                with open(myfn, 'w') as f:
                    f.write(data)
            else:
                print('Remote server reported {0} could not be found:'.format(
                      fn))
                print(data)
    def _do_cell(self, code):
        realcode = self._codewrap.format(code)
        result = self._get_url('compute', self._encode({'code': realcode}))
        if result['status'] == 'computing':
            cell = result['cell_id']
            while result['status'] == 'computing':
                sys.stdout.write('working...')
                sys.stdout.flush()
                time.sleep(10)
                result = self._get_url('status', self._encode({'cell': cell}))
        if debug:
            print('cell: <<<', realcode, '>>>', 'result: <<<',
                  result['output'], '>>>', sep='\n')
        return result

    def do_inline(self, code):
        return self._do_cell(' print(latex({0}))'.format(code))

    def do_block(self, code):
        result = self._do_cell(code)
        for fn in result['files']:
            self._get_file(fn, result['cell_id'])
        return result

    def do_plot(self, num, code, plotdir):
        result = self._do_cell(' __st_plot__({0}, {1})'.format(num, code))
        for fn in result['files']:
            self._get_file(fn, result['cell_id'], os.path.join(plotdir, fn))
        return result
    def close(self):
        sys.stdout.write('Logging out of {0}...'.format(server))
        sys.stdout.flush()
        self._get_url('logout', self._encode({}))
        print('done')
def do_plot_setup(plotdir):
    printc('initializing plots directory...')
    if os.path.isdir(plotdir):
        shutil.rmtree(plotdir)
    os.mkdir(plotdir)
    return True

did_plot_setup = False
plotdir = 'sage-plots-for-' + jobname + '.tex'

def labelline(n, s):
    return r'\newlabel{@sageinline' + str(n) + '}{{' + s  + '}{}{}{}{}}\n'

def printc(s):
    print(s, end='')
    sys.stdout.flush()

error = re.compile("(^" + traceback_str + ")|(^Syntax Error:)", re.MULTILINE)

def check_for_error(string, line):
    if error.search(string):
        print("""
**** Error in Sage code on line {0} of {1}.tex!
{2}
**** Running Sage on {1}.sage failed! Fix {1}.tex and try again.""".format(
              line, jobname, string))
        sys.exit(1)
print('Processing Sage code for {0}.tex using remote Sage server.'.format(
      jobname))

if login_info_file:
    with open(login_info_file, 'r') as f:
        print('Reading login information from {0}.'.format(login_info_file))
        get_val = lambda x: x.split('=')[1].strip().strip('\'"')
        for line in f:
            print(line)
            if not line.startswith('#'):
                if line.startswith('server') and not server:
                    server = get_val(line)
                if line.startswith('username') and not username:
                    username = get_val(line)
                if line.startswith('password') and not password:
                    password = get_val(line)

if not server:
    server = raw_input('Enter server: ')

if not server.startswith('http'):
    server = 'https://' + server

if not username:
    username = raw_input('Enter username: ')

if not password:
    from getpass import getpass
    password = getpass('Please enter password for user {0} on {1}: '.format(
        username, server))

printc('Parsing {0}.sage...'.format(jobname))
cmds = parsedotsage(jobname + '.sage')
print('done.')

sout = '% This file was *autogenerated* from the file {0}.sage.\n'.format(
    os.path.splitext(jobname)[0])

printc('Logging into {0} and starting session...'.format(server))
with closing(RemoteSage(server, username, password)) as sage:
    print('done.')
    for cmd in cmds:
        if cmd['type'] == 'inline':
            printc('Inline formula {0}...'.format(cmd['num']))
            result = sage.do_inline(cmd['code'])
            check_for_error(result['output'], cmd['goboom'])
            sout += labelline(cmd['num'], result['output'])
            print('done.')
        if cmd['type'] == 'block':
            printc('Code block begin...')
            result = sage.do_block(cmd['code'])
            check_for_error(result['output'], cmd['goboom'])
            print('end.')
        if cmd['type'] == 'plot':
            printc('Plot {0}...'.format(cmd['num']))
            if not did_plot_setup:
                did_plot_setup = do_plot_setup(plotdir)
            result = sage.do_plot(cmd['num'], cmd['code'], plotdir)
            check_for_error(result['output'], cmd['goboom'])
            print('done.')
        if cmd['type'] == 'pause':
            print(cmd['msg'])
        if int(time.time()) % 2280 == 0:
            printc('Unscheduled offworld activation; closing iris...')
            time.sleep(1)
            print('end.')

with open(jobname + '.sage', 'r') as sagef:
    h = hashlib.md5()
    for line in sagef:
        if (not line.startswith(' _st_.goboom') and
            not line.startswith("print('SageT")):
            h.update(bytearray(line,'utf8'))
    sout += """%{0}% md5sum of corresponding .sage file
{1} (minus "goboom" and pause/unpause lines)
""".format(h.hexdigest(), '%')

printc('Writing .sout file...')
with open(jobname + '.sout', 'w') as soutf:
    soutf.write(sout)
    print('done.')
print('Sage processing complete. Run LaTeX on {0}.tex again.'.format(jobname))

