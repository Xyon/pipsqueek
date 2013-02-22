package PipSqueek::Plugin::Brainbleach;
use base qw(PipSqueek::Plugin);

# Original brain-replacement therapy plugin for Pipsqueek, written by Xyon
# For use when the mental images are just too much.

# This software is open-source and freeware. Don't pay anybody any money for it - you won't get it back.

sub plugin_initialize {
	my $self = shift;

	# If the database table doesn't already exist, create it
	my $schema = [
	[ 'id',     'INTEGER PRIMARY KEY' ],
	[ 'bleachitem',    'INTEGER NOT NULL' ],
	[ 'type', 'INTEGER'],
	];

	$self->dbi()->install_schema( 'brainbleach', $schema );
	
	# Configure responses to commands - see levels.conf for restrictions
	$self->plugin_handlers({
	'multi_brainbleach'	=>	'responder',
	'multi_+bleachitem'	=>	'item_adder',
	'multi_-bleachitem'	=>	'item_deleter',
	'multi_bleachlist'	=>	'list_display',
	'multi_changetype'	=>	'change_type',
	'multi_bleachratio'		=>	'ratio',
	});
	
	# Used to format responses from the list command (Formats the type integer into something more informative)
	@types = ("Bad","Neutral","Good");
}

sub responder {

	# Called with !brainbleach
	# Primary function, takes your brain out, and replaces it with something vaguely humerous.
	
	my ($self, $message) = @_;
	my $nick = $message->{nick};
	
	# Find how many database entries there are (used for the limit of the RNG)
	my $idcheck = "SELECT id FROM brainbleach ORDER BY id DESC LIMIT 1"; 
	my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck );
	
	$sthidcheck->execute();
	
	my @row = $sthidcheck->fetchrow_array();
	my $limit = $row[0];
	
	# Generate the random number used to select an entry from the database.
	$rand = int(rand($limit));
	
	# Pull out our entry from the database
	my $querycheck = "SELECT * FROM brainbleach WHERE id = ?"; 
	my $sthcheck = $self->dbi()->dbh()->prepare( $querycheck );
    # Run the query
    $sthcheck->execute($rand);
	
	my @row = $sthcheck->fetchrow_array(); # Pull the data
		unless ($row[1] eq "") # Sanity check, make sure we got valid data out of the db
	{
		# Response to channel, as a CTCP ACTION string.
		return $self->respond($message,"\x01ACTION rips $nick\'s brain from their skull, dunks it in bleach, and then replaces it. WITH $row[1]\x01");
	}
	else
	{
		# Error handling - this happens when there is nothing in the database, when the database doesn't exist,
		# or when all hell has broken loose in your SQL environment and the goblins are revolting again.
		return $self->respond($message,"Error handler - got crap data from db.");
	}
}

sub item_adder {

	# Adds an item to the database. This command is by default restricted in levels.conf
	
	my ($self, $message) =@_;
	
	# Grab the command input to pull in the name of the item they want to add.
	my $item = $message->command_input();
	
	# Check for interesting input - blame Lambo for this check, but the regex we generated was all him because regex hurts my brain.
    $item =~ s/[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]+//g;
	
	if ($item eq "")
	{
		# If they didn't give us an item to add (NULL input)
		return $self->respond($message, "I can't add something to the database unless you tell me what it is.");
	}
	
	# Get the highest id number from the database
	
	my $idcheck = "SELECT id FROM brainbleach ORDER BY id DESC LIMIT 1";
	my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck );
	
	$sthidcheck->execute();
	
	my @row = $sthidcheck->fetchrow_array();
	my $id = $row[0];
	
	# Format the id number to account for zero-based indexing in the database
	
	if ($id eq "")
	{
		# Only happens when the database is brand new and empty - we'll get NULL out of the database
		# so set $id to 0 for the first entry
		$id = 0;
	}
	else
	{
		# Otherwise, we'll get the last id number - incrementing it gives us the id number we're adding.
		$id = $id + 1;
	}
	
#	Uncomment and change to insert an item into a specific slot
#	$id = 0;
	
	# Generate the query. Using the "?" approach is safer than running the command directly, apparently.
	
	my $addquery = 'INSERT INTO brainbleach(id, bleachitem) values (?,?)';
	
	my $sth = $self->dbi()->dbh()->prepare($addquery) or die "prepare $DBI::errstr;";
       
    $sth->execute("$id", "$item")
		or die "execute $DBI::errstr";
	
	# Provided neither of the "die" cases above are hit (again, errors in SQL or goblins can cause that)
	# we've added the item successfully - inform the user and tell them their item's id number
	
	return $self->respond($message,"Item added to database with ID $id");
}

sub item_deleter {
	
	# Removes an item from the database. Access normally restricted in levels.conf
	
	my ($self, $message) =@_;
	
	# Take the item they want to remove. Only numbers are of any use.
	my $item = $message->command_input();
	
	# Make sure the input is numeric
    unless ($item =~ /^\d/)
	{
		# Item was not a number - tell the user to query the list with the list query command to get the number.
		return $self->respond($message, "You need to use the ID number of the item. Use bleachlist to query the database.");
	}
	
	if ($item eq "")
	{
		# If they gave us nothing, tell them it's hard to delete something unless we know what to delete.
		return $self->respond($message, "I'm all for deleting something, but I need a clue about what to delete, or bad things will happen.");
	}
	
	# Check if the number is too high (check it against the ID index limit)
	
	# Find the highest id number from the database
	my $idcheck = "SELECT id FROM brainbleach ORDER BY id DESC LIMIT 1";
	my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck );
	
	$sthidcheck->execute();
	
	my @row = $sthidcheck->fetchrow_array();
	my $id = $row[0];
	
	if ($id < $item)
	{
		# If the id number is higher than the last entry in the db - it's helpful to explain the limits to the user
		# at this point.
		return $self->respond($message, "You wanted to delete item $item from the database, but the indexes don't go that high. Please specify a number between 0 and $id.");
	}
	
	my $sth1 = $self->dbi()->dbh()->prepare('DELETE FROM brainbleach WHERE id = ?');
    # Run the query... lalalala
    $sth1->execute($item)
		or die "Delete failure: $DBI::errstr";
 
    # Shuffle the index to move the gap
	# Without this code, we would wind up with a non-contiguous database after deletions, because SQL
	# likes to just leave the database entries as they are after deleting one.
	
	# Since I like my indices to add up and count cardinally, this snippet comes in handy.
    # It is a REAL hackjob, inspired by hard black coffee and 3am, nicked from my own freezer code...
    
	# Firstly, find everything with an id higher than the one we just took out
	
    my $gapfind = 'SELECT id FROM brainbleach WHERE id > ?'; 
    my $sth3 = $self->dbi()->dbh()->prepare($gapfind) or die "Prepare: $DBI::errstr";
    $sth3->execute($item) or die "Execute: $DBI::errstr";
    
    while (@row = $sth3->fetchrow_array()){
    
            my $oldnum = $row[0];
			
			# Decrement each id sequentially. The less there are the less this takes.
            my $newnum = ($oldnum)-1;
    
			# Now update each entry with an id number one lower than it previously had.
            my $gapkiller = 'UPDATE brainbleach SET id=? WHERE id=?';
            my $qr1 = $self->dbi()->dbh()->prepare($gapkiller)
				or die "Prepare failure: DBI::errstr";
            $qr1->execute($newnum, $oldnum)
				or die "Execute failure: DBI::errstr";
    }
	
    # Confirm removal and finish
    return $self->respond($message, "Item $item removed from database.");
}

sub list_display {

	# Displays the list of items in the database (limited to one item at a time - gets spammy as hell otherwise).
	# Access to this command is optionally restricted in levels.conf.
	
	my ($self, $message) =@_;
	
	# Arguments here specify which id number to inspect.
	my $args = $message->command_input();
	
	if ($args eq "")
	{
		# Ask them to specify an item, but provide the size of the database.
		
		my $idcheck = "SELECT id FROM brainbleach ORDER BY id DESC LIMIT 1"; #find the last ID
		my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck );
		
		$sthidcheck->execute();
		
		my @row = $sthidcheck->fetchrow_array();
		my $id = $row[0];
		
		$id++; #Increment because we count from 0
		
		return $self->respond($message, "There are $id items in the brainbleach database. Please specifiy an entry to display.");
	}
	
	# Otherwise, the argument specifies the ID of the entry to show
	
	if ($args =~ /^\d/) # Make sure the arg is a number, otherwise querying the db with it will go badly
	{
		# Check that the number passed to us actually exists in the database.
		my $idcheck = "SELECT * FROM brainbleach WHERE id = ?";
		my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck ) or die "Prepare; $DBI::errstr";
		
		$sthidcheck->execute($args)
			or die "Execute; $DBI::errstr";
		
		my @row = $sthidcheck->fetchrow_array();
		
		# Safeguard against getting nothing out of the query; handle errors with our usual grace
		if ($row[0] eq "") 
		{
			# The most common reason for this is specifying a number too large, so let's check if that's
			# what happened and return something more helpful if it was.
			
			# Find the highest index number in the database.
			my $idcheck = "SELECT id FROM brainbleach ORDER BY id DESC LIMIT 1";
			my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck );
			
			$sthidcheck->execute();
			
			my @row = $sthidcheck->fetchrow_array();
			my $id = $row[0];	
			
			if ($id < $args)
			{
				# Yes, the number given to us was higher than the amount of entries in the db; tell the user this
				
				$id++; #increment because we count from 0
				
				return $self->respond($message, "Error: You asked for item $args, but there are only $id items in the database (It's a zero-based index).");
			}
			else
			{
				# Some other creative error
			
				# Zatman had a soft spot for floating point numbers when this was written, so;
				
				if ($args =~ /^\d+.\d/)
				{
					# Floating point (or any decimal number) given.
					
					return $self->respond($message, "Round it up, dumdum, ID numbers are integers.");
				}
			
				# Some other problem. Dunno what it was, so neither does the bot, we'll just add a catch-all to
				# break out of processing anything else.
				return $self->respond($message, "Whatever the fuck that argument was, I didn't understand it. Please stop being a dick.");
			}
		}
		
		# If it's good, return the specified ID and its corresponding string
		
		return $self->respond($message,"Item $row[0]: $row[1] ($types[$row[2]])");
	}
	
	else 
	{
		# If it gets here, it's probably a negative number, because it didn't pass the regex above
		
		if ($args =~ /^-?\d/) 
		{
			# Yes, negative number.
			
			return $self->respond($message, "Negative numbers don't work here - the database starts at ID 0.");
		}
	}
	
	# Otherwise, it wasn't a number at all.
	return $self->respond($message, "Please use a number.");
}

sub change_type {
	# Changes the type of the database entry (Good, Neutral, Bad) (Default is Bad)
	
	my ($self, $message) = @_;
	
	# Take the command input and split it up into different commands on a whitespace character
	my @check = split(/\s+/, $message->command_input());
	
	unless ($check[0] =~ /^\d/)
	{
		# Verify that the first command is the number of the item to change
		
		return $self->respond($message, "I need the numerical ID of the entry to change its type.");
	}
	
	# Check that the item exists in the database
	my $idcheck = "SELECT * FROM brainbleach WHERE id = ?"; 
	my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck ) or die "Prepare; $DBI::errstr";
	
	$sthidcheck->execute($check[0])
		or die "Execute; $DBI::errstr";
	
	my @row = $sthidcheck->fetchrow_array();
			
	if ($row[0] eq "")
	{
		# Got NULL output from DB
		
		# Test if the number is within the range
		
		# Find the highest id number in the database.		
		my $idcheck = "SELECT id FROM brainbleach ORDER BY id DESC LIMIT 1";
		my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck )
			or die "Prepare $DBI::errstr";
		
		$sthidcheck->execute()
			or die "Execute $DBI::errstr";
		
		my @row = $sthidcheck->fetchrow_array();
		my $id = $row[0];
		
		if ($id < $check[0])
		{
			# Number was too large for database.
			
			$id++; #increment because we count from 0
			
			return $self->respond($message, "Error: You asked for item $check[0], but there are only $id items in the database (It's a zero-based index).");
		}
	}
	
	# If it's good, we can set the type
	
	unless ($check[1] =~ /^\d/ && $check[1] >= 0 && $check[1] <= 2)
	{
		# Checking that the command was a number, and between 0 and 2 (Our defined type identifiers).
		return $self->respond($message, "You must specify a number for the type; 0 = bad, 1 = neutral, 2 = good");
	}
	
	# All is good - we can alter the database entry with that data, so let's do it.
	
	my $idcheck = "UPDATE brainbleach SET type=? WHERE id = ?"; #find the highest ID
	my $sthidcheck = $self->dbi()->dbh()->prepare( $idcheck ) or die "Prepare; $DBI::errstr";
	
	$sthidcheck->execute($check[1], $check[0])
		or die "Execute; $DBI::errstr";
	
	# Done and done. Tell the user about what we did and exit the subroutine.
	# We're using the @types array defined in the plugin init to format the 0,1,2 number into something more
	# relevant.
	return $self->respond($message, "Type of item $check[0] set to $types[$check[1]] ($row[1])");
}

sub ratio {
	
	# Provides information about the number of each type of item in the database.
	# Usually a public command.
	
	my ($self, $message) = @_;
	
	# Select every entry from the database from id 0 to the limit and examine its "type" entry
	my $query = "SELECT type FROM brainbleach";
	my $sth = $self->dbi()->dbh()->prepare($query) or die "Prepare $DBI::errstr";
	$sth->execute();
	
	# Variables to hold the different results
	my ($bad, $neut, $good) = 0;
	
	# Sequential checking - each row in turn is examined. This doesn't appear to be anything terrifyingly slow,
	# but could be if you're a lunatic and add 100,000 database entries.
	
	while (@row = $sth->fetchrow_array())
	{
		if ($row[0] == 0)
		{
			# Value of 0 in type column - increment the $bad variable.
			$bad++;
		}
		if ($row [0] == 1)
		{
			# 1 = neutral
			$neut++;
		}
		if ($row[0] == 2)
		{
			# and 2 = good. Simple, eh?
			$good++;
		}
	}
	
	
	# Print out a summary of the number of each type in the database.
	$self->respond($message, "Item summary: Bad: $bad, Neutral: $neut, Good: $good");
	
	# This next bit is supposed to generate a ratio Good:Neutral:Bad, normalised to 1
	# However it doesn't yet work right.
	
	# It does some stuff, but nothing useful, so its outputs are commented out until it's working.
	
	if ($bad < $good && $bad < $neut || $bad == $neut) {
		# Bad is smallest
		
		$bad = $bad/$bad; # 1
		$good = $good/$bad;
		$neut = $neut/$bad;
		
		# round the digits off
		
		$bad = sprintf("%.2f", $bad);
		$good = sprintf("%.2f", $good);
		$neut = sprintf("%.2f", $neut);
		
	#	return $self->respond($message, "Ratio (Good:Neut:Bad): $good:$neut:$bad");
	}
	if ($good < $neut && $good < $bad || $good == $bad) {
		# good is smallest
		
		$bad = $bad/$good; 
		$good = $good/$good; # 1
		$neut = $neut/$good;
		
		# round the digits off
		
		$bad = sprintf("%.2f", $bad);
		$good = sprintf("%.2f", $good);
		$neut = sprintf("%.2f", $neut);
		
	#	return $self->respond($message, "Ratio (Bad:Neut:Good): $bad:$neut:$good");
	}
	if ($neut < $good && $neut < $bad || $neut == $good) {
		# neut is smallest
		
		$bad = $bad/$neut; 
		$good = $good/$neut;
		$neut = $neut/$neut; # 1
		
		# round the digits off
		
		$bad = sprintf("%.2f", $bad);
		$good = sprintf("%.2f", $good);
		$neut = sprintf("%.2f", $neut);
		
	#	return $self->respond($message, "Ratio (Good:Bad:Neut): $good:$bad:$neut");
	}
}

1;