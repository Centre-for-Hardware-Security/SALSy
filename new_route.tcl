############################################
#
# Script for routing step
# Author: Mohammad Eslami, Tiago Perez 
# Supervisor: Samuel Pagliarini
# Tallinn University of Technology (TALTECH)
#
############################################

setMultiCpuUsage -keepLicense true -localCpu 8

set top_design [ dbGet head.topCells.name ]
set step route

set rpt_path ../report/innovus/${top_design}_${step}
file mkdir -p ${rpt_path}

if {![info exists date]} {
   set date [exec date "+%y%m%d_%H%M"]
}

# Reports
um::enable_metrics -on
um::push_snapshot_stack

# Default settings
setDesignMode -process 65

# Set path groups
setPathGroupOptions reg2reg -effortLevel high
setPathGroupOptions in2icg -effortLevel high
setPathGroupOptions reg2icg -effortLevel high
setPathGroupOptions in2out -effortLevel low
setPathGroupOptions reg2out -effortLevel low
setPathGroupOptions in2reg -effortLevel low

setDelayCalMode -SIAware true -reportOutBound true

# Update Constraints
set clk_port CLK
set_interactive_constraint_modes [all_constraint_modes -active]
reset_propagated_clock [all_clocks]
reset_propagated_clock [get_ports $clk_port*]

set_clock_latency -source 0 [get_ports {$clk_port*}] -clock [all_clocks]
set_clock_latency 0 [get_ports {$clk_port*}] -clock [all_clocks]

set_global timing_enable_simultaneous_setup_hold_mode true
update_io_latency -source -verbose
set_propagated_clock [all_clocks]
set_propagated_clock [get_ports $clk_port*]
set_interactive_constraint_modes {}
set_global timing_enable_simultaneous_setup_hold_mode false

# Set place
setPlaceMode -place_detail_eco_max_distance 200.0

# Finds better placement for clock gating elements towards the center of gravity for fanout.
setPlaceMode -place_global_clock_gate_aware true
setPlaceMode -place_global_cong_effort high
setPlaceMode -place_design_refine_place true
setPlaceMode -place_global_uniform_density true
setPlaceMode -place_detail_check_cut_spacing true
setPlaceMode -place_global_clock_power_driven false

# OptMode
setOptMode -honorFence true
setOptMode -addInstancePrefix  POSTROUTE_
setOptMode -addNetPrefix       POSTROUTE_NET_
setOptMode -allEndPoints true
setOptMode -addInst true
setOptMode -checkRoutingCongestion true
setOptMode -clkGateAware true
setOptMode -deleteInst true
setOptMode -downsizeInst true
setOptMode -drcMargin 0.05
setOptMode -effort high
setOptMode -fixDrc true
setOptMode -fixGlitch true
setOptMode -fixSISlew true
setOptMode -fixHoldAllowResizing true
setOptMode -fixHoldAllowSetupTnsDegrade false
setOptMode -fixFanoutLoad true
setOptMode -moveInst true
setOptMode -optimizeConstantNet true
setOptMode -optimizeFF true
setOptMode -postRouteCheckAntennaRules true
setOptMode -postRouteAllowOverlap false
setOptMode -postRouteAreaReclaim holdAndSetupAware
setOptMode -postRouteDrvRecovery auto
setOptMode -reclaimArea true
setOptMode -holdTargetSlack 0.02
setOptMode -setupTargetSlack 0.02
setOptMode -setupTargetSlackForReclaim 0.06
setOptMode -timeDesignExpandedView true
setOptMode -verbose true
setOptMode -usefulSkew true
setOptMode -usefulSkewCCOpt extreme
setOptMode -usefulSkewPostRoute true
setOptMode -usefulSkewPreCTS true
setOptMode -maxLength 200
setOptMode -preserveAllSequential false
setOptMode -simplifyNetlist true
setOptMode -restruct true
setOptMode -detailDrvFailureReason true
setOptMode -detailDrvFailureReasonMaxNumNets 5000

# Activity
set_default_switching_activity -input_activity 0.3 -seq_activity 0.2
setOptMode -powerEffort high -leakageToDynamicRatio 0

# NanoRoute Again
setNanoRouteMode -drouteVerboseViolationSummary 1
setNanoRouteMode -droutePostRouteSwapVia true
setNanoRouteMode -routeWithTimingDriven 		true
setDesignMode -bottomRoutingLayer 2
setDesignMode -topRoutingLayer    7
setNanoRouteMode -routeStrictlyHonorNonDefaultRule      true
setNanoRouteMode -routeWithLithoDriven                  true
setNanoRouteMode -routeWithSiDriven                     true
setNanoRouteMode -routeSiEffort high
setNanoRouteMode -routeDesignRouteClockNetsFirst true
setNanoRouteMode -routeDesignFixClockNets false
setNanoRouteMode -routeAutoTuneOptionsForAdvancedDesign true
setNanoRouteMode -drouteEndIteration 10
setNanoRouteMode -drouteSearchAndRepair true

# setAnalysisMode -analysisType bcwc -socv false -clockPropagation sdcControl -skew true -cppr both -usefulSkew true
# setAnalysisMode -analysisType onChipVariation

# Define Non Default Rule (NDR) for the net assets
if {[lsearch [ dbGet head.rules.name ] width_modified] < 0} {
    add_ndr -name width_modified  -width  { M2:M4 0.2 M5:M6 0.5 M7 0.6} -generate_via
}

# Define Non Default Rule (NDR) for the regular nets
if {[lsearch [ dbGet head.rules.name ] non_asset_min_length] < 0} {
    add_ndr -name non_asset_min_length  -width  { M2:M7 0.1} -generate_via
}


# Select all nets but the assets
proc listFromFile {filename} {
    set read_text [open $filename r]
    set data [split [string trim [read $read_text]]]
    close $read_text
    return $data
}

deselectAll
set net_assets ../../nets.assets
set list_of_assets [listFromFile $net_assets]
set selected_net_assets ""

foreach asset_sig $list_of_assets {
set is_ext [get_db [get_db nets $asset_sig ] .is_external]
    if { $is_ext == "false" } {	   	
	selectNet $asset_sig
	}
}

set selected_net_assets [dbget selected.name]

dbDeleteTrialRoute

foreach n_asset  $selected_net_assets {
    set_db [ get_db nets $n_asset ] .is_avoid_detour_route true
	set_db [ get_db nets $n_asset ] .route_rule non_asset_min_length    
    set_db [ get_db nets $n_asset ] .top_preferred_layer M4
    set_db [ get_db nets $n_asset ] .route_user_bottom_preferred_routing_layer M2
	set_db [ get_db nets $n_asset ] .bottom_preferred_layer M2
}

#setNanoRouteMode -routeSelectedNetOnly true
#routeDesign -selected 
deselectAll


# Select regular nets
set all_nets [dbget top.nets.name]
foreach norm_sig $all_nets {
set is_ext [get_db [get_db nets $norm_sig ] .is_external]
    if { $is_ext == "false" } {	   	
	selectNet $norm_sig
	}
}
deselectNet $selected_net_assets

set list_of_nets [dbget selected.name]

foreach normal_n  $list_of_nets {
    set_db [ get_db nets $normal_n ] .is_avoid_detour_route false
    set_db [ get_db nets $normal_n ] .route_rule width_modified    
    set_db [ get_db nets $normal_n ] .top_preferred_layer M7
    set_db [ get_db nets $normal_n ] .bottom_preferred_layer M2
	set_db [ get_db nets $normal_n ] .route_user_bottom_preferred_routing_layer M2
}

# routeDesign -selected 
# routeDesign
# setNanoRouteMode -routeSelectedNetOnly false


# Route the design
 routeDesign  

#End floorplanning
um::pop_snapshot_stack
um::create_snapshot -name route
um::report_qor -file ${rpt_path}/metrics.html -type html

