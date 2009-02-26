#!/usr/bin/perl

$/="<pre>";
@content=<>;
shift @content;
for $i(@content){
	$i=~s/pre>.+//sm;
	$i=~s/&/&amp;/g;
	$i=~s/>/&gt;/g;
	$i=~s/</&lt;/g;
	@lines=split ",\n",$i;
	my %dict=();
	while(scalar(@lines)>0){
		$line=shift @lines;
		if($line=~m/^\@Article/){
			$key="tex_key";
			@tmp=split "{",$line;
			$value=$tmp[1];
		}else{
			while($line!~m/"$/ && scalar(@lines)>0){
				$line.=", ";
				$line.=shift @lines;
			}
			($key,$value)=($line=~m/([A-Za-z]+) += +"(.+)"/sm );			
		}
		next if($key eq "");
		$value=~s/\n/ /;
		$value=~s/ +/ /g;
		$value=~s/[{}]//g;
		$dict{$key}=$value;
#		print "$key,$value\n";
	}
	push @data, \%dict;
}

print <<EOF;
<?xml version="1.0"?>
<results>
EOF

for $i (@data){
	next unless exists $i->{title};
	print <<EOF;
<document>
EOF
	if(exists $i->{title}){
		print "<title>". $i->{title}. "</title>\n";
	}
	if(exists $i->{author}){
		@authors=split " and ", $i->{author};
		print "<authaffgrp>\n";
		for $a(@authors){
			print "<author>$a</author>\n";
		}
		print "</authaffgrp>\n";
	}
	if(exists $i->{eprint}){
		$x=$i->{eprint};
		if($x=~/^[01-9]/){
			$x = "arXiv:". $x;
		}
		print "<eprint>$x</eprint>\n"
	}elsif(exists $i->{SLACcitation}){
		$x=$i->{SLACcitation};
		$x=~/CITATION += +(.+);/;
		$y=$1;
		print "<spicite>$y</spicite>\n";
	}
	if(exists $i->{doi}){
		print "<doi>". $i->{doi}. "</doi>\n";
	}
	if(exists $i->{journal}){
		$j=$i->{journal};
		$j=~s/\. /./g;
		$v=$i->{volume};
		$y=$i->{year};
		$p=$i->{pages};
		print "<journal><name>$j</name><volume>$v</volume><page>$p</page><year>$y</year></journal>\n";
	}
	print <<EOF;
</document>
EOF
	
}
print <<EOF;
</results>
EOF
