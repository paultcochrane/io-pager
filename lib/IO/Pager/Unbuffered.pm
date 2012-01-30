package IO::Pager::Unbuffered;

use 5;
use strict;
use vars qw(@ISA $VERSION);
use Tie::Handle;

@ISA = qw(Tie::Handle);
$VERSION = 0.10;

sub new(;$){
  no strict 'refs';
  my $FH = $_[1] || *{select()};

  #STDOUT & STDERR are seperately bound to tty
  if( defined( my $FHn = fileno($FH) ) ){
    if( $FHn == fileno(STDOUT) ){
      return 0 unless -t $FH;
    }
    if( $FHn == fileno(STDERR) ){
      return 0 unless -t $FH;
    }
  }
  #This allows us to have multiple pseudo-STDOUT
  return 0 unless -t STDOUT;

  tie($FH, $_[0], $FH) or die "Can't tie $$FH";
}

sub open(;$){
  new IO::Pager::Unbuffered;
}

sub TIEHANDLE{
  #XXX data structure/assignment cleanness
  my $child;
  unless( $child = CORE::open($_[1], "| $ENV{PAGER}") ){
    $! = "Can't pipe to $ENV{PAGER}: $!";
    return 0;
  }

        #FH, PAGER, CHLD
  bless [$_[1], $ENV{PAGER}, $child], $_[0];
}

sub BINMODE{
  binmode(shift()->[0], @_);
}

sub PRINT{
  CORE::print {shift()->[0]} @_;
}

sub PRINTF{
  PRINT shift, sprintf shift, @_;
}

sub WRITE{
  PRINT shift, substr $_[0], $_[2]||0, $_[1];
}

#XXX close called automagically by destroy on scope exit?
#*DESTROY = *CLOSE;
sub CLOSE{
#  local $^W = 0;
  my $ref = $_[0];

  close($ref->[0]);
#  return if $ref->[2]++;
  untie $ref;
}

1;
__END__
=pod

=head1 NAME

IO::Pager::Unbuffered - Pipe output to a pager if output is to a TTY

=head1 SYNOPSIS

  use IO::Pager::Unbuffered;
  {
    #local $STDOUT =     IO::Pager::Unbuffered::open *STDOUT;
    local  $STDOUT = new IO::Pager::Unbuffered       *STDOUT;
    print <<"  HEREDOC" ;
    ...
    A bunch of text later
    HEREDOC
  }

=head1 DESCRIPTION

IO::Pager is designed to programmatically decide whether or not to point
the STDOUT file handle into a pipe to program specified in $ENV{PAGER}
or one of a standard list of pagers.

=head2 new( [FILEHANDLE] )

Instantiate a new IO::Pager to paginate FILEHANDLE if necessary.
I<Assign the return value to a scoped variable>.

=over

=item FILEHANDLE

Defaults to currently select()-ed FILEHANDLE.

=back

=head2 open( [FILEHANDLE] )

An alias for new.

=head2 close( FILEHANDLE )

Explicitly close the filehandle, if a pager was deemed necessary this
will kill it. Normally you'd just wait for the user to exit the pager
and the object to pass out of scope.

I<This does not default to the current filehandle>.

=head1 CAVEATS

You probably want to do something with SIGPIPE eg;

  eval{
    $SIG{PIPE} = sub{ die };
    local $STDOUT = IO::Pager::open(*STDOUT);

    while(1){
      #Do something
    }
  }

  #Do something else

=head1 SEE ALSO

L<IO::Pager>, L<IO::Pager::Buffered>, L<IO::Pager::Page>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

This module inspired by Monte Mitzelfelt's IO::Page 0.02

Significant proddage provided by Tye McQueen.

=head1 LICENSE

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

=cut
