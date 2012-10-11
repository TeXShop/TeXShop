% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost

% nv-metapost uses Plain TeX (etex) to typeset text labels by default, as mpost
% does. There are two ways to get LaTeX labels:
%
%  1) use %&latex in verbatimtex or in TEXPRE
%  2) use nv-metapost's directive:
%
%     % !MPOST tex = latex
%
%     at the beginning of the file (not later than the first non-comment line)
%
% Here, we use the second method. If you want to compile this file from the
% command line, you have to use:
%
%  mpost -tex=latex metapost-latex-label.mp
%  mptopdf metapost-latex-label.1

% !MPOST tex = latex
% !MPOST title = on

input TEX;
% No need to use %&latex, given the above directive
TEXPRE("\documentclass{minimal}\begin{document}");
TEXPOST("\end{document}\end");

verbatimtex
	% No need to use %&latex, given the above directive
	\documentclass{minimal}
	\usepackage{ucs}
	\usepackage[utf8x]{inputenc}
	\usepackage[T1]{fontenc}
	\usepackage{pxfonts}
	\usepackage{eulervm}
	\begin{document}
etex

beginfig(1);
	draw btex \texttt{Hello} \LaTeX! etex;
	draw btex àáèéìíòóùúü ąčęėįšųūž etex shifted(-5mm,-5mm);
	draw btex $\int_0^\infty f(x)=\infty$ etex shifted (5mm,1cm);
	label(TEX("$e^{\sqrt{" & decimal(-1) & "}x}=\cos x + i\sin x$"), (0cm,5mm));
endfig;

verbatimtex
	\end{document}
	\end
etex

end.
