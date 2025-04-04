package ShinyCMS::PSGI;

use ShinyCMS;
use Plack::Runner;

sub to_app { ShinyCMS->to_app }
sub run { Plack::Runner->run(@_, to_app()) }

sub call {
  my ($command, @args) = @_;
  return run(@args) if $command eq 'run';
  return to_app(@args) if $command eq 'to_app';
}

caller(1) ? 1 : call(@ARGV);
