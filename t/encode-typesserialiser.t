use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use JSON::PS;
use Encode;
use Test::X1;
use Test::Differences;
use Types::Serialiser;

sub u8 ($) { encode 'utf8', $_[0] }

for my $test (
  [Types::Serialiser::true, 'true'],
  [Types::Serialiser::false, 'false'],
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

run_tests;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
