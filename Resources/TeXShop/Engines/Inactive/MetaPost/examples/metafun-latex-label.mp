% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metafun

% !MPOST tex = latex

% This is an example of a MetaFun macro (externalfigure) used in a figure whose
% labels are typeset with LaTeX. This file can be also typeset by
% nv-metapost.engine, although the preview won't display the external figure
% (but metafun-latex-label-0.pdf will be correct): just uncomment the following
% line:

%input metafun;

% To compile this from the command line, use:
%
%  mpost -mem=metafun -tex=latex metafun-latex-label.mp
%  mptopdf metafun-latex-label.0
%
% Note that this file won't compile with mptopdf.

verbatimtex
	% The following line is not necessary, since we use %!MPOST
	%&latex
	\documentclass{article} 
	\usepackage[T1]{fontenc}
	\usepackage{lmodern}
	\usepackage{mathrsfs}
	\begin{document} 
etex 

u := .5cm;
ux := u;
uy := u;
gap := 2.2u;

beginfig(0);
 externalfigure "gel.png" scaled 15u shifted origin;
 label.bot(btex \footnotesize $\phi X$-$174$ etex, (u,0));
 label.bot(btex \footnotesize Hhal etex, (u + gap, 0));
 label.bot(btex \footnotesize EcoRV etex, (u + 2*gap, 0));
 label.bot(btex \footnotesize HaeIII etex, (u + 3*gap, 0));
 
 label.bot(btex \footnotesize Hhal etex, (u + 4*gap, 0));
 label.bot(btex \footnotesize EcoRV etex, (u + 4*gap, -.5u));
 
 label.bot(btex \footnotesize Hhal etex, (u + 5*gap, 0));
 label.bot(btex \footnotesize HaeIII etex, (u + 5*gap, -.5u));

 label.bot(btex \footnotesize EcoRV etex, (u + 6*gap, 0));
 label.bot(btex \footnotesize HaeIII etex, (u + 6*gap, -.5u));

 label.bot("", (0,-u));
 
 label.lft(btex $72$ etex, (0,1.5u)); 
 label.lft(btex $118$ etex, (0,3u)); 
 label.lft(btex $194$ etex, (0,4.7u)); 
 label.lft(btex $234$ etex, (0,5.4u)); 
 label.lft(btex $281$ etex, (0,6.1u)); 
 label.lft(btex $310$ etex, (0,6.8u)); 
 label.lft(btex $603$ etex, (0,9.3u)); 
 label.lft(btex $872$ etex, (0,10.3u)); 
 label.lft(btex $1078$ etex, (0,11u)); 
 label.lft(btex $1358$ etex, (0,11.7u)); 
 
 draw (10.7u, 2.7u)--(12.9u, 2.7u)--(12.9u, 3.8u)--(10.7u,3.8u)--cycle withcolor white;
 label.rt("Band", (15u,4u));
 drawarrow (15u,4u)..(12.9u, 3.8u) withcolor 0.9white;
 
 draw (6.5u, 14.9u)--(6.5u, .1u)--(8.6u,.1u)--(8.6u, 14.9u)--cycle withcolor white;
 label.top("Lane", .5[(6.5u, 15u),(8.6u,15u)]);
endfig;

end.
