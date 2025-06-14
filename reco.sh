#!/bin/bash


set -eux

usage="Usage: $0 [-R lambda] [-a fB0_a] [-b fB0_b] [-i newton] [-o overgrid] [-s scaling_r2s] [-S scaling_B0] [-I] [-M] [-f] <TI> <TE> <traj> <ksp> <output> <output_sens>"

if [ $# -lt 5 ] ; then

        echo "$usage" >&2
        exit 1
fi

# whether to initialize fB0 with a 3-echo moba
init=0

# whether to include fat in the model
fat=1

SMS=''

overgrid=1.25

while getopts "hR:a:b:i:o:s:S:IMf" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	R) 
		lambda=${OPTARG}
		;;
        a) 
		fB0_a=${OPTARG}
		;;
        b) 
		fB0_b=${OPTARG}
		;;
        i) 
		newton=${OPTARG}
		;;
        o) 
		overgrid=${OPTARG}
		;;
        s) 
		scaling_r2s=${OPTARG}
		;;
        S) 
		scaling_B0=${OPTARG}
		;;
        I) 
		init=1
		;;
	M) 
		SMS='-M'
		;;
        f) 
		fat=0
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

TI=$(readlink -f "$1")
TE=$(readlink -f "$2")
traj=$(readlink -f "$3")
ksp=$(readlink -f "$4")
reco=$(readlink -f "$5")
sens=$(readlink -f "$6")

lambda=$lambda
fB0_a=$fB0_a
fB0_b=$fB0_b
overgrid=$overgrid
scaling_fat=1.0
scaling_r2s=$scaling_r2s
scaling_B0=$scaling_B0

if [ ! -e ${TI}.cfl ] ; then
        echo "Input TI file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${TE}.cfl ] ; then
        echo "Input TE file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${traj}.cfl ] ; then
        echo "Input traj file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${ksp}.cfl ] ; then
        echo "Input ksp file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi


bart copy $traj TRAJ_moba
bart copy $ksp kdat_moba
bart copy $TI TI_moba

function calc() { awk "BEGIN { print "$*" }"; }
# overgrid=1.25
# Initialization
dim=$(bart show -d1 $ksp)
dimx=`calc $dim*$overgrid`

bart ones 6 $((dimx/2)) $((dimx/2)) 1 1 1 1 ones
bart resize -c 0 $dimx 1 $dimx ones mask
bart scale 0. mask R2s_mask

bart zeros 6 $dimx $dimx 1 1 1 1 zeros_mask

echo $dimx

bart show $TE

# Initializa fB0 with 3-echo moba recon
if (($init == 1));
then
        bart extract 9 0 3 TRAJ_moba tmp-TRAJ_moba-3e
        bart extract 9 0 3 kdat_moba tmp-kdat_moba-3e
        bart extract 9 0 3 $TE tmp-TE_moba-3e

        NSPK=$(bart show -d2 tmp-TRAJ_moba-3e)
        NFRM=$(bart show -d5 tmp-TRAJ_moba-3e)

        bart ones 6 1 1 1 1 1 1 TI-tmp

        bart moba -i30 -d4 -g -D -m6 -R3 --img_dims $((dimx/2)):$((dimx/2)):1 --kfilter-2 -o$overgrid -C150 -j0.001 \
        --normalize_scaling --scale_data 500 --scale_psf 500 \
	--other pinit=1:$scaling_fat:$scaling_B0:1:1:1:1:1,pscale=1:$scaling_fat:$scaling_B0:1:1:1:1:1,echo=tmp-TE_moba-3e \
	-B0.0 -b 110:16 --positive-maps $(bart bitmask 1) \
        -t tmp-TRAJ_moba-3e tmp-kdat_moba-3e TI-tmp reco-wf-3e2 sens-wf-3e2

        bart extract 6 0 1 reco-wf-3e2 water
        bart extract 6 1 2 reco-wf-3e2 fat
        bart extract 6 2 3 reco-wf-3e2 fB0

	bart scale $(echo "scale=6; 1/$scaling_fat" | bc) fat fat2
	bart scale $(echo "scale=6; 1/($scaling_B0*1000)" | bc) fB0 fB02 # *1000 becaue required in [1/ms]

        bart join 6 water fat2 R2s_mask fB02 M_init
fi


recon_type=7

if (($init == 1));
then
        echo "The recon_type is."
        echo $recon_type

        bart moba -i$newton -d4 -g -D -m7 -R3 --img_dims $((dimx/2)):$((dimx/2)):1 -k --kfilter-2 -o$overgrid -C200 -j$lambda \
        --normalize_scaling --scale_data 500 --scale_psf 500 \
	--other pinit=1:$scaling_fat:$scaling_r2s:$scaling_B0:1:1:1:1,pscale=1:$scaling_fat:$scaling_r2s:$scaling_B0:1:1:1:1,echo=$TE \
	-b $fB0_a:$fB0_b -T0.9 -I M_init \
        -t TRAJ_moba kdat_moba TI_moba $reco $sens
else    
        echo "The recon_type is."
        echo $recon_type
        bart moba -i15 -d4 -g -D -m7 -R3 --img_dims $((dimx/2)):$((dimx/2)):1 -k --kfilter-2 -o$overgrid -C200 -j0.002 \
        --normalize_scaling --scale_data 500 --scale_psf 500 \
	--other pinit=1:$scaling_fat:$scaling_r2s:$scaling_B0:1:1:1:1,pscale=1:$scaling_fat:$scaling_r2s:$scaling_B0:1:1:1:1,echo=$TE,export-ksp-sens \
	-b $fB0_a:$fB0_b \
        -t TRAJ_moba kdat_moba TI_moba $reco $sens
fi

rm tmp*.{hdr,cfl}
