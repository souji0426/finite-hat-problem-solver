use strict;
use warnings;
use utf8;
use Encode;
use Config::Tiny;
use Data::Dumper;
use Time::Piece;
use Time::Seconds;
use Time::Local;
use File::Copy;
use File::Path;

my $setting = Config::Tiny->read( encode_cp932( "./setting/setting.ini" ) );

my $time_stamp = make_time_stamp();
my $calc_data_dir_path = "./calc_data_${time_stamp}";
mkdir encode_cp932( $calc_data_dir_path );

sub make_time_stamp {
  my $today = localtime;
  my $year = $today->year;
  my $month = sprintf( "%02d", $today->mon );
  my $day = sprintf( "%02d", $today->mday );
  my $hour = sprintf( "%02d", $today->hour );
  my $min = sprintf( "%02d", $today->minute );
  my $sec = sprintf( "%02d", $today->sec );
  return join( "-", ( $year, $month, $day, $hour, $min, $sec ) );
}

my $result_data_dir_path = "./result_data";
rmtree encode_cp932( $result_data_dir_path );
mkdir encode_cp932( $result_data_dir_path );

my $num_of_prisoner = $setting->{"game_rule"}->{"num_of_prisoner"};
my $num_of_color = $setting->{"game_rule"}->{"num_of_color"};
my $gragh_data = read_gragh_for_one_prisoner();

my $data = {};

calc();

sub calc {
  my $coloring_list_file_path = make_coloring_list();
  for ( my $prisoner_name = 0; $prisoner_name < $num_of_prisoner; $prisoner_name++ ){
    make_indistinguishable_coloring_list( $prisoner_name, $coloring_list_file_path );
  }

  my $indistinguishable_coloring_data = read_indistinguishable_coloring_list();

  for ( my $prisoner_name = 0; $prisoner_name < $num_of_prisoner; $prisoner_name++ ){
    make_strategy_list( $prisoner_name );
  }
  print Dumper $data;
  #my $predictor_list_file_path = make_predictor_list();
}

#------------------------------------------------------------------

sub read_gragh_for_one_prisoner {
  my $data = {};
  for ( my $prisoner_name = 0; $prisoner_name < $num_of_prisoner; $prisoner_name++ ){
    my @can_see_list = split( ",", $setting->{"visibility_gragh"}->{$prisoner_name} );
    $data->{$prisoner_name}->{"can_see"} = \@can_see_list;

    my @can_not_see_list;
    for ( my $prisoner_name = 0; $prisoner_name < $num_of_prisoner; $prisoner_name++ ){
      if ( !grep { $_ eq $prisoner_name } @can_see_list ) {
        push( @can_not_see_list, $prisoner_name );
      }
    }
    $data->{$prisoner_name}->{"can_not_see"} = \@can_not_see_list;
  }
  return $data;
}

#------------------------------------------------------------------

sub make_coloring_list {
  my $process_name = "coloringリスト作成";
  my $coloring_list_file_name = "coloring_list.txt";
  my $coloring_list_file_path = "${calc_data_dir_path}/${coloring_list_file_name}";
  my $calc_file_path;

  my $first = 1;
  my $calc_counter = 0;
  for ( my $prisoner_name = 0; $prisoner_name < $num_of_prisoner; $prisoner_name++ ){
    if ( $first ) {

      $calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${calc_counter}.txt";
      output_first_list( $calc_file_path, $num_of_color );
      $calc_counter++;
      $first = 0;

    } else {

      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${calc_counter}.txt";
      output_not_frist_list( $last_calc_file_path, $now_calc_file_path, $num_of_color );
      $calc_counter++;

      if ( $num_of_prisoner == $calc_counter ) {
        make_outputed_name_file( $now_calc_file_path, $coloring_list_file_path );
      }

    }
  }
  $data->{"num_of_coloring"} = get_num_of_line( $coloring_list_file_path );
  copy( encode_cp932( $coloring_list_file_path ), encode_cp932( "${result_data_dir_path}/${coloring_list_file_name}" ) );
  return $coloring_list_file_path;
}

#---------------------------------------------------------------------------------------------------

sub make_indistinguishable_coloring_list {
  my ( $prisoner_name, $coloring_list_file_path ) = @_;
  my $process_name = "囚人${prisoner_name}のindistinguishable_coloringリスト作成";

  my $indistinguishable_coloring_list_txt_path = "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt";
  open( my $indistinguishable_coloring_fh, ">", encode_cp932( $indistinguishable_coloring_list_txt_path ) );

  my $calc_counter = 0;
  my $calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${calc_counter}.txt";
  copy( encode_cp932( $coloring_list_file_path ), encode_cp932( $calc_file_path ) );

  my $num_of_coloring = $data->{"num_of_coloring"};
  for ( my $coloring_counter = 0; $coloring_counter < $num_of_coloring; $coloring_counter++ ){
    my $now_counter = $calc_counter+1;
    my $last_calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${calc_counter}.txt";;
    my $now_calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${now_counter}.txt";
    open( my $last_calc_fh, "<", encode_cp932( $last_calc_file_path ) );
    open( my $now_calc_fh, ">", encode_cp932( $now_calc_file_path ) );

    my $is_first_line = 1;
    my ( $target_coloring_name, $target_coloring_data );
    my @indistinguishable_coloring_list_of_target;
    while ( my $line = <$last_calc_fh> ) {
      chomp $line;

      if ( $is_first_line ) {

        ( $target_coloring_name, $target_coloring_data ) = read_function_data( $line );
        push( @indistinguishable_coloring_list_of_target, $target_coloring_name );
        $is_first_line = 0;

      } else {
        my ( $next_target_coloring_name, $next_target_coloring_data ) = read_function_data( $line );
        if ( is_indistinguish( $prisoner_name, $target_coloring_data, $next_target_coloring_data ) ) {
          push( @indistinguishable_coloring_list_of_target, $next_target_coloring_name );
        } else {
          print $now_calc_fh $line . "\n";
        }
      }
    }
    close $last_calc_fh;
    close $now_calc_fh;

    print $indistinguishable_coloring_fh "${calc_counter}:" . join( ",", @indistinguishable_coloring_list_of_target ) . "\n";

    if ( get_num_of_line( $now_calc_file_path ) == 0 ) {
      $data->{"num_of_class_of_indistinguishable_coloring"}->{$prisoner_name} = $calc_counter + 1;
      last;
    }

    $calc_counter++;
  }
  close $indistinguishable_coloring_fh;
}

sub is_indistinguish {
  my ( $prisoner_name, $data_one, $data_two ) = @_;
  my $coloring_names_indistinguish = 1;
  my $can_see_list = $gragh_data->{$prisoner_name}->{"can_see"};
  foreach my $target_prisoner_name ( @$can_see_list ) {
    #見えている範囲で違う色が見えた
    if ( $data_one->{$target_prisoner_name} ne $data_two->{$target_prisoner_name} ) {
      $coloring_names_indistinguish = 0;
      last;
    }
  }
  return $coloring_names_indistinguish;
}

#---------------------------------------------------------------------------------------------------

sub read_indistinguishable_coloring_list {
  my $data = {};
  for ( my $prisoner_name = 0; $prisoner_name < $num_of_prisoner; $prisoner_name++ ){
    open( my $fh, "<", encode_cp932( "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt" ) );
    while( my $line = <$fh> ) {
      chomp $line;
      my @data_in_one_line = split( ":", $line );
      my $class_name = $data_in_one_line[0];
      my @class = split( ",", $data_in_one_line[1] );
      $data->{$prisoner_name}->{$class_name} = \@class;
    }
    close $fh;
  }
  return $data;
}

#---------------------------------------------------------------------------------------------------

sub make_strategy_list {
  my ( $prisoner_name ) = @_;

  my $process_name = "囚人${prisoner_name}のstrategyリスト作成";
  my $strategy_list_file_name = "strategy_list_of_${prisoner_name}.txt";
  my $strategy_list_file_path = "${calc_data_dir_path}/${strategy_list_file_name}";

  my $indistinguishable_coloring_list_txt_path = "${calc_data_dir_path}/indistinguishable_coloring_list_of_${prisoner_name}.txt";
  my $num_of_class = get_num_of_line( $indistinguishable_coloring_list_txt_path );

  my $first = 1;
  my $calc_counter = 0;
  my $calc_file_path;
  for ( my $class_name = 0; $class_name < $num_of_class; $class_name++ ){
    if ( $first ) {

      $calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${calc_counter}.txt";
      output_first_list( $calc_file_path, $num_of_color );
      $calc_counter++;
      $first = 0;

    } else {

      my $last_counter = $calc_counter-1;
      my $last_calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${last_counter}.txt";
      my $now_calc_file_path = "${calc_data_dir_path}/calc_${process_name}_${calc_counter}.txt";
      output_not_frist_list( $last_calc_file_path, $now_calc_file_path, $num_of_color );
      $calc_counter++;

      if ( $num_of_class == $calc_counter ) {
        make_outputed_name_file( $now_calc_file_path, $strategy_list_file_path );
      }
    }
  }
  $data->{"num_of_strategy"}->{$prisoner_name} = get_num_of_line( $strategy_list_file_path );
  copy( encode_cp932( $strategy_list_file_path ), encode_cp932( "${result_data_dir_path}/${strategy_list_file_name}" ) );
}

sub is_target_fragment_of_strategy {
  my ( $prisoner_name, $indistinguishable_coloring_data, $fragment_of_strategy ) = @_;
  my $is_target = 1;
  my ( $name, $data_of_fragment ) = read_function_data( "hoge:" . $fragment_of_strategy );
  my @coloring_in_domain_of_fragment = keys %$data_of_fragment;
  foreach my $class_counter ( keys %{$indistinguishable_coloring_data->{$prisoner_name}} ) {
    my @colorings_in_class = @{$indistinguishable_coloring_data->{$prisoner_name}->{$class_counter}};

    my @target_coloring = get_same_element( \@coloring_in_domain_of_fragment, \@colorings_in_class );
    my $num_of_target = @target_coloring;
    if ( $num_of_target < 2 ) {
      next;
    } elsif ( $num_of_target > 1 ) {

      my $representative_coloring = $target_coloring[0];
      shift @target_coloring;
      my $color_at_representative_coloring = $data_of_fragment->{$representative_coloring};
      foreach my $coloring ( @target_coloring ) {
        if ( $data_of_fragment->{$coloring} ne $color_at_representative_coloring ) {
          $is_target = 0;
          last;
        }
      }
    }
  }
  return $is_target;
}

sub get_same_element {
  my ( $array_one, $array_two ) = @_;
  my @same_element;
  foreach my $element_one ( @$array_one ) {
    foreach my $element_two ( @$array_two ) {
      if ( $element_one eq $element_two ) {
        push( @same_element, $element_one );
      }
    }
  }
  return @same_element;
}

#---------------------------------------------------------------------------------------------------

sub encode_cp932 {
  my ( $str ) = @_;
  return encode( "cp932", $str );
}

sub output_first_list {
  my ( $file_path, $num ) = @_;
  open( my $fh, ">", encode_cp932( $file_path ) );
  for ( my $i = 0; $i < $num; $i++ ) {
    print $fh "${i}\n";
  }
  close $fh;
}

sub output_not_frist_list {
  my ( $last_file_path, $new_file_path, $num ) = @_;
  open( my $last_fh, "<", encode_cp932( $last_file_path ) );
  open( my $now_fh, ">", encode_cp932( $new_file_path ) );
  while ( my $last_line = <$last_fh> ) {
    chomp $last_line;
    for ( my $i = 0; $i < $num; $i++ ) {
      print $now_fh "$last_line,${i}\n";
    }
  }
  close $last_fh;
  close $now_fh;
}

sub make_outputed_name_file {
  my ( $last_file_path, $target_file_path ) = @_;

  open( my $target_fh, ">", $target_file_path );
  open( my $last_fh, "<", encode_cp932( $last_file_path ) );
  my $counter = 0;
  while ( my $line = <$last_fh> ) {
    print $target_fh "${counter}:" . $line;
    $counter++;
  }
  close $last_fh;
  close $target_fh;

}

sub get_num_of_line {
  my ( $file_path ) = @_;
  open( my $fh, "<", encode_cp932( $file_path ) );
  my $line_counter = 0;
  while( my $line = <$fh> ) {
    $line_counter++;
  }
  return $line_counter;
}

sub read_function_data {
  my ( $line) = @_;
  my @data_in_one_line = split( ":", $line );
  my $function_name = $data_in_one_line[0];
  my %function_data;
  my $counter = 0;
  foreach my $value ( split( ",", $data_in_one_line[1] ) ) {
    $function_data{$counter} = $value;
    $counter++;
  }
  return ( $function_name, \%function_data );
}

1;
