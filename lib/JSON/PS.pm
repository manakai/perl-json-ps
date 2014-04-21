package JSON::PS;
use strict;
use warnings;
no warnings 'utf8';
use warnings FATAL => 'recursion';
our $VERSION = '1.0';
use Encode ();

our @EXPORT;

my $EscapeToChar = {
  '"' => q<">,
  '\\' => q<\\>,
  '/' => q</>,
  'b' => "\x08",
  'f' => "\x0C",
  'n' => "\x0A",
  'r' => "\x0D",
  't' => "\x09",
};

sub _decode_value ($);
sub _decode_value ($) {
  if ($_[0] =~ /\Gtrue/gc) {
    return 1;
  } elsif ($_[0] =~ /\Gfalse/gc) {
    return 0;
  } elsif ($_[0] =~ /\Gnull/gc) {
    return undef;
  } elsif ($_[0] =~ /\G(-?(?>[1-9][0-9]*|0)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?)/gc) {
    return 1*(0+$1);
  } elsif ($_[0] =~ /\G"/gc) {
    my @s;
    while (1) {
      if ($_[0] =~ /\G([^\x22\x5C\x00-\x1F]+)/gc) {
        push @s, $1;
      } elsif ($_[0] =~ m{\G\\(["\\/bfnrt])}gc) {
        push @s, $EscapeToChar->{$1};
      } elsif ($_[0] =~ /\G\\u([0-9A-Fa-f]{4})/gc) {
        push @s, chr hex $1;
# XXX surrogate
      } elsif ($_[0] =~ /\G"/gc) {
        last;
      } else {
        die {index => pos $_[0], type => 'json:bad string'};
      }
    }
    return join '', @s;
  } elsif ($_[0] =~ m{\G\{}gc) {
    my $obj = {};
    $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
    if ($_[0] =~ /\G\}/gc) {
      #
    } else {
      OBJECT: {
        if ($_[0] =~ /\G(?=\")/gc) {
          my $name = _decode_value $_[0];
          $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
          if ($_[0] =~ /\G:/gc) {
            $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
            # XXX duplicate $name warning
            $obj->{$name} = _decode_value $_[0];
            $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
            if ($_[0] =~ /\G,/gc) {
              $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
              redo OBJECT;
            } elsif ($_[0] =~ /\G\}/gc) {
              last OBJECT;
            } else {
              die {index => pos $_[0], type => 'json:bad object sep'};
            }
          } else {
            die {index => pos $_[0], type => 'json:bad object nv sep'};
          }
        } else {
          die {index => pos $_[0], type => 'json:bad object name'};
        }
      } # OBJECT
    }
    return $obj;
  } elsif ($_[0] =~ m{\G\[}gc) {
    my @item;
    $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
    if ($_[0] =~ /\G\]/gc) {
      #
    } else {
      ARRAY: {
        push @item, _decode_value $_[0];
        $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
        if ($_[0] =~ /\G,/gc) {
          $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
          redo ARRAY;
        } elsif ($_[0] =~ /\G\]/gc) {
          last ARRAY;
        } else {
          die {index => pos $_[0], type => 'json:bad array sep'};
        }
      } # ARRAY
    }
    return \@item;
  } else {
    die {index => pos $_[0], type => 'json:bad value'};
  }
} # _decode_value

sub _decode ($) {
  $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
  my $result = _decode_value $_[0];
  $_[0] =~ /\G[\x09\x0A\x0D\x20]+/gc;
  die {index => pos $_[0], type => 'json:eof expected'} if $_[0] =~ /\G./gcs;
  return $result;
} # _decode

push @EXPORT, qw(json_bytes2perl);
sub json_bytes2perl ($) {
  local $@;
  return eval { _decode Encode::decode 'utf-8', $_[0] };
} # json_bytes2perl

push @EXPORT, qw(json_chars2perl);
sub json_chars2perl ($) {
  local $@;
  return eval { _decode $_[0] };
} # json_chars2perl

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
