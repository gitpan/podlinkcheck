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

package App::PodLinkCheck;
use 5.005;
use strict;
use warnings;
use Carp;
use Locale::TextDomain ('App-PodLinkCheck');

use vars '$VERSION';
$VERSION = 6;

# uncomment this to run the ### lines
#use Smart::Comments;

sub command_line {
  my ($self) = @_;
  ### command_line(): @ARGV
  ref $self or $self = $self->new;

  require Getopt::Long;
  Getopt::Long::Configure ('permute',  # options with args, callback '<>'
                           'no_ignore_case',
                           'bundling');
  Getopt::Long::GetOptions
      ('version'   => sub { $self->action_version },
       'help'      => sub { $self->action_help },
       'verbose:i' => \$self->{'verbose'},
       'V+'        => \$self->{'verbose'},
       'I=s'       => $self->{'extra_INC'},

       '<>' => sub {
         my ($value) = @_;
         # stringize to avoid Getopt::Long object
         $self->check_tree ("$value");
       },
      );
  ### final ARGV: @ARGV
  $self->check_tree (@ARGV);
  return 0;
}

sub action_version {
  my ($self) = @_;
  print __x("PodLinkCheck version {version}\n", version => $self->VERSION);
  if ($self->{'verbose'} >= 2) {
    require Pod::Simple;
    print __x("  Perl        version {version}\n", version => $]);
    print __x("  Pod::Simple version {version}\n", version => Pod::Simple->VERSION);
  }
  return 0;
}

sub action_help {
  my ($self) = @_;
  require FindBin;
  no warnings 'once';
  my $progname = $FindBin::Script;
  print __x("Usage: $progname [--options] file-or-dir...\n");
  print __x("  --help         print this message\n");
  print __x("  --version      print version number (and module versions if --verbose=2)\n");
  print __x("  --verbose      print diagnostic details\n");
  print __x("  --verbose=2    print even more diagnostics\n");
  return 0;
}


#------------------------------------------------------------------------------

sub new {
  my ($class, @options) = @_;
  return bless { verbose => 0,
                 cpan_methods => ['CPAN_SQLite','CPAN','CPANPLUS'],
                 extra_INC => [],
                 @options }, $class;
}

sub check_tree {
  my ($self, @files_or_directories) = @_;
  ### check_tree(): \@files_or_directories

  my $order = eval { require Sort::Key::Natural }
    ? \&_find_order_natural : \&_find_order_plain;
  ### Natural: $@

  foreach my $filename (@files_or_directories) {
    if (-d $filename) {
      require File::Find::Iterator;
      require Sort::Key::Natural;
      my $finder = File::Find::Iterator->create (dir => [$filename],
                                                 order => $order,
                                                 filter => \&_is_perlfile);
      while ($filename = $finder->next) {
        print "$filename:\n";
        $self->check_file ($filename);
      }
    } else {
      print "$filename:\n";
      $self->check_file ($filename);
    }
  }

  #         ### recurse dir: $filename
  #         require File::Find;
  #         File::Find::find ({ wanted => sub {
  #                               #### file: $_
  #                               if (_is_perlfile()) {
  #                                 print "$_:\n";
  #                                 $self->check_file ($_);
  #                               }
  #                             },
  #                             follow_fast => 1,
  #                             preprocess => \&_find_sort,
  #                             no_chdir => 1,
  #                           },
  #                           $filename);
  #       } else {
  #         print "$filename:\n";
  #         $self->check_file ($filename);
  #       }
  #     }
}

sub _is_perlfile {
  ### _is_perlfile(): $@
  return (! -d
          && ! m{/\.#}   # emacs lockfile
          && /\.p([lm]|od)$/);
}

# sub _find_sort {
#   # print "_find_sort\n";
#   return sort _find_order @_;
# }
sub _find_order_plain {
  my ($x, $y) = @_;
  return (-d $y <=> -d $x   # plain files first
          || lc($y) cmp lc($x)
          || $y cmp $x);
}
sub _find_order_natural {
  my ($x, $y) = @_;
  return (-d $y <=> -d $x   # plain files first
          || do {
            $x = Sort::Key::Natural::mkkey_natural($x);
            $y = Sort::Key::Natural::mkkey_natural($y);
            lc($y) cmp lc($x)
              || $y cmp $x
            });
}

sub check_file {
  my ($self, $filename) = @_;
  require App::PodLinkCheck::ParseLinks;
  my $parser = App::PodLinkCheck::ParseLinks->new ($self);
  $parser->parse_from_file ($filename);

  my $own_sections = $parser->sections_hashref;
  ### $own_sections

  foreach my $link (@{$parser->links_arrayref}) {
    my ($type, $to, $section, $linenum, $column) = @$link;

    if ($self->{'verbose'}) {
      print "Link: $type ",(defined $to ? $to : '[undef]'),
        (defined $section ? " / $section" : ""), "\n";
    }

    if ($type eq 'man') {
      if (! $self->manpage_is_known($to)) {
        $self->report ($filename, $linenum, $column,
                       __x('no man page "{name}"', name => $to));
      }
      next;
    }

    if (! defined $to) {
      if (defined $section
          && ! $own_sections->{$section}) {
        if (my $approximations
            = _section_approximations($section,$own_sections)) {
          $self->report ($filename, $linenum, $column,
                         __x("no section \"{section}\"\n    perhaps it should be {approximations}",
                             section => $section,
                             approximations => $approximations));
        } else {
          $self->report ($filename, $linenum, $column,
                         __x('no section "{section}"',
                             section => $section));
        }
        if ($self->{'verbose'} >= 2) {
          print __("    available sections:\n");
          foreach my $section (keys %$own_sections) {
            print "    $section\n";
          }
        }
      }
      next;
    }

    my $podfile = ($self->module_to_podfile($to)
                   || $self->find_script($to));
    ### $podfile
    if (! defined $podfile) {
      if (my $method = $self->_module_known_cpan($to)) {
        if (defined $section && $section ne '') {
          $self->report ($filename, $linenum, $column,
                         __x('target "{name}" on cpan ({method}) but no local copy to check section "{section}"',
                             name => $to,
                             method => $method,
                             section => $section));
        }
        next;
      }
    }

    if (! defined $podfile
        && ! defined $section
        && $self->manpage_is_known($to)) {
      # perhaps a script or something we can't find the source but does
      # have a manpage -- take that as good enough
      next;
    }
    if (! defined $section
        && _is_one_word($to)
        && $own_sections->{$to}) {
      # one-word internal section
      if (defined $podfile) {
        # print "$filename:$linenum:$column: target \"$to\" is both external module/program and internal section\n";
      } else {
        $self->report ($filename, $linenum, $column,
                       __x('internal one-word link recommend {slash} or {quote} style',
                           slash => "L</"._escape_angles($to).">",
                           quote => "L<\""._escape_angles($to)."\">"));
      }
      next;
    }
    if (! defined $podfile) {
      if ($own_sections->{$to}) {
        # multi-word internal section
        return;
      }
      $self->report ($filename, $linenum, $column,
                     "no module/program/pod \"$to\"");
      next;
    }

    if (defined $section && $section ne '') {
      my $podfile_sections = $self->filename_to_sections ($podfile);
      if (! $podfile_sections->{$section}) {
        if (my $approximations
            = _section_approximations($section,$podfile_sections)) {
          $self->report ($filename, $linenum, $column,
                         __x("no section \"{section}\" in \"{name}\" (file {filename})\n    perhaps it should be {approximations}",
                             name => $to,
                             section => $section,
                             filename => $podfile,
                             approximations => $approximations));
        } else {
          $self->report ($filename, $linenum, $column,
                         __x('no section "{section}" in "{name}" (file {filename})',
                             name => $to,
                             section => $section,
                             filename => $podfile));
        }
        if ($self->{'verbose'} >= 2) {
          print __("    available sections:\n");
          foreach my $section (keys %$podfile_sections) {
            print "    $section\n";
          }
        }

      }
    }
  }
}

sub report {
  my ($self, $filename, $linenum, $column, $message) = @_;
  print "$filename:$linenum:$column: $message\n";
}

# return a string of close matches of $section in the keys of %$hashref
sub _section_approximations {
  my ($section, $hashref) = @_;
  $section = _section_approximation_crunch($section);
  return join(' or ',
              map {"\"$_\""}
              grep {_section_approximation_crunch($_) eq $section}
              keys %$hashref);
}
sub _section_approximation_crunch {
  my ($section) = @_;
  $section =~ s/\W+//g;
  return lc($section);
}

sub _is_one_word {
  my ($link) = @_;
  return ($link !~ /\W/);
}
sub _escape_angles {
  my ($str) = @_;
  $str =~ s{([<>])}
    { 'E<'.($1 eq '<' ? 'lt' : 'gt').'>' }ge;
  return $str;
}

sub module_to_podfile {
  my ($self, $module) = @_;
  require Pod::Find;
  return Pod::Find::pod_where ({ '-dirs' => $self->{'extra_INC'},
                                 '-inc' => 1,
                               },
                               $module);
}

# return hashref
sub filename_to_sections {
  my ($self, $filename) = @_;
  return ($self->{'sections_cache'}->{$filename} ||= do {
    ### parse file for sections: $filename
    my $parser = App::PodLinkCheck::ParseSections->new;
    $parser->parse_file ($filename);
    ### file sections: $parser->sections_hashref
    $parser->sections_hashref;
  });
}

#------------------------------------------------------------------------------
# CPAN

sub _module_known_cpan {
  my ($self, $module) = @_;
  foreach my $method (@{$self->{'cpan_methods'}}) {
    my $fullmethod = "_module_known_$method";
    if ($self->$fullmethod ($module)) {
      return $method;
    }
  }
  return 0;
}

use constant::defer _CPAN_config => sub {
  my $result = 0;
  eval {
    require CPAN;
    # not sure how far back this will work, maybe only 5.8.0 up
    if (! $CPAN::Config_loaded
        && CPAN::HandleConfig->can('load')) {
      # fake $loading to avoid running the CPAN::FirstTime dialog -- is
      # this the right way to do that?
      local $CPAN::HandleConfig::loading = 1;
      print __x("PodLinkCheck: {module} configs\n",
                module => 'CPAN');
      CPAN::HandleConfig->load;
    }
    $result = 1;
  }
    or print "CPAN.pm config error: $@\n";
  return $result;
};

sub _module_known_CPAN_SQLite {
  my ($self, $module) = @_;

  if (! defined $self->{'cpan_sqlite'}) {
    $self->{'cpan_sqlite'} = 0;

    if ($self->_CPAN_config) {
      print __x("PodLinkCheck: loading {module} for module existence checking\n",
                module => 'CPAN::SQLite');
      if (! eval { require CPAN::SQLite }) {
        print __x("Cannot load {module}, skipping -- {error}\n",
                  module => 'CPAN::SQLite',
                  error => $@);
        return 0;
      }
      if (! eval {
        # fake $loading to avoid running the CPAN::FirstTime dialog -- is
        # this the right way to do that?
        local $CPAN::HandleConfig::loading = 1;
        $self->{'cpan_sqlite'} = CPAN::SQLite->new (update_indices => 0);
      }) {
        print __x("{module} error: {error}\n",
                  module => 'CPAN::SQLite',
                  error => $@);
      }
    }
  }

  my $cpan_sqlite = $self->{'cpan_sqlite'} || return 0;

  # Have struck errors from cpantesters creating db tables.  Not sure if it
  # might happen in a real run.  Guard with an eval.
  #
  my $result;
  if (! eval { $result = $cpan_sqlite->query (mode => 'module',
                                              name => $module);
               1 }) {
    print __x("{module} error, disabling -- {error}\n",
              module => 'CPAN::SQLite',
              error  => $@);
    $self->{'cpan_sqlite'} = 0;
    return 0;
  }
  return $result;
}

my $use_CPAN;
sub _module_known_CPAN {
  my ($self, $module) = @_;
  ### _module_known_CPAN(): $module

  if (! defined $use_CPAN) {
    $use_CPAN = 0;

    if ($self->_CPAN_config) {
      eval {
        print __x("PodLinkCheck: load {module} for module existence checking\n",
                  module => 'CPAN');

        if (defined $CPAN::META && %$CPAN::META) {
          $use_CPAN = 1;
        } elsif (! CPAN::Index->can('read_metadata_cache')) {
          print __("PodLinkCheck: no Metadata cache in this CPAN.pm\n");
        } else {
          # try the .cpan/Metadata even if CPAN::SQLite is installed, just in
          # case the SQLite is not up-to-date or has not been used yet
          local $CPAN::Config->{use_sqlite} = 0;
          CPAN::Index->read_metadata_cache;
          if (defined $CPAN::META && %$CPAN::META) {
            $use_CPAN = 1;
          } else {
            print __("PodLinkCheck: empty Metadata cache\n");
          }
        }
        1;
      }
        or print "CPAN.pm error: $@\n";
    }
  }

  return ($use_CPAN
          && exists($CPAN::META->{'readwrite'}->{'CPAN::Module'}->{$module}));
}

sub _module_known_CPANPLUS {
  my ($self, $module) = @_;
  ### _module_known_CPANPLUS(): $module

  if (! defined $self->{'cpanplus'}) {
    print __x("PodLinkCheck: load {module} for module existence checking\n",
              module => 'CPANPLUS');
    if (! eval { require CPANPLUS::Backend;
                 require CPANPLUS::Configure;
               }) {
      $self->{'cpanplus'} = 0;
      print __x("Cannot load {module}, skipping -- {error}\n",
                module => 'CPANPLUS',
                error => $@);
      return 0;
    }
    my $conf = CPANPLUS::Configure->new;
    $conf->set_conf (verbose => 1);
    $conf->set_conf (no_update => 1);
    $self->{'cpanplus'} = CPANPLUS::Backend->new ($conf);
  }

  my $cpanplus = $self->{'cpanplus'} || return 0;

  # module_tree() returns false '' for not found.
  #
  # Struck an error from module_tree() somehow relating to
  # CPANPLUS::Internals::Source::SQLite on cpantesters at one time, so guard
  # with an eval.
  #
  my $result;
  if (! eval { $result = $cpanplus->module_tree($module); 1 }) {
    print __x("{module} error, disabling -- {error}\n",
              module => 'CPANPLUS',
              error  => $@);
    $self->{'cpanplus'} = 0;
    return 0;
  }
  return $result;
}

#------------------------------------------------------------------------------
# PATH

sub find_script {
  my ($self, $name) = @_;
  foreach my $dir ($self->PATH_list) {
    my $filename = File::Spec->catfile($dir,$name);
    #### $filename
    if (-e $filename) {
      return $filename;
    }
  }
  return undef;
}

# return list of directories
sub PATH_list {
  my ($self) = @_;
  require Config;
  return split /\Q$Config::Config{'path_sep'}/o, $self->PATH;
}

# return string
sub PATH {
  my ($self) = @_;
  if (defined $self->{'PATH'}) {
    return $self->{'PATH'};
  } else {
    return $ENV{'PATH'};
  }
}

#------------------------------------------------------------------------------
# man

# return bool
sub manpage_is_known {
  my ($self, $name) = @_;
  my @manargs;
  my $section = '';
  if ($name =~ s/\s*\((.+)\)$//) {
    $section = $1;
    @manargs = ($section);
  }

  my $r = \$self->{'manpage_is_known'}->{$section}->{$name};
  if (defined $$r) {
    return $$r;
  }
  push @manargs, $name;
  ### man: \@manargs

  return ($$r = (_man_has_location_option()
                 ? $self->_manpage_is_known_by_location(@manargs)
                 : $self->_manpage_is_known_by_output(@manargs)));
}

# --location is not in posix,
# http://www.opengroup.org/onlinepubs/009695399/utilities/man.html
# Is it man-db specific, or does it have a chance of working elsewhere?
#
use constant::defer _man_has_location_option => sub {
  require IPC::Run;
  require File::Spec;
  my $str = '';
  eval {
    IPC::Run::run (['man','--help'],
                   '<', \undef,
                   '>', \$str,
                   '2>', File::Spec->devnull);
  };
  ### _man_has_location_option(): 0 + ($str =~ /--location\b/)
  return ($str =~ /--location\b/);
};

sub _manpage_is_known_by_location {
  my ($self, @manargs) = @_;
  ### _manpage_is_known_by_location() run: \@manargs
  require IPC::Run;
  my $str;
  if (! eval {
    IPC::Run::run (['man', '--location', @manargs],
                   '<', \undef,  # stdin
                   '>', \$str,  # stdout
                   '2>', File::Spec->devnull);
    1;
  }) {
    my $err = $@;
    $err =~ s/\s+$//;
    print __x("PodLinkCheck: error running 'man': {error}\n", error => $err);
    return 0;
  }
  ### _manpage_is_known_by_location() output: $str
  return ($str =~ /\n/ ? 1 : 0);
}

sub _manpage_is_known_by_output {
  my ($self, @manargs) = @_;
  ### _manpage_is_known_by_output() run: \@manargs
  require IPC::Run;
  require File::Temp;
  my $fh = File::Temp->new (TEMPLATE => 'PodLinkCheck-man-XXXXXX',
                            TMPDIR => 1);
  if (! eval {
    IPC::Run::run (['man', @manargs],
                   '<', \undef,  # stdin
                   '>', $fh,     # stdout
                   '2>', File::Spec->devnull);
    1;
  }) {
    my $err = $@;
    $err =~ s/\s+$//;
    print __x("PodLinkCheck: error running 'man': {error}\n", error => $err);
    return 0;
  }

  seek $fh, 0, 0;
  foreach (1 .. 5) {
    if (! defined (readline $fh)) {
      return 0;
    }
  }
  return 1;
}

1;
__END__

=for stopwords PodLinkCheck Ryde

=head1 NAME

App::PodLinkCheck -- check Perl pod LE<lt>E<gt> link references

=head1 SYNOPSIS

 use App::PodLinkCheck;
 exit App::PodLinkCheck->command_line;

=head1 FUNCTIONS

=over 4

=item C<$plc = App::PodLinkCheck-E<gt>new (key =E<gt> value, ...)>

Create and return a PodLinkCheck object.

=item C<$exitcode = $plc-E<gt>command_line>

Run a PodLinkCheck as from the command line.  Arguments are taken from
C<@ARGV> and the return is an exit status code suitable for C<exit>, being 0
for success.

=item C<$plc-E<gt>check_file ($filename)>

Run checks on file C<$filename>.

=back

=head1 SEE ALSO

L<podlinkcheck>

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

