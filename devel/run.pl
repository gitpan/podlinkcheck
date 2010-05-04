#!/usr/bin/perl -w

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

use strict;
use warnings;

use FindBin;
my $progfile = "$FindBin::Bin/$FindBin::Script";
print $progfile,"\n";

{
  require Data::Dumper;
#   my @x;
#   $#x = 100e6 / 4;
#   print scalar(@x),"\n";

  #   my $pid = fork();
  #   print Data::Dumper->new([\$pid],['pid'])->Dump;

  my $out;
  require IPC::Run;
  IPC::Run::run (['ecfdjsklho', 'hello'],
                 \undef,  # stdin
                 \$out,  # stdout
                 sub{});  # stderr
  print "done\n";
  exit 0;
}

{
  require App::PodLinkCheck;
  my $plc = App::PodLinkCheck->new;

  #   my $conf = $plc->_CPAN_config;
  #   print "conf $conf\n";

  print $plc->_module_known_CPAN('Pod::Find'),"\n";
  # print $plc->_module_known_CPAN('http:'),"\n";
  # print $plc->_module_known_CPAN_SQLite('http:'),"\n";
  exit 0;
}

{
  my $parser = App::PodLinkCheck::SectionParser->new;
   $parser->parse_from_file ($progfile);
  # $parser->parse_from_file ('/usr/share/perl/5.10/pod/perlsyn.pod');

  my $sections = $parser->sections_hashref;
  require Data::Dumper;
  print Data::Dumper->new([$sections],['args'])->Sortkeys(1)->Dump;
  exit 0;
}

{
  my $plc = App::PodLinkCheck->new;
  $plc->check_file ($progfile);
  exit 0;
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# =pod
# 
# Also see L<"General Regular Expression Traps using s///, etc.">
# 
# =cut

# L<some section>
# 
# L<"another section">

# =head2 Locale, Unicode and UTF-8
# 
# See L</Locale, Unicode and UTF-8>.
# =item *
# 
# some
# fdsjk
# fsd
# fsd
# fsd
# A new pragma, C<feature>, has been added; see above in L</"Core
# Enhancements">.
# text
# kfdsjk L<cat(6)/x
# y>
# blah
# blah
# 
# L<cat(1)>
# L<cat>

# =item C<code>
# 
# L</C<code>>

#  =item E<gt>
# 
#  =item co/de
#  X<foo>
# 
#  L</coE<sol>de>
# 
#  L<AutoLoader/foo>

# =item PERL_HASH_SEED
# X<PERL_HASH_SEED>
# 
# 
# =item blah Z<>
# 
# 
# 
# L</blah>
# 
# L</no such target>
# 
# L</PERL_HASH_SEED>
# 

# 
# L<AutoLoader/"foo bar">
# 
# =back
# 
# Pod::Man


