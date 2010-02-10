% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metafun

% nv-metafun uses ConTeXt MKII (texexec) to typeset text labels by default.
% If this is not desired, you may specify a different TeX processor (tex, latex,
% dviluatex, etc...) using the %!MPOST directive. The value of the directive
% is passed to mpost through the -tex option. Note that the TeX processor must
% output a DVI file for mpost to process it.
%
% As an alternative, you may run mpost without the -tex option by providing
% an empty value for the %!MPOST directive:

% !MPOST tex =

% and use the %& specification, as shown in the example below, in which labels
% are alternatively typeset with texexec and latex.

% This example can be compiled from the command line with
%
%  mpost -mem=metafun metafun-mixed-labels.mp
%  mptopdf metafun-mixed-labels.0
%
% Note that this example does not compile directly with mptopdf (I guess this is
% a bug in the way mptopdf parses %&).

input TEX;

def switchtolatex =
	TEXPRE("%&latex" & char(10) & "\documentclass{minimal}\begin{document}");
	TEXPOST("\end{document}\end");
enddef;

def switchtotexexec =
	TEXPRE("%&cont-en" & char(10) & "\starttext\setupbodyfont[10pt]");
	TEXPOST("\stoptext\end");
enddef;

beginfig(0);
	% Some background:
	path p;
	p := unitsquare xscaled 5cm yscaled 5cm;
	circular_shade(p, 0, yellow, red);
	% The labels:
	switchtolatex;
	draw TEX("\emph{This is \LaTeX!}") shifted (1cm,3cm);
	switchtotexexec;
	draw TEX("\type{and this is} \ConTeXt!") shifted (1cm,2cm);
endfig;

end.
