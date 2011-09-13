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
Pure-Perl JSON module (version 2.27105).


	$ perl -Ilib benchmark/json.pl
	               Rate    JSON::PP TNetstrings    JSON::XS
	JSON::PP      700/s          --        -48%        -98%
	TNetstrings  1359/s         94%          --        -95%
	JSON::XS    29326/s       4091%       2058%          --

Similarly the Pure-Perl version of Data::Dumper performs about twice as
slow as TNetstrings.

	$ perl -Ilib benchmark/dumper.pl
	              Rate      Dumper TNetstrings
	Dumper       700/s          --        -48%
	TNetstrings 1355/s         93%          --

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


