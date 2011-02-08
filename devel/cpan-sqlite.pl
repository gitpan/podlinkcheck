#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use Smart::Comments;


{
  require CPAN::SQLite;
  my $cps = CPAN::SQLite->new (update_indices => 0);

#   print "index() setup\n";
#   $cps->index (setup => 1);

  print "query()\n";
  $cps->query(mode => 'module',
              name => 'Filter::Util::Call');
  my $results = $cps->{'results'};

  ### results: $results

  exit 0;
}


{
  print "Index index()\n";
  $ENV{CPAN_SQLITE_NO_LOG_FILES} = 1;
  require CPAN::SQLite::Index;
  my $index = CPAN::SQLite::Index->new (CPAN => '/home/gg/.cpan/source',
                                        update_indices => 0);
  $index->index() or do {
    warn qq{Indexing failed!};
    exit 1;
  };
  exit 0;
}
