use inc::Module::Install;

my $module = 'Catalyst::Helper::AuthDBIC';

my $dist   = $module;
$dist =~ s/::/-/g;
name($dist);

my @path = split '::', $module;
all_from('lib/'. (join '/',@path). '.pm');

build_requires 'Catalyst::Runtime';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
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

WriteAll();
