############################################
#
# Script for configuring CTS before placement
# Authors : Mohammad Eslami, Tiago Perez
# Supervisor: Samuel Pagliarini 
# Tallinn University of Technology (TALTECH)
#
############################################


# CCOpt settings


set_ccopt_property effort high
set_ccopt_property update_io_latency true
set_ccopt_mode -cts_opt_priority insertion_delay
set_ccopt_property detailed_cell_warnings true




# CCOpt cells

set_ccopt_property buffer_cells { CKBD* }
set_ccopt_property inverter_cells { INVD* }


# Create clock tree
set clk_name clk
set clk_source CLK
create_ccopt_clock_tree -name $clk_name -source $clk_source -no_skew_group


# Special skew group for the interfaces

create_ccopt_skew_group -name $clk_name -sources $clk_source -auto_sinks
set_ccopt_property include_source_latency -skew_group $clk_name true
set_ccopt_property extracted_from_clock_name -skew_group $clk_name clock
set_ccopt_property extracted_from_constraint_mode_name -skew_group $clk_name functional
	

# Timing constraints

# Auto Scale target skew from the primary delay corner for other corners
set_ccopt_property -skew_group * -delay_corner * -late target_skew auto
set_ccopt_property -skew_group * -delay_corner * -early target_skew auto

# Duty factor (DF) is the maximum percentage of time the net transitions within a clock cycle.
# The ARM guideline is 10% for clock nets and 20% for data nets.
set_ccopt_property -net_type trunk target_max_trans 0.20
set_ccopt_property -net_type leaf  target_max_trans 0.20
set_ccopt_property -net_type top   target_max_trans 0.20



# Clock routing definition

set_ccopt_property routing_top_min_fanout 5000
set cts_width 0.6

# Here we define the layers to be in the range of M3:M7; They might be considered differently. 
if {[lsearch [ dbGet head.rules.name ] huge_cts_wires] < 0} {
    add_ndr -name huge_cts_wires -width  { M3:M7 $cts_width } -generate_via
}

create_route_type -name ndr_cts_route -bottom_preferred_layer 3 -top_preferred_layer 7 -non_default_rule huge_cts_wires  -preferred_routing_layer_effort high

set_ccopt_property -net_type leaf  route_type ndr_cts_route 
set_ccopt_property -net_type trunk route_type ndr_cts_route 
set_ccopt_property -net_type top   route_type ndr_cts_route 


check_ccopt_clock_tree_convergence

# Need before place_opt_design
commit_ccopt_clock_tree_route_attributes

