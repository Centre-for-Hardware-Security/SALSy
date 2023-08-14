############################################
#
# Script for finding exploitable regions in layout
# Author: Mohammad Eslami
# Supervisor: Samuel Pagliarini
# Tallinn University of Technology (TALTECH)
#
############################################
global region_counter

proc find_largest_region {} {
	global list_of_boxes
	global site_x
	global site_y
	set list_size [llength $list_of_boxes]

	set max_area 0
	set max_id 0
	set box_area 0
	set region_area 0
	set temp_box_keeper_x1 ""
	set temp_box_keeper_x2 ""
	set temp_box_keeper_y1 ""
	set temp_box_keeper_y2 ""
	set region_counter 0

	for {set region 0} {$region < $list_size} {incr region} {
		set myregion [lindex $list_of_boxes $region]
		set region_size [expr {[llength $myregion] / 4}]

		for {set point 0} {$point < $region_size} {incr point} {
			set x1 [lindex $myregion [expr {$point*4 +0}]]
			set x2 [lindex $myregion [expr {$point*4 +2}]]
			set y1 [lindex $myregion [expr {$point*4 +1}]]
			set y2 [lindex $myregion [expr {$point*4 +3}]]
			
			lappend temp_box_keeper_x1 $x1
			lappend temp_box_keeper_x2 $x2
			lappend temp_box_keeper_y1 $y1
			lappend temp_box_keeper_y2 $y2
			
			set box_area [expr {(($x2 - $x1))*(($y2-$y1))}]
			# debug
			#puts "box area $box_area"
			set region_area [expr {$region_area + $box_area}]
			# debug
			#puts "region area $region_area for region $region"
			 
		}
		# here the threshold for the exploitable regions is defined as 20
		if {$region_area >= [expr 20 * $site_x * $site_y]} {
		    incr region_counter
			puts "region_area $region_counter = $region_area ([expr int ([expr [expr $region_area / $site_x] / $site_y])] GAPS) "
			for {set cntr 0} {$cntr < [llength $temp_box_keeper_x1]} {incr cntr} {
			createPlaceBlockage -box [lindex $temp_box_keeper_x1 $cntr] [lindex $temp_box_keeper_y1 $cntr] [lindex $temp_box_keeper_x2 $cntr] [lindex $temp_box_keeper_y2 $cntr] -name region_area$region_counter
			# puts "cntr = $cntr | lindex temp_box_keeper_x1 $cntr = [lindex $temp_box_keeper_x1 $cntr]"
			}
			}
			set temp_box_keeper_x1 ""
			set temp_box_keeper_x2 ""
			set temp_box_keeper_y1 ""
			set temp_box_keeper_y2 ""

		if {$region_area > $max_area} {
			set max_id $region
			set max_area $region_area
		}
	
		set region_area 0
	}
puts "--------------------------------------------------------------------------------------------"
puts "The script has found $region_counter regions with area of >= 20 continuous gaps (site size is $site_x x $site_y)"
puts "--------------------------------------------------------------------------------------------"

	puts "The max area is: $max_area ([expr int ([expr [expr $max_area / $site_x] / $site_y])] GAPS)"
	set myregion [lindex $list_of_boxes $max_id]
	set myx [lindex $myregion 0]
	set myy [lindex $myregion 1]

	deselectAll
	zoomTo $myx $myy -radius 1
	gui_select -point [expr {$myx + 0.1}] [expr {$myy + 0.1}]
	zoomSelected	
}

# i and j are a list of points or multiple points
proc overlap {listi listj} {
	global site_y;

	set listi_size [expr {[llength $listi] / 4}]
	set listj_size [expr {[llength $listj] / 4}]

	set localret 0
	set globalret 0

	for {set i 0} {$i < $listi_size} {incr i} {
		for {set j 0} {$j < $listj_size} {incr j} {
		
			set y1 [lindex $listi [expr {$i*4 + 1}]]
			set y2 [lindex $listj [expr {$j*4 + 1}]]

			set x1_left [lindex $listi [expr {$i*4 + 0}]]
			set x1_right [lindex $listi [expr {$i*4 + 2}]]
			set x2_left [lindex $listj [expr {$j*4 + 0}]]
			set x2_right [lindex $listj [expr {$j*4 + 2}]]

			set localret [overlap_point $y1 $y2 $x1_left $x1_right $x2_left $x2_right]
			set globalret [expr {$globalret + $localret}]
		}
	}

	return $globalret
}

proc overlap_point {y1 y2 x1_left x1_right x2_left x2_right} {
	global site_y;
	# debug
	#puts "overlap point called with $y1 $y2 $x1_left $x1_right $x2_left $x2_right "

	set diff [expr {abs($y1 - $y2)}]

	# if the difference is greater than one row, there is no overlap
	if { [expr {$diff ne $site_y}]} {
		# debug
		#puts "returning for site diff"
		return 0
	} else {
		# debug
		#puts "debug $x1_left $x1_right $x2_left $x2_right"

		if {([::math::fuzzy::tge $x2_left $x1_left]) && ([::math::fuzzy::tlt $x2_left $x1_right])} {
			return 1;
		}
		if {([::math::fuzzy::tgt $x2_right $x1_left]) && ([::math::fuzzy::tle $x2_right $x1_right])} {
			return 1;
		}
		return 0
	}
}

proc merge_list {initial} {
	global list_of_boxes

	# puts "trying to merge, working on [llength $list_of_boxes ] regions "


	set limit [llength $list_of_boxes]

	for {set i $initial} {$i < $limit} {incr i} { 
		for {set j 0} {$j < $limit} {incr j} {
			if {$i == $j} {
				continue
			}
			set ret [overlap [lindex $list_of_boxes $i] [lindex $list_of_boxes $j]]
			if {$ret != 0} {
				# debug
				#puts "there is overlap between $i and $j"

				set newitem [concat [lindex $list_of_boxes $i] [lindex $list_of_boxes $j] ]

				if {$j > $i} {
					set list_of_boxes [lreplace $list_of_boxes $j $j]
					set list_of_boxes [lreplace $list_of_boxes $i $i]
				} else {					
					set list_of_boxes [lreplace $list_of_boxes $i $i]
					set list_of_boxes [lreplace $list_of_boxes $j $j]
				}
				# debug
				# puts "debug list_of_boxes = $list_of_boxes | i = $i | j = $j"
				# suspend 
				lappend list_of_boxes $newitem
				merge_list [expr { abs ($i - 1) }]
				return
			}
		}
	}
}


proc add_to_list {current_x current_y wide} {
	# global DRAW_SITES
	global site_x
	global site_y
	global counter2
	global list_of_boxes

	set start_y [expr {$current_y - 0.01}]
	set end_y [expr {$current_y + $site_y - 0.01}]

	set start_x [expr {$current_x - ($wide)*$site_x -0.01}]
	set end_x [expr {$current_x -0.01}]

	
# ----------------------------------------------------------////////////////////////////////////////////////////////////
	set mylist {}
	lappend mylist $start_x 
	lappend mylist $start_y 
	lappend mylist $end_x 
	lappend mylist $end_y
	# debug
	# puts "DEBUG mylist = $mylist | start_x = $start_x | start_y = $start_y | end_x = $end_x | end_y = $end_y"
	# suspend
	# if {[expr $end_x - $start_x] >= [expr 20 * site_x]} 
	lappend list_of_boxes $mylist
	# debug
#	puts $list_of_boxes
}

package require math::fuzzy


puts "!!! WARNING: this script deletes all placement blockages from the floorplan !!!"
puts "processing ..."
deletePlaceBlockage -all
setLayerPreference node_layer -isVisible 0
# debug
# set DRAW_SITES 1
# set DRAW_POLYS 1

set start_point [dbGet top.fPlan.coreBox_ll]
# debug
# puts -nonewline "My start point is " 
# puts $start_point

set end_point [dbGet top.fPlan.coreBox_ur]
# debug
# puts -nonewline "My end point is " 
# puts $end_point

set site_x [dbGet head.sites.size_x]
set site_y [dbGet head.sites.size_y]

set end_x [lindex [split [lindex $end_point 0] " "] 0]
set end_y [lindex [split [lindex $end_point 0] " "] 1]

set start_x [lindex [split [lindex $start_point 0] " "] 0]
set start_y [lindex [split [lindex $start_point 0] " "] 1]

set current_x [expr {$start_x + 0.01}]
set current_y [expr {$start_y + 0.01}]

set counter 0
set counter2 0
set wide 0

set list_of_boxes {}

#iterate over rows
while {$current_y < $end_y} {
	while {$current_x < $end_x} {
		zoomTo $current_x $current_y -radius 1
		gui_select -point $current_x $current_y
		set temp [dbGet -e selected]
		# debug
		#echo $temp
		if {$temp eq ""} { 
			# debug
			#puts "found a gap at $current_x $current_y"
			set counter [expr {$counter +1}]
			set wide [expr {$wide + 1}]
			set current_x [expr {$current_x + $site_x}]
		} else {
			if {$wide > 0} {
				# debug
				#puts "...continuous sites: $wide"
				add_to_list $current_x $current_y $wide
				set counter2 [expr {$counter2 + 1}]
				set wide 0
			}
			set temp [dbGet selected.objType]
			if {$temp != "inst"} {
				puts "found a $temp, aborting"
				return
				#sanity check, just in case something that is not a cell gets selected (somehow)
			}
			set temp [dbGet selected.box_sizex]
			set current_x [expr {$current_x + $temp}]
		}	
	}

	# in some cases the continuous gap ends because the row changes
	if {$wide > 0} {
		# debug
		#puts "...continuous sites: $wide"
		add_to_list $current_x $current_y $wide
		set counter2 [expr {$counter2 + 1}]
		set wide 0
	}


	set current_x [expr {$start_x + 0.01}]
	set current_y [expr {$current_y + $site_y}]
}


merge_list 0
# draw_regions
find_largest_region
fit
