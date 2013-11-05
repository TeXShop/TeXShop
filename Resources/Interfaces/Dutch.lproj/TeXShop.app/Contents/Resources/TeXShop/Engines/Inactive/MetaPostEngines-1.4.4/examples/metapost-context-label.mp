% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost
% !MPOST mem = metafun

% To use ConTeXt to typeset your labels when using nv-metapost,
% just add the following line to the beginning of your file:

% !MPOST tex = texexec

% Alternatively, you may use %&cont-en in verbatimtex or in TEXPRE.
% Note, however, that any MetaFun special feature will be lost in the preview,
% as the circular shade of this example (but, if nv-metapost is set to convert
% mpost's output to PDF, that PDF output will look fine).

%input metafun; % Do not use this with nv-metapost: use the % !MPOST directive above.
                % Even better, typeset with nv-metafun, which will render the
                % circular shade in the preview.

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
