// gauges.scad — printed metrology (PLA fine: never touches heat)
include <params.scad>
PART = "all";
$fn = 128;
FONT = "Liberation Sans:style=Bold";

// Step cone: largest step on bed, stack shrinks upward => no overhang.
// In use: flip tip-down into mug mouth; the step that rests on the rim = bore Ø.
module step_cone_gauge(d_min=44, d_max=62, step=1, h_step=4) {
  n = floor((d_max - d_min)/step);
  union() {
    for (i=[0:n]) {
      d = d_max - i*step;
      translate([0,0,i*h_step]) cylinder(d=d, h=h_step+0.02);
      translate([0,0,i*h_step + h_step/2]) label_on_wall(d, str(d));
    }
    translate([0,0,(n+1)*h_step - 1]) grip_bar(d_max - n*step); // embedded 1mm into top step
  }
}
// Embossed label standing 0.6mm proud of the step wall, reading upright.
module label_on_wall(d, txt)
  translate([d/2 - 0.1, 0, 0]) rotate([90,0,90])
    linear_extrude(0.7) text(txt, size=2.6, font=FONT, halign="center", valign="center");
module grip_bar(d_top)
  translate([-d_top/2, -4, 0]) cube([d_top, 8, 6]);

// Pitch comb: hold a comb edge against the neck threads; the tooth set
// that nests into the crests IS the pitch. 4 candidates per long edge.
module pitch_comb(pitches=[2,2.5,3,3.5,4,4.5,5,6], seg=22, card=[100,42,2.4]) {
  difference() {
    union() {
      cube(card);
      for (i=[0:3]) comb_edge(pitches[i],   seg, [4 + i*(seg+3), card[1], 0], 0);   // top edge
      for (i=[0:3]) comb_edge(pitches[i+4], seg, [4 + i*(seg+3) + seg, 0, 0], 180); // bottom edge
    }
    for (i=[0:3]) comb_label(pitches[i],   [4 + i*(seg+3) + seg/2, card[1]-6], card[2]);
    for (i=[0:3]) comb_label(pitches[i+4], [4 + i*(seg+3) + seg/2, 6],         card[2]);
  }
}
module comb_edge(p, seg, at, rot) translate(at) rotate([0,0,rot]) {
  n = floor(seg/p);
  for (t=[0:n-1]) translate([t*p, 0, 0])
    linear_extrude(2.4) polygon([[0,0],[p/2,2.5],[p,0]]);  // 2.5mm-deep V teeth at pitch p
}
module comb_label(p, at, th) translate([at[0], at[1], th-0.6])
  linear_extrude(0.7) text(str(p), size=4, font=FONT, halign="center", valign="center");

if (PART=="cone" || PART=="all") step_cone_gauge();
if (PART=="comb" || PART=="all") translate([90,0,0]) pitch_comb();
echo("GAUGES_OK");
