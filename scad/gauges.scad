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

if (PART=="cone" || PART=="all") step_cone_gauge();
echo("GAUGES_OK");
