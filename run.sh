#!/bin/bash
# 
# Copyright 2025. 
#
# Author: Xiaoqing Wang, 2023-2025
# xiaoqingwang2010@gmail.com / xiaoqing.wang@childrens.harvard.edu
# Department of Radiology, 
# Boston Children's Hospital, Harvard Medical School

# path to the example data set 
data=fetal_data/subject9/ksp_cc 
READ=$(bart show -d0 $data)
ne=35 # number of echos
TR=68500
GA=2
lambda=0.002
SPOKES=30 # no. of TRs 
nframe=1 # total number of k-space frames
fB0_a=22
fB0_b=4
newton=15
overgrid=1.5
NBR=$((READ / 2))
scaling_R2s=0.05
scaling_fB0=0.05
scaling_fB0_HZ=$(echo "scale=4; $scaling_fB0*1000" | bc)
SLICES2=1


## Preparing traj, data, TI and TE
bash prep.sh -E$ne -T$TR -G$GA -s$SLICES2 -f$SPOKES $data data_2D_35e traj_2D_35e TI_2D_35e TE_2D_35e

## Coil compression
bart cc -A -p12 data_2D_35e data_2D_35e_cc

bart ones 6 1 1 1 1 1 1 TI

## Model-based reconstruction
bash reco.sh -I -R$lambda -a$fB0_a -b$fB0_b -i$newton -o$overgrid -s$scaling_R2s -S$scaling_fB0 TI_2D_35e TE_2D_35e traj_2D_35e \
	data_2D_35e_cc reco_moba_reg${lambda}_np${SPOKES} sens_moba_reg${lambda}_np${SPOKES}

bart resize -c 0 $NBR 1 $NBR reco_moba_reg${lambda}_np${SPOKES} reco_moba_reg${lambda}_np${SPOKES}_${NBR}


# Extract and save R2* and B0 maps
bart extract 6 2 3 reco_moba_reg${lambda}_np${SPOKES}_${NBR} reco_moba_reg${lambda}_np${SPOKES}_${NBR}_r2star

python3 utils/save_maps.py reco_moba_reg${lambda}_np${SPOKES}_${NBR}_r2star magma 0 30 reco_moba_reg${lambda}_np${SPOKES}_${NBR}_r2star.png

bart extract 6 3 4 reco_moba_reg${lambda}_np${SPOKES}_${NBR} reco_moba_reg${lambda}_np${SPOKES}_${NBR}_B0

python3 utils/save_maps.py reco_moba_reg${lambda}_np${SPOKES}_${NBR}_B0 RdBu_r -50 50 reco_moba_reg${lambda}_np${SPOKES}_${NBR}_B0.png 0

# Generate water and fat images
bart rss $(bart bitmask 3) sens_moba_reg${lambda}_np${SPOKES} sens_rss
bart resize -c 0 $NBR 1 $NBR sens_rss sens_rss_${NBR}
bart extract 6 0 2 reco_moba_reg${lambda}_np${SPOKES}_${NBR} reco_moba_reg${lambda}_np${SPOKES}_${NBR}_W_F
bart fmac reco_moba_reg${lambda}_np${SPOKES}_${NBR}_W_F sens_rss_${NBR} reco_moba_reg${lambda}_np${SPOKES}_${NBR}_W_F_rss

# Join all parameter maps for Figure 5
bart join 6 reco_moba_reg${lambda}_np${SPOKES}_${NBR}_W_F_rss reco_moba_reg${lambda}_np${SPOKES}_${NBR}_r2star reco_moba_reg${lambda}_np${SPOKES}_${NBR}_B0 reco_moba_reg${lambda}_np${SPOKES}_${NBR}_all_maps

