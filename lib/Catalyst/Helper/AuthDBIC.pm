package Catalyst::Helper::AuthDBIC;
use strict;
use warnings;
use Catalyst::Helper;
our $VERSION = '0.01';
use Carp;
use UNIVERSAL::require;
use DBI;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use Memoize;
use PPI;
use PPI::Find;
use Catalyst::Utils;
use PPI::Dumper;
memoize('app_name');

=head1 NAME

Catalyst::Helper::AuthDBIC (EXPERIMENTAL)

=head1 SUMMARY

This is an experimental module to bootstrap the authentication portion
of a Catalyst application.  It creates a Catalyst model,
DBIx::Class::Schema classes, basic templates adjusts the required
plugins for you, and configures authentication.  There are no options,
and it doesn't do much inthe way of error checking for you, so you are
recommended to back up your application before using this module.

=head2 USAGE

run the auth_bootstrap.pl in your application's root dir.

=head2 sub app_name()

Get the name of the application from Makefile.PL

=cut

sub app_name {
    my $app_name;
    my $file = "Makefile.PL";
    open my ($FH), "<", $file or croak "Makefile.PL not found, run this script from your application root dir\n";
    while (<$FH>) {
        next unless /^name '(.*?)';/;
        $app_name=$1;
        croak "Makefile.PL appears to have no name for the application\n" unless $app_name;
        last;
    }
    return $app_name
}

=head2 sub make_model()

Creates the sqlite auth db in ./db and makes the dbic schema and
catalyst model with Catalyst::Helper::Model::DBIC::Schema

=cut

sub make_model {
    # put sqlitedb in __path_to('db')__;
    my $helper = Catalyst::Helper->new();
    $helper->mk_dir('db');
    my $dbh = DBI->connect("dbi:SQLite:dbname=db/auth.db","","");
    my @sql = ("CREATE TABLE role (
                id   INTEGER PRIMARY KEY,
                role TEXT );",
               "CREATE TABLE user (
                id       INTEGER PRIMARY KEY,
                username TEXT,
                email    TEXT,
                password TEXT,
                status   TEXT,
                role_text TEXT,
                session_data TEXT );",
               "CREATE TABLE user_role (
                id   INTEGER PRIMARY KEY,
                user INTEGER REFERENCES user(id),
                roleid INTEGER REFERENCES role(id) );"
           );

    map { $dbh->do($_) } @sql;
    my $app_name = Catalyst::Utils::appprefix(app_name());
    make_schema_at("Auth::Schema",
                   {  components => ['DigestColumns'],
                      dump_directory => 'lib' ,
                  },
                   ["dbi:SQLite:dbname=db/auth.db", "",""]);

    my @cmd = ( "./script/$app_name" . "_create.pl" ,
                 'model',
                 'Auth',
                 'DBIC::Schema',
                 'Auth::Schema',
                 'dbi:SQLite:db/auth.db,"",""');
    system( @cmd );
    my $user_schema = 'Auth::Schema::User';
    my @path = split /::/, $user_schema;
    my $user_schema_path = join '/', @path;
    my $module = "lib/$user_schema_path.pm";
    my $doc = PPI::Document->new($module);
    my $digest_code = $helper->get_file(__PACKAGE__, 'digest');

    my $comments = $doc->find(
        sub { $_[1]->isa('PPI::Token::Comment')}
    );
    my $last_comment = $comments->[$#{$comments}];
    $last_comment->set_content($digest_code);
    $doc->save($module);
}

=head2 sub mk_auth_controller()

uses Catalyst::Helper to make a ::Controller::Auth

=cut

sub mk_auth_controller {
    my $helper = Catalyst::Helper->new();
    my $app_name = app_name();
    my $controller_file = "lib/$app_name/Controller/Auth.pm";
    $helper->render_file ('auth_controller',
                          $controller_file,
                          {app_name => $app_name});
}

=head2 sub add_plugins()

    uses ppi to add the auth plugins in the use Catalyst qw// statement

=cut

sub add_plugins {
    my ($module, $doc) = _get_ppi();
    
    my $find = PPI::Find->new( \&_find_use_catalyst);
    my ($found) = $find->in($doc);
    my $find_plugins = PPI::Find->new(\&_find_plugins);
    my ($plugins) = $find_plugins->in($found);
    croak "Your app is not using any plugins, so we can't continue\n" if !$plugins;
    my $plugin_str = scalar($plugins);
    my $tail = chop $plugin_str;
    $plugin_str .= "\n               Authentication\n               Authorization::Roles\n               Session\n               Session::State::Cookie\n               Session::Store::FastMmap $tail";
    $plugins->set_content($plugin_str);
    $doc->save($module);
}

sub _find_plugins {
    my ($element, $search) = @_;
    return 1 if $element->isa('PPI::Token::QuoteLike::Words');
    return 0
}

sub _find_use_catalyst {
    my ($element, $search) = @_;
    if ( $element->isa('PPI::Statement::Include') &&
         $element->type eq 'use' &&
         $element->module eq 'Catalyst'
     ) {
        return 1;
    }
    return 0;
}

=head2 sub add_config()

Add the auth configuration in MyApp.pm

=cut

sub add_config {
    my ($module, $doc) = _get_ppi();
    my $found = PPI::Find->new(\&_find_setup);
    my ($setup) = $found->in($doc);
    croak "unable to find __PACKAGE__->setup in $module\n" if !$setup;
    my $auth_doc = PPI::Document->new(\(Catalyst::Helper->get_file(__PACKAGE__, 'auth_conf')));
    my $auth_conf = $auth_doc->find_first('PPI::Statement');
    # can't get this working, so we'll cope with cosmetic uglyness
    #     my $space =  PPI::Document->new(\"\n")->find_first('PPI::Token::Whitespace');
    #    $setup->insert_before($space);
    #    my $sib = $setup->previous_sibling;
    $setup->insert_before($auth_conf);
    $doc->save($module);
}

sub _find_setup {
    my ($element, $search) = @_;
    if ( $element->isa('PPI::Statement')
         && $element =~ /setup.*?;/
     ) {
        return 1;
    }
    return 0;
}

sub _get_ppi {
    my $app_name = app_name() || 'TestApp';
    my @path = split /::/, $app_name;
    my $app_path = join '/', @path;
    my $module = "lib/$app_path.pm";
    my $doc = PPI::Document->new($module);
    return ($module, $doc);
}

=head2 write_templates()

make the login, logout and unauth templates

=cut

sub write_templates {
    my $helper = Catalyst::Helper->new();
    my $login = $helper->get_file(__PACKAGE__, 'login.tt');
    my $logout = $helper->get_file(__PACKAGE__, 'logout.tt');
    my $unauth = $helper->get_file(__PACKAGE__, 'unauth.tt');
    $helper->mk_dir("root/auth");
    $helper->mk_file("root/auth/login.tt", $login);
    $helper->mk_file("root/auth/logout.tt", $logout);
    $helper->mk_file("root/auth/unauth.tt", $unauth);
}

=head2 update_makefile()

Adds the auth and session dependencies to Makefile.PL

=cut

sub update_makefile {
    my $deps = Catalyst::Helper->get_file(__PACKAGE__, 'requires');
    my $doc = PPI::Document->new('Makefile.PL');
    my $find = PPI::Find->new( \&_find_install_script );
    my ($found) = $find->in($doc);
    croak "There's something wrong with your Makefile.PL so we can't continue (can't find  the install_script directive\n" if ! $found;
    my $install_script = $found->find_first('PPI::Token::Word');
    my $install_script_str = scalar($install_script);
    $install_script->set_content($deps . "\n" . $install_script_str);
    $doc->save('Makefile.PL')
}

sub _find_install_script {
    my ($element, $search) = @_;
    if ($element->isa('PPI::Statement')
            && $element =~ 'install_script') {
        return 1;
    }
    return 0;
}


=head2 BUGS

This is experimental, fairly rough code.  It's a proof of concept for
helper modules for Catalyst that need to alter the application
configuration, Makefile.PL and other parts of the application.  Bug
reports, and patches are encouraged.  Report bugs or provide patches
to http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Helper-AuthDBIC.

=head2 AUTHOR

Kieren Diment <zarquon@cpan.org>


=head1 COPYRIGHT AND LICENCE

Copyright (c) 2008 Kieren Diment

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;

__DATA__

=begin pod_to_ignore

__auth_controller__
package [% app_name %]::Controller::Auth;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    $c->detach('get_login');
}

sub get_login : Local {
    my ($self, $c) = @_;
    $c->stash->{destination} = $c->req->path;
    $c->stash->{template} = 'auth/login.tt';
}

sub logout : Local {
    my ( $self, $c ) = @_;
    $c->logout;
    $c->stash->{template} = 'auth/logout.tt';
}

sub login : Local {
    my ( $self, $c ) = @_;
    my $user = $c->req->params->{user};
    my $password = $c->req->params->{password};
    $c->flash->{destination} = $c->req->params->{destination} || $c->req->path;
    $c->stash->{remember} = $c->req->params->{remember};
    if ( $user && $password ) {
        if ( $c->authenticate( { username => $user,
                                 password => $password } ) ) {
            $c->{session}{expires} = 999999999999 if $c->req->params->{remember};
            $c->res->redirect($c->uri_for($c->flash->{destination}));
        }
        else {
            # login incorrect
            $c->stash->{message} = 'Invalid user and/or password';
            $c->stash->{template} =  'auth/login.tt';
        }
    }
    else {
        # invalid form input
        $c->stash->{message} = 'invalid form input';
        $c->stash->{template} =  'auth/login.tt';
    }
}

sub unauthorized : Private {
    my ($self, $c) = @_;
    $c->stash->{template}= 'auth/unauth.tt';
}

1;

=head1 NAME

[% app_name %]Controller::Auth

=head2 SUMMARY

This is a controller to provide simple authentication provided by
Catalyst::Helper::AuthDBIC. The database schema provided by the Helper
will also provide autheorization facilities.  As an example, If you
wanted to use this controller to provide application wide requirement
for login you would put something like the following in
MyApp::Controller::Root:

 sub auto : Private {
      my ( $self, $c) = @_;
      if ( !$c->user && $c->req->path !~ /^auth.*?login/) {
          $c->forward('[% app_name %]::Controller::Auth');
          return 0;
      }
      return 1;
 }


__auth_conf__
 __PACKAGE__->config( authentication => {
    'default_realm' => 'users',
    'realms' => {
        'users' => {
            'store' => {
                'role_column' => 'role_text',
                'user_class' => 'AuthSchema::User',
                'class' => 'DBIx::Class',
            }, 
           'credential' => {
                'password_type' => 'hashed',
                'password_field' => 'password',
                'password_hash_type' => 'SHA-1',
                'class' => 'Password'
            }
        }
    },
});

__digest__
 __PACKAGE__->digestcolumns(
             columns   => [qw/ password /],
             algorithm => 'SHA-1',
             encoding  => 'base64',
             auto      => 1,
);

__requires__
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Authentication::Store::DBIC';
requires 'Digest::SHA1';
__login.tt__
<h1> Please login</h1>
[% IF c.stash.message != '' %] <h2 style='color:red'> [% c.stash.message %] </h2
> [% END %]
<form name="login" method='post' action='[% c.uri_for('/auth/login')  %]'>
User: <input name='user' type='text' /><br />
Password: <input name='password' type='password' /><br />
<input type='checkbox' name='remember' >Remember me</input> <br />
<input type='hidden' value='[% c.flash.destination  %]' />
<input type='submit' name='Log In' /> &nbsp; <input type='reset' name='Reset' />
</form>

__logout.tt__
<h1> Logout successful</h1>
<a href='[% c.uri_for('/') %]'>Return to home page</a>
__unauth.tt__
<h1> [%c.user.id %]: You are not allowed to view this page.</h1>
You can <a href="[% c.req.referrer  %]">go back</a> where you came from, or <a h
ref="[% c.uri_for('/auth/logout') %]">logout</a> and try logging in again as a d
ifferent user.  If you think this is an error, please contact <a href="mailto:[%
c.config.admin %]">[% c.config.admin %]</a>

