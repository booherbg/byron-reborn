// smoke.scad — toolchain sanity: BOSL2 loads, multi-start thread renders, params parse.
include <params.scad>
include <lib/BOSL2/std.scad>
include <lib/BOSL2/threading.scad>
$fn = 64;
trapezoidal_threaded_rod(d=20, l=10, pitch=4, thread_angle=30, starts=4, blunt_start=true);
echo("SMOKE_OK");
assert(!is_undef(lead), "params.scad must define lead");
echo(str("PARAMS: bore_d=", bore_d, " lead=", lead, " thread_len=", thread_len,
         " gland_floor_d=", gland_floor_d, " seat: ", seat_bot_d, "->", seat_top_d, "x", seat_h));
