package PipSqueek::Plugin::wfratio;
use base qw(PipSqueek::Plugin);
use Date::Manip;
 
  # Takes data from the database added by failcounter and wincounter and makes a priddy ratio out of it.

sub plugin_initialize {
	my $self = shift;
	
	$self->plugin_handlers(
			'multi_ratio'         =>      'ratio',
	);
}

sub ratio {
	my ($self, $message) = @_;
	
	my $querycheck = "SELECT * FROM failcounter ORDER BY id DESC LIMIT 1"; # highest ID count in fail db
	my $sthcheck = $self->dbi()->dbh()->prepare( $querycheck );
    # Run the query
    $sthcheck->execute();
	
	my @fail = $sthcheck->fetchrow_array();
	
	my $failamount = $fail[1];
	
	my $querycheck2 = "SELECT * FROM wincounter ORDER BY id DESC LIMIT 1"; # highest ID count in win db
	my $sthcheck2 = $self->dbi()->dbh()->prepare( $querycheck2 );
    # Run the query
    $sthcheck2->execute();
	
	my @win = $sthcheck2->fetchrow_array();
	
	my $winamount = $win[1];

	my $normalised = $failamount / $winamount;
	
	# Fuck rounding this off. We like precision in our channel - well, I do anyway.
	my $buffer = "Fail:Win ratio is currently $failamount:$winamount ($normalised:1)";
	return $self->respond($message, $buffer);
}

1;