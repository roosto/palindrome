#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use File::Basename;


# TODO: default output should be neither pretty nor verbose
# TODO: add --pretty_print switch
# TODO: add --verbose switch (overridden by --printy_print)
# TODO: add --sort [col[,col2 ...]] (implies --verbose)

my ( $min, $max, $min_palindromes );
my $do_help		= ''; # print $USAGE to STDERR and exit
my $do_verbose		= ''; # output match counts and representation in decimal, prepend "Total: " to answer
my $do_pretty_print	= ''; # output representations in all bases, implies $do_verbose
my $do_tabbed_output	= ''; # overides $do_pretty_print
my $do_sort_by_value	= ''; # sort by number, instead of match

my $USAGE = "Usage: $0 min max min_palindromes\n" .
	"[--verbose] [--pretty_print] [--tabbed_output] [--sort_by_value] [--help]\n" .
	"See $0 --help for more info\n";

my $ME = File::Basename::basename($0);
my $USAGE_LONG = <<"EOF";

Usage: $ME min max min_palindromes

Default behavior is to print the total integers between min and max, 
inclusive, with at least min_palindromes for in their representations in
b64, hex, dec, oct, & bin followed by a newline (just as your submission
must do).

With --verbose or no options, this reference script should run O(n) time*.

Your program need not support any of the of the below options, but you may
find the extra output that can be produced by this reference implementation
helpful for while developing your program.

Options:
      --verbose  print all matched numbers in decimal notation, on a single
                 line; last line of output will be: "Total: n"

 --pretty_print  include match 'count', and all bases in results. Columns are
                 pretty printed with spaces and column headers; last line of
                 output will be: "Total: n"
                 N.B. overrides --verbose

--tabbed_output  include match 'count', and all bases in results. Columns are
                 separated by tabs. "Total: n" will _not_ be printed as last
                 line (`wc -l` is your friend here).
                 N.B. overrides --verbose & --pretty_print

--sort_by_value  for --pretty_print and --tabbed_output, override default
                 sorting by 'count' of matched palindromes, instead sort by
                 numeric value.

         --help  display this message and exit

Core util programs that maybe helpful in conjunction with your development:
diff(1) (particularly, in the form of: `diff - file`)
cut(1)
sort(1) (in conjunction with --tabbed_output and sort's -k option)
time(1) a.k.a. /usr/bin/time, this is also a shell keyword for most shells

* I am a dummy and I never even passed trig, so that may be wrong.

N.B. Getopt::Long is used to parse switches, so any leading portion of a
     switch (or its short equivalent; e.g., -v) maybe used in place of the
     full switch, if the portion can be disambiguated from other switches
     (spoiler: all these switches can be shortened to -X [I know; I'm good])
EOF

# your submitted solution may assume good args to the script & does _not_ need a --help or any other switches
process_args_or_die(); # N.B. sbu will exit on --help or bad args

# code refs for converting to other bases
my %to_base = (
	'bin'	=> sub { return sprintf '%b', shift; },
	'oct'	=> sub { return sprintf '%o', shift; },
	'dec'	=> sub { return shift; },
	'hex'	=> sub { return sprintf '%x', shift; },
	'b64'	=> \&to_base64,
);

# for the prettiest of printing
my %col_widths = (
	'count'	=> 5,
	'b64'	=> 4,
	'hex'	=> 4,
	'dec'	=> 4,
	'oct'	=> 4,
	'bin'	=> 4,
);

# 2nd hash, with dec representation as the key to a hash of the form of %col_widths
my %palindromes = ();
my $total = 0;

### start our super amaze algorythmz ###
for my $i ( $min ... $max ) { # inclusive range operator
	my $count = 0;
	my %i_in_base = ();
	my $palindromes_for_i = 0;
	foreach my $base ( keys %to_base ) {
		$i_in_base{$base} = $to_base{$base}->($i);
		if ( is_a_palindrome( $i_in_base{$base} ) ) {
			$palindromes_for_i++;
		}
	}

	# should we toss this one back? (yes, I'm a size queen #sorrynotsorry)
	if ( $palindromes_for_i >= $min_palindromes ) {
		$total++;
		if ( $do_verbose ) {
			print $i, "\n";
		}
		# unless we are do some extra output, no need to store all this nonsense
		elsif ( $do_pretty_print || $do_tabbed_output ) {
			foreach my $base ( keys %to_base ) {
				# I feel pretty, so pretty, so pretty and niiiice
				if ( $col_widths{$base} < ( length $i_in_base{$base} ) + 1) {
					$col_widths{$base} = ( length $i_in_base{$base} ) + 1;
				}
			}

			$i_in_base{'count'} = $palindromes_for_i;
			$palindromes{$i} = \%i_in_base;
		}
	}
}

### thank goodness we got to the bottom of that, now do output ###

if ( $do_pretty_print || $do_tabbed_output ) {

	my @cols = qw( count b64 hex dec oct bin ); # order of column output

	# printf format strings for output of our columns, assume no switches
	my %fmts = (
		'count'	=> '%s',
		'b64'	=> "\t%s",
		'hex'	=> "\t%s",
		'dec'	=> "\t%d",
		'oct'	=> "\t%s",
		'bin'	=> "\t%s\n",
	);

	if ( $do_pretty_print ) {
		%fmts = (
			'count'	=> '%-' . $col_widths{'count'} . 's ',
			'b64'	=> '%-' . $col_widths{'b64'} . 's',
			'hex'	=> '%-' . $col_widths{'hex'} . 's',
			'dec'	=> '%-' . $col_widths{'dec'} . 's',
			'oct'	=> '%-' . $col_widths{'oct'} . 's',
			'bin'	=> '%-' . $col_widths{'bin'} . "s\n",
		);

		# print header row
		foreach my $col ( @cols ) {
			printf $fmts{$col}, $col;
		}
	}

	foreach my $i ( sort sort_matched keys %palindromes ) {
		foreach my $col ( @cols ) {
			if ( $fmts{$col} ) {
				printf $fmts{$col}, $palindromes{$i}->{$col};
			}
		}
	}
}

if ( $do_pretty_print || $do_verbose ) {
	print 'total: ';
}

if ( ! $do_tabbed_output ) {
	printf "$total\n";
}

### end main() ###

sub is_a_palindrome {
	my $str = shift;

	return $str eq reverse $str;
}

sub to_base64 {

	my $num	= shift;
	my $ret	= '';

	use integer; # use integer pragma locally, to force integer division

	my @base64_digits = qw( 0 1 2 3 4 5 6 7 8 9 
		a b c d e f g h i j k l m n o p q r s t u v w x y z
		A B C D E F G H I J K L M N O P Q R S T U V W X Y Z @ _ 
	);

	while ( $num > 63 ) {
		my $digit = $num % 64;
		$ret = $base64_digits[$digit] . $ret;
		$num = $num / 64; # integer math, because of use integer pragma
	}

	return $base64_digits[$num] . $ret;
}


sub sort_matched {
	my $a = $palindromes{$a};
	my $b = $palindromes{$b};

	my $count_comparator = 0;
	if ( ! $do_sort_by_value ) {
		$count_comparator = $a->{'count'} <=> $b->{'count'};
	}

	return $count_comparator || $a->{'dec'} <=> $b->{'dec'};
}


sub process_args_or_die {

	my $saw_good_opts = GetOptions (
		'help'		=> \$do_help,
		'verbose'	=> \$do_verbose,
		'pretty_print'	=> \$do_pretty_print,
		'tabs'		=> \$do_tabbed_output,
		'sort_by_value'	=> \$do_sort_by_value,
	);

	if ( $do_help ) {
		exit_with_usage( '', 1 );
	}

	if ( ! $saw_good_opts || scalar @ARGV != 3 ) {
		exit_with_usage( "bad arguments\n" );
	}

	# process the required 3 args now that everything else has been swept from the table
	( $min, $max, $min_palindromes ) = @ARGV; # required 3 arguments

	my $err_msg = '';
	if ( $min !~ /^\d+$/ ) {
		$err_msg .= "min: must be a non negative integer\n";
	}

	if ( $max !~ /^\d+$/ ) {
		$err_msg .= "max: must be an integer\n";
	}

	if ( $err_msg ) {
		exit_with_usage( $err_msg );
	}

	if ( $min >= $max ) {
		$err_msg .= "max: must be greater than min\n";
	}

	if ( $max > 2**32 - 1 ) {
		$err_msg .= 'max: max max is 2^32-1 (' . (2**32 -1) .")\n";
	}

	if ( $min_palindromes !~ /^\d$/ || $min_palindromes < 2 || $min_palindromes > 5 ) {
		$err_msg .= "min_palindromes: valid values are 2, 3, 4, & 5\n";
	}

	# --tabbed_output overrides these
	if ( $do_tabbed_output ) {
		$do_verbose = '';
		$do_pretty_print = '';
	}

	# --pretty_print overrides --verbose
	if ( $do_pretty_print ) {
		$do_verbose = '';
	}

	# when only displaying decimal notation, it makes no sense to sort by match count
	if ( $do_verbose ) {
		$do_sort_by_value = 1;
	}

	if ( $err_msg ) {
		exit_with_usage( $err_msg );
	}

	return;
}


sub exit_with_usage {

	my $err_msgs	= shift;
	my $to_stdout	= shift;

	if ( $to_stdout ) {
		print $USAGE_LONG;
		exit 0;
	}

	print STDERR $USAGE;

	foreach my $msg ( split /\n/, $err_msgs ) {
		if ( $msg ) {
			print STDERR '[error] ', $msg, "\n";
		}
	}

	exit 1;
}