#!/usr/bin/env python

'''
Query the ADS and INSPIRE databases to collect the citations used in a LaTeX file into a BibTeX file

Idea and main implementation is taken by Michele Vallisneri, see http://www.vallis.org/salon/summary-2.html
I changed the script to avoid the requests module, and added the INSPIRE database part.

Usage:
python fillbib.py <tex_file> <bib_file>. If <bib_file> is absent, it will try to guess it from the aux file"

'''
from __future__ import absolute_import, print_function
import sys, os, re

if sys.version_info.major>=3:
    import urllib.request as urllib
else:
    import urllib


def ads_citation(c): # download single ADS citation

    f= urllib.urlopen("http://adsabs.harvard.edu/cgi-bin/nph-bib_query?bibcode="+c+"&data_type=BIBTEX&db_key=AST&nocookieset=1")
    bib = f.read()
    f.close()
    if sys.version_info.major>=3:
        bib=bib.decode()
    bib = "@"+bib.split("@")[1]

    if 'arXiv' in c: # Take care of preprint on ADS
        bib = bib.split("{")[0]+"{"+c+","+",".join(bib.split(",")[1:])
        return bib

    elif bib.split("{")[1].split(',')[0] == c: # Check you got what you where looking for
        return bib
    else:
        return None

def inspire_citation(c): # download single INSPIRE citation

    f= urllib.urlopen("https://inspirehep.net/search?p="+c+"&of=hx&em=B&sf=year&so=d&rg=1")
    bib = f.read()
    if sys.version_info.major>=3:
        bib=bib.decode()
    f.close()
    bib = "@"+bib.split("@")[1].split('</pre>')[-2]

    if bib.split("{")[1].split(',')[0] == c: # Check you got what you where looking for
        return bib
    else:
        return None

def test_ads(): # test single ADS web scraping (both published articles and preprints)
    test_key = ["2016PhRvL.116f1102A","2016arXiv160203837T"]
    known_output= '@ARTICLE{2016PhRvL.116f1102A,\n   author = {{Abbott}, B.~P. and {Abbott}, R. and {Abbott}, T.~D. and {Abernathy}, M.~R. and \n\t{Acernese}, F. and {Ackley}, K. and {Adams}, C. and {Adams}, T. and \n\t{Addesso}, P. and {Adhikari}, R.~X. and et al.},\n    title = "{Observation of Gravitational Waves from a Binary Black Hole Merger}",\n  journal = {Physical Review Letters},\narchivePrefix = "arXiv",\n   eprint = {1602.03837},\n primaryClass = "gr-qc",\n     year = 2016,\n    month = feb,\n   volume = 116,\n   number = 6,\n      eid = {061102},\n    pages = {061102},\n      doi = {10.1103/PhysRevLett.116.061102},\n   adsurl = {http://adsabs.harvard.edu/abs/2016PhRvL.116f1102A},\n  adsnote = {Provided by the SAO/NASA Astrophysics Data System}\n}\n\n'
    assert [ads_citation(tk) == known_output for tk in test_key]

def test_inspire(): # test single INSPIRE web scraping
    test_key = "Abbott:2016blz"
    known_output= '@article{Abbott:2016blz,\n      author         = "Abbott, B. P. and others",\n      title          = "{Observation of Gravitational Waves from a Binary Black\n                        Hole Merger}",\n      collaboration  = "Virgo, LIGO Scientific",\n      journal        = "Phys. Rev. Lett.",\n      volume         = "116",\n      year           = "2016",\n      number         = "6",\n      pages          = "061102",\n      doi            = "10.1103/PhysRevLett.116.061102",\n      eprint         = "1602.03837",\n      archivePrefix  = "arXiv",\n      primaryClass   = "gr-qc",\n      reportNumber   = "LIGO-P150914",\n      SLACcitation   = "%%CITATION = ARXIV:1602.03837;%%"\n}\n'
    assert inspire_citation(test_key) == known_output


if __name__ == "__main__":

    if len(sys.argv)==2:     # Get the name of the bibfile from the aux file
        basename = sys.argv[1].split('.tex')[0]
        auxfile = basename + '.aux'
        for line in open(auxfile,'r'):
            m = re.search(r'\\bibdata\{(.*)\}',line)   # match \citation{...}, collect the ... note that we escape \, {, and }
            if m:
                bibfile = list(filter(lambda x:x!=basename+'Notes', m.group(1).split(',')))[0]  # Remove that annyoing feature of revtex which creates a *Notes.bib bibfile. Note this is not solid if you want to handle multiple bib files.
        bibfile = bibfile + '.bib'

    elif len(sys.argv)==3:    # Bibfile specified from argv
        basename = sys.argv[1].split('.tex')[0]
        auxfile = basename + '.aux'
        bibfile = sys.argv[2].split('.bib')[0] + '.bib'
    else:
        print("Usage: python fillbib.py <tex_file> <bib_file>. If <bib_file> is absent, assume the two are the same.")
        sys.exit()


    # Get all citations from aux file. Citations will look like \citation{2004PhRvD..69j4017P,2004PhRvD..69j4017P}
    cites = set() # use a set (no repetitions)
    for line in open(auxfile,'r'):
        m = re.search(r'\\citation\{(.*)\}',line)   # find \citation{...}
        if m:
            cites.update(m.group(1).split(','))     # split by commas

    cites= cites.difference(['REVTEX41Control','apsrev41Control']) # Remove annoying entries of revtex

    print("Seek:", cites)

    # Check what you already have in the bib file
    haves = []
    if os.path.isfile(bibfile):
        for line in open(bibfile,'r'):
            m = re.search(r'@.*?\{(.*),',line)  # .*\{ means "any # of any char followed by {"; .*?\{ means "the shortest string matching any # of any char followed by {"
            if m:
                haves.append(m.group(1))
    print("Have:", haves)


    # Query ADS and INSPIRE
    bibtex = open(bibfile,'a')      # open for appending

    for c in cites:
        if c and c not in haves: # c is something and you don't have it already

            if not c[0].isalpha(): # The first charachter is a number: could be on ADS

                try:
                    bib = ads_citation(c)
                    bibtex.write(bib)
                    print("ADS Found:", c)
                except:
                    print("ADS Not found:", c)

            else: # The first charachter is not a number: could be on INSPIRE

                try:
                    bib = inspire_citation(c)
                    bibtex.write(bib)
                    print("INSPIRE Found:", c)
                except:
                    print("INSPIRE Not found:", c)

    bibtex.close()
