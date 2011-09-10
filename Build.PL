use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::TNetstrings',
    license             => 'mit',
	configure_requires => {
		'version' => '>=0.77',
		'Module::Build' => '',
	},
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'    => 5.006,
        'version' => '>=0.77',
    },
    add_to_cleanup     => [ 'Text-TNetstrings-*' ],
);

$builder->create_build_script();
