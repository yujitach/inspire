var htmlTeXRegExps=[
["([^\\\\$])\\^([-\\d]+)","$1<sup>$2</sup>"],
["([^\\\\$])\\^\\(([^\\})]*)\\)","$1<sup>$2</sup>"],
["([^\\\\$])\\^\\{([^\\}]*)\\}","$1<sup>$2</sup>"],
["([^\\\\$])\\^([^\\{\\} ]+)","$1<sup>$2</sup>"],
["([^\\\\$])\\^(.)","$1<sup>$2</sup>"],
["([^\\\\$])_([-\\d]+)","$1<sub>$2</sub>"],
["([^\\\\$])_\\(([^\\})]*)\\)","$1<sub>$2</sub>"],
["([^\\\\])_\\{([^\\}]*)\\}","$1<sub>$2</sub>"],
["([^\\\\$])_([^\\{\\} ]+)","$1<sub>$2</sub>"],
["([^\\\\])_(.)","$1<sub>$2</sub>"],
["\\{\\\\cal (.+?)\\}","<span style=\"font-family:Apple-Chancery\">$1</span>"],
["N *= *([01-9]+)","<span style=\"font-style:italic\">N</span>=$1"],
["\\{\\\\rm (.+?)\\}","$1"],
["\\\\cal\\{(.+?)\\}","<span style=\"font-family:Apple-Chancery\">$1</span>"],
["\\\\rm\\{(.+?)\\}","$1"],
["\\\\'([aeiou])","&$1acute;"],
["\\\\\"([aeiou])","&$1uml;"],
["\\$([^\\$]+)\\$","<span class=\"equation\">$1</span>"],
["&lt;-&gt;","↔"],
["\\\\v\\{r\\}","ř"],
["\\\\v\\{c\\}","č"],
["-+&gt;","→"],
["\\\\v r","ř"],
["\\\\v c","č"],
["-&gt;","→"],
["&lt;→","↔"],
["\\{\\}","<span></span>"],
["\\*\\*","^"],
["\\+-","±"],
["-+>","→"],
[" x ","×"],
["``","“"],
["''","”"],
];
var htmlTeXMacrosWithoutArguments={
    "zeta" : "ζ",
    "xi" : "ξ",
    "wedge" : "∧",
    "vee" : "∨",
    "upsilon" : "υ",
    "to" : "→",
    "times" : "×",
    "theta" : "θ",
    "tau" : "τ",
    "sqrt" : "√",
    "sim" : "〜",
    "sigma" : "σ",
    "rightarrow" : "→",
    "rho" : "ρ",
    "psi" : "ψ",
    "propto" : "<span style=\"font-size:175%\">∝</span>",
    "prod" : "Π",
    "prime" : "'",
    "pm" : "±",
    "pi" : "π",
    "phi" : "φ",
    "perp" : "⟂",
    "partial" : "∂",
    "over" : "/",
    "otimes" : "⊗",
    "oplus" : "⊕",
    "omega" : "ω",
    "odot" : "⊙",
    "nu" : "ν",
    "neq" : "≠",
    "ne" : "≠",
    "mu" : "μ",
    "mp" : "∓",
    "lsim" : "≲",
    "ll" : "≪",
    "leq" : "≤",
    "leftrightarrow" : "↔",
    "leftarrow" : "←",
    "le" : "≤",
    "lambda" : "λ",
    "kappa" : "κ",
    "iota" : "ι",
    "int" : "∫",
    "infty" : "∞",
    "in" : "∈",
    "hbar" : "ħ",
    "gsim" : "≳",
    "gg" : "≫",
    "geq" : "≥",
    "ge" : "≥",
    "gamma" : "γ",
    "eta" : "η",
    "equiv" : "≡",
    "epsilon" : "ε",
    "ell" : "ℓ",
    "delta" : "δ",
    "circ" : "o",
    "chi" : "χ",
    "beta" : "β",
    "approx" : "≈",
    "alpha" : "α",
    "Zeta" : "Ζ",
    "Xi" : "Ξ",
    "Upsilon" : "Υ",
    "Theta" : "Θ",
    "Tau" : "Τ",
    "Sigma" : "Σ",
    "Rho" : "Ρ",
    "Psi" : "Ψ",
    "Pi" : "Π",
    "Phi" : "Φ",
    "Omega" : "Ω",
    "Nu" : "Ν",
    "Mu" : "Μ",
    "Lambda" : "Λ",
    "Kappa" : "Κ",
    "Iota" : "Ι",
    "Gamma" : "Γ",
    "Eta" : "Η",
    "Epsilon" : "Ε",
    "Delta" : "Δ",
    "Chi" : "Χ",
    "Beta" : "Β",
    "Alpha" : "Α"
};
var htmlTeXMacrosWithOneArgument={
    "bar" : "<span class=\"overline\">$1</span>",
    "textrm" : "$1",
    "mathrm" : "$1",
    "mathbf" : "<i><b>$1</b></i>",
    "mathbb" : "<span style=\"font-family:msbm5\">$1</span>",
    "mathcal" : "<span style=\"font-family:Apple-Chancery\">$1</span>",
    "emph" : "<b>$1</b>",
    "text" : "$1",
    "overline" : "<span class=\"overline\">$1</span>"
};
var htmlTeXMacrosWithoutArgumentsWhichRequireBackSlash=
[
 "ll",
 "gg",
 "times",
 "over",
 "prime",
 "Pi",
 "partial"
];
var prepositions=[
		  "a",
		  "among",
		  "and",
		  "an",
		  "are",
		  "as",
		  "at",
		  "by",
		  "during",
		  "for",
		  "from",
		  "in",
		  "into",
		  "is",
		  "of",
		  "on",
		  "over",
		"le",
		"la",
		"les",
		  "the",
		  "to",
		  "via",
		  "with",
		  "without"
		  ];
function texify(s){
    s.replace(/\\ /g,"SpaceMarker");
    s.replace(/\\_/g,"UnderscoreMarker");
    
    var from,to;
    for(key in htmlTeXMacrosWithoutArguments){
	from=new RegExp("\\\\"+key,"g");
	to=htmlTeXMacrosWithoutArguments[key];
	s=s.replace(from,to);
	s=s.replace(from,to);
	if(prepositions.indexOf(key)==-1 && 
	   htmlTeXMacrosWithoutArgumentsWhichRequireBackSlash.indexOf(key)==-1){
	    from=new RegExp("([^A-Za-z])"+key+"([^A-Za-z])","g");
	    to="$1"+to+"$2";
	    s=s.replace(from,to);
	    s=s.replace(from,to);
	}
    }    
    
    
    for(key in htmlTeXMacrosWithOneArgument){
	from=new RegExp("\\\\"+key+" +(.)","g");
	to=htmlTeXMacrosWithOneArgument[key];
	s=s.replace(from,to);
	s=s.replace(from,to);
	s=s.replace(from,to);
	s=s.replace(from,to);
	from=new RegExp("\\\\"+key+"\\{(.+?)\\}","g");
	to=htmlTeXMacrosWithOneArgument[key];
    }    
    
    for(i=0;i<htmlTeXRegExps.length;i++){
	pair=htmlTeXRegExps[i];
	from=new RegExp(pair[0],"g");
	to=pair[1];
	s=s.replace(from,to);
    }	
    
    s.replace(/UnderscoreMarker/g,"_");
    s.replace(/SpaceMarker/g," ");
    return s;
}
function batchTeXify(a){
    var i,s;
    for(i in a){
	s=a[i].innerHTML;
	if(s){
	    a[i].innerHTML=texify(s);
	}
    }
    return "";
}
batchTeXify(document.getElementsByClassName("list-title"));
batchTeXify(document.getElementsByClassName("abstract"));
batchTeXify(document.getElementsByClassName("title"));
batchTeXify(document.getElementsByTagName("p"));
