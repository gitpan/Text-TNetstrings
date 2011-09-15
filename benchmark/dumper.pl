#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese timeit);
use Data::Dumper qw(Dumper DumperX);
use Text::TNetstrings::PP;
use Text::TNetstrings::XS;

$Data::Dumper::Useperl = 1;

my $structure = {
	'hello' => 'world',
	'array' => [1,2,3,4,5,'six'],
	'hash' => {
		'eggs' => 'spam',
	},
	'pi' => 3.14,
	'null' => undef,
};

cmpthese(10000, {
	'Dumper'      => sub {eval(Dumper($structure))},
	'DumperX'      => sub {eval(DumperX($structure))},
	'TNetstrings::PP' => sub {Text::TNetstrings::PP::decode_tnetstrings(Text::TNetstrings::PP::encode_tnetstrings($structure))},
	'TNetstrings::XS' => sub {Text::TNetstrings::XS::decode_tnetstrings(Text::TNetstrings::XS::encode_tnetstrings($structure))},
});

