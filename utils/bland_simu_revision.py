#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
# sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

import matplotlib.pyplot as plt
import numpy as np

FS = 45

def bland_altman_plot_1(data1, data2, out_file, yliml, ylimm, label=False, *args, **kwargs):

	plt.rcParams.update({'font.size': FS, 'lines.linewidth': 9, 'font.family':'Arial'})

	data1     = np.asarray(data1)
	data2     = np.asarray(data2)
	mean      = np.mean([data1, data2], axis=0)
	diff      = data1 - data2                   # Difference between data1 and data2
	md        = np.mean(diff)                   # Mean of the difference
	sd        = np.std(diff, axis=0)            # Standard deviation of the difference
	print(md)
	print(sd)

	print(diff)

	plt.figure(figsize=(10, 9), dpi=80)
	plt.scatter(mean, diff, s=120, c='black', *args, **kwargs)
	plt.axhline(md,           color='blue', linestyle='--',zorder=-1)
	plt.axhline(md + 1.96*sd, color='red', linestyle='--',zorder=-1)
	plt.axhline(md - 1.96*sd, color='red', linestyle='--',zorder=-1)
	plt.ylim(yliml, ylimm)

	if (label):
		# "+3" to increase distance slightly more
		plt.text(np.max(mean), np.max(md + 1.96*sd)+3, "Mean + 1.96 SD", horizontalalignment='right', verticalalignment='bottom', color = "red")

		plt.text(np.max(mean), np.max(md - 1.96*sd)-3, "Mean - 1.96 SD", horizontalalignment='right', verticalalignment='top', color = "red")

##################################################################


if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 2):
		print( "Function for creating Bland-Altman plots" )
		print( "Usage: bland.py <joined-values>" )
		exit()

	values = np.real(cfl.readcfl(sys.argv[1]).squeeze())

	ref = values[:,:,0]
	meas = values[:,:,1]


	# R2s: Ref vs. Meas

	out_file = "bland_R2s_num_ref.pdf" #df"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(1/ref[:,0], meas[:,0], out_file, -0.4, 0.4) # "1/(...)" T2* [s] -> R1* [1/s]
	# ax.set_xticks(np.arange(14, 23, 2))
	ax.grid()
	plt.xlabel("$R_{2}^{*}$ Average / s$^{-1}$", fontsize=FS - 3, fontname="Arial")
	plt.ylabel("$R_{2}^{*}$ Difference \n Ref. - Proposed / s$^{-1}$", fontsize=FS - 3, fontname="Arial")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)



	# B0: Ref vs. Meas

	out_file = "bland_B0_num_ref.pdf" #df"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(ref[:,1], meas[:,1], out_file, -0.3, .3)
	ax.set_xticks(np.arange(-50, 100, 50))
	ax.grid()
	plt.xlabel("$B_{0}$ Average / Hz", fontsize=FS - 3, fontname="Arial")
	plt.ylabel("$B_{0}$ Difference \n Ref. - Proposed / Hz", fontsize=FS - 3, fontname="Arial")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)


	# Fat fraction: Ref vs. Meas

	out_file = "bland_FF_num_ref.pdf" #df"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(ref[:,2], meas[:,2], out_file, -0.3, 0.3)
	# ax.set_xticks(np.arange(-50, 100, 50))
	ax.grid()
	plt.xlabel("FF Average / $\%$", fontsize=FS - 3, fontname="Arial")
	plt.ylabel("FF Difference \n Ref. - Proposed / $\%$", fontsize=FS - 3, fontname="Arial")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)
