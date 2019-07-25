use Test::Most;
use JSON::MaybeXS;

{
  package Local::User;

  use Moo;
  use MooX::JSON;

  has name => (is=>'ro', json=>1);
  has age => (is=>'ro', json=>'age-years,num');
  has alive => (is=>'ro', json=>',bool');
  has possibly_empty => (is=>'ro', json=>',omit_if_empty');
  has not_encoded => (is=>'ro');
}

ok my $json = JSON::MaybeXS->new(convert_blessed=>1);
ok my $user = Local::User->new(name=>'John', age=>25, alive=>'yes', not_encoded=>'internal');
ok my $encoded = $json->encode($user);

ok $encoded=~m/"age-years":25/;
ok $encoded=~m/"name":"John"/;
ok $encoded=~m/"alive":true/;
ok $encoded!~m/possibly_empty/;
is length($encoded),43;

done_testing;

