var htmlTeXRegExps=[
// Double superscript (not complete)
//["([^\\\\$])\\^\\{([^\\}\\^]+?)^\\{([^\\}\\^]+?)\\}([^\\}\\^]*?)\\}","$1<sup>$2<sup>$3</sup>$4</sup>"],
["([^\\\\$\\\\])\\^\\{([^\\}\\^]+?)^\\{([^\\}\\^]+?)\\}([^\\}\\^]*?)\\}","$1<sup>$2<sup>$3</sup>$4</sup>"],
// Double subscript (not complete)
["([^\\\\$])_\\{([^\\}\\_]+?)_\\{([^\\}\\_]+?)\\}([^\\}\\^]*?)\\}","$1<sub>$2<sub>$3</sub>$4</sub>"],
// SUP: Interpret parentheses, $^something$, typefaces (HTML tags)
["([^\\\\$])\\^\\{([^\\}]+?)\\}","$1<sup>$2</sup>"],
["([^\\\\$])\\^\\(([^\\)]+?)\\)","$1<sup>$2</sup>"],
["\\$\\^([^$]+)\\$","<sup>$1</sup>"],
["([^\\\\$])\\^<span (.*?)>(.*?)</span>","$1<sup><span $2>$3</span></sup>"],
// Interpret naive TeX codes
["([^\\\\$])\\^([0-9]+)","$1<sup>$2</sup>"],
["([^\\\\$])\\^([a-z]+)","$1<sup>$2</sup>"],
["([^\\\\$])\\^([A-Z]+)","$1<sup>$2</sup>"],
// For X^\omega, X^\Omega, X^*, X^+, X^-
["([^\\\\$])\\^(\\\\[a-z]+)","$1<sup>$2</sup>"],
["([^\\\\$])\\^(\\\\[A-Z][a-z]+)","$1<sup>$2</sup>"],
["([^\\\\$])\\^([*+-]+)","$1<sup>$2</sup>"],
// X^< and X^> compatible with HTML tags?
["([^\\\\$])\\^([<>]+)","$1<sup>$2</sup>"],
/* DELETED: Everything except for spaces
["([^\\\\$])\\^([\\S]+)","$1<sup>$2</sup>"],
*/
// SUB: Interpret parentheses, $^something$, typefaces (HTML tags)
["([^\\\\])_\\{([^\\}]+?)\\}","$1<sub>$2</sub>"],
["([^\\\\$])_\\(([^\\)]+?)\\)","$1<sub>$2</sub>"],
["\\$_([^$]+)\\$","<sub>$1</sub>"],
["([^\\\\$])_<span (.*?)>(.*?)</span>","$1<sub><span $2>$3</span></sub>"],
// Interpret naive TeX codes
["([^\\\\$])_([0-9]+)","$1<sub>$2</sub>"],
["([^\\\\$])_([a-z]+)","$1<sub>$2</sub>"],
["([^\\\\$])_([A-Z]+)","$1<sub>$2</sub>"],
// For X_\omega, X_\Omega, X_*, X_+, X_-
["([^\\\\$])_(\\\\[a-z]+)","$1<sub>$2</sub>"],
["([^\\\\$])_(\\\\[A-Z][a-z]+)","$1<sub>$2</sub>"],
["([^\\\\$])_([*+-]+)","$1<sub>$2</sub>"],
// X_< and X_> compatible with HTML tags?
["([^\\\\$])_([<>]+)","$1<sub>$2</sub>"],
/* DELETED: Everything except for spaces
["([^\\\\$])_([\\S]+)","$1<sub>$2</sub>"],
*/
//["\\\\acute\\{\\\\text\\{a\\}\\}","á"],
["N *= *([01-9]+)","<span style=\"font-style:italic\">N</span>=$1"],
["\\\\'([aeiou])","&$1acute;"],
["\\\\\\^([aeiouy])","&$1circ;"],
["\\\\`([aeiou])","&$1grave;"],
["\\\\\"([aeiou])","&$1uml;"],
["\\\\\"\\{([aeiou])\\}","&$1uml;"],
// To rip off extra $'s
["\\$([^\\$]+)\\$","<span class=\"equation\">$1</span>"],
["&lt;-&gt;","↔"],
["\\\\v\\{r\\}","ř"],
["\\\\v\\{c\\}","č"],
["\\\\v\\{C\\}","Č"],
["-+&gt;","→"],
["\\\\v r","ř"],
["\\\\v c","č"],
["\\\\v C","Č"],
["\\\\'y","ý"],
["\\\\ae","æ"],
["-&gt;","→"],
["&lt;→","↔"],
["\\{\\}","<span></span>"],
["\\*\\*","^"],
["\\+-","±"],
["\\+/-","±"],
["---","&mdash;"],
/* DELETED: We need -- as it is.
["--","&ndash;"],
*/
["-+>","→"],
[" x ","×"],
["``","“"],
["''","”"],
[" *\\\\, *"," "],
["\\\\ast","*"],
];
var htmlTeXMacrosWithoutArguments={
    "zeta" : "ζ",
    "xi" : "ξ",
    "wedge" : "∧",
	"vert" : "|",
	"vee" : "∨",
	"varphi" : "φ",
	"varkappa" : "κ",
    "upsilon" : "υ",
    "to" : "→",
	"times" : "×",
    "theta" : "θ",
    "tau" : "τ",
	"supset" : "⊃",
	"sum" : "∑",
	"subset" : "⊂",
    "ss" : "ß",
    "sqrt" : "√",
    "simeq" : "<span style=\"font-size:150%\">≃</span>",
    "sim" : "〜",
    "sigma" : "σ",
    "rightarrow" : "→",
	"uparrow" : "↑",
	"downarrow" : "↓",	
    "rho" : "ρ",
	"rangle" : "⟩",
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
    "nabla" : "∇",
    "mu" : "μ",
    "mp" : "∓",
    "lesssim" : "≲",
	"langle" : "⟨",
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
    "gtrsim" : "≳",
    "gsim" : "≳",
    "gg" : "≫",
    "geq" : "≥",
    "ge" : "≥",
    "gamma" : "γ",
    "eta" : "η",
    "equiv" : "≡",
    "epsilon" : "ε",
    "varepsilon" : "ε",
    "ell" : "ℓ",
    "delta" : "δ",
    "circ" : "o",
    "cup" : "∪",
    "chi" : "χ",
    "cap" : "∩",
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
    "Bmu" : "Βμ",
    "Beta" : "Β",
    "Alpha" : "Α",
    "AA" : "Å",
    "Box" : "<span style=\"font-size:150%\">□</span>",
    "cdot" : "•",
};
var htmlTeXMacrosWithOneArgument={
    "bar" : "<span class=\"overline\">$1</span>",
    "overline" : "<span class=\"overline\">$1</span>",
    "mathrm" : "<span style=\"font-style:normal;\">$1</span>",  
    "mathbf" : "<span style=\"font-weight:bold\">$1</span>",
/* Why bf and it?
    "mathbf" : "<i><b>$1</b></i>",
    "textbf" : "<i><b>$1</b></i>", */
    "mathbb" : "<span style=\"font-family:msbm5\">$1</span>",
    "mathcal" : "<span style=\"font-family:Apple-Chancery\">$1</span>",
    "emph" : "<span style=\"font-weight:bold\">$1</span>",
//    "emph" : "<b>$1</b>",
    "text" : "<span style=\"font-style:normal;\">$1</span>",  
    "textrm" : "<span style=\"font-style:normal;\">$1</span>",  
    "textbf" : "<span style=\"font-weight:bold\">$1</span>",
    "textit" : "<span style=\"font-style:italic;\">$1</span>",
    "cite" : "[$1]"
};
var htmlTeXMacrosTypeface={
//  "rm" : "<span style=\"font-family:default; font-style:normal;\">$1</span>", 
    "rm" : "<span style=\"font-style:normal;\">$1</span>",  
    "bf" : "<span style=\"font-weight:bold\">$1</span>",
    "it" : "<span style=\"font-style:italic;\">$1</span>",
    "bb" : "<span style=\"font-family:msbm5\">$1</span>",
    "cal" : "<span style=\"font-family:Apple-Chancery\">$1</span>"
};
var htmlTeXMacrosLeftParentheses={
    "\\(" : "<span style=\"font-size: large\">(</span>",
    "\\[" : "<span style=\"font-size: large\">[</span>",
    "\\\\\\{" : "<span style=\"font-size: large\">{</span>",
};
var htmlTeXMacrosRightParentheses={
    "\\)" : "<span style=\"font-size: large\">)</span>",
    "\\]" : "<span style=\"font-size: large\">]</span>",
    "\\\\\\}" : "<span style=\"font-size: large\">}</span>"
};
var htmlTeXMacrosBoxes={
    "mbox" : "$1",  
    "parbox" : "$1"
};
var htmlTeXMacrosWithoutArgumentsWhichRequireBackSlash=
[
 "ll",
 "gg",
 "times",
 "sum",
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
    

    for(key in htmlTeXMacrosWithOneArgument){
    // First with parenthesis
    from=new RegExp("\\\\"+key+" *\\{(.+?)\\}","g");
	to=htmlTeXMacrosWithOneArgument[key];
    s=s.replace(from,to);
    // Next without parenthesis
	from=new RegExp("\\\\"+key+" +(.)","g");
	to=htmlTeXMacrosWithOneArgument[key];
	s=s.replace(from,to);
	s=s.replace(from,to);
	s=s.replace(from,to);
	s=s.replace(from,to);
    }    
    
    // For {\rm|\bf|\it|\bb|\cal ...}
    for(key in htmlTeXMacrosTypeface){
    from=new RegExp("\\{\\\\"+key+" *(.+?)\\}","g");
	to=htmlTeXMacrosTypeface[key];
    s=s.replace(from,to);
    s=s.replace(from,to);
	s=s.replace(from,to);
    }
    
    // For \left .. \right ([\{ , )]\}
    for(key in htmlTeXMacrosLeftParentheses){
    from=new RegExp("\\\\left"+key,"g");
	to=htmlTeXMacrosLeftParentheses[key];
    s=s.replace(from,to);
    s=s.replace(from,to);
    }
    for(key in htmlTeXMacrosRightParentheses){
    from=new RegExp("\\\\right"+key,"g");
	to=htmlTeXMacrosRightParentheses[key];
    s=s.replace(from,to);
    s=s.replace(from,to);
    }

    // Replace indices and symbols
    for(i=0;i<htmlTeXRegExps.length;i++){
	pair=htmlTeXRegExps[i];
	from=new RegExp(pair[0],"g");
	to=pair[1];
	s=s.replace(from,to);
    }	
  
    // Replace more symbols
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
    
    // For \mbox (and \parbox ?)
    for(key in htmlTeXMacrosBoxes){
    from=new RegExp("\\\\"+key+" *\\{([^\\}]+?)\\}","g");
	to=htmlTeXMacrosBoxes[key];
    s=s.replace(from,to);
    s=s.replace(from,to);
	s=s.replace(from,to);
    }

    if(!(s.match(/\\frac/))){
        s=s.replace(RegExp("\\{","g"),"<span>");
        s=s.replace(RegExp("\\}","g"),"</span>");
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
