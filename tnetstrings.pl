#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese timeit);
use JSON::PP;
use Text::TNetstrings qw(:all);

my $structure = {
	'hello' => 'world',
	'array' => [1,2,3,4,5,'six'],
	'hash' => {
		'eggs' => 'spam',
	},
	'pi' => 3.14,
	'null' => undef,
};
my $json = encode_json($structure);
my $tnetstrings = encode_tnetstrings($structure);

cmpthese(0, {
	'encode TN' => sub {encode_tnetstrings($structure)},
	'encode JS' => sub {encode_json($structure)},
	'decode TN' => sub {decode_tnetstrings($tnetstrings)},
	'decode JS' => sub {decode_json($json)},
	'TNetstrings::PP' => sub {decode_tnetstrings(encode_tnetstrings($structure))},
	'JSON::PP' => sub {decode_json(encode_json($structure))},
});

