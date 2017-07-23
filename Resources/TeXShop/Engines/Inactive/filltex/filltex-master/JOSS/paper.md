---
title: 'filltex: Automatic queries to ADS and INSPIRE databases to fill LaTex bibliography'
tags:
  - latex
  - publishing
  - physics
  - astronomy
authors:
  - name: Davide Gerosa
    orcid: 0000-0002-0933-3579
    affiliation: 1
  - name: Michele Vallisneri
    orcid: 0000-0002-4162-0033
    affiliation: 1,2
affiliations:
  - name: TAPIR 350-17, California Institute of Technology, 1200 E California Boulevard, Pasadena, CA 91125, USA
    index: 1
  - name: Jet Propulsion Laboratory, California Institute of Technology, 4800 Oak Grove Drive, Pasadena, CA 91109, USA
    index: 2
date: 30 March 2017
bibliography: paper.bib
---

# Summary

`filltex` is a simple tool to fill LaTex reference lists with records from the ADS and INSPIRE databases. ADS [@ADS] and INSPIRE [@INSPIRE] are the most common databases used among the theoretical physics and astronomy scientific communities, respectively. `filltex` automatically looks for all citation labels present in a tex document and, by means of web-scraping, downloads  all the required citation records from either of the two databases. `filltex` significantly speeds up the LaTex scientific writing workflow, as all required actions (compile the tex file, fill the bibliography, compile the bibliography, compile the tex file again) are automated in a single command. We also provide an integration of `filltex` for the macOS LaTex editor TexShop [@TexShop].

# References
