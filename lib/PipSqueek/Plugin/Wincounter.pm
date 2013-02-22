package PipSqueek::Plugin::Wincounter;
use base qw(PipSqueek::Plugin);
use Date::Manip;
 
  # This plugin is almost identical in functionality to Failcounter.pm, but for wins instead. See the other file for the more detailed comments.

sub plugin_initialize {
	my $self = shift;

	my $schema = [
	[ 'id',     'INTEGER PRIMARY KEY' ],
	[ 'wincount',    'INTEGER NOT NULL' ],
	[ 'last_mod',    'TIMESTAMP NOT NULL' ],
	];

	$self->dbi()->install_schema( 'wincounter', $schema );

	$self->plugin_handlers(
			'multi_win'         =>      'wincounter',
	);
}

sub wincounter {
	my ($self, $message) = @_;
	my $arg = $message->command_input();
	
	if ($arg eq "+") # Win counter increment command
	{
		my $querycheck = "SELECT * FROM wincounter WHERE id = 1"; # win count entry in db
		my $sthcheck = $self->dbi()->dbh()->prepare( $querycheck );
        # Run the query
        $sthcheck->execute();
		
        my @row = $sthcheck->fetchrow_array(); # Pull the data
		unless ($row[1] eq "") # Sanity check, make sure we got valid data out of the db
		{
			my $originalcount = $row[1]; # Stores the old count
			my $newcount = $originalcount + 1; # Increment it
			
			# Now for the last win entry
			# What time is it?
			
			@tm = localtime(); # Get the date and time. Works in whatever timezone the bot runs in.
		my ($DAY, $MONTH, $YEAR, $HOUR, $MINUTE, $SECOND) = ($tm[3], $tm[4]+1, $tm[5]+1900, $tm[2], $tm[1], $tm[0]);
			
			if ($HOUR < "10") { $HOUR = "0$HOUR"; }
			if ($HOUR eq "0") { $HOUR = "0$HOUR"; }
			if ($MINUTE < "10") { $MINUTE = "0$MINUTE"; }
			if ($MINUTE eq "0") {$MINUTE = "0$MINUTE";  }
			if ($SECOND < "10") { $SECOND = "0$SECOND"; }
			if ($SECOND eq "0") {$SECOND = "0$SECOND";  }
			# formatting...
			
			# Now stick them in the database
			my $newmoddate = "$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND";
			
			my $dateupdate = "UPDATE wincounter SET last_mod = ?, wincount = ? WHERE id = 1"; 
			# Set the last mod entry and wincount
			my $sth = $self->dbi()->dbh()->prepare( $dateupdate )
			or die ("Prepare failed anyway. $DBI::errstr");
			$sth->execute($newmoddate, $newcount);			# Timestamp format.
			
			my $buffer = "wincount incremented; Count is now $newcount.";
			
			#Print to channel and exit
			return $self->respond($message, $buffer);
		}
		
		else
		{
		@tm = localtime(); # Get the date and time. Works in whatever timezone the bot runs in.
        my ($DAY, $MONTH, $YEAR, $HOUR, $MINUTE, $SECOND) = ($tm[3], $tm[4]+1, $tm[5]+1900, $tm[2], $tm[1], $tm[0]);

			if ($HOUR < "10") { $HOUR = "0$HOUR"; }
			if ($HOUR eq "0") { $HOUR = "0$HOUR"; }
			if ($MINUTE < "10") { $MINUTE = "0$MINUTE"; }
			if ($MINUTE eq "0") {$MINUTE = "0$MINUTE";  }
			if ($SECOND < "10") { $SECOND = "0$SECOND"; }
			if ($SECOND eq "0") {$SECOND = "0$SECOND";  }
		
			my $counterfirst = "INSERT INTO wincounter(wincount, last_mod) values (?,?)";
			my $sth = $self->dbi()->dbh()->prepare( $counterfirst );
			
			$sth->execute(1, "$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND");
			
			return $self->respond($message, "Win counter begun!");
		}
		return $self->respond($message, "b0rk");
	}
	
	if ($arg eq "-")
	{
		my $querycheck = "SELECT * FROM wincounter WHERE id = 1"; # win count entry in db
		my $sthcheck = $self->dbi()->dbh()->prepare( $querycheck );
        # Run the query
        $sthcheck->execute();
		
        my @row = $sthcheck->fetchrow_array(); # Pull the data
		unless ($row[1] eq "") # Sanity check, make sure we got valid data out of the db
		{
			my $originalcount = $row[1]; # Stores the old count
			my $newcount = $originalcount - 1; # decrement it
			
			my $dateupdate = "UPDATE wincounter SET wincount = ? WHERE id = 1"; 
			# Set the last mod entry and wincount
			my $sth = $self->dbi()->dbh()->prepare( $dateupdate )
			or die ("Prepare failed anyway. $DBI::errstr");
			$sth->execute($newcount);			# Timestamp format.
			
			my $buffer = "We lost a win. Count is now $newcount.";
			
			#Print to channel and exit
			return $self->respond($message, $buffer);
		}
	}
	
	if ($arg eq "count")
	{
		my $sthcheck = "SELECT * FROM wincounter WHERE id = 1";
		my $sth = $self->dbi()->dbh()->prepare( $sthcheck );
		# Run the query
		$sth->execute();
		
		my @row = $sth->fetchrow_array();
		unless ($row[1] eq "")
		{
			my $buffer = "Win Count is currently: $row[1], last win was $row[2].";
			return $self->respond($message, $buffer);
		}
		else
		{
			return $self->respond($message, "Wincounter is undefined, broken, being worked on, or uninitialised.");
		}
	}
	
	else
	{
		return $self->respond($message, "You said something I did not recognise or said it in a way I wasn't expecting. Please rephrase it and try again.");
	}
}

1;