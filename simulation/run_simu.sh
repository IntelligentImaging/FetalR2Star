#!/bin/bash
# 
# Copyright 2025. 
#
# Author: Xiaoqing Wang, 2023-2025
# xiaoqingwang2010@gmail.com / xiaoqing.wang@childrens.harvard.edu
# Department of Radiology, 
# Boston Children's Hospital, Harvard Medical School


READ=384
ne=35 # number of echos
TR=68300 # micro second
TR0=$(echo "scale=4; $TR*0.000001" | bc)

GA=2
lambda=0.002
SPOKES=30 # no. of spokes per k-space frame
nkframe=1 # total number of k-space frames
fB0_a=11
fB0_b=4
NBR=$((READ / 2))
TD=0.
newton=30
overgrid=1.0
scaling_R2s=0.1
scaling_fB0=0.03
noise_level=300 # relative noise level


for noise_level in 50 300 2000
do      
        bash ./prep_simu.sh -S$READ -E$ne -T$TR -G$GA -f$SPOKES -M$nkframe -n$noise_level data_noise$noise_level traj TI TE
        
        bart cc -p2 -A data_noise$noise_level data_2c_noise$noise_level

        bart ones 6 1 1 1 1 1 1 TI

        spokes=$(bart show -d2 data_noise$noise_level)
        nspokes=30

        bart extract 2 0 $nspokes traj traj_sp$nspokes
        bart extract 2 0 $nspokes data_2c_noise$noise_level data_2c_noise${noise_level}_sp$nspokes


        bash ./recon_simu.sh -I -R$lambda -a$fB0_a -b$fB0_b -i$newton -o$overgrid -s$scaling_R2s -S$scaling_fB0 TI TE traj_sp$nspokes \
	        data_2c_noise${noise_level}_sp$nspokes reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_a${fB0_a}_b${fB0_b} \
                sens_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_a${fB0_a}_b${fB0_b}

        READ=$(bart show -d1 data_2c_noise${noise_level}_sp$nspokes)
        NBR=$((READ/2))

        bart resize -c 0 $NBR 1 $NBR reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_a${fB0_a}_b${fB0_b} reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}

        # Create mask and ROIs
        bart phantom -T -x$NBR mask
        bart phantom -T -x$NBR -b tmp
        bart morphop -e 3 tmp rois

        bart fmac mask reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR} reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked

        bart extract 6 0 1 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked W2_ss
        bart extract 6 1 2 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked F2_ss
        bart scale 1.0 F2_ss F2_ss2

        bash ../utils/./fatfrac.sh W2_ss F2_ss2 wf2_frac_ss_noise${noise_level}
        bart fmac mask wf2_frac_ss_noise${noise_level} wf2_frac_ss_noise${noise_level}_masked

        bart rss $(bart bitmask 3) sens_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_a${fB0_a}_b${fB0_b} sens_rss

        bart resize -c 0 $NBR 1 $NBR sens_rss sens_rss_$NBR

        bart fmac W2_ss sens_rss_$NBR W_rss_noise${noise_level}
        bart fmac F2_ss sens_rss_$NBR F_rss_noise${noise_level}

        # Output quantitative maps
        # Water
        name=W_rss_noise${noise_level}
        bart flip $(bart bitmask 1) $name tmp
        python3 ../utils/save_maps.py tmp gray 1e-3 0.6 $name.png

        # Fat Fraction (FF)
        name=wf2_frac_ss_noise${noise_level}_masked
        python3 ../utils/save_maps.py $name hot 0 100 $name.png

        # R2* map
        bart extract 6 2 3 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star       
        name=reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star
        python3 ../utils/save_maps.py $name magma 0 40 $name.png

        # B0 map
        bart extract 6 3 4 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0
        name=reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0
        python3 ../utils/save_maps.py $name RdBu_r -50 50 $name.png 0

        # Quantitative values
        # R2*
        bart roistat -M rois reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_mean
        
        echo "The mean R2* values are: "
        bart show reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_mean

        bart roistat -D rois reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_std
        
        echo "The standard deviation of R2* values are: "
        bart show reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_std

        # B0
        bart roistat -M rois reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0_mean
        
        echo "The mean B0 values are: "
        bart show reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0_mean       
done