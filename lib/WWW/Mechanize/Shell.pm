#!/usr/bin/perl -w

use strict;
use Carp;
use WWW::Mechanize;
use HTTP::Cookies;

# Blindly allow redirects
{
  no warnings;
  *WWW::Mechanize::redirect_ok = sub { print "\nRedirecting to ",$_[1]->uri; $_[0]->{uri} = $_[1]; 1 };
}

{
  use WWW::Mechanize::FormFiller;
  package WWW::Mechanize::FormFiller::Value::Ask;
  use base 'WWW::Mechanize::FormFiller::Value::Callback';

  use vars qw( $VERSION );
  $VERSION = 0.01;

  sub new {
    my ($class,$name,$shell) = @_;
    my $self = $class->SUPER::new($name, \&ask_value);
    $self->{shell} = $shell;
    Carp::carp "WWW::Mechanize::FormFiller::Value::Ask->new called without a value for the shell" unless $self->{shell};

    $self;
  };

  sub ask_value {
    my ($self,$input) = @_;
    my @values;
    if ($input->possible_values) {
      @values = $input->possible_values;
      print join( "|", @values ), "\n";
    };
    my $value;
    $value = $input->value;
    if ($value eq "") {
      $value = $self->{shell}->prompt("(" . $input->type . ")" . $input->name . "> [" . ($input->value || "") . "] ",
                            ($input->value||''), @values );
    };
    undef $value if ($value eq "" and $input->type eq "checkbox");
    $value;
  };
};

package WWW::Mechanize::Shell;

# TODO:
# * Log facility, log all stuff to a file
# * History persistence (see log facility)
# * Fix Term::Shell command repetition on empty lines
# * Add "open()" and "click()" RE functionality
# * Modify WWW::Mechanize to accept REs as well as the other stuff
# * Add comment facility to Term::Shell
# * Add simple script generation
# DONE:
# * Add auto form fill out stuff

use base 'Term::Shell';
use Win32::OLE;
use File::Modified;
use FindBin;

use WWW::Mechanize::FormFiller;

sub source_file {
  my ($self,$filename) = @_;
  local *F;
  open F, "< $filename" or die "Couldn't open '$filename' : $!\n";
  while (<F>) {
    $self->cmd($_);
  };
  close F;
};

sub add_history {
  my ($self,@code) = @_;
  push @{$self->{history}},[$self->line,join "",@code];
};

sub init {
  my ($self) = @_;
  my ($name,%args) = @{$self->{API}{args}};

  $self->{agent} = WWW::Mechanize->new();
  $self->{browser} = undef;
  $self->{formfiller} = WWW::Mechanize::FormFiller->new(default => [ Ask => $self ]);

  $self->{history} = [];

  $self->{options} = {
    autosync => 0,
    autorestart => 0,
    cookiefile => 'cookies.txt',
    dumprequests => 0,
  };

  # Keep track of the files we consist of, to enable automatic reloading
  $self->{files} = File::Modified->new(files=>[values %INC, $0]);

  # Read our .rc file :
  # I could use File::Homedir, but the docs claim it dosen't work on Win32. Maybe
  # I should just release a patch for File::Homedir then... Not now.
  my $sourcefile;
  if (exists $args{rcfile}) {
    $sourcefile = delete $args{rcfile};
  } else {
    my $userhome = $^O =~ /win32/i ? $ENV{'USERPROFILE'} || $ENV{'HOME'} : `cd ~; pwd`;
    $sourcefile = "$userhome/.mechanizerc";
  };
  $self->option('cookiefile', $args{cookiefile}) if (exists $args{cookiefile});

  $self->source_file($sourcefile) if $sourcefile; # and -f $sourcefile and -r $sourcefile;
};

sub agent { $_[0]->{agent}; };

sub option {
  my ($self,$option,$value) = @_;
  if (exists $self->{options}->{$option}) {
    my $result = $self->{options}->{$option};
    if (defined $value) {
      $self->{options}->{$option} = $value;
    };
    $result;
  } else {
    Carp::carp "Unknown option '$option'";
  };
};

sub restart_shell {
  print "Restarting $0\n";

  exec $^X, $0, @ARGV;
};

sub precmd {
  my $self = shift @_;
  # We want to restart when any module was changed
  if ($self->{files}->changed()) {
    print "One or more of the base files were changed\n";
    $self->restart_shell if ($self->option('autorestart'));
  };

  $self->SUPER::precmd(@_);
};

sub postcmd {
  my $self = shift @_;
  # We want to restart when any module was changed
  if ($self->{files}->changed()) {
    print "One or more of the base files were changed\n";
    $self->restart_shell if ($self->option('autorestart'));
  };

  $self->SUPER::precmd(@_);
};

sub browser {
  my ($self) = @_;
  my $browser = $self->{browser};
  unless ($browser) {
    $browser = Win32::OLE->CreateObject("InternetExplorer.Application");
    $browser->{'Visible'} = 1;
    $self->{browser} = $browser;
    $browser->Navigate('about:blank');
  };
  $browser;
};

sub sync_browser {
  my ($self) = @_;

  my $document = $self->browser->{Document};
  $document->open("text/html","replace");
  my $html = $self->agent->{res}->content;
  my $location = $self->agent->{uri};

  # If there is no <BASE> tag, set one

  $html =~ s!(</head>)!<base href="$location" />$1!i
    unless ($html =~ /<BASE/i);

  $document->write($html);
};

sub prompt_str { $_[0]->agent->{uri} . ">" };

sub alias_exit { qw(quit) };

sub run_restart {
  my ($self) = @_;
  $self->restart_shell;
};

sub run_get {
  my ($self,$url) = @_;
  print "Retrieving $url";
  print "(",$self->agent->get($url)->code,")";
  print "\n";

  $self->agent->form(1);
  $self->sync_browser if $self->option('autosync');
  $self->add_history('$agent->get("'.$url.'");'."\n",'  $agent->form(1);');
};

sub run_links {
  my ($self) = @_;
  my $links = $self->agent->extract_links();
  my $count = 0;
  for my $link (@$links) {
    print "[", $count++, "] ", $link->[1],"\n";
  };
};

sub run_forms {
  my ($self,$number) = @_;
  if ($number) {
    $self->agent->form($number);
    $self->agent->current_form->dump;
    $self->add_history('$agent->form('.$number.');');
  } else {
    my $count = 1;
    my @forms = @{$self->agent->{forms}};
    for my $form (@forms) {
      print "Form [",$count++,"]\n";
      $form->dump;
    };
  };
};

sub help_dump {
  "Dump the values of the current form"
};

sub run_dump {
  my ($self) = @_;
  $self->agent->current_form->dump;
};

sub run_value {
  my ($self,$key,$value) = @_;
  $self->agent->current_form->value($key,$value);
  # $self->agent->current_form->dump;
  # Hmm - neither $key nor $value can contain backslashes nor single quotes ...
  $self->add_history('$agent->current_form->value(\''.$key.'\',\''.$value.'\');');
};

sub run_submit {
  my ($self) = @_;
  print $self->agent->submit->code;
  $self->add_history('$agent->submit();');
};

sub run_click {
  my ($self,$button) = @_;
  $button ||= "";
  print $self->agent->current_form->click($button, 1, 1)
    if ($self->option("dumprequests"));
  my $res = $self->agent->click($button);
  $self->agent->form(1);
  print "(",$res->code,")\n";
  if ($self->option('autosync')) {
    $self->sync_browser;
  };
  $self->add_history('$agent->click(\''.$button.'\');');
};

sub run_open {
  my ($self,$link) = @_;
  unless (defined $link) {
    print "No link given\n";
    return
  };
  if ($link =~ m!^/(.*)/$!) {
    my $re = $1;
    my $count = -1;
    my @possible_links = @{$self->agent->extract_links()};
    my @links = map { $count++; $_->[1] =~ /$re/ ? $count : () } @possible_links;
    if (@links > 1) {
      $self->print_pairs([ @links ],[ map {$possible_links[$_]->[1]} @links ]);
      undef $link;
    } elsif (@links == 0) {
      print "No match.\n";
      undef $link;
    } else {
      $link = $links[0];
    };
  };

  if ($link) {
    eval {
      $self->agent->follow($link);
      $self->add_history('$agent->follow(\''.$link.'\');');
      $self->agent->form(1);
      if ($self->option('autosync')) {
        $self->sync_browser;
      } else {
        #print $self->agent->{res}->as_string;
        print "(",$self->agent->{res}->code,")\n";
      };
    };
    warn $@ if $@;
  };
};

# Complete partially typed links :
sub comp_open {
  my ($self,$word,$line,$start) = @_;
  return grep {/^$word/} map {$_->[1]} (@{$self->agent->extract_links()});
};

sub run_back {
  my ($self) = @_;
  $self->agent->back();
  $self->sync_browser
    if ($self->option('autosync'));
  $self->add_history('$agent->back();');
};

sub run_browse {
  my ($self) = @_;
  $self->sync_browser;
};

sub run_set {
  my ($self,$option,$value) = @_;
  $option ||= "";
  if ($option && exists $self->{options}->{$option}) {
    if ($option and defined $value) {
      $self->option($option,$value);
    } else {
      $self->print_pairs( [$option], [$self->option($option)] );
    };
  } else {
    print "Unknown option '$option'\n" if $option;
    print "Valid options are :\n";
    $self->print_pairs( [keys %{$self->{options}}], [ map {$self->option($_)} (keys %{$self->{options}}) ] );
  };
};

sub run_history {
  my ($self) = @_;
  #print join( "", map { $_->[0] } @{$self->{history}}), "\n";
  print <<'HEADER';
use WWW::Mechanize;
use WWW::Mechanize::FormFiller;

my $agent = WWW::Mechanize->new();
my $formfiller = WWW::Mechanize::FormFiller->new();
HEADER
  print join( "", map { "  " . $_->[1] . "\n" } @{$self->{history}}), "\n";
  print <<'FOOTER';
print $agent->{content};
FOOTER
};

sub run_fillout {
  my ($self) = @_;
  $self->{formfiller}->fill_form($self->agent->current_form);
  $self->add_history('$formfiller->fill_form($agent->current_form);');
};

sub run_cookies {
  my ($self,$filename) = @_;
  $self->agent->cookie_jar(HTTP::Cookies->new(
    file => $filename,
    autosave => 1,
    ignore_discard => 1,
  ));
};

sub run_ {
  # ignore empty lines
};

sub help_autofill {
  my ($shell) = @_;
  return "Define an automatic value";
};

sub smry_autofill {
  my ($shell) = @_;
  return "Define an automatic value";
};

sub run_autofill {
  my ($self,$name,$class,@args) = @_;
  $self->{formfiller}->add_filler($name,$class,@args);
  $self->add_history('$formfiller->add_filler( ',$name, ' => ',$class, ' => ', join( ",", @args), ');' );
};

sub run_eval {
  my ($self) = @_;
  my $code = $self->line;
  $code =~ /^eval\s+(.*)$/ and do {
    print eval $1,"\n";
  };
};

sub run_source {
  my ($self,$file) = @_;
  $self->source_file($file);
};

sub help_eval {
  my ($shell) = @_;
  return "Evaluate Perl code and print the result";
};

sub smry_eval {
  my ($shell) = @_;
  return "Evaluate Perl code and print the result";
};

1;

__END__

=head1 NAME

WWW::Mechanize::Shell - A crude shell for WWW::Mechanize

=head1 SYNOPSIS

=for example
  require WWW::Mechanize::Shell;
  no warnings 'once';
  *WWW::Mechanize::Shell::cmdloop = sub {};
  eval { require Term::ReadKey; Term::ReadKey::GetTerminalSize() };
  if ($@) {
    print "0..0 # The tests must be run interactively, as Term::ReadKey seems to want a terminal\n";
    exit 0;
  };

=for example begin

  #!/usr/bin/perl -w
  use strict;
  use WWW::Mechanize::Shell;

  my $shell = WWW::Mechanize::Shell->new("shell", rcfile => undef );

  if (@ARGV) {
    $shell->source_file( @ARGV );
  } else {
    $shell->cmdloop;
  };

=for example end

=for example_testing
  isa_ok( $shell, "WWW::Mechanize::Shell" );

=head1 DESCRIPTION

This module implements a www-like shell above WWW::Mechanize
and also has the capability to output crude Perl code that recreates
the recorded session. Its main use is as an interactive starting point
for automating a session through WWW::Mechanize.

It has "live" display support for Microsoft Internet Explorer on Win32,
if anybody has an idea on how to implement this for other browsers, I'll be
glad to build this in - from what I know, you cannot write raw HTML into
any other browser window.

The cookie support is there, but no cookies are read from your existing
sessions. See L<HTTP::Cookies> on how to implement reading/writing
your current browser cookies.

=head2 COMMANDS

The shell implements various commands :

=over 4

=item restart

Restarts the shell. This is mostly used when you modified the Shell.pm source code.

=item get URL

Downloads a specific URL. This is used as the entry point in all sessions.

=item links

Displays all links on a page.

=item forms

Displays all forms on a page.

=item dump

Dumps the crude Perl code for the current session.

=item value NAME [, VALUE]

Gets respective sets the form field named NAME.

=item submit

Clicks on the button labeled "submit".

=item click NAME

Clicks on the button named NAME.

=item open RE

Opens the link whose text is matched by RE, displays all links if more than one matches.

=item back

Goes back one page.

=item browse

Displays the current page in Microsoft Internet Explorer. No
provision is currently made about IE not being available.

=item set

Sets an option.

=item history

Displays your current session history.

=item fillout

Fills out all form values for which auto-values have been preset.

=item cookies FILENAME

Loads (and stores) the cookies in FILENAME.

=item autofill NAME [PARAMETERS]

Sets a form value to be filled automatically. The NAME parameter is
the WWW::Mechanize::FormFiller::Value subclass you want to use. For
session fields, C<Keep> is a good candidate, for interactive stuff,
C<Ask> is a value implemented by the shell.

=item eval

Evaluates Perl code and prints the result.

=item source

Loads and executes a sequence of commands from a file.

=back

=head2 TODO

=head2 EXPORT

None by default.

=head2 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2002,2003 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

=head1 SEE ALSO

L<WWW::Mechanize>,L<WWW::Mechanize::FormFiller>

=cut
