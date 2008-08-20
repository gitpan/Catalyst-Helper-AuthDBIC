#!/usr/bin/perl
use warnings;
use strict;
use Catalyst::Helper::AuthDBIC;

=head1 NAME

auth_bootstrap.pl

=head1 Summary

Run with no arguments in the root directory of a catalyst application
to bootstrap a catalyst application.  This uses
Catalyst::Helper::AuthDBIC to do so.  This is an experiemntal module,
and you are urged to back up your application before using this
script.  At present there are no options to pass on to the script.

=cut

Catalyst::Helper::AuthDBIC::make_model();
Catalyst::Helper::AuthDBIC::mk_auth_controller();
Catalyst::Helper::AuthDBIC::add_plugins();
Catalyst::Helper::AuthDBIC::add_config();
Catalyst::Helper::AuthDBIC::write_templates();
Catalyst::Helper::AuthDBIC::update_makefile();
