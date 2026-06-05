#!/usr/bin/perl -w
use strict;
use File::Basename;
use File::Spec;

my $vcfPattern = qr/\.vcf$|vcf.gz$/;
my $bamPattern = qr/\.bam$/;
my $fqPattern = qr/fastq\.gz$|fq\.gz$|fq$|fastq$/;
my $arrowPattern = qr/\.arrow$/;

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
	$bamDurationSize, $arrowTotalSize, $arrowDurationSize) = @_;
	my $hrTotalSize = &humanReadable($totalSize);
	my $hrFqTotalSize = &humanReadable($fqTotalSize);
	my $hrFqDurationSize = &humanReadable($fqDurationSize);
	my $hrVcfTotalSize = &humanReadable($vcfTotalSize);
	my $hrVcfDurationSize = &humanReadable($vcfDurationSize);
	my $hrBamTotalSize = &humanReadable($bamTotalSize);
	my $hrBamDurationSize = &humanReadable($bamDurationSize);
	my $hrArrowTotalSize = &humanReadable($arrowTotalSize);
	my $hrArrowDurationSize = &humanReadable($arrowDurationSize);
	open RPT, "> $reportMD" or die $!;
	open TSV, "> $reportTsv" or die $!;
	print RPT <<"EOF";
| **User** | **TotalSize** | **VCFTotalSize**  | **VCFDurationSize** | **FQTotalSize** | **FQDurationSize** | **BAMTotalSize** | **BAMDurationSize** | **ArrowTotalSize** | **ArrowDurationSize** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| $user | $hrTotalSize | $hrVcfTotalSize | $hrVcfDurationSize | $hrFqTotalSize | $hrFqDurationSize | $hrBamTotalSize | $hrBamDurationSize | $hrArrowTotalSize | $hrArrowDurationSize |
EOF
	print TSV "User\tTotalSize\tVCFTotalSize\tVCFDurationSize\tFQTotalSize\tFQDurationSize\tBAMTotalSize\tBAMDurationSize\tArrowTotalSize\tArrowDurationSize\n";
	printf TSV "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $user, $hrTotalSize, $hrVcfTotalSize, $hrVcfDurationSize, $hrFqTotalSize, $hrFqDurationSize, $hrBamTotalSize, $hrBamDurationSize, $hrArrowTotalSize, $hrArrowDurationSize;
	close RPT; close TSV;	
}
sub main() {
	if (@ARGV < 3) {
		&helpInfo && exit(0);
	}
	my ($user, $dsRet, $durationThreshold) = @ARGV;
	open IN, "< $dsRet" or die $!;
	my $totalSize = 0;
	my ($vcfTotalSize, $vcfDurationSize, $fqTotalSize, $fqDurationSize, $bamTotalSize, $bamDurationSize, $arrowTotalSize, $arrowDurationSize )= (0) x 8;
	my $inputParentDir = dirname($dsRet);
	my $vcfFilterTsv = File::Spec->catfile($inputParentDir, "vcf.tsv");
	my $fqFilterTsv = File::Spec->catfile($inputParentDir, "fastq.tsv");
	my $bamFilterTsv = File::Spec->catfile($inputParentDir, "bam.tsv");
	my $arrowFilterTsv = File::Spec->catfile($inputParentDir, "arrow.tsv");
	my $reportMD = File::Spec->catfile($inputParentDir, "report.md");
	my $reportTsv = File::Spec->catfile($inputParentDir, "report.tsv");
	my $dupListTsv = File::Spec->catfile($inputParentDir, "dup.list.tsv");
	open VCF, "> $vcfFilterTsv" or die $!;
	open FQ, "> $fqFilterTsv" or die $!;
	open BAM, "> $bamFilterTsv" or die $!;
	open ARROW, "> $arrowFilterTsv" or die $!;
	open DUP, "> $dupListTsv" or die $!;
	my %dupHash;
	while(<IN>){
		chomp;
		my @cols = split/\t/, $_;
		my $size = &getByteSize($cols[1]);
		my $duration = $cols[-1];
		$totalSize += $size;
		my $eachFile;
		($eachFile = $cols[0]) =~ s/"//g; 
		my $fileName = basename($eachFile);
		push @{$dupHash{$fileName}{$size}}, $eachFile;
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
		}elsif ($eachFile =~ $arrowPattern) {
			print ARROW $_,"\n";
			$arrowTotalSize += $size;
			if ($duration >= $durationThreshold) {
				$arrowDurationSize += $size;
			}
		}
	}
	close IN; close VCF; close FQ; close BAM; close ARROW;
	&report($user, $reportMD, $reportTsv, $totalSize, $fqTotalSize, $fqDurationSize, $vcfTotalSize, $vcfDurationSize, $bamTotalSize, $bamDurationSize, $arrowTotalSize, $arrowDurationSize);
	print DUP "DupSize\tSize(bytes)\tFilePathList\n";
	while (my ($fn, $sizeHashPtr) = each %dupHash) {
		while (my ($size, $fileListPtr) = each %$sizeHashPtr) {
			next if (@$fileListPtr <= 1);
			my $dupNum = scalar(@$fileListPtr);
			my $fileListStr = join(",", @$fileListPtr);
			print DUP "$dupNum\t$size\t$fileListStr\n";
		}
	}
	close DUP;
}

&main();
