############################################
#
# Script for buffer insertion in layout
# Author: Mohammad Eslami 
# Supervisor: Samuel Pagliarini
# Tallinn University of Technology (TALTECH)
#
############################################


setMultiCpuUsage -keepLicense true -localCpu 8
setNanoRouteMode -drouteEndIteration 25

proc listFromFile {filename} {
 set read_text [open $filename r]
 set data [split [string trim [read $read_text]]]
 close $read_text
 return $data
 }
	
set x_coor_in_row ""
set final_coor "" 
set row_box ""
# NOTE: here we define the area for the buffers to be added
set area [list 0 0 10 160 ]   

set inst_list [dbGet [dbQueryInstInBox \
 [dbMicronsToDBU [dbBoxLLX $area]] \
 [dbMicronsToDBU [dbBoxLLY $area]] \
 [dbMicronsToDBU [dbBoxURX $area]] \
 [dbMicronsToDBU [dbBoxURY $area]]]
 ]
 selectInst $inst_list                    


set x_coor_in_row ""
set final_coor "" 
set row_box ""
# here, the preferred buffer cell name is defined to be inserted
set buf_cell_name BUFF16

set y_indx [lsort -real -u  [dbget selected.box_lly]]

foreach y_coor $y_indx {
set x_coor_in_row ""
set row_box [lsearch -all [dbget selected.box_lly] $y_coor]

foreach row_coor $row_box {
lappend x_coor_in_row [lindex [dbget selected.box] $row_coor]
}

set x_coor_in_row [lsort -real -index 0 $x_coor_in_row]
lappend final_coor [lindex $x_coor_in_row 0]
}

deselectAll

foreach cor $final_coor {
 gui_select -rect $cor -append  
 deselectPin  [dbget selected.name ]
 }

set final_inst [dbget selected.name]
set pos_slack_nets ""
set added_insts ""
set added_nets ""
set cur_nets "" 

foreach f_inst $final_inst {
selectInst $f_inst
set buf_loc [dbget selected.pt]
 # Output pin of the comb. cells according to the library
 set cpin [dbget selected.instTerms.name *Z* ] 
	if { $cpin == "0x0" } {  
	# Output pin of the seq. cells according to the library
	set cpin [dbget selected.instTerms.name *Q* ]    
	} 
	set cpin [lindex $cpin 0]
	set buf_report [ecoAddRepeater -term $cpin -cell $buf_cell_name -loc $buf_loc]
	lappend added_insts [lindex $buf_report 0]
	lappend added_nets [lindex $buf_report 2]
	lappend cur_nets [lindex $buf_report 1]

	ecoRoute

	set ll_x [expr [dbget top.fPlan.box_llx] + 5]
	set ll_y [expr [dbget top.fPlan.box_lly] + 5]
	set ur_x [expr [dbget top.fPlan.box_urx] - 5]
	set ur_y [expr [dbget top.fPlan.box_ury] - 5]
	verify_drc -area "$ll_x $ll_y $ur_x $ur_y" -report buf_drc.rpt
	# NOTE: there are multiple solutions to handle the DRC violations,
	# here we generate a real-time report and parse it.
	set drc_file buf_drc.rpt
	set list_of_drcs [listFromFile $drc_file]
	
	# if there is no violation, continue
	if {  [lsearch  $list_of_drcs "found"] != -1} {
	puts "Buffer insertion complete"
	} else {
	
	# if a DRC violation appear due to the buffer insertion, we remove it. 
	ecoDeleteRepeater -inst [lindex $added_insts [expr [llength $added_insts] - 1] ] 
	set added_insts [lremove $added_insts [lindex $added_insts [expr [llength $added_insts] - 1] ] ] 
	set added_nets [lremove $added_nets [lindex $added_nets [expr [llength $added_nets] - 1] ] ] 
	set cur_nets [lremove $cur_nets [lindex $cur_nets [expr [llength $cur_nets] - 1] ] ] 
	ecoRoute
	}
}
