#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;

my $vcfPattern = qr/\.vcf$|vcf.gz$/;
my $bamPattern = qr/\.bam$/;
my $fqPattern = qr/fastq\.gz$|fq\.gz$|fq$|fastq$/;

sub helpInfo() {
	print "Usage: \n";
	print "\tperl $0 <userName> <dirScanResult> <timeDuration>\n";
	print "\texample:\n";
	print "\tperl $0 fuxiangke fuxiangke.ds.tsv 365\n";
}

sub getByteSize(){
	my $fileSize = shift;
	my $size;
	if ($fileSize =~ /\(/){
		$fileSize =~ /\((\d+)\)/;
		$size = $1;
	}else {
		$fileSize =~ /(\d+)/;
		$size = $1;
	}
	return $size;
}

sub humanReadable() {
	my $size = shift;
	my $hrSize;
	my $idx = 0;
	while($size >= 1024) {
		$idx++;
		$size/=1024;
	}
	my @tags = qw(B K M G T P E);
	$hrSize = sprintf"%.4f", $size;
	$hrSize = $hrSize.$tags[$idx];
	return $hrSize;
}

sub report() {
	my ($user, $reportMD, $reportTsv, $totalSize,
	$fqTotalSize, $fqDurationSize, $vcfTotalSize,
	$vcfDurationSize, $bamTotalSize,
	$bamDurationSize) = @_;
	my $hrTotalSize = &humanReadable($totalSize);
	my $hrFqTotalSize = &humanReadable($fqTotalSize);
	my $hrFqDurationSize = &humanReadable($fqDurationSize);
	my $hrVcfTotalSize = &humanReadable($vcfTotalSize);
	my $hrVcfDurationSize = &humanReadable($vcfDurationSize);
	my $hrBamTotalSize = &humanReadable($bamTotalSize);
	my $hrBamDurationSize = &humanReadable($bamDurationSize);
	open RPT, "> $reportMD" or die $!;
	open TSV, "> $reportTsv" or die $!;
	print RPT <<"EOF";
| **User** | **TotalSize** | **VCFTotalSize**  | **VCFDurationSize** | **FQTotalSize** | **FQDurationSize** | **BAMTotalSize** | **BAMDurationSize** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| $user | $hrTotalSize | $hrVcfTotalSize | $hrVcfDurationSize | $hrFqTotalSize | $hrFqDurationSize | $hrBamTotalSize | $hrBamDurationSize |	
EOF
	print TSV "User\tTotalSize\tVCFTotalSize\tVCFDurationSize\tFQTotalSize\tFQDurationSize\tBAMTotalSize\tBAMDurationSize\n";
	printf TSV "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $user, $hrTotalSize, $hrVcfTotalSize, $hrVcfDurationSize, $hrFqTotalSize, $hrFqDurationSize, $hrBamTotalSize, $hrBamDurationSize;
	close RPT; close TSV;	
}
sub main() {
	if (@ARGV < 3) {
		&helpInfo && exit(0);
	}
	my ($user, $dsRet, $durationThreshold) = @ARGV;
	open IN, "< $dsRet" or die $!;
	my $totalSize = 0;
	my ($vcfTotalSize, $vcfDurationSize, $fqTotalSize, $fqDurationSize, $bamTotalSize, $bamDurationSize )= (0) x 6;
	my $inputParentDir = dirname($dsRet);
	my $vcfFilterTsv = File::Spec->catfile($inputParentDir, "vcf.tsv");
	my $fqFilterTsv = File::Spec->catfile($inputParentDir, "fastq.tsv");
	my $bamFilterTsv = File::Spec->catfile($inputParentDir, "bam.tsv");
	my $reportMD = File::Spec->catfile($inputParentDir, "report.md");
	my $reportTsv = File::Spec->catfile($inputParentDir, "report.tsv");
	open VCF, "> $vcfFilterTsv" or die $!;
	open FQ, "> $fqFilterTsv" or die $!;
	open BAM, "> $bamFilterTsv" or die $!;
	while(<IN>){
		chomp;
		my @cols = split/\t/, $_;
		my $size = &getByteSize($cols[1]);
		my $duration = $cols[-1];
		$totalSize += $size;
		my $eachFile;
		($eachFile = $cols[0]) =~ s/"//g; 
		if ($eachFile =~ $vcfPattern) {
			print VCF $_,"\n";
			$vcfTotalSize += $size;
			if ($duration >= $durationThreshold) {
				$vcfDurationSize += $size;
			}
		}elsif ($eachFile =~ $bamPattern) {
			print BAM $_,"\n";
			$bamTotalSize += $size;
			if ($duration >= $durationThreshold) {
				$bamDurationSize += $size;
			}
		}elsif ($eachFile =~ $fqPattern) {
			print FQ $_,"\n";
			$fqTotalSize += $size;
			if ($duration >= $durationThreshold) {
				$fqDurationSize += $size;
			}
		}
	}
	close IN; close VCF; close FQ; close BAM;
	&report($user, $reportMD, $reportTsv, $totalSize, $fqTotalSize, $fqDurationSize, $vcfTotalSize, $vcfDurationSize, $bamTotalSize, $bamDurationSize);
}

&main();
