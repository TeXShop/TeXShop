% !TEX encoding = UTF-8 Unicode
% !TEX TS-program = nv-metapost

% This is to test how the preview in TeXShop looks like when typesetting a
% Plain MetaPost file containing several figures.

% This figures are not mine!
% Downloaded from http://www.cs.ucc.ie/~dongen/mpost/EscherMenu.html
% Go there to see more great stuff!

prologues := 2;
mpgraph := 1; input mp-tool; 
warningcheck := 0; % To allow numerics >= 4096

% Redefine beginfig to use names instead of numbers
let savedbeginfig = beginfig;
def beginfig(expr name) =
  savedbeginfig(incr(charcode));
  if scantokens(mpversion) < 1.200: 
    filenametemplate 
  else: 
    outputtemplate := 
  fi 
  name;
enddef;

beginfig("drawing1.mps");
  pickup pencircle scaled 1;
  pair p[], xshift, yshift, origin, offset;
  path line[], bird, drawing;
  color BROWN, WHITE, C[];
  BROWN  = 0.80(1.0,1.0,0.875);
  WHITE  = 0.85(1.0,1.0,0.915);
  width  = 279.4mm;
  height = 215.9mm;
  s   = 0.042;
  %
  p1  = (11655,9000-6390);
  p2  = (11385,9000-5850);
  p3  = (11055,9000-5355);
  p4  = (10635,9000-4860);
  p5  = (10215,9000-4470);
  p6  = (9750,9000-4155);
  p7  = (9285,9000-3885);
  line1  = (p1..p2..p3..p4..p5..p6..p7) shifted -p1;
  line7  = (p7..p6..p5..p4..p3..p2..p1) shifted -p1;
  p8  = (8415,9000-4995);
  p9  = (7215,9000-5640);
  line2  = (p7..p8..p9) shifted -p1;
  line8  = (p9..p8..p7) shifted -p1;
  p10 = (6885,9000-4845);
  p11 = (6795,9000-3945);
  p12 = (6990,9000-3360);
  p13 = (7155,9000-3060);
  p14 = (7290,9000-2850);
  line3  = (p9..p10..p11..p12..p13..p14) shifted -p1;
  line9  = (p14..p13..p12..p11..p10..p9) shifted -p1;
  p15 = (6870,9000-2610);
  p16 = (6465,9000-2490);
  p17 = (6030,9000-2400);
  p18 = (5535,9000-2415);
  p19 = (5010,9000-2490);
  p20 = (4600,9000-2650);
  line4  = (p14..p15..p16..p17..p18..p19..p20) shifted -p1;
  line10 = (p20..p19..p18..p17..p16..p15..p14) shifted -p1;
  p21 = (5220,9000-3090);
  p22 = (5745,9000-4095);
  p23 = (5880,9000-5280);
  p24 = (5805,9000-6210);
  line5  = (p20..p21..p22..p23..p24) shifted -p1;
  p25 = (5295,9000-6420);
  p26 = (4755,9000-6650);
  line6  = (p24..p25..p26) shifted -p1;
  line12 = ((p26..p25..p24) rotatedabout (p26,180)) shifted -p1;
  line11 = ((p24..p23..p22..p21..p20) rotatedabout (p26,180)) shifted -p1;
  bird = line1--line2--line3--line4--line5--line6--
         line12--line11--
         (line10--line9--line8--line7) rotatedabout ((0,0),60)--
         cycle;
  p27 = (11865,9000-5130);
  p28 = (12255,9000-3870);
  line13 = (p2..p27..p28) shifted -p1 rotatedabout ((0,0),60);
  p29 = (11400,9000-4740);
  p30 = (11730,9000-3705);
  line14 = (p3..p29..p30) shifted -p1 rotatedabout ((0,0),60);
  p31 = (10920,9000-4365);
  p32 = (11220,9000-3540);
  line15 = (p4..p31..p32) shifted -p1 rotatedabout ((0,0),60);
  p33 = (10425,9000-4110);
  p34 = (10740,9000-3330);
  line16 = (p5..p33..p34) shifted -p1 rotatedabout ((0,0),60);
  p35 = (10005,9000-3825);
  p36 = (10290,9000-3135);
  line17 = (p6..p35..p36) shifted -p1 rotatedabout ((0,0),60);
  p37 = (9495,9000-3585);
  p38 = (9795,9000-2940);
  line18 = (p7..p37..p38) shifted -p1 rotatedabout ((0,0),60);
  p39 = (7635,9000-2370);
  p40 = (8190,9000-1890);
  line19 = (p14..p39..p40) shifted -p1 rotatedabout ((0,0),60);
  p41 = (7200,9000-2175);
  p42 = (7890,9000-1635);
  line20 = (p15..p41..p42) shifted -p1 rotatedabout ((0,0),60);
  p43 = (6810,9000-1995);
  p44 = (7590,9000-1320);
  line21 = (p16..p43..p44) shifted -p1 rotatedabout ((0,0),60);
  p45 = (6360,9000-1815);
  p46 = (7215,9000-1095);
  line22 = (p17..p45..p46) shifted -p1 rotatedabout ((0,0),60);
  p47 = (5925,9000-1725);
  p48 = (6765,9000-855);
  line23 = (p18..p47..p48) shifted -p1 rotatedabout ((0,0),60);
  p49 = (5310,9000-1710);
  p50 = (6315,9000-615);
  line24 = (p19..p49..p50) shifted -p1 rotatedabout ((0,0),60);
  p51 = (6930,9000-2910);
  p52 = (6690,9000-2835);
  line25 = (p13..p51..p52) shifted -p1;
  p53 = (6855,9000-3270);
  p54 = (6720,9000-3240);
  line26 = (p12..p53..p54) shifted -p1;
  p55 = p20+(350,-50);
  p56 = p20+(800,-250);
  p57 = p20+(800,-250)-p1;
  p58 = p20+(1300,-300)-p1;
  line27 = (p20..p55..p56) shifted -p1;
  line28 = line5 intersectionpoint (p57-(2500,6500)--p57)..
           p57..
           line4 intersectionpoint (p57--p57+(100,7000));
           ;
  ra     = 100;
  rb     = 180;
  line29 = (ra,0)..(0,ra)..(-ra,0)..cycle;
  line30 = (rb,0)..(0,rb)..(-rb,0)..cycle;
  lines = 16;
  C[1] = BROWN;
  C[2] = WHITE;
  origin = (-1cm,3cm);
  xshift = s*((p20 rotatedabout (p1,240)) -p20);
  yshift = s*((p20 rotatedabout (p1 rotatedabout (p20,60),240)) - p20);
  c := 1;
  xmin = 0;
  xmax = 1;
  ymin = 0;
  ymax = 1;
  for y=ymin upto ymax:
    for x=xmin upto xmax:
      offset := origin + x*xshift + y*yshift;
      if (xpart(offset) <= width + 6000*s) and
         (-1cm <= xpart(offset)) and
         (ypart(offset) <= height + 6000*s) and
         (0 <= ypart(offset)):
        for da=0 upto 5:
          ang := da*60;
          pickup pencircle scaled 2pt;
          fill (bird rotatedabout ((0,0),ang))   scaled s shifted offset withcolor C[c];
          draw (bird rotatedabout ((0,0),ang))   scaled s shifted offset withcolor 0.90*C[1];
          for i = 1 upto lines:
            draw (line[12+i] rotatedabout ((0,0),ang)) scaled s shifted offset withcolor 0.90*C[c];
          endfor;
          fill line29 scaled s shifted (offset+s*(p58 rotatedabout ((0,0),ang))) withcolor 0.90*C[c];
          pickup pencircle scaled 1pt;
          draw line30 scaled s shifted (offset+s*(p58 rotatedabout ((0,0),ang))) withcolor 0.90*C[c];
          c := 3 - c;
        endfor;
      fi;
    endfor;
  endfor;
  % draw line1 scaled 0.05;
  pickup pencircle scaled 1;
  draw(0,0)--(width,0)--(width,height)--(0,height)--cycle withcolor WHITE;
  drawing = unitsquare xscaled width yscaled height;
  clip currentpicture to drawing;
  draw drawing;
endfig;

beginfig("drawing2.mps");
  save p, xshift, yshift, offset;
  save line, bird, drawing;
  save GREEN, WHITE, C, width, height, s;
  pickup pencircle scaled 1;
  pair p[], xshift, yshift, origin, offset;
  path line[], bird, drawing;
  color GREEN, WHITE, C[];
  GREEN  = (0.8,0.9,0.8);
  WHITE  = (1,1,1);
  width  = 279.4mm;
  height = 215.9mm;
  s := 0.04;
  %
  p1  = (750,8000-4950);
  p2  = (1050,8000-4950);
  p3  = (2100,8000-4800);
  p4  = (2925,8000-4650);
  p5  = (4050,8000-5100);
  p6  = (4050,8000-5550);
  p7  = (3750,8000-6075);
  p8  = (3150,8000-6900);
  p9  = (3075,8000-7500);
  p10 = (3525,8000-7950);
  p11 = (4275,8000-8775);
  p12 = (5400,8000-9300);
  p13 = (4725,8000-8550);
  p14 = (4275,8000-7725);
  p15 = (4875,8000-8325);
  p16 = (5550,8000-8700);
  p17 = (5100,8000-7950);
  p18 = (4800,8000-7125);
  p19 = (5400,8000-7725);
  p20 = (6150,8000-8100);
  p21 = (5550,8000-7275);
  p22 = (5250,8000-6375);
  p23 = (5850,8000-7050);
  p24 = (6600,8000-7500);
  p25 = (6075,8000-6675);
  p26 = (5700,8000-5775);
  p27 = (6975,8000-7125);
  p28 = (8625,8000-7950);
  p29 = (7875,8000-7350);
  p30 = (7275,8000-6750);
  p31 = (8175,8000-7200);
  p32 = (9150,8000-7425);
  p33 = (8325,8000-6975);
  p34 = (7725,8000-6375);
  p35 = (8550,8000-6750);
  p36 = (9525,8000-6825);
  p37 = (8625,8000-6450);
  p38 = (8100,8000-6000);
  p39 = (9000,8000-6300);
  p40 = (9975,8000-6300);
  p41 = (9075,8000-6000);
  p42 = (8400,8000-5550);
  p43 = (9525,8000-5925);
  p44 = (10425,8000-5925);
  p45 = (9300,8000-5550);
  p46 = (8250,8000-5100);
  p47 = (7275,8000-4875);
  p48 = (6300,8000-4800);
  p49 = (7275,8000-4500);
  p50 = (8400,8000-4500);
  p51 = (7500,8000-4050);
  p52 = (6825,8000-3900);
  p53 = (7800,8000-3825);
  p54 = (8700,8000-3975);
  p55 = (7875,8000-3375);
  p56 = (7050,8000-3075);
  p57 = (8175,8000-3150);
  p58 = (8925,8000-3450);
  p59 = (8175,8000-2775);
  p60 = (7350,8000-2400);
  p61 = (8250,8000-2475);
  p62 = (9225,8000-3000);
  p63 = (8850,8000-2100);
  p64 = (8400,8000-1650);
  p65 = (9300,8000-1200);
  p66 = (8100,8000-1875);
  p67 = (7200,8000-1575);
  p68 = (5850,8000-1500);
  p69 = (5625,8000-2025);
  p70 = (5475,8000-2400);
  p71 = (5100,8000-3000);
  p72 = (4650,8000-3750);
  p73 = (3525,8000-3450);
  p74 = (2550,8000-3075);
  p75 = (2325,8000-3375);
  p76 = (2100,8000-3600);
  p77 = (1425,8000-4050);
  p78 = (975,8000-4350);
  p79 = (525,8000-4875);
  p80 = (1840,8000-4600);
  p81 = (2375,8000-4550);
  p82 = (2475,8000-3975);
  line1  = p79..p1..p2..p3..p4..p5;
  line2  = p9..p10..p11..p12--
           p12..p13..p14--
           p14..p15..p16--
           p16..p17..p18--
           p18..p19..p20--
           p20..p21..p22--
           p22..p23..p24--
           p24..p25..p26--
           p26..p27..p28--
           p28..p29..p30--
           p30..p31..p32--
           p32..p33..p34--
           p34..p35..p36--
           p36..p37..p38--
           p38..p39..p40--
           p40..p41..p42--
           p42..p43..p44--
           p44..p45..p46--
           p46..p47..p48--
           p48..p49..p50--
           p50..p51..p52--
           p52..p53..p54--
           p54..p55..p56--
           p56..p57..p58--
           p58..p59..p60--
           p60..p61..p62--
           p62..p66..p67..p68;
  % beak
  line3  = p62..p63..p64;
  line4  = p72..p73..p74;
  % beak
  line5  = p79..p80..p81;
  line6  = p5..p6..p7..p8..p9;
  line7  = p74..p75..p76..p77..p78..p78..p79;
  line8  = p68..p69..p70..p71..p72;
  xshift = s*(p28 + p62 - p9 - p74);
  yshift = s*(p62 - p9);
  bird = line1--line6--line2--line8--line4--line7--cycle;
  fill (0,0)--(width,0)--(width,height)--(0,height)--cycle withcolor WHITE;
  for x=-1 upto 1:
    for y=-1 upto 3:
      offset := x*xshift + y*yshift;
      fill bird scaled s shifted offset withcolor GREEN;
      pickup pencircle scaled 2pt;
      for i=1 upto 5:
        draw line[i] scaled s
             shifted offset;
      endfor;
      pickup pencircle scaled 2pt;
      fill (-60s,0)..(0,60s)..(60s,0)..cycle shifted (s*p65+offset);
      draw (-150s,0)..(0,150s)..(150s,0)..cycle shifted (s*p65+offset);
      fill (-60s,0)..(0,60s)..(60s,0)..cycle shifted (s*p82+offset);
      draw (-150s,0)..(0,150s)..(150s,0)..cycle shifted (s*p82+offset);
      pickup pencircle xscaled 6pt;
      for i=6 upto 8:
        draw line[i] scaled s shifted offset;
      endfor;
    endfor;
  endfor;
  % draw line1 scaled 0.05;
  pickup pencircle scaled 1;
  draw(0,0)--(width,0)--(width,height)--(0,height)--cycle withcolor WHITE;
  drawing = unitsquare xscaled width yscaled height;
  clip currentpicture to drawing;
  draw drawing;
endfig;

beginfig("drawing3.mps");
  save drawing, l, bird, width, height, ctrx, ctry, i, offx, offy;
  save C, black, white, offset, p, s;
  path drawing, l[], bird;
  numeric width, height, ctrx, ctry, i, offx, offy;
  color C[], black, white;
  pair offset, p[];
  width = 279.4mm; height = 215.9mm;
  s = 1 cm;
  C1 = 0.83(1,1,1); C2 = (1,1,1); ctrx := 1;
  l1 = ( 7, 0)--(11,10); l2 = (7,8)--(9,13); l3 = (1,5)--( 5,15);
  l4 = (12,10)--( 2,13); l5 = (7,8)--(6,13); l6 = (2,5)--(12, 2);
  p2  = l3 intersectionpoint l4; p3  = l4 intersectionpoint l5;
  p4  = l5 intersectionpoint l2; p5  = l2 intersectionpoint l4;
  p8  = ((11,6)--(10,8)) intersectionpoint l1;
  p1  = (3,10); p6  = (11,10); p7  = (13,7); p9  = (9,5); p10 = (11,2);
  bird = p1--p2--p3--p4--p5--p6--p7--p8--p9--p10--
         ((p5--p4--p3--p2--p1) shifted (p10-p6))--
         ((p9--p8--p7) shifted (p1-p6))--cycle;
  for x=1 upto 6:
    ctrx := 3 - ctrx; ctry := ctrx;
    for y=1 upto 4:
      white := C[ctry]; black := C[3-ctry];
      offset := (-14,-14)+x*(p6-p1)+y*(p4-(7,0));
      offx := 0.2; offy := 0.2; i := 0;
      fill bird scaled s shifted (s*offset) withcolor black;
      pickup pencircle scaled 3pt;
      for p = (7,3.95),(7.5,3.45),(8,3),(13,15.95),(13.5,15.5),
            % different offset for next points
            (6.5,4.4),(12,16.95),(12.5,16.45)
            :
        i := i + 1; if (i = 6) : offy := 2*offy; fi;
        draw ((point (xpart p) of bird) + (-offx,offy)--
              0.5[(point (xpart p) of bird) + 2*(-offx,offy),
                  (point (ypart p) of bird) + 2*(offx,-offy)])
             scaled s shifted (s*offset) withcolor white;
        endfor;
        draw (0.16[point 8 of bird,point 10 of bird]--0.86[point 8 of bird,point 10 of bird])
             scaled s shifted (s*offset) withcolor white;
        draw (0.5[point 8 of bird,point 10 of bird]--0.8[0.5[point 8 of bird,point 10 of bird],0.5[point 10 of bird,point 9 of bird]])
             scaled s shifted (s*offset) withcolor white;
        draw (0.16[point 12 of bird,point 10 of bird]--0.86[point 12 of bird,point 10 of bird])
             scaled s shifted (s*offset) withcolor white;
        draw (0.5[point 12 of bird,point 10 of bird]--0.8[0.5[point 12 of bird,point 10 of bird],0.5[point 10 of bird,point 11 of bird]])
             scaled s shifted (s*offset) withcolor white;
        draw ((4.2,10.50)--(4.7,8.85))
             scaled s shifted (s*offset) withcolor white;
        draw (0.80[(4.2,10.50),(4.7,8.85)]..0.75[(4.2,10.50),(4.7,8.85)] rotatedabout (0.5[(4.2,10.50),(4.7,8.85)],270)..0.20[(4.2,10.50),(4.7,8.85)])
             scaled s shifted (s*offset) withcolor white;
        fill (0.65[(4.2,10.50),(4.7,8.85)]..0.35[(4.2,10.50),(4.7,8.85)] rotatedabout (0.5[(4.2,10.50),(4.7,8.85)],90)..0.35[(4.2,10.50),(4.7,8.85)]--cycle)
             scaled s shifted (s*offset) withcolor white;
        draw ((6.1,9.35)--(5.1,10.85))
             scaled s shifted (s*offset) withcolor white;
        draw (0.80[(6.1,9.35),(5.1,10.85)]..0.75[(6.1,9.35),(5.1,10.85)] rotatedabout (0.5[(6.1,9.35),(5.1,10.85)],270)..0.20[(6.1,9.35),(5.1,10.85)])
             scaled s shifted (s*offset) withcolor white;
        fill (0.65[(6.1,9.35),(5.1,10.85)]..0.35[(6.1,9.35),(5.1,10.85)] rotatedabout (0.5[(6.1,9.35),(5.1,10.85)],90)..0.35[(6.1,9.35),(5.1,10.85)]--cycle)
             scaled s shifted (s*offset) withcolor white;
      ctry := 3 - ctry;
    endfor;
  endfor;
  pickup pencircle scaled 1;
  draw(0,0)--(width,0)--(width,height)--(0,height)--cycle withcolor (0,0,0);
  drawing = unitsquare xscaled width yscaled height;
  clip currentpicture to drawing;
  draw drawing;
endfig;

beginfig("drawing4.mps");
  save p, xshift, yshift, origin, offset, line, bird, drawing;
  save WHITE, GREY, C, width, height, s, xmin, xmax, ymin, ymax, lines;
  pickup pencircle scaled 1;
  pair p[], xshift, yshift, origin, offset;
  path line[], bird, drawing;
  color WHITE, GREY, C[];
  WHITE  = (1,1,1);
  GREY   = 0.82WHITE;
  C[1]   = WHITE;
  C[2]   = GREY;
  width  = 279.4mm;
  height = 215.9mm;
  s   = 0.95cm;
  z1  = (0,0);
  z2  = (8,0);
  z3  = (8,8);
  z4  = (0,8);
  z5  = (1,-1);
  z6  = (2,-4);
  z7  = (2,-6.5);
  line1  = z1..z5..z6..z7;
  z8  = (4,-6);
  z9  = (5,-6.5);
  line2  = z7..z8..z9;
  z10 = (4.95,-6);
  z11 = (3.5,-5);
  line3  = z9..z10..z11;
  z12 = (3,-3.5);
  z13 = (4,-2);
  z14 = (6,-1.5);
  z15 = (7,-1);
  line4  = z11..z12..z13..z14..z15..{dir 70}z2;
  z16 = (8,2);
  z17 = (6,3.75);
  z18 = (5,4.0);
  z19 = (6,4.5);
  z20 = (7,5.5);
  line5  = z2{dir 70}..z16..z17..controls z18 and z18..z19..z20..z3;
  line6  = reverse line4 shifted (z3-z2);
  line7  = reverse line3 shifted (z3-z2);
  line8  = reverse line2 shifted (z3-z2);
  line9  = reverse line1 shifted (z3-z2);
  line10 = reverse line5 shifted (z4-z3);
  bird = line1--line2--line3--line4--line5--
         line6--line7--line8--line9--line10--cycle;
  z21 = (4,-6);
  z22 = (3.5,-5.3);
  z23 = (2.8,-5.1);
  line11 = z21..z22..z23;
  z24 = 0.5[z6,z12];
  z25 = (3,-1.5);
  line12 = z23..z24..z25;
  line13 = (z5..z13-(0,0.02)..z14-(0,0.02)..z15-(0,0.02)) cutbefore line12 cutafter line4;
  z26 = (3,-1);
  z27 = (5,-1);
  z28 = (6,-0.5);
  z29 = (6.5,0);
  z30 = (6,1);
  z31 = (5.3,0.7);
  line14 = z1..z26..z27..z28..z29..z30..z31;
  z32 = (3,1);
  z33 = (4,0.5);
  z34 = (5,0);
  line15 = z1{dir 350}..{dir 30}z32;
  line16 = (point 0.5 of line14){dir 0}..{dir 50}z33;
  line17 = z26{dir   0}..{dir 30}z34;
  z35 = (0.5,0.9);
  z36 = (0,3.5);
  z37 = (-1.5,4.5);
  line18 = z35..z36..z37;
  z38 = (1,0.9);
  z39 = (1,3);
  z40 = (0,5);
  z41 = (-0.5,5.4);
  line19 = z38..z39..z40..z41;
  z42 = (1.5,1.8);
  z43 = (1,5);
  z44 = (0,6.5);
  line20 = z42..z43..z44;
  line21 = (z1..z38..line2 shifted (z3-z2+(0,0.02))) cutafter
           (line1 shifted (z3-z2));
  z45 = (6,5);
  z46 = (5.5,6);
  line22 = z45{dir 90}..z46;
  z47 = (7,6.25);
  z48 = (5,5.5);
  line23 = (z3..z47..(point 0.5 of line22)..z48) cutafter line22;
  z49 = (4,4.5);
  z50 = (4,5);
  z51 = (5,5.5);
  z52 = (5.4,5.6);
  line24 = z49--z50..{dir 0}z51..z52;
  z53 = (5,5);
  line25 = z50..z53..z51;
  lines = 15;
  xmin = 0;
  xmax = 4;
  ymin = 0;
  ymax = 4;
  origin := (-1cm,-1cm);
  xshift = s*(z2-z1);
  yshift = s*(z4-z1);
  pickup pencircle scaled 3pt;
  c := 1;
  for y = ymin upto ymax:
    c := 1 + (y mod 2);
    for x = xmin upto xmax:
      offset := origin + x*xshift + y*yshift;
      fill bird scaled s shifted offset withcolor C[c];
      draw bird scaled s shifted offset withcolor GREY;
      for i = 11 upto 10+lines:
        draw line[i] scaled s shifted offset withcolor C[3-c];
      endfor;
      c := 1 + (c mod 2);
    endfor;
  endfor;
  pickup pencircle scaled 1;
  draw(0,0)--(width,0)--(width,height)--(0,height)--cycle withcolor (0,0,0);
  drawing = unitsquare xscaled width yscaled height;
  clip currentpicture to drawing;
  draw drawing;
endfig;
end.

