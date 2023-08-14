############################################
#
# Script for reporting design statistics at post-route step
# Author: Tiago Perez 
# Supervisor: Samuel Pagliarini
# Tallinn University of Technology (TALTECH)
#
############################################

setPreference CmdLogMode 0
set step postRoute
set top_design [dbget top.name]
set REPORTS_PATH ${rpt_path}
file mkdir -p $REPORTS_PATH
set ofptr [open ${REPORTS_PATH}/DesignStatistics.rpt w]

set designName [dbgDesignName]

# reset all counts:
set physicalCnt 0
set spareGateCnt 0
set stdCellArea 0
set stdCellCnt 0
set bufferCnt 0
set invCnt 0
set holdFixCnt 0
set sequentialStdCellCnt 0
set combStdCellCnt 0
set netWireLenUm 0
set totWireLenUm 0
set macroArea 0
set macroCnt 0
set totInstCnt 0
set totInstArea 0
set totAreaFF 0
set totAreaBuf 0
set totAreaInv 0
set fillerMarkers 0

# Empty gaps
checkFiller

set fillerMarkers [ llength [dbget top.markers.type ] ]

# block dimension:
set blockDimension [dbHeadBox]
set blockX [dbDBUToMicrons [dbBoxDimX $blockDimension]]
set blockY [dbDBUToMicrons [dbBoxDimY $blockDimension]]
set blockArea [expr $blockX * $blockY]

# Die area
set dieArea [dbget top.fplan.area]
# or:
#set blockArea [dbGet top.fplan.area]
# or:
#sum up all the row boxes:
#   each row:
#      set blockArea [dbGet top.fplan.rows.box_area]
#


# calculate total wire length:
set topCellPtr [dbgTopCell]
if { $topCellPtr != "0x0" } {
    # each net:
    dbForEachCellNetS [dbgTopCell] netPtr {
	set netWireLen 0
	# each net segment:
	dbForEachNetWire $netPtr segmentPtr {
	    set netSegLen [dbWireLen $segmentPtr]
	    set netWireLen [expr $netWireLen+$netSegLen]
	}
	set netWireLenUm [expr $netWireLen*[dbHeadMicronPerDBU]]
	set totWireLenUm [expr $netWireLenUm + $totWireLenUm]
    }
}

# get cell statistics:
# each instance:
dbForEachCellInst [dbHeadTopCell] inst {
    set cell [dbInstCell $inst]

    set cellDimension [dbCellDim [dbInstCell $inst]]
    set instArea [expr [dbDBUToMicrons [lindex $cellDimension 0]] * [dbDBUToMicrons [lindex $cellDimension 1]]]
    set totInstArea [expr $instArea + $totInstArea]
    incr totInstCnt

    # collect stats for instance types :
    if {[dbIsInstBlock $inst]} {
	set macroArea [expr $instArea + $macroArea]
	incr macroCnt
    } elseif {[dbIsInstPhysicalOnly $inst]} {
        incr physicalCnt
    } elseif {[dbIsInstSpareGate $inst]} {
        incr spareGateCnt
    } elseif {[dbIsInstStdCell $inst]} {
	set stdCellArea [expr $instArea + $stdCellArea]
	incr stdCellCnt

	# now collect sub-category stats for std cell types (inv,buf,ff,comb):
	if {[ckIsInstanceBuf $inst] == 2} {
	    incr invCnt
	    set totAreaInv [expr $instArea + $totAreaInv]
	} elseif {[ckIsInstanceBuf $inst] == 1} {
	    incr bufferCnt
	    set totAreaBuf [expr $instArea + $totAreaBuf]
	} elseif {[dbIsCellSequential $cell]} {
	    incr sequentialStdCellCnt
	    set totAreaFF [expr $instArea + $totAreaFF]
	} else {
	    # call the rest 'combinational':
	    incr combStdCellCnt
	}
	## end of sub-categories

    }

    # extra info:  get hold buffer count based on EDI inst naming convention:
    set instname [dbGet ${inst}.name]
    if { [string match "*FE_PHC*" $instname ] } {
        incr holdFixCnt
    }

}

# now calculate block Density:
set blockDensity  [expr ($stdCellArea + $macroArea ) / $blockArea ]
set designDesinty [expr ($stdCellArea + $macroArea ) / $dieArea   ]


puts $ofptr "Design: $designName"
puts $ofptr "Instance area: $totInstArea"
puts $ofptr "Block density: $blockDensity"
puts $ofptr "Design density: $designDensity"
puts $ofptr "Inst count: $totInstCnt"
puts $ofptr "Empty sites (do not mix with gaps): $fillerMarkers"
puts $ofptr "   Physical cell count : $physicalCnt"
puts $ofptr "   Macro area: $macroArea"
puts $ofptr "   Macro count: $macroCnt"
puts $ofptr "   StdCell area: $stdCellArea"
puts $ofptr "   StdCell count: $stdCellCnt"
puts $ofptr "      Buffer count: $bufferCnt Area: $totAreaBuf"
puts $ofptr "      Hold count: $holdFixCnt"
puts $ofptr "      Inv count: $invCnt Area: $totAreaInv"
puts $ofptr "      Sequential count: $sequentialStdCellCnt Area: $totAreaFF"
puts $ofptr "      Comb count: $combStdCellCnt"
puts $ofptr "        Sparegate count: $spareGateCnt"
puts $ofptr "Total wirelength: $totWireLenUm um"
puts $ofptr "\n============================\n"
puts $ofptr "Statistics excluding all physical cells (pad_power, DECAP, FILLECO, FILL, ENDCAP, WELLTAP)"
puts $ofptr "Drive Strength:"
puts $ofptr "X1:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X1*].isPhysOnly 0].name]]"
puts $ofptr "X2:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X2*].isPhysOnly 0].name]]"
puts $ofptr "X3:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X3*].isPhysOnly 0].name]]"
puts $ofptr "X4:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X4*].isPhysOnly 0].name]]"
puts $ofptr "X5:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X5*].isPhysOnly 0].name]]"
puts $ofptr "X6:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X6*].isPhysOnly 0].name]]"
puts $ofptr "X8:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X8*].isPhysOnly 0].name]]"
puts $ofptr "X9:  [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X9*].isPhysOnly 0].name]]"
puts $ofptr "X11: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X11*].isPhysOnly 0].name]]"
puts $ofptr "X13: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X13*].isPhysOnly 0].name]]"
puts $ofptr "X16: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X16*].isPhysOnly 0].name]]"
puts $ofptr "X32: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *X32*].isPhysOnly 0].name]]"
puts $ofptr "\nCell Type:"
puts $ofptr "Buffer:     [llength [dbGet -e [dbGet -p2 top.insts.cell.isBuffer 1].name]]"
puts $ofptr "Inverter:   [llength [dbGet -e [dbGet -p2 top.insts.cell.isInverter 1].name]]"
puts $ofptr "Sequential: [llength [dbGet -e [dbGet -p2 top.insts.cell.isSequential 1].name]]"
puts $ofptr "Comb Logic: [llength [dbGet -e [dbGet -p1 [dbGet -p2 [dbGet -p2 [dbGet -p2 top.insts.cell.isBuffer 0].cell.isInverter 0].cell.isSequential 0].isPhysOnly 0].name]]"
# puts $ofptr "\nCell Threshold:"
# puts $ofptr "RVT: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *TR*].isPhysOnly 0].name]]"
# puts $ofptr "LVT: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *TL*].isPhysOnly 0].name]]"
# puts $ofptr "SLVT: [llength [dbGet -e [dbGet -p1 [dbGet -p2 top.insts.cell.name *TSL*].isPhysOnly 0].name]]"


close $ofptr
setPreference CmdLogMode 2
