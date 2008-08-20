package Auth::Schema::UserRole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("DigestColumns", "Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "user",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "roleid",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to("user", "Auth::Schema::User", { id => "user" });
__PACKAGE__->belongs_to("roleid", "Auth::Schema::Role", { id => "roleid" });


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-08-20 22:39:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PWPF/7UbMqJ6T5J3735miw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
