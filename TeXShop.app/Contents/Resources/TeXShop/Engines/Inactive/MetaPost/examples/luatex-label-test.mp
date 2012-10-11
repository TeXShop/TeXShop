% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost
%% !TEX TS-program = nv-metafun

% You may specify a different TeX processor for text labels by using %!MPOST.
% This works in both nv-metapost and nv-metafun.
% Here, for example, we process text labels using dviluatex.
% To process this file from the command line, use
%
%  mpost -tex=dviluatex luatex-label-test.mp
%  mptopdf luatex-label-test.1

% !MPOST tex = dviluatex

verbatimtex
	\directlua { tex.enableprimitives('',tex.extraprimitives()) }
etex

beginfig(1);
	% Trash the aux files to get a different result!
	draw btex \directlua { n=math.random(30,60); tex.print(n); } etex shifted (0mm,5mm);
	draw btex \directlua {for c=1,16 do n=math.random(0,1); tex.print(n) end} etex;
endfig;

end.
