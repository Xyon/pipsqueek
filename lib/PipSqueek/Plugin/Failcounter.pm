package PipSqueek::Plugin::Failcounter;
use base qw(PipSqueek::Plugin);
use Date::Manip;
 
  # Fail counter Pipsqueek module. A simple way of tracking how many times the IRC channel has failed.

sub plugin_initialize {
	my $self = shift;

	# We use the SQL database Pipsqueek already has to store data in. If the table doesn't exist, this creates it on plugin load.
	
	my $schema = [
	[ 'id',     'INTEGER PRIMARY KEY' ],
	[ 'failcount',    'INTEGER NOT NULL' ],
	[ 'last_mod',    'TIMESTAMP NOT NULL' ],
	];

	$self->dbi()->install_schema( 'failcounter', $schema );

	# Configure what commands should be handled by this module
	$self->plugin_handlers(
			'multi_fail'         =>      'failcounter',
	);
}

sub failcounter {

	# One command in this module, triggered by "Fail". It splits into separate components based on input.
	
	my ($self, $message) = @_;
	
	# Take the input - it defines the command.
	my $arg = $message->command_input();
	
	if ($arg eq "+") # Fail counter increment command
	{
		my $querycheck = "SELECT * FROM failcounter WHERE id = 1"; # Fail count entry in db
		my $sthcheck = $self->dbi()->dbh()->prepare( $querycheck );
        # Run the query
        $sthcheck->execute();
		
        my @row = $sthcheck->fetchrow_array(); # Pull the data
		unless ($row[1] eq "") # Sanity check, make sure we got valid data out of the db
		{
			my $originalcount = $row[1]; # Stores the old count
			my $newcount = $originalcount + 1; # Increment it
			
			# Now for the last fail entry
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
			
			my $dateupdate = "UPDATE failcounter SET last_mod = ?, failcount = ? WHERE id = 1"; 
			# Set the last mod entry and failcount
			my $sth = $self->dbi()->dbh()->prepare( $dateupdate )
			or die ("Prepare failed anyway. $DBI::errstr");
			$sth->execute($newmoddate, $newcount);			# Timestamp format.
			
			my $buffer = "Failcount incremented; Count is now $newcount.";
			
			#Print to channel and exit
			return $self->respond($message, $buffer);
		}
		
		else
		{
			# We didn't get valid data out of the database. This usually means that the table is empty or something horrendous broke, so
			# create the initial counter data, or die in an horrifically painful manner as befits SQL.
		
			@tm = localtime(); # Get the date and time. Works in whatever timezone the bot runs in.
			my ($DAY, $MONTH, $YEAR, $HOUR, $MINUTE, $SECOND) = ($tm[3], $tm[4]+1, $tm[5]+1900, $tm[2], $tm[1], $tm[0]);

			if ($HOUR < "10") { $HOUR = "0$HOUR"; }
			if ($HOUR eq "0") { $HOUR = "0$HOUR"; }
			if ($MINUTE < "10") { $MINUTE = "0$MINUTE"; }
			if ($MINUTE eq "0") {$MINUTE = "0$MINUTE";  }
			if ($SECOND < "10") { $SECOND = "0$SECOND"; }
			if ($SECOND eq "0") {$SECOND = "0$SECOND";  }
		
			my $counterfirst = "INSERT INTO failcounter(failcount, last_mod) values (?,?)";
			my $sth = $self->dbi()->dbh()->prepare( $counterfirst );
			
			$sth->execute(1, "$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND");
			
			return $self->respond($message, "Failcounter begun!");
		}
		
		# Uh, yeah. Not sure what has to happen for us to get down here, hence the really helpful error message.
		return $self->respond($message, "b0rk");
	}
	
	if ($arg eq "-")
	{
		# Fail count decrement command... sort of.
		
		return $self->respond($message, "I have no provision for reducing the failcount. You can't undo fail.");
	}
	
	if ($arg eq "count")
	{
		# Fail count command - shows the amount of fail, and when the last fail was, but doesn't increment the count.
	
		my $sthcheck = "SELECT * FROM failcounter WHERE id = 1";
		my $sth = $self->dbi()->dbh()->prepare( $sthcheck );
		# Run the query
		$sth->execute();
		
		my @row = $sth->fetchrow_array();
		unless ($row[1] eq "")
		{
			my $buffer = "Failcount is currently: $row[1], last fail was $row[2].";
			return $self->respond($message, $buffer);
		}
		else
		{
			# Something broke.
			return $self->respond($message, "Failcounter is undefined, broken, being worked on, or uninitialised.");
		}
	}
	
	else
	{
		# No other arguments are supported, barf out to channel and go die in the corner.
		return $self->respond($message, "You said something I did not recognise or said it in a way I wasn't expecting. Please rephrase it and try again.");
	}
}

1;