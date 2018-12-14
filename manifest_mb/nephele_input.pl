#!/usr/bin/perl
# Name of file: microbiome.pl
# Owner: Samantha Sevilla
# Last Update: 4/23/18

######################################################################################
								##NOTES##
######################################################################################
###This script takes in the Project and MR number of a program and finds the associated MB Manifest, downloaded
###from LIMS. It then copies the fastq files of all QC samples and moves them to the Nephele folder. It creates
###the necessary txt file to input into Nephele.

######################################################################################
								##Main Code##
######################################################################################
use warnings;
use strict;
use Cwd;
use CPAN;
use File::chdir;
use File::Copy;

#Determine if the modules are up to date for user
eval "use File::chdir" 
	or do { 
		CPAN::install("File::chdir");
	};
	
#eval "use File::Copy" 
#	or do { 
#		CPAN::install("File::Copy");
#	};
	
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
	print "\nHave you downloaded the Microbiome manifest from LIMS (Y or N) ";
		my $ManiAns = <STDIN>; chomp $ManiAns;
		if($ManiAns =~ "N") {print "\n**Generate Microbiome Manifest for Project from LIMS, then re-run**\n";
			exit;}
	print "Do you only need the manifest? (Y or N) ";
		my $man_only = <STDIN>; chomp $man_only;
	print "Do you want to include study samples (Y or N)? ";
		my $StudyAns = <STDIN>; chomp $StudyAns;
	print "What is the date to assoicate with analysis(04_10_17)? ";
		my $date = <STDIN>; chomp $date;
	print "How many projects would you like to include? ";
		my $Proj_Num = <STDIN>; chomp $Proj_Num;
		until($Proj_Num == 0){
			print "What is the name of your project? (NP0452-MB3) ";
			my $ProjName = <STDIN>; chomp $ProjName;
			push(@Proj_List,$ProjName);
			$Proj_Num = $Proj_Num - 1;
		}

#Call subroutines
	qc_mb_dir(\@Proj_List, \$MRName, \$Proj_Num, \@QCPath, \@ManPath);
		$CWD = $QCPath[0];
	Neph_Dir(\$Nephpath, $date); 
		$CWD = $ManPath[0];
	read_MB_Man($StudyAns, @Proj_List, @ManPath, \@SampleID, \@ExternalID, \@SampleType, \@SourceMaterial, \@ExtractionBatchID, \@SourcePCRPlate, 
		\@RunID, \@ProjectID);
	neph_variables(@SampleID, @ExternalID, @SampleType, @SourceMaterial, @ExtractionBatchID, 
		@SourcePCRPlate, \@AssayPlate_Neph, \@SampleID_Neph, \@Treatment_Neph, \@VialLab_Neph, \@ExtractBatch_Neph, \@Descrip_Neph);
	FastQ_File($Nephpath, $man_only, @RunID, @ProjectID, @SampleID, \@filename_R1, \@filename_R2);
	FastQ_Man($Nephpath, $date, @Proj_List, @SampleID_Neph, @Treatment_Neph, @SourceMaterial, @VialLab_Neph, @AssayPlate_Neph, 
		@ExtractBatch_Neph, @Descrip_Neph, @filename_R1, @filename_R2);

######################################################################################
								##Subroutines##
######################################################################################

#Creates variables with directory names of the Manifest file location, and QIIME directory location
sub qc_mb_dir {

	#Initiate variables
	my ($Proj_List, $MRName, $Proj_Num, $QCPath, $ManPath)=@_;
	my $n=0; my $tempQC; my $tempMan;
	
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

#Creates Nephele Directory, if necessary using variables created in QC_MB_DIR
sub Neph_Dir {
	
	#Initialize variables
	my ($Nephpath, $date) = @_;
	my $nephele = "nephele";
	
	#Make Directories for nephele (unless already created)
	mkdir $nephele unless -d $nephele;

	#Create new Nephele directory
	my $nephele_vers = "$date\_input";
	$CWD .= "\\$nephele";
	mkdir $nephele_vers unless -d $nephele_vers;
	$$Nephpath = "$CWD\\$nephele_vers";
}

#Reads in Microbiome Manifest, and parses for data
sub read_MB_Man {
	
	#Initialize Variables
	my ($StudyAns, $Proj_List, $ManPath, $SampleID, $ExternalID, $SampleType, $SourceMaterial, 
		$ExtractionBatchID, $SourcePCRPlate, $RunID, $ProjectID) =@_;
	my $manifile=""; my $n=0;
	my @filedata; my @QCdata;

	#Create a loop for each Study included, to read in manifest and save data into array variables
	foreach (@Proj_List){
		$CWD = $ManPath[$n];
		
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
		if (lc $StudyAns eq lc "Y") {
			foreach my $line (@filedata) {
				push (@QCdata, $line);
				next; 
			}
		} else{ 
			for(my $i=0; $i < @filedata; $i++) {
				if ($filedata[$i] =~ m/Study/) {
					next;
				} elsif($filedata[$i] =~ m/SACCOMANNOFLUID/){
					next;
				} elsif($filedata[$i] =~ m/ORALRNS_TEBUFFER/){
					next;
				} elsif($filedata[$i] =~ m/ExtractionReplicate/){
					push(@QCdata,$filedata[$i-1]); ##To include the study matches for replicate sample
					push(@QCdata,$filedata[$i]);
				} else {
					push (@QCdata, $filedata[$i]);
					next;
				}
			}
		} 
		shift @QCdata;

		#Create arrays with sample line data separated by tabs
		foreach (@QCdata) {
			my @columns = split('\t',$_);
			if(length $columns[7]>0){
				push(@SampleID, $columns[0]);
				push(@ExternalID, $columns[1]);
				push(@SampleType, $columns[2]);
				push(@SourceMaterial, $columns[3]);
				push(@ExtractionBatchID, $columns[5]);
				push(@SourcePCRPlate, $columns[6]);
				push(@RunID,$columns[7]);
				push(@ProjectID,$columns[9]);
			} else {next;}
		}
		
		#Move through studys, clearing QC data to avoid repeats
		$n++; @QCdata=();
	}
}

#Creates variables needed for Neph Manifest
sub neph_variables{
	
	#Initialize variables
	my ($SampleID, $ExternalID, $SampleType, $SourceMaterial, $ExtractionBatchID, $SourcePCRPlate, $AssayPlate_Neph, $SampleID_Neph, $Treatment_Neph, $VialLab_Neph, $ExtractBatch_Neph, $Descrip_Neph)=@_;
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

	#Format treatment groups and assign
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
		} push (@Treatment_Neph, $line);
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
}

#Creates paths for the FastQfiles and copies them into Nephele folder
sub FastQ_File{
	
	#Initialize Variables
	my ($Nephpath, $man_only, $RunID, $ProjectID, $SampleID, $filename_R1, $filename_R2) =@_;
	my @foldernames; my @fastqpath;
	my $b = 0; my $c=0; my $n=0; my $FastP;

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
	print "\n****************************** \nMoving Files\n";
	
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
	if($man_only=~'N'){
		opendir (NDIR, $Nephpath);
		foreach my $line(@fastqpath) {
			
			#Open directory with FastQ folders
			$CWD = $line;
			my $tempfile_R1 = $filename_R1[$b];
			my $tempfile_R2 = $filename_R2[$c];
		
		#Create loop for files to be copied and pasted to nephele
			copy ($tempfile_R1, $Nephpath) or die;
			copy ($tempfile_R2, $Nephpath) or die;
			$b++; $c++;
		}
		closedir(NDIR);
		print "\nCompleted moving FastQ files";
	}
}

#Creates the Manifest for Nephele input
sub FastQ_Man {
	#Initialize Variables
	my ($Nephpath, $date, @Proj_List, $SampleID_Neph, $Treatment_Neph, $VialLab_Neph, $AssayPlate_Neph, 
		$ExtractBatch_Neph, $Descrip_Neph, $filename_R1, $filename_R2)= @_;
	my $n =0; 
	
	#Create headers for text file
	my @headers = ("\#SampleID", "ForwardFastqFile", "ReverseFastqFile", "TreatmentGroup", "VialLabel", "AssayPlate", "ExtractionBatch", "Description");
	
	#Create Nephele txt file in Nephele Directory
	$CWD = $Nephpath; my $newfile= "$Proj_List[0]\_Nephele_Input\_$date.txt";
	
	#Print data to Nephele txt file
	open (FILE, ">$newfile") or die;
		
		#Print headers to file
		print FILE join ("\t", @headers), "\n";
		
		#Print sample data to file for completed file lines only
		foreach my $sample (@SampleID_Neph) {
			my @temparray;
			
			#Convert "-" in sample ID to "."
			my $temp = $SampleID_Neph[$n];
			$temp =~ s/-/./g;
			push(@temparray, $temp);
			
			#Add remaining columns
			push(@temparray, $filename_R1[$n]);
			push(@temparray, $filename_R2[$n]);
			push(@temparray, $Treatment_Neph[$n]);
			push(@temparray, $VialLab_Neph[$n]);
			push(@temparray, $AssayPlate_Neph[$n]);
			push(@temparray, $ExtractBatch_Neph[$n]);
			push(@temparray, $Descrip_Neph[0]);
			print FILE join("\t",@temparray), "\n";
			$n++;
		}
	#Confirmations
	print "\n\n******************************\nFinished generating TXT file\n";
	
	my $total = scalar @SampleID_Neph*2;
	print "\n******************************\nThere should be $total FASTQ files in the folder\n\n";
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
##8/6/17: Continued with 8/4 changes, fixed bugs for second and third study input
##9/11/17: Added feature to compare Study sample that pairs with Extraction Replicate
##4/23/18: Added option to only create manifest file
##12/4/18: Formatting edits to initial questions, remove testing information
##12/6/18: Disable eval of File::Copy until new perl module downloaded, add confirmations to file moving, and final file count
		# Updated Manifest subroutine to match new Nephele file parameters 
		## 1)remove Barcode and Linker Seq columns
		## 2) change all "-" in sample ID to "."
		## 3) remove code that previously removed .gz from file name of FastQ - required now
##12/13/18: Change directory name from qiime to nephele