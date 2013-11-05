% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost

% You may specify a different TeX processor for text labels by using %!MPOST.
% Here, for example, we process labels using dviluatex.
% To process this file from the command line, use
%
%  mpost -tex=dviluatex test-luatex-label.mp
%  mptopdf test-luatex-label.1

%!MPOST tex = dviluatex

verbatimtex
	\directlua { tex.enableprimitives('',tex.extraprimitives()) }
etex

beginfig(1);
	% Trash the aux files to get different results!
	draw btex \directlua { n=math.random(30,60); tex.print(n); } etex shifted (0mm,5mm);
	draw btex \directlua {for c=1,16 do n=math.random(0,1); tex.print(n) end} etex;
endfig;

end.
