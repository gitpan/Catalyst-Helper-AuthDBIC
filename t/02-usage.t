#!/usr/bin/env perl

use strict;
use warnings;
use Test::Command qw/no_plan/;
use Test::More;
use Directory::Scratch;
use Path::Class;
use FindBin qw/$Bin/;
my $bootstrap = "$Bin/../script/auth_bootstrap.pl";

use ok 'Catalyst::Helper::AuthDBIC';

my $scratch = Directory::Scratch->new();
my $wdir = Path::Class::Dir->new($scratch);

chdir $wdir;
exit_is_num ( 'catalyst.pl Test::App', 0 , 'test app');
ok(chdir 'Test-App');
exit_is_num ("/usr/bin/env perl $bootstrap -credential http", 0, 'auth bootstrap');
exit_is_num( "/usr/bin/env perl script/test_app_auth_admin.pl -user fred -password wilma", 0 , "created user");

my $controller = <<'EOF';

package Test::App::Controller::Secret;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub auto : Private {
    my ( $self, $c ) = @_;
    $c->authenticate({realm => 'users'});
}

sub default : Path {
    my ($self, $c) = @_;
    $c->res->body('ok');
}

1;

EOF

my $controller_file;
$controller_file = $wdir->subdir('Test-App')->subdir('lib')->subdir('Test')->subdir('App')->subdir('Controller')->file('Secret.pm');

my $FH;

open $FH, ">", $controller_file;
print $FH $controller;
close $FH;
# stdout_like('$wdir/script/test_app_test.pl /secret', qr/Authorization required/ism, 'auth required');
$DB::single=1;
undef $scratch;