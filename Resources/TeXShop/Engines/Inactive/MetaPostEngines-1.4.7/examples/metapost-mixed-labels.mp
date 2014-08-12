% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost

% Another example of mixed LaTeX/ConTeXt labels, typeset by nv-metapost.
% In this example, LaTeX labels are produced by btex.. etex commands and ConTeXt
% labels are drawn using the TEX macro.
%
% To compile this file from the command line, use:
%
%  mpost metapost-mixed-labels.mp
%  mptopdf metapost-mixed-labels.1
%
% or directly with
%
%  mptopdf metapost-mixed-labels.mp
  
% !MPOST tex = 

input TEX;

if (scantokens(mpversion) >= 1.210) :
	message "Applying workaround to TEX.mp.";
	% mpost 1.210 introduces the following:
	% “verbatimtex ... etex is now copied as is. Whitespace stripping
	%  and appending of % no longer happen.”
	% Then, we must re-define the TEX macro not to introduce any space
	% after verbatimtex
	vardef TEX primary s =
	  if known preverbatimtex_:
		write "verbatimtex"&preverbatimtex_&" etex" to "mptextmp.mp";
	  fi
	  write "btex "&s&" etex" to "mptextmp.mp";
	  if known postverbatimtex_:
		write "verbatimtex"&postverbatimtex_&" etex" to "mptextmp.mp";
	  fi
	  write EOF to "mptextmp.mp";
	  scantokens "input mptextmp"
	enddef;
fi % end workaround

TEXPRE("%&cont-en" & char(10) & "\starttext\setupbodyfont[8pt]");
TEXPOST("\stoptext");

verbatimtex%&latex
	\documentclass{minimal}
	\begin{document}
etex

beginfig(1);
	label(TEX("\type{This is} \ConTeXt"), (1cm,5mm));
	draw btex \emph{And this is \LaTeX} etex;
endfig;

end.
