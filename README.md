Shield: [![CC BY-NC 4.0][cc-by-nc-shield]][cc-by-nc]

This work is licensed under a
[Creative Commons Attribution-NonCommercial 4.0 International License][cc-by-nc].

[![CC BY-NC 4.0][cc-by-nc-image]][cc-by-nc]

[cc-by-nc]: https://creativecommons.org/licenses/by-nc/4.0/
[cc-by-nc-image]: https://licensebuttons.net/l/by-nc/4.0/88x31.png
[cc-by-nc-shield]: https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg

# SALSy
This repository contains several scripts for enhancing the security of digital designs during physical synthesis. The techniques that are part of SALSy are described in the following paper: https://doi.org/10.48550/arXiv.2308.06201

INDEX:

asset_checker.tcl --> Script for checking the net and cell assets in the layout. Some of the assets might be removed during different rounds of optimization in the physical synthesis. Hence, it is necessary to check if all of them still remain in the final layout.

buf_insert.tcl --> Script for adding preferred buffer type according to the library within the user-defined area in the layout

ccopt_config --> Script for routing the CTS with non-default rules; The width and preferred metal layer can be defined by the user.

gap_finder.tcl --> Script for finding the exploitable regions (continuous gaps) in the layout with the preferred threshold

new_route.tcl --> Script for routing the signal wires with non-default rules; The width and preferred metal layer can be defined by the user.

report_design_statistics.tcl --> Script for generating different statistics about the design in the post-route step

How to cite:

```
@misc{eslami2023salsy,
      title={SALSy: Security-Aware Layout Synthesis}, 
      author={Mohammad Eslami and Tiago Perez and Samuel Pagliarini},
      year={2023},
      eprint={2308.06201},
      archivePrefix={arXiv},
      primaryClass={cs.CR}
}
```

