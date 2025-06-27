/*
Yes, this is Perl code. It's just here for reference...
*/

# Utility functions for tagtime.
# This uses settings from ~/.tagtimerc so that must have been loaded first.

if(!defined($linelen)) { $linelen = 80; }  # default line length.

sub max { my $max = $_[0]; for(@_) { $max = $_ if ($_ > $max); } $max; }
sub min { my $min = $_[0]; for(@_) { $min = $_ if ($_ < $min); } $min; }

sub clip { my($x, $a, $b) = @_;  return max($a, min($b, $x)); }

# Strips out stuff in parens and brackets; remaining parens/brackets means
#  they were unmatched.
sub strip {
  my($s) = @_;
  while($s =~ s/\([^\(\)]*\)//g) {}
  while($s =~ s/\[[^\[\]]*\]//g) {}

  # Also remove trailing whitespace? (this breaks cntpings.pl)
  #$s =~ s/\s*$//;

  return $s;
}

# Strips out stuff in brackets only; remaining brackets means they were 
#  unmatched.
sub stripb {
  my($s) = @_;
  while($s =~ s/\s*\[[^\[\]]*\]//g) {}
  $s;
}

# Strips out stuff *not* in parens and brackets.
sub stripc {
  my($s) = @_;
  my $tmp = $s;
  while($tmp =~ s/\([^\(\)]*\)/UNIQUE78DIV/g) {}
  while($tmp =~ s/\[[^\[\]]*\]/UNIQUE78DIV/g) {}
  my @a = split('UNIQUE78DIV', $tmp);
  for(@a) {
    my $i = index($s, $_);
    substr($s, $i, length($_)) = "";
  }
  return $s;
}

# Whether the given string is valid line in a tagtime log file
sub parsable { my($s) = @_;
  $s = strip($s);
  return !(!($s =~ s/^\d+\s+//) || ($s =~ /(\(|\)|\[|\])/));
}

# Fetches stuff in parens. Not currently used.
sub fetchp {
  my($s) = @_;
  my $tmp = $s;
  while($tmp =~ s/\([^\(\)]*\)/UNIQUE78DIV/g) {}
  my @a = split('UNIQUE78DIV', $tmp);
  for(@a) {
    my $i = index($s, $_);
    substr($s, $i, length($_)) = "";
  }
  $s =~ s/^\(//;
  $s =~ s/\)$//;
  return $s;
}

# Extracts tags prepended with colons and returns them space-separated.
#  Eg: "blah blah :foo blah :bar" --> "foo bar"
sub gettags {
  my($s) = @_;
  my @t;
  $s = strip($s);
  while($s =~ s/(\s\:([\w\_]+))//) { push(@t, $2); }
  return join(' ', @t);
}

# Singular or Plural:  Pluralize the given noun properly, if n is not 1. 
#   Eg: splur(3, "boy") -> "3 boys"
sub splur { my($n, $noun) = @_;  return "$n $noun".($n==1 ? "" : "s"); }

# Trim whitespace from front and back of string s.
sub trim { my($s) = @_;  $s =~ s/^\s+//;  $s =~ s/\s+$//;  return $s; }

# Takes a string "foo" and returns "-----foo-----" of length $linelen.
sub divider { my($label) = @_;
  #if(!defined($linelen)) { $linelen = 79; }
  my $n = length($label);
  my $left = int(($linelen - $n)/2);
  my $rt = $linelen - $left - $n;
  return ("-"x$left).$label.("-"x$rt);
}

# Takes 2 strings and returns them concatenated with enough space in the middle
# so the whole string is $x long (default: $linelen).
sub lrjust { my($a, $b, $x) = @_;
  $x = $linelen unless defined($x);
  "$a " . " "x(max(0,$x-length("$a $b"))) . $b;
}

# Annotates a line of text with the given timestamp.
sub annotime {                 # NB: this does not include a newline.
  my($a, $t, $ll) = @_;
  $ll = $linelen unless defined($ll);
  my($yea,$o,$d,$h,$m,$s,$wd) = dt($t);
  my @candidates = (
    #"[$yea.$o.$d $h:$m:$s $wd; r=".round1(time()-$t)."]",
    "[$yea.$o.$d $h:$m:$s $wd]",    # 24 chars
    "[$o.$d $h:$m:$s $wd]",         # 18 chars
    "[$d $h:$m:$s $wd]",            # 15 chars
    "[$o.$d $h:$m:$s]",             # 14 chars
    "[$h:$m:$s $wd]",               # 12 chars
    "[$o.$d $h:$m]",                # 11 chars
    "[$d $h:$m:$s]",                # also 11 so this will never get chosen
    "[$h:$m $wd]",                  #  9 chars
    "[$h:$m:$s]",                   #  8 chars
    "[$d $h:$m]",                   # also 8 so this will never get chosen
    "[$h:$m]",                      #  5 chars
    "[$m]"                          #  2 chars
  );
  for(@candidates) {
    if(length("$a $_") <= $ll) {
      return lrjust($a, $_, $ll-0*24);
    }
  }
  return $a;
}

# append a string to the log file ($logf defined in settings file)
sub slog {
  my($s) = @_;
  open(F, ">>$logf") or die "Can't open log file for writing: $!\n";
  print F $s;
  close(F);
}

# double-digit: takes number from 0-99, returns 2-char string eg "03" or "42".
sub dd { my($n) = @_;  return padl($n, "0", 2); }
  # simpler but less general version: return ($n<=9 && $n>=0 ? "0".$n : $n)

# pad left: returns string x but with p's prepended so it has width w
sub padl {
  my($x,$p,$w) = @_;
  if(length($x) >= $w) { return substr($x,0,$w); }
  return $p x ($w-length($x)) . $x;
}

# pad right: returns string x but with p's appended so it has width w
sub padr {
  my($x,$p,$w) = @_;
  if(length($x) >= $w) { return substr($x,0,$w); }
  return $x . $p x ($w-length($x));
}

# Whether the argument is a valid real number.
sub isnum { my($x)=@_; return ($x=~ /^\s*(\+|\-)?(\d+\.?\d*|\d*\.?\d+)\s*$/); }

# round to nearest integer.
sub round1 { my($x) = @_; return int($x + .5 * ($x <=> 0)); }



# DATE/TIME FUNCTIONS FOLLOW

# Time string: takes unixtime and returns a formated YMD HMS string.
sub ts { my($t) = @_;
  my($year,$mon,$mday,$hour,$min,$sec,$wday,$yday,$isdst) = dt($t);
  return "$year-$mon-$mday $hour:$min:$sec $wday";
}

# Human-Compressed Time String: like 0711281947 for 2007-11-28 19:47
sub hcts { my($t) = @_;
  if($t % 60 >= 30) { $t += 60; } # round to the nearest minute.
  my($year,$mon,$mday,$hour,$min,$sec,$wday,$yday,$isdst) = dt($t);
  return substr($year,-2)."${mon}${mday}${hour}${min}";
}

# Parse ss: takes a string like the one returned from ss() and parses it,
# returning a number of seconds.
sub pss { my($s) = @_;
  $s =~ /^\s*(\-?)(\d*?)d?(\d*?)h?(\d*?)(?:\:|m)?(\d*?)s?\s*$/;
  return ($1 eq '-' ? -1 : 1) * ($2*24*3600+$3*3600+$4*60+$5);
}

# Parse Date: must be in year, month, day, hour, min, sec order, returns
#   unixtime.
sub pd { my($s) = @_;
  my($year, $month, $day, $hour, $minute, $second);

  if($s =~ m{^\s*(\d{1,4})\W*0*(\d{1,2})\W*0*(\d{1,2})\W*0*
                 (\d{0,2})\W*0*(\d{0,2})\W*0*(\d{0,2})\s*.*$}x) {
    $year = $1;  $month = $2;   $day = $3;
    $hour = $4;  $minute = $5;  $second = $6;
    $hour |= 0;  $minute |= 0;  $second |= 0;  # defaults.
    $year = ($year<100 ? ($year<70 ? 2000+$year : 1900+$year) : $year);
  }
  else {
    ($year,$month,$day,$hour,$minute,$second) =
      (1969,12,31,23,59,59); # indicates couldn't parse it.
  }

  return timelocal($second,$minute,$hour,$day,$month-1,$year);
}

1;  # perl wants this for libraries imported with 'require'.


# SCRATCH AREA:

# Implementation of ran0 in C, from numerical recipes:

# #define IA 16807
# #define IM 2147483647
# #define IQ 127773     /* = floor(IM / IA) */
# #define IR 2836       /* = IM % IA */
# #define SEED 1
# static long state = SEED;
# long ran0() {
#   long k = (state)/IQ;
#   state = IA*((state) - k*IQ) - IR*k;
#   if (state < 0) { state += IM; }
#   return (state);
# }
