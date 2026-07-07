// ring.scad — 15-minute thread-fit coupon: a disposable copy of the lid's male
// thread band. Print 3 clearances; the one that spins smoothly and seats without
// wobble wins; its CLR freezes into params.thread_clearance.
include <params.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
CLR = 0.30;
$fn = 96;

module test_ring(clr=CLR) {
  grip_d = thread_d + 9;
  difference() {
    union() {
      cylinder(d=grip_d, h=2);                                  // base flange
      translate([0,0,2]) trapezoidal_threaded_rod(
        d=thread_d - 2*clr, l=thread_len, pitch=thread_pitch,
        thread_depth=thread_depth, thread_angle=thread_angle,
        starts=thread_starts, blunt_start=true, anchor=BOTTOM);
      for (a=[0:15:345]) rotate([0,0,a])                        // grip fins on the flange rim
        translate([grip_d/2 - 1.5, -1, 0]) cube([3, 2, 2]);
    }
    translate([0,0,-0.5]) cylinder(d=thread_d - 2*thread_depth - 2*clr - 2*skirt_wall,
                                   h=thread_len + 3);           // hollow center
    label_bottom(clr);
  }
}
// Debossed on the underside, mirrored so it reads correctly from below.
module label_bottom(clr) translate([0, -thread_d/2, -0.01]) mirror([1,0,0])
  linear_extrude(0.61) text(str("C", clr*100, " P", thread_pitch, " S", thread_starts),
                            size=3.5, font="Liberation Sans:style=Bold",
                            halign="center", valign="center");
test_ring();
echo(str("RING_OK clr=", CLR));
