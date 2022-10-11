use strict;
use warnings;
use utf8;
use Encode;
use Config::Tiny;
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::Local;

my $num_of_prisoner = $ARGV[0];
my $num_of_color = $ARGV[1];

my $setting_dir_path = "./setting";
mkdir encode( "cp932", $setting_dir_path );

my $setting_ini_path = "${setting_dir_path}/setting.ini";
open( my $setting_fh, ">", encode( "cp932", $setting_ini_path ) );
print $setting_fh "\[game_rule\]\n";

print $setting_fh "num_of_prisoner=${num_of_prisoner}\n\n";
print $setting_fh "num_of_color=${num_of_color}\n\n";
print $setting_fh "pass_mode=0\n\n";
print $setting_fh "simultaneous_mode=1\n\n";
output_visibility_gragh_base_setting( $setting_fh );
output_guess_order_base_setting( $setting_fh );
close $setting_fh;

sub output_visibility_gragh_base_setting {
  my ( $fh ) = @_;
  print $fh "\[visibility_gragh\]\n";
  for ( my $i = 0; $i < $num_of_prisoner; $i++ ){
    print $fh "${i}=";
    my @can_see_list;
    for ( my $j = 0; $j < $num_of_prisoner; $j++ ){
      if ( $i != $j ) {
        push( @can_see_list, $j );
      }
    }
    print $fh join( ",", @can_see_list ) . "\n";
  }
  print $fh "\n";
}

sub output_guess_order_base_setting {
  my ( $fh ) = @_;
  print $fh "\[guess_order\]\n";
  for ( my $i = 0; $i < $num_of_prisoner; $i++ ){
    print $fh "${i}=${i}\n";
  }
}

1;
