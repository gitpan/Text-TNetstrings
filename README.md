Text::TNetstrings
=================

The library provides an implementation of the TNetstrings serialization
format.


Usage
=====

	use Text::TNetstrings qw(:all);

	my $data = encode_tnetstrings({"foo" => "bar"}) # => "12:3:foo,3:bar,}"
	my $hash = decode_tnetstrings($data)            # => {"foo" => "bar"}

Performance
===========

The JSON benchmark shows that TNetstrings is about twice as fast as the
Pure-Perl JSON module (version 2.27105), and the XS version is ~15%
slower than the JSON module.

	$ perl -Ilib benchmark/json.pl
	                    Rate  JSON::PP TNetstrings::PP TNetstrings::XS  JSON::XS
	JSON::PP           727/s        --            -47%            -97%      -97%
	TNetstrings::PP   1366/s       88%              --            -94%      -95%
	TNetstrings::XS  24814/s     3312%           1716%              --      -14%
	JSON::XS         28736/s     3851%           2003%             16%        --

The above benchmarks were performed on a dual core Intel Atom 330 @ 1.6GHz.


Installation
============

Module::Build is used as the build system for this library. The typical
procedure applies:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install


Documentation
=============

The library contains embedded POD documentation. Any of the POD tools
can be used to generate documentation, such as pod2html


License
=======

The library is licensed under the MIT license. Please read the LICENSE
file for details.


