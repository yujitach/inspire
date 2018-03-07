#This file is NOT interpreted by perl. 
# rudimentary magic
s/%%/!!/g;
s/  %/  /g; # if $wanttitleofpapers;
s/!!/%%/g;
s/~.~/~/;
s/ ([,.a-zA-Z]+) *([01-9]+) *\(/$1 \\textbf{$2} (/g;
s/,'' *([A-Z].*) *\\t/,'' \\textsl{$1}\\t/g;
s/([^\['{]+){\\bf/{\\slshape $1}{\\bf/msg; # }'
    s/math.dg/math.DG/gi;
    s/math.ag/math.AG/gi;
    s/%%CITATION/%%CITATIO/;
    s/&/\\&/g;
    s/ '/ `/g;  #`'
    
    
    #Equations
    s/\^(.)/\$^$1\$/g;
    s/E *Theta *\/ *2 *Pi/\$e\\theta\/2\\pi\$/ig;
    s/X +S\*\*2/ \$\\times\\ S^2\$ /ig;
    s/X +S\*\*3/ \$\\times\\ S^3\$ /ig;
    s/ x / \$\\times\$ /ig;
    s/ Z-min/ \$Z\$-min/g;
    s/chiSB/\$\\chi\$SB/g;
    s/N *= *(\d)/\${\\mathcal{N}}\\!=$1\$/g;
    s/ N / \$N\$ /g;
    s/N ?= ?\( ?1 ?, ?0 ?\)/\$\\mathcal{N}=(1,0)\$/g;
    s/U\(1\)R/\$U(1)_R\$/ig;
    s/'a-theorem'/`a-theorem'/g; #`
    s/ c Theorem/ \$c\$-Theorem/g;
    s/maximizes +a,/maximizes \$a\$,/g;
    s/a-maximi([sz])ation/\$a\$-maximi$1ation/g;
    s/AdS\(5\) +x +T\(11\)/\$\\AdS_5\$ \$\\times\$ \$T^{1,1}\$/ig;
    s/AdS\(5\)/\$\\mathrm{AdS}_5\$/ig;
    s/AdS_([1-9])/\$\\mathrm{AdS}_$1\$/ig;
    s/CFT_([1-9])/CFT\$_$1\$/ig;
    s/S\^5/\$S^5\$/ig;
    s/([^\$])\\times/$1\$\\times\$/ig;
    s/SU\((.)\)/\$SU($1)\$/;
    s/SU\((...)\)/\$SU($1)\$/;
    s/SL\((.)\)/\$SL($1)\$/;
    s/SL\((...)\)/\$SL($1)\$/;
    s/SL([1-9])/\$SL($1)\$/i;
    s/W([1-9])/\$W_$1\$/i;
    s/N\(c\)/\\hbox{\$N_c\$}/i;
    s/N\(f\)/\\hbox{\$N_f\$}/i;
    s/O\((.)\)/\$O($1)\$/i;
    s/SO\((.)\)/\$SO($1)\$/;
    s/(SU)\(2\|2\)/\$$1(2|2)\$/i;
    s/(PSU)\(2,2\|4\)/\$$1(2,2|4)\$/i;
    s/L\(p,q\$\|\$r\)/\$L^{p,q|r}\$/g;
    s/L\(p,q,r\)/\$L^{p,q,r}\$/g;
    s/Y *\( *p *, *q *\)/\$Y^{p,q}\$/;
    s/Y *(\*\*)* *\( *p *, *q *\)/\$Y^{p,q}\$/;
    s/S\((.)\)/\$S^$1\$/g;
    s/R\^2/\$R^2\$/g;
    s/(.)\*\*(.)/\$ $1^$2\$/;
    s/T\(11\)/\$T^{1,1}\$/g;
    s/R\(2\)/\$R^2\$/g;
    s/G\(2\)/\$G_2\$/g;
    s/Z\(2\)/\$Z_2\$/g;
    s/A_\{(.+?)\}/\$A_{$1}\$/g;
    s/A_([^{])/\$A_{$1}\$/g; #}
    s/T_N/\$T_N\$/;
    s/D_(.)/\$D_{$1}\$/g;
    s/E_(.)/\$E_{$1}\$/g;
    s/A\((.)\)/\$A_{$1}\$/g;
    s/D\((.)\)/\$D_{$1}\$/g;
    s/E\((.)\)/\$E_{$1}\$/g;
    s/S2/\$S^2\$/g;
    s/S3/\$S^3\$/g;
    s/Electric +- +magnetic/Electric--magnetic/g;
    s/M *-+ *[Tt]heory/M-theory/g;
    s/prepotential +F +/prepotential \$F\$ /ig;
    s/modulus +u +/modulus \$u\$ /ig;
    s/(en)hancon/$1han\\c{c}on/ig;
    s/Lee-+yang/Lee--Yang/ig;
    s/u-plane/\$u\$-plane/ig;
    s/d=4/\$d=4\$/ig;
    s/O6-/O\$6^-\$/g;
    s/A-D-E/A-D-E/ig;
    s/AGT/AGT/ig;
    s/CHL/CHL/ig;
    s/\(p,q\) +7/\$[p,q]\$ 7/ig;
    s/\(p,q\) +5/\$(p,q)\$ 5/ig;
    s/\(p,q\) +(w)/\$(p,q)\$ $1/ig;
    s/Anti-De +Sitter/Anti-de~Sitter/;
    s/(k)ahler/$1\\"ahler/ig; #"
    s/hyperK/hyperk/g;
    s/\*\*(\d)/\$^$1\$/g;
    
    #Names
    s/Asterisque/Ast\\'erisque/ig;
    s/Alvarez/\\'Alvarez/g;
    s/Gomez/G\\'omez/g;
    s/Barbon/Barb\\'on/g;
    s/Banados/Ba\\~nados/g;
    s/Billo,/Bill\\'o,/g;
    s/Breitenlohner/Breitenl\\"ohner/g; #"
    s/Compere/Comp\\`ere/g; #`
    s/Cvetic/Cveti{\\v c}/g;
    s/de +la +ossa/de la Ossa/ig;
    s/Fre,/Fr\\`e,/g; #`
    s/-Gaume/-Gaum\\'e/;
    s/Garcia-/Garc{\\'\\i a-}/;
    s/G\\.odel/G\\"odel/gi; #"
    s/Grana/Gra\\~na/g;
    s/Gunayd/G\\"unayd/ig;  #"
    s/Guven/G\\"uven/g; #"
    s/H\.~+Lu/H.~L\\"u/g;  #"
    s/H\.[ ~]*z\./H.-Z./ig;
    s/Horvathy/Horv\\'athy/g;
    s/Hubsch/H\\"ubsch/g;  #"
    s/Inonu/\\.{I}n\\"on\\"u/;
    s/K\.[ ~]*I\./K.-I./ig;
    s/(K)aehler/$1\\"ahler/ig; #"
    s/(K)ahler/$1\\"ahler/gi;  #"
    s/Kozcaz/Koz\\c{c}az/gi;  
    s/Lindstrom/Lindstr\\"om/g;  #"
    s/Lust,/L\\"ust,/g;  #"
    s/McKernan/M\\raise.5ex\\hbox{c}Kernan/g;
    s/Marino/Mari\\~no/g;
    s/Martinez/Mart{\\'\\i ne}z/g;
    s/Mendez-Escobar/M\\'ende{z-Es}cobar/ig;
    s/Mueck/M\\"uck/g;  #"
    s/O.~Tafjord/\\O.~Tafjord/g;
    s/P.[ ~]*Zayas/Pando~Zayas/g;
    s/Plucker/Pl\\"ucker/g;  #"
    s/Rocek/Ro\\v{c}ek/g;
    s/Ronen/R./g;
    s/Schafer-Nameki/Sch\\"afe{r-Na}meki/g;  #"
    s/Schrodinger/Schr\\"odinger/g;  #"
    s/Schroedinger/Schr\\"odinger/g;  #"
    s/Schr\\.odinger/Schr\\"odinger/gi;  #"
    s/Spalinski/Spa\\l inski/g;
    s/Vazquez/V\\'azquez/g;
    
    #correction to spires
    s/in the Noether/is the Noether/;
    s/%%CITATIO/%%CITATION/;
        #final magic
        s/\$+/\$/;
