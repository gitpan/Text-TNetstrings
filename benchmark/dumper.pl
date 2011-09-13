#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese timeit);
use Data::Dumper;
use Text::TNetstrings qw(:all);

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
	'TNetstrings' => sub {decode_tnetstrings(encode_tnetstrings($structure))},
});

