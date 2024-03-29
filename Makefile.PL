#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of PodLinkCheck.
#
# PodLinkCheck is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# PodLinkCheck is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with PodLinkCheck.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'podlinkcheck',
   ABSTRACT     => 'Check POD L<> link references.',
   VERSION_FROM => 'podlinkcheck',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   EXE_FILES    => [ 'podlinkcheck' ],
   PREREQ_PM    => {
                    'constant::defer' => 0,
                    'Pod::Simple' => 0,
                    'Pod::Find' => 0,
                    'File::Find::Iterator' => 0,
                    'File::Spec' => '0.8', # version 0.8 for ->devnull()
                    'File::Temp' => 0,
                    'IPC::Run' => 0,
                    'List::Util' => 0,
                    'Locale::TextDomain' => 0,
                    'Test::More' => 0,
                   },
   MIN_PERL_VERSION => '5.006',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/podlinkcheck/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     recommends =>
     { 'Sort::Key::Natural' => 0,
       # Pod::Simple version 3.24 has a fix for L<login.conf(5)> and similar
       # man-page links with a "." dot in the name
       'Pod::Simple' => '3.24',
     },

     optional_features =>
     { maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules (optional supported other stuff).',
         requires => { 'CPANPLUS::Backend' => 0,
                       'CPANPLUS::Configure' => 0,
                       'Sort::Key::Natural' => 0,
                     },
       },
     },
   },
  );


# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'IO::String' => 0,
#                 'Smart::Comments' => 0,
#                 'Pod::Escapes' => 0,
#                 'Pod::Parser' => 0,
#                 'Pod::ParseLink' => 0,
#                 'Pod::Simple::HTMLBatch' => 0,
#               },
# },
