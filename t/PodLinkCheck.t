#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of PodLinkCheck.
#
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

use strict;
use warnings;
use App::PodLinkCheck;
use Test::More tests => 19;

BEGIN {
 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

#------------------------------------------------------------------------------
{
  my $want_version = 2;
  is ($App::PodLinkCheck::VERSION, $want_version, 'VERSION variable');
  is (App::PodLinkCheck->VERSION,  $want_version, 'VERSION class method');
  ok (eval { App::PodLinkCheck->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { App::PodLinkCheck->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $plc = App::PodLinkCheck->new;
  is ($plc->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $plc->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $plc->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# new()

{
  my $plc = App::PodLinkCheck->new;
  is ($plc->{'verbose'}, 0, "new() verbose default value");
}
{
  my $plc = App::PodLinkCheck->new (verbose => 123);
  is ($plc->{'verbose'}, 123, "new() verbose specified");
}

#------------------------------------------------------------------------------
# manpage_is_known()

{
  my $plc = App::PodLinkCheck->new;

  foreach my $name ('cat',
                    'cat(1)',
                    'nosuchmanpagename') {
    diag "manpage_is_known() $name is ", $plc->manpage_is_known($name);
  }
}


#------------------------------------------------------------------------------
# _escape_angles()

foreach my $elem (['<', 'E<lt>'],
                  ['>', 'E<gt>'],
                  ['x<y>z', 'xE<lt>yE<gt>z'],
                 ) {
  my ($str, $want) = @$elem;
  is (App::PodLinkCheck::_escape_angles($str), $want,
      "_escape_angles() '$str'");
}


#------------------------------------------------------------------------------
# CPAN

{
  # CPANPLUS variously warn()s for dodgy .gz file reading and stuff ...
  local $SIG{'__WARN__'} = sub {
    diag @_;
  };

  my $plc = App::PodLinkCheck->new;
  foreach my $method ('_module_known_CPAN_SQLite',
                      '_module_known_CPAN',
                      '_module_known_CPANPLUS') {
    diag $method;
    ok (! $plc->$method ('No::Such::Module'),
        "$method() No::Such::Module");
    diag "$method() Pod::Find is ", $plc->$method('Pod::Find');

    # check a successful find isn't held onto
    ok (! $plc->$method ('No::Such::Module::Again'),
        "$method() No::Such::Module::Again");
  }
}

#------------------------------------------------------------------------------

diag 'INC is ',join (' ',@INC);
diag 'PATH is ',$ENV{'PATH'};
require Config;
diag 'Config{path_sep} is ', $Config::Config{'path_sep'};

exit 0;
