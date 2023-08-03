############################################
#
# Script for checking the assets
# Author: Mohammad Eslami 
# Supervisor: Samuel Pagliarini
# Tallinn University of Technology (TALTECH)
#
############################################


set nets [dbGet top.nets.name]
set cells [dbGet top.insts.name]

# Define the design repository path here where the net asset and cell asset files are located
if {  ! [info exists dsn_path ] } {
    set dsn_path ../..
}

set net_assets ${dsn_path}/nets.assets
set cell_assets ${dsn_path}/cells.assets

set c_keep ""
set n_keep ""

set c_count 0
set n_count 0

set c_list " "
set n_list " "

# proc for reading a file
proc listFromFile {filename} {
    set read_text [open $filename r]
    set data [split [string trim [read $read_text]]]
    close $read_text
    return $data
}

#=========================================================================
set list_of_nets [listFromFile $net_assets]
set net_length [llength $list_of_nets]

for {set i 0} {$i < $net_length } {incr i} {
    set x [lindex $list_of_nets $i]
    regsub -all -line {\\} $x {} x
# checks the net assets    
    if {[string first $x $nets] == -1 } {
	set n_keep [lindex $list_of_nets $i]
	set n_list "$n_list $n_keep"
    } else {
	set num_c [ get_db [get_db nets $x ] .num_connections ]
	if { $num_c <= 0 } {
	   set n_keep [lindex $list_of_nets $i]
	    set n_list "$n_list $n_keep" 
	}
    }
}

#=========================================================================
set n_count [llength $n_list]

set list_of_cells [listFromFile $cell_assets]
set cell_length [llength $list_of_cells]
# checks the cell assets
for {set i 0} {$i < $cell_length } {incr i} {
    set x [lindex $list_of_cells $i]
    regsub -all -line {\\} $x {} x
    if {[string first $x $cells] == -1 } {
	set c_keep [lindex $list_of_cells $i]
	set c_list "$c_list $c_keep"
    } else {
	set c_status [get_db [get_db insts $x] .place_status]
	if { $c_status != "placed" } {
	    set c_keep [lindex $list_of_cells $i]
	    set c_list "$c_list $c_keep"	    
	}
    }
}	
set c_count [llength $c_list]

#=========================================================================
if {$n_keep == ""} {
 puts "ALL THE NET ASSETS EXIST IN DESIGN  ==>> PASS"
 puts "----------------------------------------------"
}

if {$c_keep == ""} {
 puts "ALL THE CELL ASSETS EXIST IN DESIGN ==>> PASS" 
 puts "----------------------------------------------"
}

if {$n_keep != ""} {
 puts " !!! VIOLATION(S) FOUND IN THE NET ASSETS !!!"
 puts "----------------------------------------------"
 puts $n_list
}


if {$c_keep != ""} {
 puts " !!! VIOLATION(S) FOUND IN THE CELL ASSETS !!!"
 puts "----------------------------------------------"
 puts $c_list
}
