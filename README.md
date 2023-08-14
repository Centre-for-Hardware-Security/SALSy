# SALSy
This repository contains several scripts for enhancing the security of digital designs during physical synthesis.

INDEX:

asset_checker.tcl --> Script for checking the net and cell assets in the layout. Some of the assets might be removed during different rounds of optimization in the physical synthesis. Hence, it is necessary to check if all of them still remain in the final layout.

buf_insert.tcl --> Script for adding preferred buffer type according to the library within the user-defined area in the layout

ccopt_config --> Script for routing the CTS with non-default rules; The width and preferred metal layer can be defined by the user.

gap_finder.tcl --> Script for finding the exploitable regions (continuous gaps) in the layout with the preferred threshold

new_route.tcl --> Script for routing the signal wires with non-default rules; The width and preferred metal layer can be defined by the user.

report_design_statistics.tcl --> Script for generating different statistics about the design in the post-route step

How to cite:

Please cite our paper in case of using each of the SALSy scripts as the following:

https://doi.org/10.48550/arXiv.2308.06201
