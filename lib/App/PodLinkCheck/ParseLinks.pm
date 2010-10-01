# Copyright 2010 Kevin Ryde

# This file is part of PodLinkCheck.

# PodLinkCheck is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.


package App::PodLinkCheck::ParseLinks;
use 5.005;
use strict;
use warnings;
use File::Spec;
use List::Util;
use Text::Tabs;
use base 'App::PodLinkCheck::ParseSections';

use vars '$VERSION';
$VERSION = 6;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class, $plc) = @_;
  my $self = $class->SUPER::new ($plc);
  $self->{(__PACKAGE__)}->{'links'} = [];
  $self->{(__PACKAGE__)}->{'linenum'} = 1;
  $self->{(__PACKAGE__)}->{'column'} = 1;
  return $self;
}

sub links_arrayref {
  my ($self) = @_;
  return $self->{(__PACKAGE__)}->{'links'};
}

sub _handle_text {
  my ($self, $text) = @_;
  shift->SUPER::_handle_text (@_);

  ### $text
  #### newlines: scalar($text =~ tr/\n/\n/)
  $self->{(__PACKAGE__)}->{'linenum'} += ($text =~ tr/\n/\n/);
  #### linenum: $self->{(__PACKAGE__)}->{'linenum'}

  my $pos = 1 + rindex ($text, "\n");
  if ($pos) {
    $self->{(__PACKAGE__)}->{'column'} = 1;
  }
  substr ($text, 0, $pos, '');
  $text = Text::Tabs::expand ($text);
  $self->{(__PACKAGE__)}->{'column'} += length($text);
}

sub _handle_element_start {
  my ($self, $ename, $attr) = @_;
  shift->SUPER::_handle_element_start (@_);
  ### $ename
  ### $attr

  if (defined $attr->{'start_line'}) {
    $self->{(__PACKAGE__)}->{'linenum'} = $attr->{'start_line'};
    $self->{(__PACKAGE__)}->{'column'} = 1;
  }
  if ($ename eq 'item-bullet') {
    $self->{(__PACKAGE__)}->{'linenum'} += 2;
  }

  if ($ename eq 'L') {
    my $type = "$attr->{'type'}";
    if ($type eq 'man' || $type eq 'pod') {
      my $to = $attr->{'to'};
      if (defined $to) {
        $to = App::PodLinkCheck::ParseSections::_collapse_whitespace("$to");
      }
      my $section = $attr->{'section'};
      if (defined $section) {
        $section = App::PodLinkCheck::ParseSections::_collapse_whitespace("$section");
      }
      ### $to
      ### $section

      push @{$self->{(__PACKAGE__)}->{'links'}},
        [ $type,
          $to,
          $section,
          $self->{(__PACKAGE__)}->{'linenum'},
          $self->{(__PACKAGE__)}->{'column'} ];
    }
  }
}

#   sub _str_last_line {
#     my ($str) = @_;
#     return substr ($str, 1+rindex ($str, "\n"));
#   }

1;
__END__

=for stopwords PodLinkCheck Ryde

=head1 NAME

App::PodLinkCheck::ParseLinks -- parse out POD LE<lt>E<gt> links

=head1 SYNOPSIS

 use App::PodLinkCheck::ParseLinks;

=head1 DESCRIPTION

This is an internal part of PodLinkCheck.

=head1 SEE ALSO

L<App::PodLinkCheck>

=head1 HOME PAGE

http://user42.tuxfamily.org/podlinkcheck/index.html

=head1 LICENSE

Copyright 2010 Kevin Ryde

PodLinkCheck is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

PodLinkCheck is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

=cut
