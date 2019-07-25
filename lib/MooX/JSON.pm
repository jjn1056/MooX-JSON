package MooX::JSON;

use warnings;
use strict;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Carp;
use Class::Method::Modifiers qw(install_modifier);

sub import {
  my ($class) = @_;
  my $target = caller;

  my @to_json;
  {
    no strict 'refs';
    *{"${target}::TO_JSON"} = sub {
      my $self = shift;
      my @structure = ();
      foreach my $rule (@to_json) {
        my $value = $self->${\$rule->{field}};
        if(my $type = $rule->{type}) {
          $value = ''+$value if $type == 1;
          $value = 0+$value if $type == 2;
          $value = $value ? \1:\0 if $type == 3;
        }
        if($rule->{omit_if_empty}) {
          next unless $value;
        }
        push @structure, (
          $rule->{mapped_field} => $value,
        );
      }
      return +{ @structure };
    };
  }

  my %types = (
    str => 1,
    num => 2,
    bool => 3);

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $json = delete $opts{json};
    return $orig->($attr, %opts) unless $json;

    my $field = $attr;
    $field =~ s/^\+//;

    unless(ref $json) {
      my $json_to_split = $json eq '1' ? ',':$json;
      my ($mapped_field, $extra1, $extra2) = split(',', $json_to_split);
      my ($type, $omit_if_empty);

      if(my $found_type = $types{$extra1||''}) {
        $type = $found_type;
      }
      
      $omit_if_empty = 1 if (($extra1||'') eq 'omit_if_empty') || (($extra2||'') eq 'omit_if_empty');

      $json = +{
        field => $field,
        mapped_field => ($mapped_field ? $mapped_field : $field),
        type => $type,
        omit_if_empty => $omit_if_empty,
      };
    }

    push @to_json, $json;
    
    return $orig->($attr, %opts);
  };
}

1;

=head1 NAME

MooX::JSON - Generate a TO_JSON method from attributes.

=head1 SYNOPSIS

    package Local::User;

    use Moo;
    use MooX::JSON;

    has name => (is=>'ro', json=>1);
    has age => (is=>'ro', json=>'age-years,num');
    has alive => (is=>'ro', json=>',bool');
    has possibly_empty => (is=>'ro', json=>',omit_if_empty');
    has not_encoded => (is=>'ro');
    
    use JSON::MaybeXS;

    my $json = JSON::MaybeXS->new(convert_blessed=>1);
    my $user = Local::User->new(
      name=>'John',
      age=>25,
      alive=>'yes',
      not_encoded=>'internal');

    my $encoded = $json->encode($user);

The value of C<$encoded> is:

    {
       "alive" : true,
       "name" : "John",
       "age-years" : 25
    }
   
Please note that the JSON spec does not preserve hash order, so the keys above
could be arranged differently.

=head1 DESCRIPTION

Make it easier to correctly encode your L<Moo> object into JSON.  It does this
by inspecting your attributes and injection a C<TO_JSON> method into your class.

=head1 AUTHOR

John Napiorkowski (cpan:JJNAPIORK) <jjnapiork@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2019 by </AUTHOR> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
