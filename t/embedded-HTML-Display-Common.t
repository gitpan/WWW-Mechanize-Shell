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

my $Original_File = 'D:lib\HTML\Display\Common.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module base
  eval { require base };
  skip "Need module base to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 20 lib/HTML/Display/Common.pm

  package HTML::Display::WhizBang;
  use base 'HTML::Display::Common';

  sub new {
    my ($class) = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);

    # do stuff

    $self;
  };




;

  }
};
is($@, '', "example from line 20");

};
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display
  eval { require HTML::Display };
  skip "Need module HTML::Display to run this test", 1
    if $@;

  # Check for module base
  eval { require base };
  skip "Need module base to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 20 lib/HTML/Display/Common.pm

  package HTML::Display::WhizBang;
  use base 'HTML::Display::Common';

  sub new {
    my ($class) = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);

    # do stuff

    $self;
  };




  package main;
  use HTML::Display;
  my $browser = HTML::Display->new( class => "HTML::Display::WhizBang");
  isa_ok($browser,"HTML::Display::Common");

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
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display::Dump
  eval { require HTML::Display::Dump };
  skip "Need module HTML::Display::Dump to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 64 lib/HTML/Display/Common.pm
  no warnings 'redefine';
  *HTML::Display::new = sub {
    my $class = shift;
    require HTML::Display::Dump;
    return HTML::Display::Dump->new(@_);
  };



  my $html = "<html><body><h1>Hello world!</h1></body></html>";
  my $browser = HTML::Display->new();
  $browser->display( html => $html );




;

  }
};
is($@, '', "example from line 64");

};
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display::Dump
  eval { require HTML::Display::Dump };
  skip "Need module HTML::Display::Dump to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 64 lib/HTML/Display/Common.pm
  no warnings 'redefine';
  *HTML::Display::new = sub {
    my $class = shift;
    require HTML::Display::Dump;
    return HTML::Display::Dump->new(@_);
  };



  my $html = "<html><body><h1>Hello world!</h1></body></html>";
  my $browser = HTML::Display->new();
  $browser->display( html => $html );




  isa_ok($browser, "HTML::Display::Dump","The browser");
  is( $main::_STDOUT_,"<html><body><h1>Hello world!</h1></body></html>","HTML gets output");

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
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display::Dump
  eval { require HTML::Display::Dump };
  skip "Need module HTML::Display::Dump to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 89 lib/HTML/Display/Common.pm
  no warnings 'redefine';
  *HTML::Display::new = sub {
    my $class = shift;
    require HTML::Display::Dump;
    return HTML::Display::Dump->new(@_);
  };



  my $html = '<html><body><img src="/images/hp0.gif"></body>';
  my $browser = HTML::Display->new();

  # This will display part of the Google logo
  $browser->display( html => $html, location => 'http://www.google.com' );




;

  }
};
is($@, '', "example from line 89");

};
SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module HTML::Display::Dump
  eval { require HTML::Display::Dump };
  skip "Need module HTML::Display::Dump to run this test", 1
    if $@;


    # The original POD test
    {
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 89 lib/HTML/Display/Common.pm
  no warnings 'redefine';
  *HTML::Display::new = sub {
    my $class = shift;
    require HTML::Display::Dump;
    return HTML::Display::Dump->new(@_);
  };



  my $html = '<html><body><img src="/images/hp0.gif"></body>';
  my $browser = HTML::Display->new();

  # This will display part of the Google logo
  $browser->display( html => $html, location => 'http://www.google.com' );




  isa_ok($browser, "HTML::Display::Dump","The browser");
  is( $main::_STDOUT_,'<html><body><img src="/images/hp0.gif"></body>',"HTML gets output");

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
