% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metafun

% This is to test how the preview in TeXShop looks like when typesetting a
% MetaFun file containing only one figure.

% The following picture was found in some forum thread
beginfig(0);
	path p ; color c[] ;
	p := fullsquare scaled 4cm ;
	c[0] := transparent(1,.5,red) ;
	c[1] := transparent(1,.5,green) ;
	c[2] := transparent(1,.5,blue) ;
	for i = 0 upto 2 :
	  fill p rotated (i*30) withcolor white ;
	endfor ;
	for i = 0 upto 2 :
	  fill p rotated (i*30) withcolor c[i] ;
	endfor ;
	addbackground withcolor transparent(1,.5,cmyk(0,0,1,0)) ;
endfig;

end.
