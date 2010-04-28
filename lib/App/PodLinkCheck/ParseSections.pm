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

package App::PodLinkCheck::ParseSections;
use 5.005;
use strict;
use warnings;
use base 'Pod::Simple';

use vars '$VERSION';
$VERSION = 1;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class, $plc) = @_;
  my $self = $class->SUPER::new;
  $self->{(__PACKAGE__)}->{'sections'} = {};
  $self->{(__PACKAGE__)}->{'plc'} = $plc;
  $self->nix_X_codes(1);
  $self->no_errata_section(1);
  $self->preserve_whitespace(1);
  if (! $plc->{'verbose'}) {
    $self->no_whining(1);
  }
  return $self;
}
sub _plc {
  my ($self) = @_;
  return $self->{(__PACKAGE__)}->{'plc'};
}

# return hashref where keys are the section names
sub sections_hashref {
  my ($self) = @_;
  return $self->{(__PACKAGE__)}->{'sections'};
}

sub _handle_element_start {
  my ($self, $ename, $attr) = @_;
  if ($ename =~ /^(head|item-text)/) {
    $self->{(__PACKAGE__)}->{'item_text'} = '';
  }
}
sub _handle_text {
  my ($self, $text) = @_;
  if (exists $self->{(__PACKAGE__)}->{'item_text'}) {
    ### $text
    $self->{(__PACKAGE__)}->{'item_text'} .= $text;
  }
}
sub _handle_element_end {
  my ($self, $ename) = @_;
  if ($ename =~ /^(head|item-text)/) {
    my $section = delete $self->{(__PACKAGE__)}->{'item_text'};
    ### section: $section

    $section = _collapse_whitespace ($section);
    $self->{(__PACKAGE__)}->{'sections'}->{$section} = 1;

    # like Pod::Checker take the first word as a section name too, which is
    # much used for cross-references to perlfunc.
    # THINK-ABOUT-ME: Pod::Checker uses "$section =~ s/\s.*//" to crunch
    # down, CHI.pm better treated by a first word, to exclude parens etc.
    if ($section =~ /^(\w+)/) {
      ### section one word: $section
      $self->{(__PACKAGE__)}->{'sections'}->{$1} = 1;
    }
  }
}

sub _collapse_whitespace {
  my ($str) = @_;
  $str =~ s/\s+/ /g;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

1;
__END__

=for stopwords PodLinkCheck Ryde

=head1 NAME

App::PodLinkCheck::ParseSections -- parse out section names from POD

=head1 SYNOPSIS

 use App::PodLinkCheck::ParseSections;

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
