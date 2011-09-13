#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese);
use Text::TNetstrings qw(:all);

cmpthese(100000, {
	'null' => sub{decode_tnetstrings(encode_tnetstrings(undef))},
	'string' => sub{decode_tnetstrings(encode_tnetstrings("hello"))},
	'number' => sub{decode_tnetstrings(encode_tnetstrings(42))},
	'float' => sub{decode_tnetstrings(encode_tnetstrings(3.14))},
	'array' => sub{decode_tnetstrings(encode_tnetstrings(["hello"]))},
	'hash' => sub{decode_tnetstrings(encode_tnetstrings({"hello" => "world"}))},
});

