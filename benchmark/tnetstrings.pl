#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese timeit);
use JSON::PP qw();
use Text::TNetstrings::PP qw(:all);
require Text::TNetstrings::XS;

my $structure = {
	'hello' => 'world',
	'array' => [1,2,3,4,5,'six'],
	'hash' => {
		'eggs' => 'spam',
	},
	'pi' => 3.14,
	'null' => undef,
};
my $encoded = encode_tnetstrings($structure);

cmpthese(0, {
	'encode PP' => sub {encode_tnetstrings($structure)},
	'encode XS' => sub {Text::TNetstrings::XS::encode_tnetstrings($structure)},
});

cmpthese(0, {
	'decode PP' => sub {decode_tnetstrings($encoded)},
	'decode XS' => sub {Text::TNetstrings::XS::decode_tnetstrings($encoded)},
});

cmpthese(0, {
	'TNetstrings::PP' => sub {decode_tnetstrings(encode_tnetstrings($structure))},
	'TNetstrings::XS' => sub {
		Text::TNetstrings::XS::decode_tnetstrings(Text::TNetstrings::XS::encode_tnetstrings($structure));
	},
});
