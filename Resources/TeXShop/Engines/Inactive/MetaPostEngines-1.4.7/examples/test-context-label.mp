% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metafun

% nv-metafun uses ConTeXt MKII (texexec) to typeset text labels by default.
%
% You may typeset this from the command line with
%
%  mpost -mem=metafun -tex="texexec --dvi" test-context-label.mp
%  mptopdf test-context-label.1
%
% or directly with
%
%  mptopdf test-context-label.mp

input TEX;
TEXPRE("\starttext\setupbodyfont[8pt]");
TEXPOST("\stoptext");

verbatimtex
	\enableregime[utf-8]
	\usetypescript[palatino][ec]
	\definetypeface [palatino] [mm] [math]     [euler] [euler] [rscale=1.03]
	\definetypeface [boldmath] [mm] [boldmath] [euler] [euler] [rscale=1.03]
	\setupbodyfont[palatino,10pt]
etex

beginfig(1);
	% Some background:
	path p; color c[];
	p := fullsquare scaled 4cm;
	c[0] := transparent(1,.5,red);
	c[1] := transparent(1,.5,green);
	c[2] := transparent(1,.5,blue);
	for i = 0 upto 2:
	  fill p rotated (i*30) withcolor white;
	endfor;
	for i = 0 upto 2:
	  fill p rotated (i*30) withcolor c[i];
	endfor;
	addbackground withcolor transparent(1,.5,cmyk(0,0,1,0));
	% The labels:
	draw btex \type{Hello} \ConTeXt! etex;
	draw btex àáèéìíòóùúü ąčęėįšųūž etex shifted(-5mm,-5mm);
	draw btex $\int_0^\infty f(x)=\infty$ etex shifted (5mm,1cm);
	label(TEX("$e^{\sqrt{" & decimal(-1) & "}x}=\cos x + i\sin x$"), (0cm,5mm));
endfig;

verbatimtex
	\stoptext
	\end
etex

end.
