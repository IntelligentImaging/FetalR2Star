#!/bin/bash
# 
# Copyright 2025. 
#
# Author: Xiaoqing Wang, 2023-2025
# xiaoqingwang2010@gmail.com / xiaoqing.wang@childrens.harvard.edu
# Department of Radiology, 
# Boston Children's Hospital, Harvard Medical School

set -e

helpstr=$(cat <<- EOF
Preparation of traj, data, inversion and echo times for IR Radial Multi-echo FLASH.
-S number of samples
-E number of echos
-R repetition time 
-G nth golden angle
-f number of spokes per frame (k-space)
-h help
EOF
)

usage="Usage: $0 [-h] [-S nSMP] [-E nEcho] [-T TR] [-G GA] [-f nspokes_per_frame] [-M NMEA_for_recon] [-n noise_level] <out_data> <out_traj> <out_TI> <out_TE>"

while getopts "hS:E:T:G:f:M:n:" opt; do
	case $opt in
	h) 
		echo "$usage"
		echo "$helpstr"
		exit 0 
		;;
	S) 
		nSMP=${OPTARG}
		;;
        E) 
		nEcho=${OPTARG}
		;;
	T) 
		TR=${OPTARG}
		;;
	G) 
		GA=${OPTARG}
		;;
	f) 	
		nspokes_per_frame=${OPTARG}
		;;
	M) 	
		NMEA_for_recon=${OPTARG}
		;;
        n) 	
		noise_level=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

out_data=$(readlink -f "$1")
out_traj=$(readlink -f "$2")
out_TI=$(readlink -f "$3")
out_TE=$(readlink -f "$4")


# simulation
nEcho=35
NECO=$((nEcho+1))
NSPK=3
NMEA=10
NI=$((NSPK*NMEA))
N=$((NECO*NMEA*NSPK))
TR=$TR
TE=1600
NSLI=1
GIND=$GA
NMEA_for_recon=$NMEA_for_recon

NSMP=$nSMP
fat_frac=$Fat_fraction

bart traj -x $NSMP -y $NSPK -t$NMEA -r -D -E -G -s2 -e $((NECO-1)) -c tmp_traj1

bart reshape $(bart bitmask 2 10) $NI 1 tmp_traj1 tmp_traj2

bart scale 0.5 tmp_traj2 tmp_traj                          
# bart phantom -k -s8 -T -b -t tmp_traj basis_geom

TR1=$(echo "scale=4; $TR*0.000001" | bc)
TE1=$(echo "scale=4; $TE*0.000001" | bc)


T1=(3.0 3.0 3.0 3.0 3.0 3.0 3.0 3.0 3.0 3.0 3.0)
T2=(0.01  0.02  0.04 0.06  0.08 0.10 0.12 0.14 0.16 0.18 0.20)
OFFRES_FAT=(`seq -50 10 50`)
fat_frac=(0.05 0.15 0.25 0.35 0.45 0.50 0.55 0.65 0.75 0.85 0.95) # Fat Fraction from 5% - 95%

NECO=36
# Simulate signals
for i in `seq 0 $((${#T1[@]}-1))`; do

        echo -e "Tube $i\t T1: ${T1[$i]} s,\tT2[$i]: ${T2[$i]} s,\tfat_frac[$i]: ${fat_frac[$i]} s,\tOFFRES_FAT[$i]: ${OFFRES_FAT[$i]} s"


	bart signal 	-G --fat -n$NECO -d${fat_frac[$i]} \
			-1 ${T1[$i]}:${T1[$i]}:1 -2 ${T2[$i]}:${T2[$i]}:1 \
			-0 ${OFFRES_FAT[$i]}:${OFFRES_FAT[$i]}:1 \
			tmp_signal_$(printf "%02d" $i)

done

bart join 7 tmp_signal_00 tmp_signal_01 tmp_signal_02 tmp_signal_03 tmp_signal_04 tmp_signal_05 tmp_signal_06 tmp_signal_07 \
	tmp_signal_08 tmp_signal_09 tmp_signal_10 tmp_signal

bart reshape $(bart bitmask 6 7) ${#T1[@]} 1 tmp_signal signal_all


bart extract 5 1 $NECO signal_all tmp_signal_all_2


# bart transpose 4 2 tmp_signal_all_2 tmp_signal_all_3

bart fmac -s 64 basis_geom tmp_signal_all_2 tmp_data0

bart transpose 5 9 tmp_traj $out_traj


# add noise to the simulated dataset 
for (( i=0; i <= 7; i++ )) ; do

        bart slice 3 $i tmp_data0 tmp
        bart noise -n$noise_level tmp tmp_ksp_$i.coo
done

bart join 3 tmp_ksp_*.coo out_data
rm tmp_ksp_*.coo


bart transpose 5 9 out_data $out_data

nTE=$(bart show -d9 $out_data)

bart index 9 $nTE tmp1.coo
# use local index from newer bart with older bart
#./index 5 $num tmp1.coo
bart scale $TE tmp1.coo tmp2.coo
bart ones 10 1 1 1 1 1 1 1 1 1 $nTE tmp1.coo
bart saxpy $TE tmp1.coo tmp2.coo tmp3.coo
bart scale 0.001 tmp3.coo $out_TE


nTI=$(bart show -d5 $out_data)
spokes=$(bart show -d2 $out_data)

bart index 5 $nTI tmp1.coo
# use local index from newer bart with older bart
#./index 5 $num tmp1.coo
bart scale $(($spokes * $TR)) tmp1.coo tmp2.coo
bart ones 6 1 1 1 1 1 $nTI tmp1.coo 
echo $((($spokes / 2) * $TR))
bart saxpy $((($spokes / 2) * $TR)) tmp1.coo tmp2.coo tmp3.coo
bart scale 0.000001 tmp3.coo $out_TI

rm tmp*.coo tmp*.{hdr,cfl}
