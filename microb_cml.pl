#!/usr/bin/perl
# Name of file: microbiome.pl
# Owner: Samantha Sevilla
# Last Update: 070617
# Use for GMU Lab Rotation Spring 2017

###This script takes in the Project and MR number of a program and finds the associated MB Manifest, downloaded
###from LIMS. It then copies the fastq files of all QC samples and moves them to the Nephele folder. It creates
###the necessary txt file to input into Nephele.

use warnings;
use strict;
use Cwd;
use CPAN;
	eval "use File::chdir" 
	 or do { 
	  CPAN::install("File::chdir");
	};
	
	eval "use File::Copy" 
	 or do { 
	  CPAN::install("File::Copy");
	};
	
	use File::chdir;
	use File::Copy;

#Intialize variables
	my @QCPath; my @ManPath; my $Nephpath; my $MRName;
	my @SampleID; my @ExternalID; my @SourceMaterial;
	my @SampleType;	my @ExtractionBatchID; my @RunID; 
	my @SourcePCRPlate; my @ProjectID; my @Proj_List;
	my @AssayPlate_Neph; my @SampleID_Neph; 
	my @Treatment_Neph;	my @VialLab_Neph; 
	my @ExtractBatch_Neph; my @Descrip_Neph;
	my @filename_R1; my @filename_R2;
	
#Take in Directory from Command Line and format for CWD
	print "\n Have you downloaded the Microbiome manifest from LIMS (Y or N) ";
		### my $ManiAns = <STDIN>; chomp $ManiAns;
		#if($ManiAns =~ "N") {print "\n**Generate Microbiome Manifest for Project from LIMS, then re-run**\n";
		#	exit;}
	print "Do you want to include study samples (Y or N)? ";
		### my $StudyAns = <STDIN>; chomp $StudyAns;
	print "What is the date to assoicate with analysis?(04_10_17) ";
		#my $date = <STDIN>; chomp $date;
	print "How many projects would you like to include?";
		#my $Proj_Num = <STDIN>; chomp $Proj_Num;
	#until($Proj_Num == 0){
	#	print "What is the name of your project? (NP0452-MB3)";
	#		my $ProjName = <STDIN>; chomp $ProjName;
	#		push(@Proj_List,$ProjName);
	#	$Proj_Num = $Proj_Num - 1;
	#}		
	

###Testing input
	my $ManiAns = "Y";	
	my $StudyAns = "Y";
	my $date = "test"; chomp $date;
	my $Proj_Num = 2;
	@Proj_List = ("NP0452-MB3", "NP0452-MB2");

#Call subroutines
	qc_mb_dir(\@Proj_List, \$MRName, \$Proj_Num, \@QCPath, \@ManPath);
		$CWD = $QCPath[0];
	Qiime_Neph_Dir(\$Nephpath, $date); 
		$CWD = $ManPath[0];
	read_MB_Man(@Proj_List, @ManPath, $StudyAns, \@SampleID, \@ExternalID, \@SampleType, \@SourceMaterial, \@ExtractionBatchID, \@SourcePCRPlate, 
		\@RunID, \@ProjectID);
#	neph_variables(@SampleID, @ExternalID, @SampleType, @SourceMaterial, @ExtractionBatchID, 
#		@SourcePCRPlate, \@AssayPlate_Neph, \@SampleID_Neph, \@Treatment_Neph, \@VialLab_Neph, \@ExtractBatch_Neph, \@Descrip_Neph);
#	FastQ_File($Nephpath, @RunID, @ProjectID, @SampleID, \@filename_R1, \@filename_R2);
#	FastQ_Man($Nephpath, $ProjName, $date, @SampleID_Neph, @Treatment_Neph, @SourceMaterial, @VialLab_Neph, @AssayPlate_Neph, 
#		@ExtractBatch_Neph, @Descrip_Neph, @filename_R1, @filename_R2);

##################################################################################################################
################################################# SUBROUTINES ####################################################
##################################################################################################################

#Creates variables of directories
sub qc_mb_dir {
	my $n=0; my $tempQC; my $tempMan;
	
	#Initiate variables
	my ($Proj_List, $MRName, $Proj_Num, $QCPath, $ManPath)=@_;
	foreach (@Proj_List){
		$$MRName = $Proj_List[$n];
		$$MRName =~ s/NP//g;
		$$MRName =~ s/-.*$//g;
		$$MRName = "MR-$$MRName";

		#Create pathway for QIIME Folder (QCPath) and Manifest (Manpath)
		$tempQC = "T:\\DCEG\\CGF\\Laboratory\\Projects\\$$MRName\\$$Proj_List[$n]\\QC Data";
		$tempMan = "T:\\DCEG\\CGF\\Laboratory\\Projects\\$$MRName\\$$Proj_List[$n]\\Analysis Manifests";
		$n++;
		push (@$QCPath, $tempQC);
		push (@$ManPath, $tempMan);
	}
}

#Creates Qiime and Nephele Directory, if necessary
sub Qiime_Neph_Dir {
	
	#Initialize variables
	my ($Nephpath, $date) = @_;
	my $qiime = "qiime";
	
	#Make Directories for qiime (unless already created)
	mkdir $qiime unless -d $qiime;


	#Create new Nephele directory
	my $nephele = "$date\_input";
	$CWD .= "\\$qiime";
	mkdir $nephele unless -d $nephele;
	$$Nephpath = "$CWD\\$nephele";
}

#Reads in Microbiome Manifest, and parses for data
sub read_MB_Man {
	#Initialize Variables
	my ($Proj_List, $ManPath, $StudyAns, $SampleID, $ExternalID, $SampleType, $SourceMaterial, $ExtractionBatchID, $SourcePCRPlate, 
		$RunID, $ProjectID) =@_;
	my $manifile; my $n=0;
	my @filedata; my @QCdata;

	foreach (@Proj_List){
		#$CWD = @$ManPath[$n];
		#print $CWD;
		#Create Manifest File name from Project Info;
		$manifile = $Proj_List[$n]; $manifile =~ s/\\//g;
		$manifile .= "-manifest.txt";

		#If filename not provided, give error message and close
		unless (open(READ_FILE, $manifile)) {
			print "Cannot open file $manifile provided\n\n";
			exit;
		}

		#Read in the file, and close
		@filedata= <READ_FILE>;
		close READ_FILE;
		
		#Create database with ("Y") or without ("N") study samples
		if ($StudyAns =~ "Y" || $StudyAns =~ "y") {
			foreach my $line (@filedata) {
				push (@QCdata, $line);
				next;
			}
		} else{ 
			foreach my $line (@filedata) {
				if ($line =~ m/Study/) {
					next;
				} elsif($line =~ m/SACCOMANNOFLUID/){
					next;
				} elsif($line =~ m/ORALRNS;TEBUFFER/){
					next;
				} else {
					push (@QCdata, $line);
					next;
				}
			}
		}

		#Create arrays with sample line data
		foreach (@QCdata) {
			my @columns = split('\t',$_);
			if(length $columns[7]>0){
				push(@$SampleID, $columns[0]);
				push(@$ExternalID, $columns[1]);
				push(@$SampleType, $columns[2]);
				push(@$SourceMaterial, $columns[3]);
				push(@$ExtractionBatchID, $columns[5]);
				push(@$SourcePCRPlate, $columns[6]);
				push(@$RunID,$columns[7]);
				push(@$ProjectID,$columns[9]);
			} else{next;}
		}
		$n++;
	}
}

#Creates variables needed for Neph Manifest
sub neph_variables{
	
	#Initialize variables
	my ($SampleID, $ExternalID, $SampleType, $SourceMaterial, $ExtractionBatchID, $SourcePCRPlate, 
		$AssayPlate_Neph, $SampleID_Neph, $Treatment_Neph, $VialLab_Neph, $ExtractBatch_Neph, $Descrip_Neph)=@_;
 	my @tempSampleID; my $n = 0;
	
	#Replace _ with . in Source PCR Plate and concatonate to Sample ID
	foreach my $line (@SourcePCRPlate) {
		$line =~ s/_/./g;
		$line =~ s/\.0/0/g;
		$line =~ s/\.1/1/g;
		push (@tempSampleID, $line);
	}
	
	#Format NTC and Water samples
	foreach my $line (@tempSampleID) {
		my $templine = $SampleID[$n];
		if($templine =~ m/NTC/){
			$templine = "NTC";
		} elsif($templine =~ m/Water/){
			$templine = "Water";
		} 
		$templine .= ".$line";
		push(@SampleID_Neph, $templine);
		$n++;
		next;
	}
	
	#Remove _ from Source PCR Plate and save PB# as AssayPlate for Nephele
	foreach my $line (@SourcePCRPlate) {
		$line =~ s/\..*//g;
		push (@AssayPlate_Neph, $line);
	}	

	#Assign Sample Type as treatment group
	foreach my $line (@SampleType){
		if($line =~ /ExtractionReplicate/){
			$line = "Extraction.Replicate";
		} elsif($line =~ /ExtractionBlank/){
			$line = "Extraction.Blank";
		} elsif($line =~/PCRNTCBlank/){
			$line = "PCRNTC";
		} elsif($line=~/PCRWaterBlank/){
			$line = "PCRWATER";
		} elsif($line=~/artificialcolony/){
			$line = "artificial.colony";
		}
		
		push (@Treatment_Neph, $line);
	}

	#Set External ID as Vial Label and format with ".", remove "_"
	foreach my $line (@ExternalID){
		$line =~ s/_/./g;
		push (@VialLab_Neph, $line);
	}
	
	#Set Extraction Batch ID as Extraction Batch
	@ExtractBatch_Neph = @ExtractionBatchID;

	#Set SourceMaterial as Description
	@Descrip_Neph = @SourceMaterial;
	
	#Remove the first headers from each array
	shift @SampleID_Neph;     shift @AssayPlate_Neph;
	shift @Treatment_Neph;	  shift @VialLab_Neph;
	shift @ExtractBatch_Neph; shift @Descrip_Neph;
}

#Creates paths for the FastQfiles and copies them into Nephele folder
sub FastQ_File{
	
	#Initialize Variables
	my ($Nephpath, $RunID, $ProjectID, $SampleID, $filename_R1, $filename_R2) =@_;
	my @foldernames; my @fastqpath;
	my $b = 0; my $c=0; my $n=1;
	my $FastP;

	#Remove first arraye element
	shift (@SampleID);

	#Create Folder Names from Sample ID's IF RunID is not blank (allows partial runs)
	foreach my $line(@SampleID) {
		my $Sample = "Sample_";
		$Sample .=$line;
		push (@foldernames, $Sample);
	}
	
	#Create Directory paths for all samples
	foreach my $line (@foldernames) {
		my $tempRun = $RunID[$n];
		my $tempProj= $ProjectID[$n];
		chomp $tempProj;
		
		#Create pathway for FastQ files, second pass
		$FastP = "T:\\DCEG\\CGF\\Sequencing\\Illumina\\MiSeq\\PostRun_Analysis\\Data\\$tempRun\\CASAVA\\L1\\Project_$tempProj\\$line\\";
		$FastP =~ s/_MB/-MB/g;
		push (@fastqpath, $FastP);
		$n++;
	}
	
	#Run through each directory, find paths for FASTQ Files
    foreach my $line (@fastqpath){

		#Open File Directory and copy fastq files
		opendir(DIR, $line) or die "Can't open directory $line!";
		my @files = grep {/_001\.fastq\.gz$/} readdir(DIR);
		closedir(DIR);

		#Read through each file of the directory
		for my $file (@files) {
							
			#If the file is an R1 FASTQ File, save
			if ($file =~ /R1/) {
                
				#Push file names and directory locations
				push(@filename_R1, $file);
			}
			
			#If the file is an R2 FASTQ File, save
			elsif ($file =~ /R2/){
                push(@filename_R2, $file);
			} else{next;}
		}
	}

	#Create copies and move FASTQ File to Nephele Folder
	opendir (NDIR, $Nephpath);
	foreach my $line(@fastqpath) {
		
		#Open directory with FastQ folders
		$CWD = $line;
		my $tempfile_R1 = $filename_R1[$b];
		my $tempfile_R2 = $filename_R2[$c];
	
	#Create loop for files to be copied and pasted to nephele
	#### copy ($tempfile_R1, $Nephpath) or die;
	#### copy ($tempfile_R2, $Nephpath) or die;
	####	$b++; $c++;
	}
	closedir(NDIR);
	print "\nCompleted moving FastQ files";
}

sub FastQ_Man {
	#Initialize Variables
	my ($Nephpath, $ProjName, $date, $SampleID_Neph, $Treatment_Neph, $VialLab_Neph, $AssayPlate_Neph, 
		$ExtractBatch_Neph, $Descrip_Neph, $filename_R1, $filename_R2)= @_;
	my $a =0;
	my @clean_R1; my @clean_R2;
	my @placeholder=("");
	
	#Create headers for text file
	my @headers = ("\#SampleID", "BarcodeSequence", "LinkerPrimerSequence", "ForwardFastqFile",
		"ReverseFastqFile", "TreatmentGroup", "VialLabel", "AssayPlate", "ExtractionBatch", "Description");
	
	#Create Nephele txt file in Nephele Directory
	$CWD = $Nephpath; my $newfile= "$ProjName\_Nephele_Input\_$date.txt";
	
	#Remove .gz from all FastQ files
	foreach my $file (@filename_R1) {
		$file =~ s/.gz//g;
		push  (@clean_R1, $file);
	} foreach my $file (@filename_R2) {
		$file =~ s/.gz//g;
		push  (@clean_R2, $file);
	}
	
	#Print data to Nephele txt file
	open (FILE, ">$newfile") or die;
		
		#Print headers to file
		print FILE join ("\t", @headers), "\n";
		
		#Print sample data to file for completed file lines only
		foreach my $sample (@SampleID_Neph) {
			my @temparray;
			push(@temparray, $SampleID_Neph[$a]);
			push(@temparray, $placeholder[0]);
			push(@temparray, $placeholder[0]);
			push(@temparray, $clean_R1[$a]);
			push(@temparray, $clean_R2[$a]);			
			push(@temparray, $Treatment_Neph[$a]);
			push(@temparray, $VialLab_Neph[$a]);
			push(@temparray, $AssayPlate_Neph[$a]);
			push(@temparray, $ExtractBatch_Neph[$a]);
			push(@temparray, $Descrip_Neph[0]);
			print FILE join("\t",@temparray), "\n";
			$a++;
		}
	print "\nFinished generating TXT file\n";
}

exit;

##################################################################################################################
################################################# Updates ####################################################
##################################################################################################################

##6/19/17: Changed the file GREP from .gz to include 001.fastq.gz to eliminate incorrect files from being copied
##6/20/17: Added a require install of chdir
##6/21/17: Add sample type to description column to ensure it is not left blank; Add validation to RunID length to allow for partial runs
##7/6/17: Modifications to print screens
##8/4/17: Changed MR input to search, allowed for second study input