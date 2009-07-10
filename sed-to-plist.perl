print <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>magicRegExps</key>
<array>
EOF
while(<>){
	($dummy,$a,$b)=split "/";
	$a=~s/&/&amp;/g;
	$b=~s/&/&amp;/g;
	print "<array><string>$a</string><string>$b</string></array>\n";
}
print <<EOF;
</array>
</dict>
</plist>
EOF
