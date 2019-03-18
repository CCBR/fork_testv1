#!/bin/bash

. /DCEG/Projects/Microbiome/CGR_MB/MicroBiome/sc_scripts_qiime2_pipeline/V1/QIIME2_v1_Global.sh


##################################################################################################################
input_table_merged_final_qza=${table_dada2_qza_merged_parts_final_dir}/${table_dada2_merged_final_param}.qza
output_table_merged_final_qzv=${table_dada2_qzv_merged_parts_final_dir}/${table_dada2_merged_final_param}.qzv

input_repseqs_merged_final_qza=${repseqs_dada2_qza_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qza
output_repseqs_merged_final_qzv=${repseqs_dada2_qzv_merged_parts_final_dir}/${repseqs_dada2_merged_final_param}.qzv

Manifest_File=$MANIFEST_FILE_qiime2_format

cmd="qsub -cwd \
	-pe by_node 10 \
	-q ${QUEUE} \
	-o ${log_dir_stage_3}/stage3_qiime2.stdout \
	-e ${log_dir_stage_3}/stage3_qiime2.stderr \
	-N stage3_qiime2 \
	-S /bin/sh \
	${SCRIPT_DIR}/substeps/QIIME2_v1_Step3.1.sh \
	$input_table_merged_final_qza \
	$output_table_merged_final_qzv \
	$input_repseqs_merged_final_qza \
	$output_repseqs_merged_final_qzv \
	$Manifest_File"
	
echo $cmd
eval $cmd
	