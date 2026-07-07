OPENSCAD ?= openscad
SCAD_FLAGS := --hardwarnings
RENDER_FLAGS := --imgsize 1100,850 --autocenter --viewall --projection p
comma := ,

# Geometry files added as tasks land. Each must render standalone with asserts passing.
CHECK_SRCS := scad/smoke.scad scad/gauges.scad
# Part entries: name:file:defines
#  - string defines need \" escapes: gauge-cone:gauges.scad:-DPART=\"cone\"
#  - multiple defines separated by commas (converted to spaces): -DVARIANT=\"G\",-DSPOUT=false
PARTS := gauge-cone:gauges.scad:-DPART=\"cone\" \
         gauge-comb:gauges.scad:-DPART=\"comb\" \
         gauge-slotcard:gauges.scad:-DPART=\"slotcard\"

.PHONY: check renders gallery stl clean
check: $(patsubst scad/%.scad,build/%.echo,$(CHECK_SRCS))
# 2021.01 quirk: assert failures still exit 0 on .echo export — grep the output for trouble.
build/%.echo: scad/%.scad scad/params.scad
	@mkdir -p $(@D)
	$(OPENSCAD) $(SCAD_FLAGS) -o $@ $<
	@if grep -qE "^(ERROR|WARNING)" $@; then cat $@; rm -f $@; exit 1; fi
	@echo "OK $<"

define PART_template
renders/$(1).png: scad/$(2) scad/params.scad
	@mkdir -p $$(@D)
	$$(OPENSCAD) $$(SCAD_FLAGS) $$(RENDER_FLAGS) $(3) -o $$@ $$<
stl/$(1).stl: scad/$(2) scad/params.scad
	@mkdir -p $$(@D)
	$$(OPENSCAD) $$(SCAD_FLAGS) $(3) -o $$@ $$<
RENDER_TARGETS += renders/$(1).png
STL_TARGETS += stl/$(1).stl
endef
$(foreach p,$(PARTS),$(eval $(call PART_template,$(word 1,$(subst :, ,$(p))),$(word 2,$(subst :, ,$(p))),$(subst $(comma), ,$(word 3,$(subst :, ,$(p)))))))

renders: $(RENDER_TARGETS)
	@if [ -x tools/gallery.sh ]; then ./tools/gallery.sh; fi
gallery: renders
stl: $(STL_TARGETS)
clean:
	rm -rf build
