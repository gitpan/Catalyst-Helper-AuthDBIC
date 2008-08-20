package Auth::Schema::User;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("DigestColumns", "Core");
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "username",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "email",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "password",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "status",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "role_text",
  { data_type => "TEXT", is_nullable => 0, size => undef },
  "session_data",
  { data_type => "TEXT", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "user_roles",
  "Auth::Schema::UserRole",
  { "foreign.user" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-08-20 22:39:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hzVawgjUd4ybZpuc/7T1ww


 __PACKAGE__->digestcolumns(
             columns   => [qw/ password /],
             algorithm => 'SHA-1',
             encoding  => 'base64',
             auto      => 1,
);

1;
