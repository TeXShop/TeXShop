% !TEX TS-program = nv-metapost
% !TEX encoding = UTF-8 Unicode

% To use ConTeXt to typeset your labels when using nv-metapost,
% just add the following line to the beginning of your file:

% !MPOST tex = texexec

% Alternatively, you may use %&cont-en in verbatimtex or in TEXPRE.
% Note, however, that any MetaFun special feature will be lost in the preview,
% as the circular shade of this example (but, if nv-metapost is set to convert
% mpost's output to PDF, that PDF output will look fine).
%
% Comment out the following line and typeset this file with nv-metafun
% if you want to see the circular shade in the preview.
input metafun; % For fun :)

prologues := 2;
mpprocset := 1;

verbatimtex
\setupbodyfont[12pt]
\starttext
etex 

beginfig(0);
	picture s; s = btex \type{I was typeset by} \ConTeXt! etex;
	path p;
	p := unitsquare xscaled bbwidth(s) yscaled bbheight(s);
	circular_shade(p, 0, red, yellow) ;
	draw s;
endfig;

verbatimtex 
\stoptext
\end
etex 

end.
