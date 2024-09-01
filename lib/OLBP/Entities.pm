package OLBP::Entities;
use strict;

my %uecode;

# numericentities turns symbolic character entities into numeric
# Unicode codes (which is now required for OAI 2.0)

$uecode{"amp"}    = 0x0026;
$uecode{"lt"}     = 0x003c;
$uecode{"gt"}     = 0x003e;
$uecode{"nbsp"}   = 0x00a0;
$uecode{"iexcl"}  = 0x00a1;
$uecode{"curren"} = 0x00a4;
$uecode{"sect"}   = 0x00a7;
$uecode{"uml"}    = 0x00a8;
$uecode{"laquo"}  = 0x00ab;
$uecode{"reg"}    = 0x00ae;
$uecode{"macr"}   = 0x00af;
$uecode{"deg"}    = 0x00b0;
$uecode{"plusmn"} = 0x00b1;
$uecode{"sup2"}   = 0x00b2;
$uecode{"sup3"}   = 0x00b3;
$uecode{"acute"}  = 0x00b4;
$uecode{"para"}   = 0x00b6;
$uecode{"cedil"}  = 0x00b8;
$uecode{"sup1"}   = 0x00b9;
$uecode{"raquo"}  = 0x00bb;
$uecode{"frac14"} = 0x00bc;
$uecode{"frac12"} = 0x00bd;
$uecode{"frac34"} = 0x00be;
$uecode{"iquest"} = 0x00bf;
$uecode{"Agrave"} = 0x00c0;
$uecode{"Aacute"} = 0x00c1;
$uecode{"Acirc"}  = 0x00c2;
$uecode{"Atilde"} = 0x00c3;
$uecode{"Auml"}   = 0x00c4;
$uecode{"Aring"}  = 0x00c5;
$uecode{"AElig"}  = 0x00c6;
$uecode{"Ccedil"} = 0x00c7;
$uecode{"Egrave"} = 0x00c8;
$uecode{"Eacute"} = 0x00c9;
$uecode{"Ecirc"}  = 0x00ca;
$uecode{"Euml"}   = 0x00cb;
$uecode{"Igrave"} = 0x00cc;
$uecode{"Iacute"} = 0x00cd;
$uecode{"Icirc"}  = 0x00ce;
$uecode{"Iuml"}   = 0x00cf;
$uecode{"ETH"}    = 0x00d0;
$uecode{"Ntilde"} = 0x00d1;
$uecode{"Ograve"} = 0x00d2;
$uecode{"Oacute"} = 0x00d3;
$uecode{"Ocirc"}  = 0x00d4;
$uecode{"Otilde"} = 0x00d5;
$uecode{"Ouml"}   = 0x00d6;
$uecode{"times"}  = 0x00d7;
$uecode{"Oslash"} = 0x00d8;
$uecode{"Ugrave"} = 0x00d9;
$uecode{"Uacute"} = 0x00da;
$uecode{"Ucirc"}  = 0x00db;
$uecode{"Uuml"}   = 0x00dc;
$uecode{"Yacute"} = 0x00dd;
$uecode{"THORN"}  = 0x00de;
$uecode{"szlig"}  = 0x00df;
$uecode{"agrave"} = 0x00e0;
$uecode{"aacute"} = 0x00e1;
$uecode{"acirc"}  = 0x00e2;
$uecode{"atilde"} = 0x00e3;
$uecode{"auml"}   = 0x00e4;
$uecode{"aring"}  = 0x00e5;
$uecode{"aelig"}  = 0x00e6;
$uecode{"ccedil"} = 0x00e7;
$uecode{"egrave"} = 0x00e8;
$uecode{"eacute"} = 0x00e9;
$uecode{"ecirc"}  = 0x00ea;
$uecode{"euml"}   = 0x00eb;
$uecode{"igrave"} = 0x00ec;
$uecode{"iacute"} = 0x00ed;
$uecode{"icirc"}  = 0x00ee;
$uecode{"iuml"}   = 0x00ef;
$uecode{"eth"}    = 0x00f0;
$uecode{"ntilde"} = 0x00f1;
$uecode{"ograve"} = 0x00f2;
$uecode{"oacute"} = 0x00f3;
$uecode{"ocirc"}  = 0x00f4;
$uecode{"otilde"} = 0x00f5;
$uecode{"ouml"}   = 0x00f6;
$uecode{"oslash"} = 0x00f8;
$uecode{"ugrave"} = 0x00f9;
$uecode{"uacute"} = 0x00fa;
$uecode{"ucirc"}  = 0x00fb;
$uecode{"uuml"}   = 0x00fc;
$uecode{"yacute"} = 0x00fd;
$uecode{"thorn"}  = 0x00fe;
$uecode{"yuml"}   = 0x00ff;
$uecode{"Amacr"}  = 0x0100;
$uecode{"amacr"}  = 0x0101;
$uecode{"Abreve"} = 0x0102;
$uecode{"abreve"} = 0x0103;
$uecode{"Aogon"}  = 0x0104;
$uecode{"aogon"}  = 0x0105;
$uecode{"Cacute"} = 0x0106;
$uecode{"cacute"} = 0x0107;
$uecode{"Ccirc"}  = 0x0108;
$uecode{"ccirc"}  = 0x0109;
$uecode{"Cdot"}   = 0x010a;
$uecode{"cdot"}   = 0x010b;
$uecode{"Ccaron"} = 0x010c;
$uecode{"ccaron"} = 0x010d;
$uecode{"Dcaron"} = 0x010e;
$uecode{"dcaron"} = 0x010f;
$uecode{"Dstrok"} = 0x0110;
$uecode{"dstrok"} = 0x0111;
$uecode{"Emacr"}  = 0x0112;
$uecode{"emacr"}  = 0x0113;
$uecode{"Edot"}   = 0x0116;
$uecode{"edot"}   = 0x0117;
$uecode{"Eogon"}  = 0x0118;
$uecode{"eogon"}  = 0x0119;
$uecode{"Ecaron"} = 0x011a;
$uecode{"ecaron"} = 0x011b;
$uecode{"Gcirc"}  = 0x011c;
$uecode{"gcirc"}  = 0x011d;
$uecode{"Gbreve"} = 0x011e;
$uecode{"gbreve"} = 0x011f;
$uecode{"Gdot"}   = 0x0120;
$uecode{"gdot"}   = 0x0121;
$uecode{"Gcedil"} = 0x0122;
$uecode{"Hcirc"}  = 0x0124;
$uecode{"hcirc"}  = 0x0125;
$uecode{"Hstrok"} = 0x0126;
$uecode{"hstrok"} = 0x0127;
$uecode{"Itilde"} = 0x0128;
$uecode{"itilde"} = 0x0129;
$uecode{"Imacr"}  = 0x012a;
$uecode{"imacr"}  = 0x012b;
$uecode{"Iogon"}  = 0x012e;
$uecode{"iogon"}  = 0x012f;
$uecode{"Idot"}   = 0x0130;
$uecode{"inodot"} = 0x0131;
$uecode{"IJlig"}  = 0x0132;
$uecode{"ijlig"}  = 0x0133;
$uecode{"Jcirc"}  = 0x0134;
$uecode{"jcirc"}  = 0x0135;
$uecode{"Kcedil"} = 0x0136;
$uecode{"kcedil"} = 0x0137;
$uecode{"kgreen"} = 0x0138;
$uecode{"Lacute"} = 0x0139;
$uecode{"lacute"} = 0x013a;
$uecode{"Lcedil"} = 0x013b;
$uecode{"lcedil"} = 0x013c;
$uecode{"Lcaron"} = 0x013d;
$uecode{"lcaron"} = 0x013e;
$uecode{"Lstrok"} = 0x0141;
$uecode{"lstrok"} = 0x0142;
$uecode{"Nacute"} = 0x0143;
$uecode{"nacute"} = 0x0144;
$uecode{"Ncedil"} = 0x0145;
$uecode{"ncedil"} = 0x0146;
$uecode{"Ncaron"} = 0x0147;
$uecode{"ncaron"} = 0x0148;
$uecode{"Omacr"}  = 0x014c;
$uecode{"omacr"}  = 0x014d;
$uecode{"OElig"}  = 0x0152;
$uecode{"oelig"}  = 0x0153;
$uecode{"Racute"} = 0x0154;
$uecode{"racute"} = 0x0155;
$uecode{"Rcedil"} = 0x0156;
$uecode{"rcedil"} = 0x0157;
$uecode{"Rcaron"} = 0x0158;
$uecode{"rcaron"} = 0x0159;
$uecode{"racute"} = 0x0155;
$uecode{"Sacute"} = 0x015a;
$uecode{"sacute"} = 0x015b;
$uecode{"Scirc"}  = 0x015c;
$uecode{"scirc"}  = 0x015d;
$uecode{"Scedil"} = 0x015e;
$uecode{"scedil"} = 0x015f;
$uecode{"Scaron"} = 0x0160;
$uecode{"scaron"} = 0x0161;
$uecode{"Tcedil"} = 0x0162;
$uecode{"tcedil"} = 0x0163;
$uecode{"Tcaron"} = 0x0164;
$uecode{"tcaron"} = 0x0165;
$uecode{"Tstrok"} = 0x0166;
$uecode{"tstrok"} = 0x0167;
$uecode{"Utilde"} = 0x0168;
$uecode{"utilde"} = 0x0169;
$uecode{"Umacr"}  = 0x016a;
$uecode{"umacr"}  = 0x016b;
$uecode{"Ubreve"} = 0x016c;
$uecode{"ubreve"} = 0x016d;
$uecode{"Uring"}  = 0x016e;
$uecode{"uring"}  = 0x016f;
$uecode{"Uogon"}  = 0x0172;
$uecode{"uogon"}  = 0x0173;
$uecode{"Wcirc"}  = 0x0174;
$uecode{"wcirc"}  = 0x0175;
$uecode{"Ycirc"}  = 0x0176;
$uecode{"ycirc"}  = 0x0177;
$uecode{"Yuml"}   = 0x0178;
$uecode{"Zacute"} = 0x0179;
$uecode{"zacute"} = 0x017a;
$uecode{"Zdot"}   = 0x017b;
$uecode{"zdot"}   = 0x017c;
$uecode{"Zcaron"} = 0x017d;
$uecode{"zcaron"} = 0x017e;
$uecode{"gacute"} = 0x01f5;
$uecode{"flat"}   = 0x266d;

#$uecode{"Alpha"}  = 0x0391;
#$uecode{"Beta"}   = 0x0392;
#$uecode{"Gamma"}  = 0x0393;
#$uecode{"Delta"}  = 0x0394;
#$uecode{"Epsilon"}= 0x0395;
#$uecode{"Zeta"}   = 0x0396;
#$uecode{"Eta"}    = 0x0397;
#$uecode{"Theta"}  = 0x0398;
#$uecode{"Iota"}   = 0x0399;
#$uecode{"Kappa"}  = 0x039a;
#$uecode{"Lambda"} = 0x039b;
#$uecode{"Mu"}     = 0x039c;
#$uecode{"Nu"}     = 0x039d;
#$uecode{"Xi"}     = 0x039e;
#$uecode{"Omicron"}= 0x039f;
#$uecode{"Pi"}     = 0x03a0;
#$uecode{"Rho"}    = 0x03a1;
#$uecode{"Sigma"}  = 0x03a3;
#$uecode{"Tau"}    = 0x03a4;
#$uecode{"Upsilon"}= 0x03a5;
#$uecode{"Phi"}    = 0x03a6;
#$uecode{"Chi"}    = 0x03a7;
#$uecode{"Psi"}    = 0x03a8;
#$uecode{"alpha"}  = 0x03b1;
#$uecode{"beta"}   = 0x03b2;
#$uecode{"gamma"}  = 0x03b3;
#$uecode{"delta"}  = 0x03b4;
#$uecode{"epsilon"}= 0x03b5;
#$uecode{"zeta"}   = 0x03b6;
#$uecode{"eta"}    = 0x03b7;
#$uecode{"theta"}  = 0x03b8;
#$uecode{"iota"}   = 0x03b9;
#$uecode{"kappa"}  = 0x03ba;
#$uecode{"lambda"} = 0x03bb;
#$uecode{"mu"}     = 0x03bc;
#$uecode{"nu"}     = 0x03bd;
#$uecode{"xi"}     = 0x03be;
#$uecode{"omicron"}= 0x03bf;
#$uecode{"pi"}     = 0x03c0;
#$uecode{"rho"}    = 0x03c1;
#$uecode{"sigmav"} = 0x03c2;
#$uecode{"sigma"}  = 0x03c3;
#$uecode{"tau"}    = 0x03c4;
#$uecode{"upsilon"}= 0x03c5;
#$uecode{"phi"}    = 0x03c6;
#$uecode{"chi"}    = 0x03c7;
#$uecode{"psi"}    = 0x03c8;
#$uecode{"omega"}  = 0x03c9;

$uecode{"ndash"}   = 0x2013;
$uecode{"mdash"}   = 0x2014;
$uecode{"ldquo"}   = 0x201c;
$uecode{"rdquo"}   = 0x201d;
$uecode{"ldquor"}  = 0x201e;
$uecode{"dagger"}  = 0x2020;
$uecode{"ddagger"} = 0x2021;
$uecode{"bull"}    = 0x2022;
$uecode{"hellip"}  = 0x2026;
$uecode{"prime"}   = 0x2032;
$uecode{"Prime"}   = 0x2033;
$uecode{"euro"}    = 0x20ac;
$uecode{"trade"}   = 0x2122;
$uecode{"minus"}   = 0x2212;

my $_codes = {
  '0' => [0x2070, 0x2080, 0x3007],
  '1' => [0x2081],
  '2' => [0x00b2, 0x2082],
  '3' => [0x00b3, 0x2083],
  '4' => [0x2074, 0x2084],
  '5' => [0x2075, 0x2085],
  '6' => [0x2076, 0x2086],
  '7' => [0x2077, 0x2087],
  '8' => [0x2078, 0x2088],
  '9' => [0x2079, 0x2089],
  'A' => [0x0100, 0x0102, 0x0104, 0x01cd, 0x01de, 0x01e0,
          0x0200, 0x0202, 0x0226, 0x023a,
          0x1ea0, 0x1ea2, 0x1ea4, 0x1ea6, 0x1ea8, 0x1eaa, 0x1eac, 0x1eae,
          0x1eb0, 0x1eb2, 0x1eb4, 0x1eb6],
  'a' => [0x0101, 0x0103, 0x0105, 0x01ce, 0x01df, 0x01e1,
          0x0201, 0x0203, 0x0227,
          0x1e01, 0x1e9a,
          0x1ea1, 0x1ea3, 0x1ea5, 0x1ea7, 0x1ea9, 0x1eab, 0x1ead, 0x1eaf,
          0x1eb1, 0x1eb3, 0x1eb5, 0x1eb7],
  'AE' => [0x01e2, 0x01fc],
  'ae' => [0x01e3, 0x01fd],
  'B' => [0x1e02, 0x1e04, 0x1e06],
  'b' => [0x1e03, 0x1e05, 0x1e07],
  'C' => [0x0106, 0x0108, 0x010a, 0x010c],
  'c' => [0x00a9, 0x0107, 0x0109, 0x010b, 0x010d],
  'D' => [0x010e, 0x0110,
          0x1e0a, 0x1e0c, 0x1e0e, 0x1e10, 0x1e12],
  'DZ' => [0x01c4],
  'Dz' => [0x01c5],
  'dz' => [0x01c6],
  'd' => [0x010f, 0x0111,
          0x1e0b, 0x1e0d, 0x1e0f, 0x1e11, 0x1e13],
  'dz' => [0x01c6],
  'E' => [0x0112, 0x0114, 0x0116, 0x0118, 0x011a,
          0x0204, 0x0206, 0x0228, 0x0246,
          0x1e14, 0x1e16, 0x1e18, 0x1e1a, 0x1e1c,
          0x1eb8, 0x1eba, 0x1ebc, 0x1ebe, 0x1ec0, 0x1ec2, 0x1ec4, 0x1ec6],
  'e' => [0x0113, 0x0115, 0x0117, 0x0119, 0x011b,
          0x0205, 0x0207, 0x0229,
          0x0259,                  # best match for schwa I can think of
          0x1e15, 0x1e17, 0x1e19, 0x1e1b, 0x1e1d,
          0x1eb9, 0x1ebb, 0x1ebd, 0x1ebf, 0x1ec1, 0x1ec3, 0x1ec5, 0x1ec7],
  'F' => [0x1e1e],
  'f' => [0x1e1f],
  'G' => [0x011c, 0x011e, 0x0120, 0x0122, 0x01e4, 0x01e6, 0x01f4,
          0x1e20],
  'g' => [0x011d, 0x011f, 0x0121, 0x0123, 0x01e5, 0x01e7, 0x01f5,
          0x1e21],
  'H' => [0x0124, 0x0126, 0x021e,
          0x1e22, 0x1e24, 0x1e26, 0x1e28, 0x1e2a, 0x1e96, 0x2c67],
  'h' => [0x0125, 0x0127, 0x021f,
          0x1e23, 0x1e25, 0x1e27, 0x1e29, 0x1e2b, 0x2c68],
  'I' => [0x0128, 0x012a, 0x012c, 0x012e, 0x0130, 0x01cf,
          0x0208, 0x020a,
          0x1e2c, 0x1e2e, 0x1ec8, 0x1eca],
  'i' => [0x0129, 0x012b, 0x012d, 0x012f, 0x0131, 0x01d0, 0x01f9,
          0x0209, 0x020b,
          0x1e2d, 0x1e2f, 0x1ec9, 0x1ecb],
  'IJ' => [0x0132],
  'ij' => [0x0133],
  'J' => [0x0134],
  'j' => [0x0135, 0x01f0],
  'K' => [0x01e8, 0x1e30, 0x1e32, 0x1e34],
  'k' => [0x0138, 0x01e9, 0x1d84, 0x1e31, 0x1e33, 0x1e35],
  'L' => [0x00a3, 0x0139, 0x013b, 0x013d, 0x013f, 0x0141,
          0x1e36, 0x1e38, 0x1e3a, 0x1e3c],
  'l' => [0x013a, 0x013c, 0x013e, 0x0140, 0x0142,
          0x1e37, 0x1e39, 0x1e3b, 0x1e3d, 0x2113],
  'M' => [0x1e3e, 0x1e40, 0x1e42],
  'm' => [0x026f, 0x0270, 0x0271, 0x1e3f, 0x1e41, 0x1e43],
  'N' => [0x0143, 0x0145, 0x0147, 0x014a, 0x01f8,
          0x1e44, 0x1e46, 0x1e48, 0x1e4a],
  'n' => [0x0144, 0x0146, 0x0148, 0x0149, 0x014b, 0x01f9,
          0x0272, 0x0273,
          0x1e45, 0x1e47, 0x1e49, 0x1e4b],
  'O' => [0x014c, 0x014e, 0x0150, 0x019f, 0x01a0, 0x01d1, 0x01ea, 0x01ec,
          0x01fe,
          0x022a, 0x022c, 0x022e, 0x0230,
          0x1e4c, 0x1e4e, 0x1e50, 0x1e52,
          0x1ecc, 0x1ece, 0x1ed0, 0x1ed2, 0x1ed4, 0x1ed6, 0x1ed8, 0x1eda,
          0x1edc, 0x1ede, 0x1ee0, 0x1ee2],
  'o' => [0x014d, 0x014f, 0x0151, 0x01a1, 0x01d2, 0x01eb, 0x01ed, 0x01ff,
          0x022b, 0x022d, 0x022f, 0x0231,
          0x1e4d, 0x1e4f, 0x1e51, 0x1e53,
          0x1ecd, 0x1ecf, 0x1ed1, 0x1ed3, 0x1ed5, 0x1ed7, 0x1ed9, 0x1edb,
          0x1edd, 0x1edf, 0x1ee1, 0x1ee3],
  'OE' => [0x0152],
  'oe' => [0x0153],
  'P' => [0x1e54, 0x1e56, 0x2117],
  'p' => [0x1e55, 0x1e57],
  'R' => [0x0154, 0x0156, 0x0158,
          0x1e58, 0x1e5a, 0x1e5c, 0x1e5e],
  'r' => [0x0155, 0x0157, 0x0159,
          0x1e59, 0x1e5b, 0x1e5d, 0x1e5f],
  'S' => [0x015a, 0x015c, 0x015e, 0x0160, 0x0218,
          0x1e60, 0x1e62, 0x1e64, 0x1e66, 0x1e68],
  's' => [0x015b, 0x015d, 0x015f, 0x0161, 0x0219,
          0x1e61, 0x1e63, 0x1e65, 0x1e67, 0x1e69],
  'T' => [0x0162, 0x0164, 0x0166, 0x021a,
          0x1e6a, 0x1e6c, 0x1e6e, 0x1e70],
  't' => [0x0163, 0x0165, 0x0167, 0x021b,
          0x1e6b, 0x1e6d, 0x1e6f, 0x1e71, 0x1e97],
  'U' => [0x0168, 0x016a, 0x016c, 0x016e, 0x0170, 0x0172,
          0x01af, 0x01d3, 0x01d5, 0x01d7, 0x01d9, 0x01db,
          0x0214, 0x0216,
          0x1e72, 0x1e74, 0x1e76, 0x1e78, 0x1e7a,
          0x1ee4, 0x1ee6, 0x1ee8, 0x1eea, 0x1eec, 0x1eee, 0x1ef0],
  'u' => [0x0169, 0x016b, 0x016d, 0x016f, 0x0171, 0x0173,
          0x01b0, 0x01d4, 0x01d6, 0x01d8, 0x01da, 0x01dc,
          0x0215, 0x0217,
          0x1e73, 0x1e75, 0x1e77, 0x1e79, 0x1e7b,
          0x1ee5, 0x1ee7, 0x1ee9, 0x1eeb, 0x1eed, 0x1eef, 0x1ef1],
  'V' => [0x1e7c, 0x1e7e],
  'v' => [0x1e7d, 0x1e7f],
  'W' => [0x0174,
          0x1e80, 0x1e82, 0x1e84, 0x1e86, 0x1e88],
  'w' => [0x0175,
          0x1e81, 0x1e83, 0x1e85, 0x1e87, 0x1e89],
  'X' => [0x1e8c],
  'x' => [0x1e8d],
  'Y' => [0x0176, 0x0178, 0x0232, 0x1e8e,
          0x1ef2, 0x1ef4, 0x1ef6, 0x1ef8],
  'y' => [0x0177, 0x0233, 0x1e8f, 0x1e99,
          0x1ef3, 0x1ef5, 0x1ef7, 0x1ef9],
  'Z' => [0x0179, 0x017b, 0x017d,
          0x1e90, 0x1e92, 0x1e94],
  'z' => [0x017a, 0x017c, 0x017e,
          0x1e91, 0x1e93, 0x1e95],
  '-' => [0x00b7, 0x2012, 0x207b, 0x0208b, 0xff0d],
  '+' => [0x207a, 0x208a],
  '(' => [0x207d, 0x208d, 0x3014, 0xff08],
  ')' => [0x207e, 0x208e, 0x3015, 0xff09],
  '[' => [0xff3b],
  ']' => [0xff3d],
  '<' => [0x3008],
  '>' => [0x3009],
  '<<' => [0x300a],
  '>>' => [0x300b],
  '#' => [9839],
  ',' => [0xff0c, 0x3001, 0xff64],
  '.' => [0xff0e, 0xff65],
  ';' => [0xff1b],
  '\'' => [0x02b9, 0x02bb, 0x02bc, 0x02bd, 0x2018, 0x2019, 0xa78c, 0xff07],
  '!' => [0x01c3],
  '?' => [0xff1f],
  # CJK left and right corner brackets function as quote mks
  '"' => [0x02ba, 0x300c, 0x300d, 0xff62, 0xff63],
  'flat' => [0x266d],
  ' ' => [0x3000],
  '' => [0x0087, 0x0096, 0x0097, 0x0098, 0x009c, 0x00ad,
         0x01c2,
         0x02be, 0x02bf, 0x02c6, 0x02d5, 0x02d8,
         0x0300 .. 0x036f,    # combining diacritics should be stripped
         0x0370 .. 0x03ff,    # just strip out all Greek and Coptic for now
         0x1f00 .. 0x1fff,    #  (including extended Greek)
         0x0400 .. 0x04ff,    # and Cyrillic
         0x0590 .. 0x05f4,    # and Hebrew
         0x0600 .. 0x06ff,    # and Arabic
         0x200c, 0x200d, 0x200e, 0x200f,
         0x25a1, 
         0x3040 .. 0x30ff,    # and Hiragana and Katakana
        # CJK (anything 4e00 - 9fcf) is taken care of by function
        # Hangul syllables (anything ac00 - d7af) is taken care of by function
         0xf900 .. 0xfaff,    # and CJK compatibility
         0x3005, 0x3013, 
         0xfe20 .. 0xfe26, 0xfeff, 0xfffd],
};

sub numeric_entities {
  my $str = shift;
  my $oldstr = $str;
  $str =~ s/&([a-zA-Z][^;]*);/"&#x".sprintf("%04x", $uecode{$1}).";"/ge;

  if ($str =~ /&#x(0000)?;/) {
    # unrecognized entities get omitted
    print STDERR "Error: Unrecognized entity in $oldstr\n";
    $str =~ s/&#x(0000)?;//g;
  }
  return $str;
}

my %_normalized = ("acute" => "'",
                   "amp" => "&",
                   "#x0026" => "&",
                   "bull" => "*",
                   "cedil" => " ",
                   "curren" => '$',
                   "dagger" => "+",
                   "ddagger" => "+",
                   "euro" => "Euro",
                   "flat" => "flat",
                   "frac14" => "1/4",
                   "frac12" => "1/2",
                   "frac34" => "3/4",
                   "hellip" => "...",
                   "iexcl" => "!",
                   "iquest" => "?",
                   "kgreen" => "k",
                   "lt" => "<",
                   "gt" => ">",
                   "reg" => "r",
                   "macr" => " ",
                   "mdash" => "--",
                   "minus" => "-",
                   "ndash" => "-",
                   "ETH" => "D",
                   "eth" => "d",
                   "deg" => "o",
                   "laquo" => "<<",
                   "ldquo" => "\"",
                   "ldquor" => "\"",
                   "nbsp" => " ",
                   "para" => "P",
                   "plusmn" => "+/-",
                   "prime" => "'",
                   "Prime" => "\"",
                   "quot" => "\"",
                   "raquo" => ">>",
                   "rdquo" => "\"",
                   "sect" => "S",
                   "shy" => "",
                   "sup1" => "1",
                   "sup2" => "2",
                   "sup3" => "3",
                   "THORN" => "th",
                   "thorn" => "th",
                   "times" => "x",
                   "trade" => "tm",
                   "uml" => ":",
                   );

my %_normalnum;
my %_ename;

sub _normalizeentity {
  my $name = shift;
  if ($name =~ /(.)((acute)|(grave)|(circ)|(uml)|(cedil)|(tilde)|(macr)|(slash)|(ring)|(caron)|(ogon)|(breve)|(dot)|(nodot)|(strok))/) {
    return $1;
  }
  if ($name =~ /(..)lig/) {
    return $1;
  }
  if ($_normalized{$name}) {
    return $_normalized{$name};
  }
  if ($name =~ /#(\d+)/ && defined($_normalnum{$1})) {
    return $_normalnum{$1};
  }
  if ($name =~ /#x([0-9a-fA-F]+)/ && defined($_normalnum{hex($1)})) {
    return $_normalnum{hex($1)};
  } elsif ($name =~ /#(\d+)/ &&
       (($1 >= 0x4e00 && $1 < 0x9fd0) ||
        ($1 >= 0xac00 && $1 < 0xd7af))) {
     # CJK (anything 4e00 - 9fcf, ac00 - d7af)
     return "";
  } elsif ($name =~ /#x([0-9a-fA-F]+)/ && 
                ((hex($1) >= 0x4e00 && hex($1) < 0x9fd0) ||
                 (hex($1) >= 0xac00 && hex($1) < 0xd7af))) {
     # CJK (anything 4e00 - 9fcf)
     return "";
  }
  print STDERR "Error: Couldn't understand entity $name\n";
  return "?";
}

# this takes a string with entities and returns the characters
# as normalized roman

sub normalize_entities {
  my $str = shift;
  $str =~ s/&([^;]*);/_normalizeentity($1)/ge;
  return $str;
}


# this takes a string with utf8 chars and returns the characters
# as normalized roman

sub normalize_utf8 {
  my ($str, $quiet) = @_;
    while ($str =~ /([^\x00-\x7f])/) {
    my $char = $1;
    if (!defined($_normalnum{ord($char)})) {
      # skip over CJK chars
      if ((ord($char) >= 0x4e00 && ord($char) < 0x9fd0) ||
               (ord($char) >= 0xac00 && ord($char) < 0xd7af)) {
        $str  =~ s/([^\x00-\x7f])//;
      } else {
        my $diagnostic = $str;
        $diagnostic  =~ s/([^\x00-\x7f])/?/;
        if (!$quiet) {
          print STDERR "Don't know what to do with " . ord($char) .
           " in $diagnostic\n" .
           "that spells as " . join(", ", map(ord, split //, $str)) . "\n";
        }
        $str = $diagnostic;
      }
    } else {
      $str =~ s/([^\x00-\x7f])/$_normalnum{ord($1)}/e;
    }
  }
  return $str;
}

# this takes a string with utf8 chars and returns the characters
# as entities.  
# Uses symbolic entities where available, unless numericonly is set

sub entitize_utf8 {
  my ($str, $numericonly) = @_;
  while ($str =~ /([^\x00-\x7f])/) {
    my $code = ord($1);
    my $label = $_ename{$code};
    if ($label) {
      $str =~ s/([^\x00-\x7f])/&$label;/;
    } else {
      $str =~ s/([^\x00-\x7f])/"&#x".sprintf("%04x", $code).";"/e;
    }
  }
  return $str;
}

# this does the reverse, turning recognizable entities into UTF-8 chars
# (bad numeric entities may be deleted; other unrecognized ones may
#  either be deleted or left as-is)

sub utf8ify_entities {
  my $str = shift;
  if ($str =~ /(.*)&([#0-9A-Za-z]+);(.*)/) {
    my ($first, $pattern, $rest) = ($1, $2, $3);
    my $newstr = "\&$pattern;";
    if ($uecode{$pattern}) {
      # print STDERR "$pattern going to code $uecode{$pattern}\n";
      $newstr = chr($uecode{$pattern});
    } if ($pattern =~ /#x(.+)/ && length($1) < 7) {
      my $hex = hex($1);
      if ($hex > 0 && $hex < 0x10ffff) {
        $newstr = chr($hex);
      }
    } elsif ($pattern =~ /#(\d+)$/ && int($1) < 0x10fff && int($1) > 0) {
      $newstr = chr(int($1));
    }
    return utf8ify_entities($first) . $newstr . $rest;
  }
  return $str;
}

# now initialize with entities above

foreach my $code (keys %uecode) {
  my $str = _normalizeentity($code);
  $_normalnum{$uecode{$code}} = $str;
  $_ename{$uecode{$code}} = $code;
}

foreach my $str (keys %{$_codes}) {
  my @codelist = @{$_codes->{$str}};
  foreach my $code (@codelist) {
    $_normalnum{$code} = $str;
  }
}

1;
