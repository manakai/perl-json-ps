use strict;
use warnings;
no warnings 'utf8';
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ("t_deps/modules/*/lib");
use Test::X1;
use Test::More;
use Test::Differences;
use JSON::PS;
use Web::Encoding;

sub u8 ($) {
  return encode_web_utf8 $_[0];
} # u8

# ------ json_chars2perl ------

test {
  my $c = shift;
  is_deeply json_chars2perl('{"a":"b","c":"\u3000"}'), {qw/a b c/, "\x{3000}"};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl "null", undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl '"null"', 'null';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl '"\u5010"', "\x{5010}";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl qq{"\x{6000}"}, "\x{6000}";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl('{"a":"b",'), undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl '""', '';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_chars2perl '0', 0;
  done $c;
} n => 1;

# ------ json_bytes2perl ------

test {
  my $c = shift;
  is_deeply json_bytes2perl('{"a":"b","c":"\u3000"}'), {qw/a b c/, "\x{3000}"};
  done $c;
} n => 1;

test {
  my $c = shift;
  is_deeply json_bytes2perl('{"a":"b","c": "'.(u8 "\x{3000}").'"}'), {qw/a b c/, "\x{3000}"};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl "null", undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl '"null"', 'null';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl qq{"\x89\xE0\xC0ab"},
      "\x{FFFD}\x{FFFD}\x{FFFD}ab";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl '"\u5010"', "\x{5010}";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl qq{"\x{6000}"}, "\x{6000}";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl u8 qq{"\x{6000}"}, "\x{6000}";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl '""', '';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl qq<  ""  \n>, '';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl "''", undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl "'abc'", undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl '" "', ' ';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl '0', 0;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl undef, undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl '', undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl "\n", undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl 'abcdef', undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl('{"a":"b",'), undef;
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff json_bytes2perl(u8 qq{{"\x{2028}":"\x{2029}"}}),
      {"\x{2028}" => "\x{2029}"};
  done $c;
} n => 1;

# ------ perl2json_chars ------

test {
  my $c = shift;
  is perl2json_chars(undef), 'null';
  done $c;
} n => 1;

test {
  my $c = shift;
  my $actual = perl2json_chars({qw/a b c/, "\x{3000}"});
  ok $actual eq qq'{"c":"\x{3000}","a":"b"}' ||
     $actual eq qq'{"a":"b","c":"\x{3000}"}';
  done $c;
} n => 1;

test {
  my $c = shift;
  is perl2json_chars({"<A>" => "<b>+"}), qq'{"\\u003CA>":"\\u003Cb>\\u002B"}';
  done $c;
} n => 1;

test {
  my $c = shift;
  my $got = perl2json_chars({qw/a b c/, "\x{3000}\x{D800}"});
  ok $got eq qq{{"c":"\x{3000}\\uD800","a":"b"}} ||
     $got eq qq{{"a":"b","c":"\x{3000}\\uD800"}};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars undef, 'null';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars "undef", '"undef"';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars "\x{5000}\x{132}a", qq{"\x{5000}\x{0132}a"};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars "\x89\xC1\xFEa", qq{"\\u0089\x{00C1}\x{00FE}a"};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars '', '""';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars 0, '0';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars {"\x{2028}\x{2029}" => "\x{2028}\x{2029}"},
      q<{"\\u2028\\u2029":"\\u2028\\u2029"}>;
  done $c;
} n => 1;

# ------ perl2json_chars_for_record ------

test {
  my $c = shift;
  is perl2json_chars_for_record({"<A>" => "<b+>"}), qq'{
   "\\u003CA>" : "\\u003Cb\\u002B>"
}
';
  done $c;
} n => 1;

test {
  my $c = shift;
  is perl2json_chars_for_record({qw/a b c/, "\x{3000}\x{D800}"}), qq{{
   "a" : "b",
   "c" : "\x{3000}\\uD800"
}
};
  done $c;
} n => 1;

test {
  my $c = shift;
  is perl2json_chars_for_record({qw/a b c/, "\x{3000}"}),
        qq'{
   "a" : "b",
   "c" : "\x{3000}"
}
';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record undef, 'null' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record "undef", '"undef"' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record "\x{5000}\x{132}a", qq{"\x{5000}\x{0132}a"\x0A};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record "\x89\xC1\xFEa", qq{"\\u0089\x{00C1}\x{00FE}a"\x0A};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record '', '""' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record 0, '0' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_chars_for_record {"\x{2028}\x{2029}" => "\x{2028}\x{2029}"}, q<{
   "\\u2028\\u2029" : "\\u2028\\u2029"
}
>;
  done $c;
} n => 1;

# ------ perl2json_bytes ------

test {
  my $c = shift;
  my $got = perl2json_bytes({qw/a b c/, "\x{3000}"});
  ok $got eq (u8 qq'{"c":"\x{3000}","a":"b"}') ||
     $got eq (u8 qq'{"a":"b","c":"\x{3000}"}');
  done $c;
} n => 1;

test {
  my $c = shift;
  is perl2json_bytes({"+<A>" => "<b>"}), qq'{"\\u002B\\u003CA>":"\\u003Cb>"}';
  done $c;
} n => 1;

test {
  my $c = shift;
  my $actual = perl2json_bytes({qw/a b c/, "\x{3000}\x{D800}"});
  ok $actual eq qq{{"c":"\xe3\x80\x80\\uD800","a":"b"}} ||
     $actual eq qq{{"a":"b","c":"\xe3\x80\x80\\uD800"}};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes undef, 'null';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes "undef", '"undef"';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes "\x{5000}\x{132}a", u8 qq{"\x{5000}\x{0132}a"};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes "\x89\xC1\xFEa",
      u8 qq{"\\u0089\x{00C1}\x{00FE}a"};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes '', '""';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes 0, '0';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes {"\x{2028}\x{4000}\x{2029}" => "\x{2028}\x{2029}"},
      qq<{"\\u2028\xe4\x80\x80\\u2029":"\\u2028\\u2029"}>;
  done $c;
} n => 1;

# ------ perl2json_bytes_for_record ------

test {
  my $c = shift;
  is perl2json_bytes_for_record({"<A>" => "<+b>"}), qq'{
   "\\u003CA>" : "\\u003C\\u002Bb>"
}
';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record({qw/a b c/, "\x{3000}\x{D800}"}), qq{{
   "a" : "b",
   "c" : "\xe3\x80\x80\\uD800"
}
};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record({qw/a b c/, "\x{3000}"}),
        u8 qq'{
   "a" : "b",
   "c" : "\x{3000}"
}
';
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record undef, 'null' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record "undef", '"undef"' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record "\x{5000}\x{132}a",
      u8 qq{"\x{5000}\x{0132}a"\x0A};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record "\x89\xC1\xFEa",
      u8 qq{"\\u0089\x{00C1}\x{00FE}a"\x0A};
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record '', '""' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record 0, '0' . "\x0A";
  done $c;
} n => 1;

test {
  my $c = shift;
  eq_or_diff perl2json_bytes_for_record {"\x{2028}\x{4000}\x{2029}" => "\x{2028}\x{2029}"}, qq<{
   "\\u2028\xe4\x80\x80\\u2029" : "\\u2028\\u2029"
}
>;
  done $c;
} n => 1;

# ------ file2perl ------

test {
  my $c = shift;
  my $file = path (__FILE__)->parent->child ('abc.json');
  eq_or_diff JSON::PS::file2perl $file, {abc => "\x{4E00}"};
  done $c;
} n => 1;

run_tests;

=head1 LICENSE

Copyright 2009-2011 Hatena <http://www.hatena.ne.jp/>.

Copyright 2012-2019 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
