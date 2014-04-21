package JSON::PS;
use strict;
use warnings;
no warnings 'utf8';
use warnings FATAL => 'recursion';
our $VERSION = '1.0';
use B;
use Carp;
use Encode ();

our @EXPORT;

sub import ($;@) {
  my $from_class = shift;
  my ($to_class, $file, $line) = caller;
  no strict 'refs';
  for (@_ ? @_ : @{$from_class . '::EXPORT'}) {
    my $code = $from_class->can ($_)
        or croak qq{"$_" is not exported by the $from_class module at $file line $line};
    *{$to_class . '::' . $_} = $code;
  }
} # import

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

my $StringNonSafe = qr/[\x00-\x1F\x22\x5C\x2B\x3C\x7F-\x9F\x{D800}-\x{DFFF}\x{FDD0}-\x{FDEF}\x{FFFE}-\x{FFFF}\x{1FFFE}-\x{1FFFF}\x{2FFFE}-\x{2FFFF}\x{3FFFE}-\x{3FFFF}\x{4FFFE}-\x{4FFFF}\x{5FFFE}-\x{5FFFF}\x{6FFFE}-\x{6FFFF}\x{7FFFE}-\x{7FFFF}\x{8FFFE}-\x{8FFFF}\x{9FFFE}-\x{9FFFF}\x{AFFFE}-\x{AFFFF}\x{BFFFE}-\x{BFFFF}\x{CFFFE}-\x{CFFFF}\x{DFFFE}-\x{DFFFF}\x{EFFFE}-\x{EFFFF}\x{FFFFE}-\x{FFFFF}\x{10FFFE}-\x{10FFFF}]/;

our $Symbols = {
  LBRACE => '{',
  RBRACE => '}',
  LBRACKET => '[',
  RBRACKET => ']',
  COLON => ':',
  COMMA => ',',
  indent => '',
  last => '',
  sort => 0,
};
my $PrettySymbols = {
  LBRACE => "{\x0A",
  RBRACE => '}',
  LBRACKET => "[\x0A",
  RBRACKET => ']',
  COLON => ' : ',
  COMMA => ",\x0A",
  indent => '   ',
  last => "\x0A",
  sort => 1,
};

sub _encode_value ($$);
sub _encode_value ($$) {
  if (defined $_[0]) {
    if (my $ref = ref $_[0]) {
      if (UNIVERSAL::can ($_[0], 'TO_JSON')) {
        return _encode_value $_[0]->TO_JSON, $_[1];
      }

      if ($ref eq 'ARRAY') {
        my $indent = $_[1].$Symbols->{indent};
        my @v = map { $indent, (_encode_value $_, $indent), $Symbols->{COMMA} } @{$_[0]};
        $v[-1] = $Symbols->{last} if @v;
        return $Symbols->{LBRACKET}, @v, $_[1], $Symbols->{RBRACKET};
      }

      if ($ref eq 'HASH') {
        my $indent = $_[1].$Symbols->{indent};
        my @key = keys %{$_[0]};
        @key = sort { $a cmp $b } @key if $Symbols->{sort};
        my @v = map {
          if ($_ =~ /$StringNonSafe/o) {
            my $v = $_;
            $v =~ s/($StringNonSafe)/sprintf '\\u%04X', ord $1/geo; # XXX surrogate
            $indent, '"', $v, '"', $Symbols->{COLON}, _encode_value ($_[0]->{$_}, $indent), $Symbols->{COMMA};
          } else {
            $indent, '"', $_, '"', $Symbols->{COLON}, _encode_value ($_[0]->{$_}, $indent), $Symbols->{COMMA};
          }
        } @key;
        $v[-1] = $Symbols->{last} if @v;
        return $Symbols->{LBRACE}, @v, $_[1], $Symbols->{RBRACE};
      }
    }

    my $f = B::svref_2object (\($_[0]))->FLAGS;
    if ($f & (B::SVp_IOK | B::SVp_NOK) && $_[0] * 0 == 0) {
      my $n = 0 + $_[0];
      if ($n =~ /\A(-?(?>[1-9][0-9]*|0)(?>\.[0-9]+)?(?>[eE][+-]?[0-9]+)?)\z/) {
        return $n;
      }
    }

    if ($_[0] =~ /$StringNonSafe/o) {
      my $v = $_[0];
      $v =~ s/($StringNonSafe)/sprintf '\\u%04X', ord $1/geo; # XXX surrogate
      return '"', $v, '"';
    } else {
      return '"', $_[0], '"';
    }
  } else {
    return 'null';
  }
} # _encode_value

push @EXPORT, qw(perl2json_bytes);
sub perl2json_bytes ($) {
  return Encode::encode 'utf-8', join '', _encode_value $_[0], '';
} # perl2json_bytes

push @EXPORT, qw(perl2json_chars);
sub perl2json_chars ($) {
  return join '', _encode_value $_[0], '';
} # perl2json_chars

push @EXPORT, qw(perl2json_bytes_for_record);
sub perl2json_bytes_for_record ($) {
  local $Symbols = $PrettySymbols;
  return Encode::encode 'utf-8', join '', _encode_value ($_[0], ''), "\x0A";
} # perl2json_bytes_for_record

push @EXPORT, qw(perl2json_chars_for_record);
sub perl2json_chars_for_record ($) {
  local $Symbols = $PrettySymbols;
  return join '', _encode_value ($_[0], ''), "\x0A";
} # perl2json_chars_for_record

1;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
