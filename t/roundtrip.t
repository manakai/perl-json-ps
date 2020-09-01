use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps', 'modules', '*', 'lib');
use Test::X1;
use Test::More;
use JSON::PS;
use Web::Encoding;

my $data_path = path (__FILE__)->parent->parent->child ('t_deps/data/largedata');
for (qw(
  era-defs.json
  teams.json
)) {
  my $path = $data_path->child ($_);

  test {
    my $c = shift;
    my $bytes = $path->slurp;
    my $obj = json_bytes2perl $bytes;
    my $bytes2 = perl2json_bytes_for_record $obj;
    my $obj2 = json_bytes2perl $bytes2;
    my $bytes3 = perl2json_bytes_for_record $obj2;
    is $bytes3, $bytes2;

    my $obj3 = json_chars2perl decode_web_utf8 $bytes;
    my $bytes4 = perl2json_bytes_for_record $obj3;
    is $bytes3, $bytes4;
    done $c;
  } n => 2, name => ['reencode', $path];
}

run_tests;

=head1 LICENSE

Copyright 2020 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
