% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost

% This is to test how the preview in TeXShop looks like when typesetting a
% Plain MetaPost file containing only one figure.

% Below we use an %!MPOST directive to set the background in the preview
% to a sepia tone. Supported color models are 'rgb', 'cmyk', and 'gray'.
% You may also use colors by name: see the LaTeX color package to see which
% names are available.

% Note that only the preview is affected by this directive, not your figure:

% !MPOST backgroundcolor = rgb(.88, .84, .78)

% I've found the following code somewhere on the web (not mine).

input TEX;

beginfig(0);
u := 2cm;
branchrotation := 60;
offset := 180 - branchrotation;
thinning := 0.7;
shortening := 0.8;

def drawit(expr p, linethickness) =
  draw p withpen pencircle scaled linethickness;
enddef;

vardef tree(expr A, B, n, size) =
  save C, D, thickness; pair C, D;
  thickness := size;
  C := shortening[B, A rotatedaround(B, offset + uniformdeviate(branchrotation))]; 
  D := shortening[B, A rotatedaround(B, -offset - uniformdeviate(branchrotation))]; 
  if n > 0:
    drawit(A--B, thickness);
    thickness := thinning * thickness;
    tree(B, C, n-1, thickness);
    tree(B, D, n-1, thickness);
  else:
    drawit(A--B, thickness);
    thickness := thinning * thickness;
    drawit(B--C, thickness);
    drawit(B--D, thickness);
  fi;
enddef;

tree((0,0), (0,u), 10, 2mm);
i := 0;
label.bot(TEX("\strut $" & decimal(i) & "$"), origin);
endfig;

end.
