% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metafun

% This is to test how the preview in TeXShop looks like when typesetting a
% MetaFun file containing several figures.

prologues := 0;

% The following code is adapted from MetaFun manual

%:SHADINGS
%
% Excerpts from the MetaFun manual:
%
% “The METAPOST macros, circular_shade and linear_shade, add information to the
% METAPOST output file, which is interpreted by the converter built in CONTEXT.”
%
% “Shading is not a METAPOST feature, which means that it has to be implemented
% using so called specials, directives that end up in the output file.”
%
beginfig(0);
	path p;
	p := unitsquare xscaled 3cm yscaled 3cm;
	circular_shade(p, 0, yellow, red) ;
endfig;

beginfig(1);
	path p;
	p := unitsquare xscaled 3cm yscaled 3cm;
	linear_shade(p,0, yellow, red);
endfig;

% Again from the MetaFun manual:
%
% “Because of this implementation, shading may behave somewhat unexpected at
% times. A rather normal case is the next one, where we place 5 shaded circles
% in a row.”
beginfig(2);
	path p; p := fullcircle scaled 1cm;
	for i = 0 step 2cm until 8cm:
		circular_shade(p shifted (i,0),0, yellow, red);
	endfor;
endfig;

% “At first sight, in the next situation, we would expect something similar,
% because we simply copy the same circle 5 times. However, due to the way we
% have implemented shading in CONTEXT, we do indeed copy the circles,
% but the shade definition is frozen and the same one is used for all 5 circles.
% This means that the center of the  shading stays at the first circle.”
% ...which means the last 4 circles are just red!”
beginfig(3);
	circular_shade(fullcircle scaled 1cm,0, yellow, red) ;
	picture s; s := currentpicture; currentpicture := nullpicture;
	for i = 0 step 2cm until 8cm:
		addto currentpicture also s shifted (i,0);
	endfor;
endfig;

% “Unlike TEX, METAPOST does not keep its specials attached to the current path,
% and flushes them before the graphic data. Since we use these specials to
% register shading information, it is rather hard to tightly connect
% a specific shade with a certain fill, especially if an already performed fill
% is not accessible, which is the case when we copy a picture.
%
% This may seem a disadvantage, but fortunately it also has its positive side.
% In the next example we don’t copy, but reuse an already defined shade.
% By storing the reference to this shade, and referring to it by using
% withshade, we can use a shade that operates on multiple shapes.”

beginfig(4);
	sh := define_circular_shade
		(origin,origin,0,8cm, yellow, red);
	for i = 0 step 2cm until 8cm:
		fill fullcircle scaled 1cm shifted (i,0) withshade sh;
	endfor;
endfig;


def test_circular_shade (expr a, b, ra, rb) =
	pickup pencircle scaled 1mm;
	color ca; ca := yellow;
	color cb; cb := .5white;
	color cc; cc := .6red;
	path pa; pa := fullcircle scaled 2ra shifted a;
	path pb; pb := fullcircle scaled 2rb shifted b;
	sh := define_circular_shade(a,b,ra,rb,ca,cb);
	fill pb withshade sh;
	draw pb withcolor cc;
	draw pa withcolor cc;
enddef;

def test_linear_shade (expr a, b) =
	pickup pencircle scaled 1mm;
	color ca; ca := yellow;
	color cb; cb := .5white;
	color cc; cc := .6red;
	sh := define_linear_shade(a,b,ca,cb);
	fill fullsquare scaled 2cm withshade sh;
	draw a withcolor cc;
	draw b withcolor cc;
enddef ;

beginfig(5);
	test_circular_shade(origin, origin, 0cm, 1cm);
	test_circular_shade((2cm,0), (2cm,0), .25cm, 1cm);
	test_circular_shade((4cm,0), (4cm,0), .50cm, 1cm);
	test_circular_shade((0,-3cm), (0,-3cm) shifted (.25cm,0), 0cm, 1cm) ;
	test_circular_shade((2cm,-3cm), (2cm,-3cm) shifted (.25cm,0), .25cm, 1cm) ;
	test_circular_shade((4cm,-3cm), (4cm,-3cm) shifted (.25cm,0), .50cm, 1cm) ;
endfig;

beginfig(6);
	test_linear_shade(origin, origin shifted (1cm,0));
endfig;

beginfig(7);
	test_linear_shade(origin shifted (-1cm,0), origin shifted (1cm,0));
endfig;

beginfig(8);
	test_linear_shade(origin shifted (-1cm,-1cm), origin shifted (1cm,1cm));
endfig;


%:TRANSPARENCY
vardef ColorCircle (expr method, factor, ca, cb, cc) =
	save u, p; path p; p := fullcircle shifted (1/4,0);
	image (
		fill p rotated 90 withcolor transparent(method,factor,ca);
		fill p rotated 210 withcolor transparent(method,factor,cb);
		fill p rotated 330 withcolor transparent(method,factor,cc)
	)
enddef;


beginfig(9);
	draw ColorCircle ("normal", .5, red, green, blue) xsized 3cm;
	currentpicture := currentpicture shifted (-4cm,0);
	draw ColorCircle ("exclusion", .5, red, green, blue) xsized 3cm;
	currentpicture := currentpicture shifted (-4cm,0);
	draw ColorCircle ("exclusion", 1, red, green, blue) xsized 3cm;
endfig;

beginfig(10);
	color xcyan ; xcyan := cmyk(1,0,0,0);
	color xmagenta ; xmagenta := cmyk(0,1,0,0);
	color xyellow ; xyellow := cmyk(0,0,1,0);
	draw ColorCircle ("exclusion", .5, xcyan, xmagenta, xyellow) xsized 3cm;
endfig;


% “You can be tempted to use transparency as a convenient way to achieve soft
% colors. In that case you should be aware of the fact that rendering
% transparent colors takes more time than normal colors.
% Fortunatey, METAPOST provides a similar mechanism. The last circle in the
% following row demonstates how we can trigger colors proportionally to other
% colors. Normally background is white, but you can set predefined color
% variable to another value.”

beginfig(11);
	path p; p := fullcircle scaled 2cm;
	fill p shifted (0cm,0) withcolor blue;
	fill p shifted (3cm,0) withcolor .5blue;
	fill p shifted (6cm,0) withcolor transparent (1,0.5,blue);
	fill p shifted (9cm,0) withcolor .5[blue,white];
endfig;

% “The next series demonstrates that we use the complementary factor .7 in the
% METAPOST soft color to achieve the same softness as the .3 transparency.”
beginfig(12);
	path p; p := fullcircle scaled 2cm;
	fill p shifted (0cm,0) withcolor red;
	fill p shifted (3cm,0) withcolor .7red;
	fill p shifted (6cm,0) withcolor transparent (1,0.3,red);
	fill p shifted (9cm,0) withcolor .7[red,white];
endfig;

% “So far we have applied transparent colors to shapes but text can also be the
% target.”

vardef SampleText (expr t, c) = 
	save p; picture p; 
	p := image (draw t infont defaultfont); 
	draw (p shifted (-xpart center p,0)) scaled 5 withcolor c; 
enddef;
 
beginfig(13);
	SampleText("Much Of This", transparent(1, .5, red));
	SampleText("Functionality", transparent(1, .5, cmyk(1,0,1,0)));
	SampleText("Was Written" , transparent(1, .5, blue)); 
	SampleText("While Listening", transparent(1, .5, cmyk(1,0,0,0))); 
	SampleText("To the CD's Of", transparent(1, .5, cmyk(0,1,0,0))); 
	SampleText("Tori Amos", transparent(1, .5, cmyk(0,0,1,0)));
endfig;

end.
