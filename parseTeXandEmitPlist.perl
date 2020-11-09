#!/usr/bin/perl
use strict;
our @bibs;
our @inputs;
our %mapping;
our %definition;
our $list;
our $bib;
our $title;
our $refresh="NO";
our $isbibtex="NO";
our $bibtexfile;
undef $/;
my $tex=<>;
$tex=~s/\r//smg;
@bibs=listidentifiers($tex);
@inputs=listinputs($tex);
listmapsanddefs($tex);
getbibtexinfo($tex);
emitplist();

sub getbibtexinfo{
	my $src=shift;
	if($src=~/\\bibliography\{(.+?)\}/){
		$isbibtex="YES";
		$bibtexfile=$1;
	}
}
sub listidentifiers{
	my $src=shift;
	$src=~s/%.+?\n//g;
	$src=~s/\\citen/\\cite/g;
	my %test;
	my @bibs;
        my @candidates=($src=~m/cite(?:\[.+?\]|)\{(.+?)\}/g);
	for my $i(@candidates){
		my @subcan=split ",",$i;
		for my $j(@subcan){
			$j=~s/^[ \n\r]+//g;
			unless(exists $test{$j}){
				push @bibs, $j;
				$test{$j}=$j;
			}
		}
	}
#    for my $i  ( split "cite{", $src  ){
#		$i=~/^([^}]+)}/;
#		next if $i=~/^\\/;
#		for(split ",", $1){
#			$_=~s/^[ \n\r]+//g;
#	    	unless (exists $test{$_}){
#				push @bibs, $_ ;
##				print "$_,";
#				$test{$_}=$_;
#	    	}
#		}
#    }
	return @bibs;
}

sub listinputs{
    my $src=shift;
    $src=~s/%.+?\n//g;
    my @i=($src=~/input\{([^\}]+)\}/g);
    my @j=($src=~/include\{([^\}]+)\}/g);
    my @inputs=(@i,@j);
	return @inputs;
}
sub listmapsanddefs{
	my $src=shift;
	my @lines=split "\n",$src;
	for my $line (@lines){
		if($line=~/^%%map/){
			my ($from,$to)=($line=~/^%% *map[a-z]*[ \t]+(.+?)[ \t=]+(.+)[ \t]*$/);
			$mapping{$from}=$to;
		}
		if($line=~/^%%def/){
			my ($from,$to)=($line=~/^%% *def[a-z]*[ \t]+(.+?)[ \t=]+(.+)$/);
			$definition{$from}=$to
		}
		if($line=~/^%%list/){
			($list)=($line=~/^%% *list[ \t]+(.+)[ \t]*$/);
		}
	    if($line=~/^%%title/){
		($title)=($line=~/^%% *title[ \t]+(.+)[ \t]*$/);
	    }
	    if($line=~/^%%out/){
			($bib)=($line=~/^%% *out[a-z]*[ \t]+(.+)[ \t]*$/);
		}
	    if($line=~/^%%refresh/){
		($refresh)=($line=~/^%% *refresh*[ \t]+(.+)[ \t]*$/);	
		$refresh=~tr/a-z/A-Z/;
	    }
	}
}
sub emitplist{
	print <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>citationsInOrder</key>
<array>
EOF
	for my $i (@bibs){
		print "\t<string>$i</string>\n";
	}
	print <<EOF;
</array>
<key>inputs</key>
<array>
EOF
    for my $i (@inputs){
	print "\t<string>$i</string>\n";
    }
    print <<EOF;
</array>
<key>mappings</key>
<dict>
EOF
	for my $key (keys %mapping){
		print "\t<key>$key</key>\n";
		my $s=escaped($mapping{$key});
		print "\t<string>$s</string>\n"
	}
	print <<EOF;
</dict>
<key>definitions</key>
<dict>
EOF
	for my $key (keys %definition){
		print "\t<key>$key</key>\n";
		my $s=escaped($definition{$key});
		print "\t<string>$s</string>\n"
	}
	print <<EOF;
</dict>
<key>listName</key>
<string>$list</string>
<key>outputFile</key>
<string>$bib</string>
<key>articleTitle</key>
<string>$title</string>
<key>forceRefresh</key>
<string>$refresh</string>
<key>isBibTeX</key>
<string>$isbibtex</string>
<key>BibTeXFile</key>
<string>$bibtexfile</string>
</dict>
</plist>
EOF
}

sub escaped{
	my $s=shift;
	$s=~s/\&/\&amp;/g;
	$s=~s/>/\&gt;/g;
	$s=~s/</\&lt;/g;
	return $s;
}
