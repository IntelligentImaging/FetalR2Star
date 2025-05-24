
# Rapid, High-resolution and Distortion-free R2* Mapping of Fetal Brain using Multi-echo Radial FLASH and Model-based Reconstruction


This repository contains scripts to reproduce the results for the following work 

#### Rapid, High-resolution and Distortion-free R2* Mapping of Fetal Brain using Multi-echo Radial FLASH and Model-based Reconstruction
> X Wang, H Fan, Z Tan, S Vasylechko, E Yang, R Didier, O Afacan, M Uecker, SK Warfield, A Gholipour
>
> Submitted to Magnetic Resonance in Medicine.
> 

## Requirements
This repository has been tested on Ubuntu 22.04.5 LTS, but is assumed to work on other Linux-based operating systems, too.

#### Scripts
Pre-processing, reconstruction and post-processing is performed with the [BART toolbox](https://github.com/mrirecon/bart).
The provided scripts are compatible with commit `gefb1de8` or later.
If you experience any compatibility problems with later BART versions please let us know!
(xiaoqingwang2010@gmail.com or xiaoqing.wang@childrens.harvard.edu)

For running the reconstructions access to a GPU is recommended.
If the CPU should be used, please remove `-g` flags from all `bart pics ...`, `bart nufft ...`, and `bart moba ...` calls.

#### Example Results
![Quantitative R2* maps and R2*-weighted images at TE = 70 ms for for a subject at 27.9 weeks gestational age](/fetal_data/SupportingInformationVideoS1.gif)

![Quantitative R2* maps and R2*-weighted images at TE = 70 ms for for a subject at 35.6 weeks gestational age](/fetal_data/SupportingInformationVideoS2.gif)