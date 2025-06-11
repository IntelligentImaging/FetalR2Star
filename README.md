
# Rapid, High-resolution and Distortion-free R2* Mapping of Fetal Brain using Multi-echo Radial FLASH and Model-based Reconstruction


This repository contains scripts to reproduce the results for the following work 

#### Rapid, High-resolution and Distortion-free R2* Mapping of Fetal Brain using Multi-echo Radial FLASH and Model-based Reconstruction
> X Wang, H Fan, Z Tan, S Vasylechko, E Yang, R Didier, O Afacan, M Uecker, SK Warfield, A Gholipour
>
> Magnetic Resonance in Medicine (DOI: 10.1002/mrm.30604).
> 

## Requirements
This repository has been tested on Ubuntu 22.04.5 LTS, but is assumed to work on other Linux-based operating systems, too. Image export and display require Python and NumPy.

#### Scripts
Pre-processing, reconstruction and post-processing is performed with the [BART toolbox](https://github.com/mrirecon/bart).
The provided scripts are compatible with commit `gefb1de8` or later.
For running the reconstructions access to a GPU is recommended.
If the CPU should be used, please remove `-g` flags from all `bart pics ...`, `bart nufft ...`, and `bart moba ...` calls.

For the in-vivo example, simply run `bash run.sh`; For the simulations, navigate to the simulation folder (`cd simulation`) and run `bash run_simu.sh`. Alternatively, you can open the Jupyter notebook `FetalR2Star.ipynb` in Google Colab to reproduce one of the in-vivo results. 

If you experience any compatibility problems with later BART versions, or need further help to run the scripts, please let us know!
(xiaoqingwang2010@gmail.com or xiaoqing.wang@childrens.harvard.edu)

#### Expected outputs
The expected outputs include water, fat, and quantitative R2* and B0 maps of the simulated phantom and fetal brain, as shown in Figures 1 and 4, respectively.

#### Example Results
<div style="text-align: center;">
  <figure style="display: inline-block;">
    <img src="/fetal_data/SupportingInformationVideoS1.gif" alt="27.9 weeks" width="400"/>
    <figcaption style="margin-top: 6px; \\">
      <em>Quantitative R2* maps (left) and R2*-weighted images (right) at TE = 70 ms for a subject at 27.9 weeks gestational age</em>
    </figcaption>
  </figure>
</div>

<div style="text-align: center;">
  <figure style="display: inline-block;">
    <img src="/fetal_data/SupportingInformationVideoS2.gif" alt="35.6 weeks" width="400"/>
    <figcaption style="margin-top: 6px; \\">
      <em>Quantitative R2* maps (left) and R2*-weighted images (right) at TE = 70 ms for a subject at 35.6 weeks gestational age</em>
    </figcaption>
  </figure>
</div>
