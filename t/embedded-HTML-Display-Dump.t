#!D:\Programme\indigoperl-5.6\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'D:lib\HTML\Display\Dump.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display
  eval { require HTML::Display };
  skip "Need module HTML::Display to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 13 lib/HTML/Display/Dump.pm
  use HTML::Display;



  my $browser = HTML::Display->new(
    class => 'HTML::Display::Dump',
  );
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");




;

  }
};
is($@, '', "example from line 13");

};
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display
  eval { require HTML::Display };
  skip "Need module HTML::Display to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 13 lib/HTML/Display/Dump.pm
  use HTML::Display;



  my $browser = HTML::Display->new(
    class => 'HTML::Display::Dump',
  );
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");




  isa_ok($browser,"HTML::Display::Common");
  is($_STDOUT_,"<html><body><h1>Hello world!</h1></body></html>","Dumped output");
  is($_STDERR_,undef,"No warnings");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
