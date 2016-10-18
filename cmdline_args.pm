package cmdline_args;
use strict;

sub get_options {
    my ($validopt_ref, $argv_ref) = @_;
    my ($option, $error);

    if (! @{$argv_ref}) {
	print "No command line options\n";
	return 0;
    }

    while(@{$argv_ref}>0) {
	$option = shift @{$argv_ref};

	my $val = undef;
	if ($option =~ m/^--([^=]+)=(.+)/) {
	    $option = $1;
	    $val = $2;
	}
	    
	if (! defined($validopt_ref->{$option})) {
	    print STDERR "Unknown option \"$option\"\n";
	    $error = 1;
	    next;
	}

	if ($validopt_ref->{$option}->[1]) {
	    # Option which requires argument, shift in the next argument from
	    # the command line, unless it was a --long-opt=value form where
	    # $val would have been set above
	    $val = shift @{$argv_ref} unless defined($val);
	    ${$validopt_ref->{$option}->[0]} = $val;
	} else {
	    # Boolean flag: invert default value
	    if (${$validopt_ref->{$option}->[0]}) {
	         ${$validopt_ref->{$option}->[0]} = 0;
            } else {
                 ${$validopt_ref->{$option}->[0]} = 1;
            }
        }
    }

    return $error;
}
return 1;
