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
fB0_b=2
NBR=$((READ / 2))
TD=0.
newton=30
overgrid=1.0
scaling_R2s=0.1
scaling_fB0=0.03
noise_level=300 # relative noise level


for noise_level in 50 300 3000
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

        bart resize -c 0 $NBR 1 $NBR reco_moba_simu_reg${lambda}_noise${noise_level}_sp$nspokes reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}

        bart phantom -T -x$NBR mask

        bart fmac mask reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR} reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked

        bart extract 6 0 1 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked W2_ss
        bart extract 6 1 2 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked F2_ss
        bart scale 1.0 F2_ss F2_ss2

        bash ../utils/./fatfrac.sh W2_ss F2_ss2 wf2_frac_ss_noise${noise_level}
        bart fmac mask wf2_frac_ss_noise${noise_level} wf2_frac_ss_noise${noise_level}_masked

        name=wf2_frac_ss_noise${noise_level}_masked
        python3 ../utils/save_maps.py $name hot 0 100 $name.png

        bart roistat -M rois wf2_frac_ss_noise${noise_level}_masked wf2_frac_ss_noise${noise_level}_masked_mean
        bart show wf2_frac_ss_noise${noise_level}_masked_mean 

        bart rss $(bart bitmask 3) sens_moba_simu_reg${lambda}_noise${noise_level}_sp$nspokes sens_rss

        bart resize -c 0 $NBR 1 $NBR sens_rss sens_rss_$NBR

        bart fmac W2_ss sens_rss_$NBR W_rss_noise${noise_level}
        bart fmac F2_ss sens_rss_$NBR F_rss_noise${noise_level}

        bart extract 6 0 1 water_fat_rss water_fat_rss_water
        # bart fmac mask water_fat_rss_water water_fat_rss_water_masked
        name=water_fat_rss_water
        python3 ../utils/save_maps.py $name gray 1e-3 0.5 $name.png

        bart extract 6 2 3 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star

        name=reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star
        python3 ../utils/save_maps.py $name magma 0 100 $name.png

        bart roistat -M rois reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_mean
        bart show reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_mean

        bart extract 6 3 4 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0
        name=reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0
        python3 ../utils/save_maps.py $name RdBu_r -50 50 $name.png 0

        bart roistat -M rois reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0_mean

        bart show reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0_mean

        bart roistat -M rois wf2_frac_ss_noise300_masked wf2_frac_ss_noise300_masked_mean
        bart show wf2_frac_ss_noise300_masked_mean


        T2star_VALUES=(0.01 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20)

        bart vec -- "${T2star_VALUES[@]}" ref_T2star

        B0_VALUES=(-50 -40 -30 -20 -10 0.0 10 20 30 40 50.0000)

        bart vec -- "${B0_VALUES[@]}" ref_b0

        fat_frac=(5 15 25 35 45 50 55 65 75 85 95) # Fat Fraction from 5% - 95%

        bart vec -- "${fat_frac[@]}" ref_ff

        bart join 1 ref_T2star ref_b0 ref_ff ref_t2star_b0_ff

        bart join 7 reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_r2star_mean \
        reco_moba_simu_reg${lambda}_noise${noise_level}_sp${nspokes}_${NBR}_masked_b0_mean \
        wf2_frac_ss_noise${noise_level}_masked_mean  meas_r2star_b0_noise${noise_level}

        bart squeeze meas_r2star_b0_noise${noise_level} meas_r2star_b0_noise${noise_level}_2
        bart join 2 ref_t2star_b0_ff meas_r2star_b0_noise${noise_level}_2 comp_r2star_b0_noise${noise_level}

        python3 ../utils/bland_simu_revision.py comp_r2star_b0_noise${noise_level}

        bart show reco_moba_simu_reg0.002_noise300_sp30_192_masked_r2star_mean

        bart roistat -D rois reco_moba_simu_reg0.002_noise300_sp30_192_masked_r2star reco_moba_simu_reg0.002_noise300_sp30_192_masked_r2star_std
        bart show reco_moba_simu_reg0.002_noise300_sp30_192_masked_r2star_std

        bart roistat -D rois reco_moba_simu_reg0.002_noise3000_sp30_192_masked_r2star reco_moba_simu_reg0.002_noise3000_sp30_192_masked_r2star_std
        bart show reco_moba_simu_reg0.002_noise3000_sp30_192_masked_r2star_std

        bart roistat -D rois reco_moba_simu_reg0.002_noise50_sp30_192_masked_r2star reco_moba_simu_reg0.002_noise50_sp30_192_masked_r2star_std
        bart show reco_moba_simu_reg0.002_noise50_sp30_192_masked_r2star_std
done