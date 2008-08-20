package Auth::Schema::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("DigestColumns", "Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "role",
  { data_type => "TEXT", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "user_roles",
  "Auth::Schema::UserRole",
  { "foreign.roleid" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-08-20 22:39:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e8MneMy/w9Kxzjhl1BIO5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
