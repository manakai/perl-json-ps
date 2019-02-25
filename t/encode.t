use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use JSON::PS;
use Test::X1;
use Test::Differences;
use Web::Encoding;

sub u8 ($) { encode_web_utf8 $_[0] }

for my $test (
  [undef, 'null'],

  [\1, 'true'],
  [\0, 'false'],
  [\'1', 'true'],
  [\'0', 'false'],
  [[\1], '[true]'],
  [[\0], '[false]'],

  [12.555, '12.555'],
  [-12.555, '-12.555'],
  [10000000000000003200000033, '1e+25'],
  [-10000000000000003200000033, '-1e+25'],
  [10000000000.000003200000033, '10000000000'],
  [0.0000000320004200033, '3.20004200033e-08'],
  [12e-41, '1.2e-40'],
  [0, '0'],
  [0+"inf", (0+"inf") eq 'Inf' ? '"Inf"' : '"inf"'],
  [0+"-inf", (0+"-inf") eq '-Inf' ? '"-Inf"' : '"-inf"'],
  [0+"nan", (0+"nan") eq 'NaN' ? '"NaN"' : '"nan"'],
  [0/"inf", '0'],
  [0/"-inf", '0'],

  ['', '""'],
  [' ', '" "'],
  ['abc', '"abc"'],
  ['aa   d  ', '"aa   d  "'],
  ["\x00\x01\x09\x9F", '"\\u0000\\u0001\\u0009\\u009F"'],
  ["\xFF", qq{"\x{FF}"}],
  ["\x{FFFC}", qq{"\x{FFFC}"}],
  ["\x{FFFF}", qq{"\\uFFFF"}],
  ["\x{4000}\x{4001}\x{10000}", qq{"\x{4000}\x{4001}\x{10000}"}],
  ["a\x0Ab\x0Dc\x0C", qq{"a\\u000Ab\\u000Dc\\u000C"}],
  ["\x{4000}\x{DFFF}\x{4001}\x{10000}", qq{"\x{4000}\\uDFFF\x{4001}\x{10000}"}],
  ["\x{1FFFF}\x{10FFFF}", qq{"\\uD83F\\uDFFF\\uDBFF\\uDFFF"}],
  [{"\x{1FFFF}\x{10FFFF}" => 1}, qq{{"\\uD83F\\uDFFF\\uDBFF\\uDFFF":1}}],

  [[], '[]'],
  [[1, "abc"], '[1,"abc"]'],
  [[1, undef, "abc"], '[1,null,"abc"]'],
  [[{}, undef, "abc"], '[{},null,"abc"]'],
  [[1, undef, {"abc" => 2.22}], '[1,null,{"abc":2.22}]'],

  [{} => qq{{}}],
  [{123, undef} => qq{{"123":null}}],
  [{"\x{FFFE}" => "\x00"} => qq{{"\\uFFFE":"\\u0000"}}],
  [{"\x{FFFE}" => ["\x00",""]} => qq{{"\\uFFFE":["\\u0000",""]}}],
  [{"\x{FFFF}" => ["\x00",""]} => qq{{"\\uFFFF":["\\u0000",""]}}],
  [{"\x{10000}" => ["\x00",""]} => qq{{"\x{10000}":["\\u0000",""]}}],
  [{"\x{1FFFF}" => ["\x00",""]} => qq{{"\\uD83F\\uDFFF":["\\u0000",""]}}],
) {
  test {
    my $c = shift;
    my $result = perl2json_chars $test->[0];
    eq_or_diff $result, $test->[1];
    done $c;
  } n => 1;

  test {
    my $c = shift;
    my $result = perl2json_bytes $test->[0];
    eq_or_diff $result, u8 $test->[1];
    done $c;
  } n => 1;
}

for my $test (
  [[] => "[\x0A]\x0A"],
  [[1, "2", 3] => qq{[\x0A   1,\x0A   "2",\x0A   3\x0A]\x0A}],
  [[1, [2], 3] => q{[
   1,
   [
      2
   ],
   3
]
}],
  [[1, [2, 2.2], 3] => q{[
   1,
   [
      2,
      2.2
   ],
   3
]
}],
  [[1, [2, 2.2, []], 3] => q{[
   1,
   [
      2,
      2.2,
      [
      ]
   ],
   3
]
}],

  [{} => q{{
}
}],
  [{abc => 12} => q{{
   "abc" : 12
}
}],
  [{abc => 12, def => 21} => q{{
   "abc" : 12,
   "def" : 21
}
}],
  [{abc => 12, def => {21 => {}}} => q{{
   "abc" : 12,
   "def" : {
      "21" : {
      }
   }
}
}],
  [{abc => 12, def => {21 => 12}} => q{{
   "abc" : 12,
   "def" : {
      "21" : 12
   }
}
}],
  [{abc => 12, def => {21 => [12, []]}} => q{{
   "abc" : 12,
   "def" : {
      "21" : [
         12,
         [
         ]
      ]
   }
}
}],
) {
  test {
    my $c = shift;
    my $result = perl2json_chars_for_record $test->[0];
    eq_or_diff $result, $test->[1];
    done $c;
  } n => 1;

  test {
    my $c = shift;
    my $result = perl2json_bytes_for_record $test->[0];
    eq_or_diff $result, u8 $test->[1];
    done $c;
  } n => 1;
}

run_tests;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
