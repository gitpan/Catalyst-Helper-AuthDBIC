use inc::Module::Install;

name     'Catalyst-Helper-AuthDBIC';
all_from 'lib/Catalyst/Helper/AuthDBIC.pm';
author   'Kieren Diment <zarquon@cpan.org>';

build_requires 'Test::More';

build_requires 'Catalyst::Runtime';
build_requires 'ok';
requires 'DBIx::Class::DigestColumns';
requires 'Digest::SHA1';
requires 'PPI';
requires 'DBIx::Class::Schema::Loader';

# not real deps but the generated bits of app need them.
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Authentication::Store::DBIC';

install_script glob('script/*.pl');


auto_install;

WriteAll;

