#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese timeit);
use JSON::PP qw();
use Text::TNetstrings::PP qw(:all);
eval {
	require Text::TNetstrings::XS;
	require JSON::XS;
};

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
	'TNetstrings::PP' => timeit(10000, sub {decode_tnetstrings(encode_tnetstrings($structure))}),
);
if(exists($INC{'JSON/XS.pm'})) {
	$benchmarks{'JSON::XS'} = timeit(100000, sub {JSON::XS::decode_json(JSON::XS::encode_json($structure))});
}
if(exists($INC{'Text/TNetstrings/XS.pm'})) {
	$benchmarks{'TNetstrings::XS'} = timeit(100000, sub {
			Text::TNetstrings::XS::decode_tnetstrings(Text::TNetstrings::XS::encode_tnetstrings($structure));
	});
}

cmpthese(\%benchmarks);

