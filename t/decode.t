use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use JSON::PS;
use Encode;
use Test::X1;
use Test::Differences;

sub u8 ($) { encode 'utf8', $_[0] }

for my $test (
  ['true' => 1],
  ['false' => 0],
  ['null' => undef],

  ['124' => 124],
  ['124.4' => 124.4],
  ['124.400' => 124.4],
  ['124.000004' => 124.000004],
  ['-1204.4' => -1204.4],
  ['124e5' => 124e5],
  ['124.0004e-2' => 124.0004e-2],
  ['124e+4' => 124e+4],
  ['0' => 0],
  ['-0' => 0],
  ['-0.33441' => -0.33441],
  ['-0.33441e-002' => -0.33441e-2],
  [" \x09\x0A\x0D -0.33441e-002" => -0.33441e-2],
  ["-0.33441\x0D\x0D\x0A \x09" => -0.33441],

  [q{""} => ''],
  [q{"abc"} => 'abc'],
  [qq{" \\t"} => " \x09"],
  [qq{" \\t\\u4E00\\u2fFe"} => " \x09\x{4E00}\x{2FFE}"],
  [qq{" \\t\\u4E00\\uFFFF\\uD800"} => " \x09\x{4E00}\x{FFFF}\x{D800}"],
  [u8 qq{" \\t\x{4E00}\x{FFFC}"} => " \x09\x{4E00}\x{FFFC}", " \x09\xe4\xb8\x80\xef\xbf\xbc"],
  [qq{" \\n\\r\\b\\f\\"\\\\\\/"} => " \x0A\x0D\x08\x0C\"\\/"],

  [q{[]} => []],
  [q{[  ]} => []],
  [q{[12]} => [12]],
  [q{[12,true ,false]} => [12, 1, 0]],
  [q{[12,true ,  null  ]} => [12, 1, undef]],
  [q{[12, [true,null  ]]} => [12, [1, undef]]],
  [q{[12,[true,null  ]]} => [12, [1, undef]]],
  [qq{[12,[true\x09,\x0Dnull \x0A ]\x09]} => [12, [1, undef]]],

  [q{{}} => {}],
  [q{{  }} => {}],
  [q{{"abc":true}} => {abc => 1}],
  [q{{"abc":true,"Abc":124.4}} => {abc => 1, Abc => 124.4}],
  [q{{"abc":true,"Abc":124.4,"abc":"x"}} => {abc => "x", Abc => 124.4}],
  [q{{"abc": false,  "Abc"  :  124.4 }} => {abc => 0, Abc => 124.4}],
  [q{{"abc": false,  "Abc"  : { "124.4": []} }} => {abc => 0, Abc => {"124.4" => []}}],
) {
  test {
    my $c = shift;
    my $result = json_bytes2perl $test->[0];
    eq_or_diff $result, $test->[1];
    done $c;
  } n => 1;

  test {
    my $c = shift;
    my $result = json_chars2perl $test->[0];
    eq_or_diff $result, defined $test->[2] ? $test->[2] : $test->[1];
    done $c;
  } n => 1;
}

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
