#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese timeit);
use JSON::PP qw();
use Text::TNetstrings qw(:all);
eval {require JSON::XS};

my $structure = {
	'hello' => 'world',
	'array' => [1,2,3,4,5,'six'],
	'hash' => {
		'eggs' => 'spam',
	},
	'pi' => 3.14,
	'null' => undef,
};

my %benchmarks = (
	'JSON::PP' => timeit(10000, sub {JSON::PP::decode_json(JSON::PP::encode_json($structure))}),
	'TNetstrings' => timeit(10000, sub {decode_tnetstrings(encode_tnetstrings($structure))}),
);
if(exists($INC{'JSON/XS.pm'})) {
	$benchmarks{'JSON::XS'} = timeit(100000, sub {JSON::XS::decode_json(JSON::XS::encode_json($structure))});
}

cmpthese(\%benchmarks);

