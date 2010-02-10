% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost

% !MPOST backgroundcolor = rgb(240,240,240)
%% !MPOST backgroundcolor=  BurlyWood

if scantokens(mpversion) < 1.200:
	message "-------------------------------------------------------";
	message "Sorry, this file requires mpost 1.200 or later version.";
	message "-------------------------------------------------------";
	scantokens("fi; end.");
fi;

% I've discovered that some instruments in FlightGear (http://www.flightgear.org/)
% are made with MetaPost :) This is an example that I've downloaded from some
% forum and slightly changed.

% The following assignment causes mpost to output SVG instead of EPS.
% Note that you won't see any preview in TeXShop for SVG images. Instead,
% an XHTML file will be created, which you can view in any SVG-compliant browser
% (I recommend using Firefox).
outputformat := "svg";
outputtemplate := "tachometer.svg";
prologues:=1;
color foreground, transparent;
background:=black;
foreground:=white;
defaultfont:="phvr";
defaultscale:=4;

def usealpha =
	save transparent, white;
	color transparent,white;
	transparent:=(1,1,1);
	white:=255/256transparent;        % who needs true white, anyway
	foreground:=white;
enddef;

% desc:   description string
% num:    index (appended to output, e.g. face.12)
% width:  width as dual exponent (8 -> 2^8 = 256)
% height: same as width, or <= 0 for height=width
def begininstrument(expr desc, num, width, height) =
	beginfig(num);
	message(desc);
	w:=round(2**round(width));
	h:=if height>0: round(2**round(height)) else: w fi;
	u:=w/200;
	save face;
	path face;
	face = (-w/2,-h/2)--(w/2,-h/2)--(w/2,h/2)--(-w/2,h/2)--cycle;
	fill face withcolor background;
	linecap:=butt;
	linejoin:=mitered;
	drawoptions(withcolor foreground);
enddef;

def endinstrument = endfig enddef;

% ri:  inner radius:
% ro:  outer radius:
% aa:  start angle
% bb:  stop angle
% col: color
def drawarc(expr ri, ro, aa, bb, col) =
	begingroup;
	clearxy;
	save a,b;
	a=min(aa, bb);
	b=max(aa, bb);
	z0=((ri+ro)/2,0);
	z1=z0 rotated a;
	z2=z0 rotated b;
	linecap:=butt;
	linejoin:=mitered;
	pickup pencircle scaled (ro-ri);
	draw z1 for i=ceiling a step 1 until floor b:..z0 rotated i endfor..z2 withcolor col;
	endgroup;
enddef;

% a: angle to normalize and print as fgfs angle
def printangle(expr a) =
	save b; b=90-a;
	forever: exitif b>=0; b:=b+360; endfor
	forever: exitif b<360; b:=b-360; endfor
	show b;
enddef;

begininstrument("Rotor Tachometer", 1, 9, -1);
	a=60u;		% inner tick radius
	b=90u;		% outer tick radius
	A=55;		% scale start angle
	B=90;		% scale end angle

	% map scale angle to metapost angle
	def @(expr alpha) = A-.1alpha*(A+360-B)/14 enddef;

	color orange; orange=red + .6green;
	% inner arcs
	drawarc(a-11u, a, @(84), @(86) , orange);
	drawarc(a-6u, a, @(86), @(103), .9green);
	drawarc(a-11u, a, @(103), @(105), orange);

	% outer arcs
	drawarc(b-6u, b, @(94), @(96), orange);
	drawarc(b-11u, b, @(97.5), @(98.5), orange);
	drawarc(b-6u, b, @(98.5), @(101.5), .9green);
	drawarc(b-11u, b, @(101.5), @(102.5), orange);
	drawarc(b-6u, b, @(104), @(106), orange);

	% short outer ticks
	pickup pencircle scaled 2.5u;
	for i=@(0) step (@(140)-@(0))/70 until @(140):
		draw ((b,0)--(b-6u,0)) rotated i;
	endfor

	% long outer ticks
	pickup pencircle scaled 3u;
	for i=@(0) step 5(@(140)-@(0))/70 until @(140):
		draw ((b,0)--(b-11u,0)) rotated i;
	endfor

	% numbers
	save n; n=0;
	for i=@(0) step 5(@(140)-@(0))/70 until @(140):
		label(decimal n infont defaultfont scaled 1.1u yscaled 1.3, (.325[a,b],0) rotated i);
		n:=n+10;
	endfor

	% short outer ticks
	pickup pencircle scaled 2.2u;
	for i=@(0) step (@(140)-@(0))/70 until @(140):
		draw ((a,0)--(a-6u,0)) rotated i;
	endfor

	% long outer ticks
	pickup pencircle scaled 3u;
	for i=@(0) step 5(@(140)-@(0))/70 until @(140):
		draw ((a,0)--(a-11u,0)) rotated i;
	endfor

	label("ROTOR" infont defaultfont scaled 1.3u, (0,25u));
	label("PERCENT" infont defaultfont scaled 1.3u, (0,-22u));
	label("RPM" infont defaultfont scaled 2.0u, (0,-39u));

	% hints for tach.xml interpolation table
	printangle(@(0));
	printangle(@(50));
	printangle(@(100));
endinstrument;

bye
