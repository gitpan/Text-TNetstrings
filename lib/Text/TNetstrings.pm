package Text::TNetstrings;

use 5.010;
use strict;
use warnings;
use feature 'switch';
use Carp qw(croak);
use base qw(Exporter);

=head1 NAME

Text::TNetstrings - Data serialization using typed netstrings.

=head1 VERSION

Version 0.1.0

=cut

use version 0.77; our $VERSION = version->declare("v1.0.0");

=head1 SYNOPSIS

An implementation of the tagged netstring specification, a simple data
interchange format better suited to low-level network communication than
JSON. See http://tnetstrings.org/ for more details.

	use Text::TNetstrings qw(:all);

	my $data = encode_tnetstrings({"foo" => "bar"}) # => "12:3:foo,3:bar,}"
	my $hash = decode_tnetstrings($data)            # => {"foo" => "bar"}

=head1 EXPORT

=over

=item encode_tnetstrings($data)

=item decode_tnetstrings($data)

=item :all

The "all" tag exports all the above subroutines.

=back

=cut

our @EXPORT_OK = qw(encode_tnetstrings decode_tnetstrings);
our %EXPORT_TAGS = (
	"all" => \@EXPORT_OK,
);

=head1 SUBROUTINES/METHODS

=head2 encode_tnetstrings($data)

Encode a scalar, hash or array into TNetstring format.

=cut

sub encode_tnetstrings {
	my ($data) = @_;
	my ($encoded, $type);

	if(ref($data) eq "ARRAY") {
		$encoded = join('', map {encode_tnetstrings($_)} @$data);
		$type = ']';
	} elsif(ref($data) eq "HASH") {
		while(my ($key, $value) = each(%$data)) {
			# Keys must be strings
			$encoded .= encode_tnetstrings("" . $key);
			$encoded .= encode_tnetstrings($value);
		}
		$type = '}';
	} elsif(!defined($data)) {
		$encoded = '';
		$type = '~';
	} elsif($data =~ /^([-+])?[0-9]*\.[0-9]+$/) {
		$encoded = $data;
		$type = '^';
	} elsif($data =~ /^([-+])?[1-9][0-9]*$/) {
		$encoded = $data;
		$type = '#';
	} else {
		$encoded = $data;
		$type = ',';
	}
	# Since there is no boolean type, it's impossible to distinguish
	# between true/false and integers, strings, etc.  Boolean values
	# will simply be represented as whatever the underlying type is
	# (integer, string, undefined).
	return sprintf("%d:%s%c", length($encoded), $encoded, ord($type));
}

=head2 decode_tnetstrings($string)

Decode TNetstring data into the appropriate scalar, hash or array.

=cut

sub decode_tnetstrings {
	my ($encoded) = @_;
	my ($decoded, $length, $data, $type, $rest);
	return unless $encoded;

	($length, $rest) = split(':', $encoded, 2);
	$length = int($length);

	$data = substr($rest, 0, $length);
	$type = substr($rest, $length, 1);
	croak("invalid type '$type'") unless $type =~ m/^[,#^!~}\]]$/;
	$rest = substr($rest, $length + 1) if wantarray && length($rest) >= $length + 1;

	for($type) {
		/,/ and do {
			$decoded = $data;
			last;
		};
		/#/ and do {
			$decoded = int($data);
			last;
		};
		/\^/ and do {
			$decoded = $data;
			last;
		};
		/!/ and do {
			$decoded = $data eq 'true';
			last;
		};
		/~/ and do {
			$decoded = undef;
			last;
		};
		/}/ and do {
			$decoded = {};
			my $ss = $data;
			do {
				my ($x, $y);
				($x, $ss) = decode_tnetstrings($ss);
				($y, $ss) = decode_tnetstrings($ss) or croak("unbalanced hash");
				$decoded->{$x} = $y;
			} while(defined($ss) && $ss ne '');
			last;
		};
		/]/ and do {
			$decoded = [];
			my $ss = $data;
			do {
				my $x;
				($x, $ss) = decode_tnetstrings($ss);
				push(@$decoded, $x);
			} while(defined($ss) && $ss ne '');
			last;
		};
		croak("type $type not supported");
	}

	return wantarray ? ($decoded, $rest) : $decoded;
}

=head1 AUTHOR

Sebastian Nowicki

=head1 SEE ALSO

L<http://tnetstrings.org/> for the TNetstrings specification.

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-tnetstrings at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-TNetstrings>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::TNetstrings


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TNetstrings>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-TNetstrings>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-TNetstrings>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-TNetstrings>

=item * GitHub

L<http://www.github.com/sebnow/text-tnetstrings-perl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Sebastian Nowicki.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1;

