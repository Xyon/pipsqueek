package PipSqueek::Plugin::Freezer2;
use base qw(PipSqueek::Plugin);
 
#######################################################################################################
#                                                                                                     #
#               Pipsqueek plugin: Freezer (second version                                             #
#                                                                                                     #
#               Created by Xyon for #orbiterradio on irc.systemnet.info                               #
#                                                                                                     #
#       This began as a running joke and evolved into the monstrocity it now is.                      #
#       It's been coded piecemeal as new scope was added and is in no way optimal.                    #
#       Most of it was done at around 3AM, so a lot of the coding errors can be blamed on that.       #
#                                                                                                     #
#       It can be used as a base for your own similar thing, but it's currently heavily hardcoded	  #
#       and custom by nature.                                                                         #
#                                                                                                     #
#       This is the second version which should hopefully be a little better.                         #
#                                                                                                     #
#######################################################################################################
 
sub config_initialize
{
    my $self = shift;
	
    $self->plugin_configuration({
                'freezer_lock_startup_state'	=>		'unlocked',
                'freezer_startup_temp'			=>		'255',
                'freezer_owner_nick'			=>		'Xyon',
                'freezer_bot_nick'				=>		'CoffeeBot', # There's probably a way to call the current bot nick so it can track changes mid-session, look into that later
    });
}
 
sub plugin_initialize {
	my $self = shift;
	my $config = $self->config();
	
	# Database stuff. Moved out of mysql now because there's no real reason to use it...
   
   $temp = $config->freezer_startup_temp();
   $lock = $config->freezer_lock_startup_state();
   $owner = $config->freezer_owner_nick();
   
	my $schema = [
	[ 'id',     'INTEGER PRIMARY KEY' ],
	[ 'listnum',    'INTEGER NOT NULL' ],
	[ 'item_name',    'VARCHAR NOT NULL' ],
	[ 'added_by',    'VARCHAR NOT NULL' ],
	[ 'added_on',    'TIMESTAMP NOT NULL' ],
	[ 'removable',     'BOOLEAN NOT NULL DEFAULT 0' ],
	];

	$self->dbi()->install_schema( 'freezer', $schema );

	# Array holds comments for when someone tries to pull the penguin out
	$Penguin[1] = "The Penguin Resists!";
	$Penguin[2] = "Uhh... I don't think he wants to move right now.";
	$Penguin[3] = "Yeah, he's WAY too busy fapping for that.";
	$Penguin[4] = "Not a chance in hell. He'd just try to buttfuck me or something.";
	$Penguin[5] = "He'll come out when he's ready... or something.";
	$Penguin[6] = "I'm... I'm scared he'll hurt me";
	$Penguin[7] = "It's too warm out here. He'd melt. Best leave him in there.";
   
	# Commands we accept for the freezer and the source we accept them from
   
	$self->plugin_handlers(
			'multi_freezer'         =>      'freezer', # list items in freezer. Needs limiting to avoid floods.
			'multi_freezerdimensionalrealignment', => 'freezer_dim', # Fixes the damn thing after a troutmode.
			'multi_freezer+'        =>      'freezer_add', # add item to freezer. May need an item-exists check.
			'multi_freezer-'        =>      'freezer_rem', # remove item from freezer.
	);

}

sub freezer {
        my ($self, $message) = @_;
		
		my $config = $self->config();
				
        #check to see if we got an argument for this
        my @check = split(/\s+/, $message->command_input()); # Splits on a space to deliniate args
        my $nick = $message->{nick}; # Grab the nick who sent us the message
       
        if ($troutmode eq 0)
        {
                return $self->respond($message, "There is no freezer. There is only trout. Expect dimensional convergence in... crap, my watch is made of trout. Well, soon, anyway.");
        }
               # Check for someone mistyping freezer- num as freezer -num
       
        if (lc($check[0]) =~ /[-]/g)
      {
              $self->respond($message, "Assuming you meant \"freezer-\"...");
              $self->freezer_rem($message);
			  return;
      }

        if ( lc($check[0]) =~ /^[+-]?\d+$/) # Check for a number, if so give item details list
        {
                # Query db for info on item number
				
                my $query = 'SELECT * FROM freezer WHERE listnum = ?';
                my $sth = $self->dbi()->dbh()->prepare($query);
                #run the query
                $sth->execute($check[0]);
               
                # Format and output to buffer for dumping.
                @string = ("Item $check[0] details");
                while(@row = $sth->fetchrow())
                {
                        my $buffer = "Name: $row[2]; Added by: $row[3] on $row[4]";
                        @string = (@string, $buffer);
                }
                # Print string to message and exit done.
                my $output = join ('; ', @string);
                return $self->respond($message, $output);
        }
        # Not a number, some other command.
		if (lc($check[0]) eq "kick") # Freezer Kick command
                {
                        my $range = 19;
                        my $num = int(rand($range) + 1); # Max num should be 20, d20 rules, y'know?
                        if ($num eq 1)
                        {
                                my $output = "You rolled a one. The freezer wobbles over and falls on you, and you are killed to death. Fatally.";
                                $self->respond($message, $output);
                                return $self->client()->kick( $message->channel(), $message->nick(), $output );
                        }
                       
                        if ($num > 1 && $num < 5)
                        {
                                my $speed = int(rand(2000));
                                my $output = "You rolled a $num. The Penguin opened the door to see what the noise was. Unfortunately the door hit you in the face at $speed mph.";
                                $self->respond($message, $output);
                                return $self->client()->kick( $message->channel(), $message->nick(), $output);
                        }
                       
                        if ($num >= 5 && $num < 10)
                        {
                                my $output;
                                if ($num = 8) {$output = "You rolled an $num. You stub your toe! You hop around in pain for a few moments. The Penguin laughs at you and slams the door shut.";}
                                else { $output = "You rolled a $num. You stub your toe! You hop around in pain for a few moments. The Penguin laughs at you and slams the door shut.";}
                                return $self->respond($message, $output);
                        }
                       
                        if ($num >= 10 && $num < 15)
                        {
                                return $self->respond($message, "You rolled a $num. The freezer wobbles slightly. A faint sound of gurgling liquid was heard within, but it soon passed.");
                        }
                       
                        if ($num >= 15 && $num < 19)
                        {
                                $lockchance = rand(1);
                                my $output = "Something broke, but it wasn't the freezer or the lock.";
                                if ($lockchance > 0.85)
                                {
                                $lock = "unlocked";
                                       
                                $output = "You rolled $num! The freezer dents where you kicked it and rattles violently. The lock pops off the freezer! The Penguin develops a serious headache."; 
								}                            
                        
                               
                                else { $output = "You rolled $num! The freezer dents where you kicked it and rattles violently. The Penguin develops a serious headache.";}

                                return $self->respond($message, $output);
                        }
						
                        if ($num eq 19)
                        {
                                $lockchance = rand(1);
                                my $output = "Something broke, but it wasn't the freezer or the lock.";
                                if ($lockchance > 0.75)
                                {
                                $lock = "unlocked";
                                        
                                $output = "You rolled a $num! The very ground vibrates violently with the vigorous power of your strike! The lock breaks! The freezer does not, though. You can hear time and space beginning to come loose. With just a little more power...";                              
                                }
                               
                                
                                else { $output = "You rolled a $num! The very ground vibrates violently with the vigorous power of your strike! The freezer does not, though. You can hear time and space beginning to come loose. With just a little more power...";}
                               
                                return $self->respond($message, $output);
                        }
                       
                        if ($num eq 20)
                        {
                                $self->respond($message, "CRITICAL HIT (20)! The very fabric of spacetime rends loose before your boot as you blow the freezer into an alternate dimension where there is only trout!");
                                my $output = "You are pulled into the rift! You feel somewhat strange... almost fishy...";
                                $self->respond($message, $output);
                                $troutmode = 0;
                               
                                return $self->client()->kick( $message->channel(), $message->nick(), $output);
                        }
                        else { # in case we get a fuckup with the rng, basically... seen a few trigger the freezer list.
                                return $self->respond($message, "You broke the dice. Try again.");
                        }
                }
       
        else {
                if ( lc($check[0]) eq "lock") # Freezer lock command, toggle.
                        {
                                if ($nick eq $owner) # Again, check for access based on username
                                {
                                        if ($lock eq "unlocked") # Toggling, so we need to poll the current state.
                                        {
                                                $lock = "locked"; # If it's not locked, lock it and tell the channel we did it
												
                                                return $self->respond($message, "\x01ACTION locks the freezer\x01");
                                        }
                                        else
                                        {
                                                $lock = "unlocked"; # And vice versa.
												
                                                return $self->respond($message, "\x01ACTION unlocks the freezer\x01");
                                        }
                                }
                                else # Unauthorised user does not have key.
                                {
                                        return $self->respond($message, "You don't have the key.");
                                }
                        }

                if (lc($check[0]) eq "temp") # Freezer Temperature command.
                {
                        if (lc($check[1]) eq "") # No number catch, returns to default temp.
                        {
                                        $temp = $config->freezer_startup_temp();
										
                                        return $self->respond($message, "Freezer temperature returned to default.");
                        }
                        if (lc($check[1]) =~ /^[+-]?\d+$/) # Catch the number and parse it.
                        {
                                if (lc($check[1]) > 255) # Temp upper limit...
                                {
                                        return $self->respond($message, "What? Freezers don't go that high, fuckwit.");
                                }
                                if (lc($check[1]) <= 0) # ... and lower. Could use config file vars here for less hardcoding.
                                {
                                        return $self->respond($message, "Brush up on your physics. Especially the bit about absolute zero.");
                                }
                       
                                $temp = $check[1]; # If the number is good, use it.
								
                                return $self->respond($message, "Freezer temperature now $temp K.");
                        }
                        else { # If not, spit out and die.
                                return $self->respond($message, "Not a valid temperature.");
                        }
                }
                
        }
       
        # None of the above match or we didn't get an arg, spew the freezer list.
        # Query db for items and who added them (We use rows 2, 3, and 4 for this list).
		if ($check[0] eq "") {
			my $sth = $self->dbi()->dbh()->prepare('SELECT * FROM freezer');
			# run the query
			$sth->execute()
			or die "Fail."; # REALLY informative error :P
		   
			# format and display query result.
			@string = ("Items in $owner\'s freezer"); # List header.
			while(@row = $sth->fetchrow_array())  # Dump the information to a buffer variable.
			{
					my $buffer = "$row[1]: $row[2] ($row[3])"; # Machines count from 0! I keep forgetting...
					@string = (@string, $buffer); # append the buffer to the array which holds temp output...
			}
			@string = (@string, "[Freezer is $lock and is at $temp K.]"); # List tail
			my $output = join ('; ', @string); # Glue the multiple lines into one big one and spew to channel (much less spammy)

			return $self->respond($message, $output); # Done.
		}
		
		else {
			return $self->respond($message, "You said something I wasn't expecting or did not understand. Please rephrase it.");
	}
}
sub freezer_add {
       
        my ($self,$message)=@_;
		my $config = $self->config();
		my $botnick = $config->freezer_bot_nick();
		my $owner = $config->freezer_owner_nick();
		
        my $item = $message->command_input(); # Takes the item they want to add.
        $item =~ s/[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]+//g; # Checking for stupid chars; Blame Lambo but thank him for the regex because mine sucked.
        my $check = lc($item); # Copy to second var for checking.

        my $nick = $message->{nick}; # For the "who added this" data
       
		@tm = localtime(); # Get the date and time. Works in whatever timezone the bot runs in.
        my ($DAY, $MONTH, $YEAR, $HOUR, $MINUTE, $SECOND) = ($tm[3], $tm[4]+1, $tm[5]+1900, $tm[2], $tm[1], $tm[0]);
		
        # Check if the freezer is locked.
       
        if ($lock eq "locked")
        {
                return $self->respond($message, "Sorry, the freezer is locked.");
        }
       
        # list number sorting
        my $runner = "SELECT listnum FROM freezer ORDER BY listnum desc limit 1";
		my $sth = $self->dbi()->dbh()->prepare( $runner );
        # A bit of a hackjob, but it works...
        $sth->execute();
        my $listnumtemp = $sth->fetchrow();
        my $listnum = ($listnumtemp)+1;
 
        #First, make sure they gave us an item to add
       
        if ($item eq "") {
                return $self->respond($message, "You have to actually give me an item to add to the freezer, dummy.");
        }
        # Test for sanity, stupidity, or both
        if ($check eq "freezer") {
                return $self->respond($message, "Sorry, but you don't have the authority to buttfuck physics like that, $nick");
        }
        # A few checks for items we've decided aren't allowed in the freezer.
        if ($check eq "tspenguin")
        {
                return $self->respond($message, "What? He's already in there...");
        }
       
        if ($check eq lc($owner))
        {
                return $self->respond($message, "... I can't do that. If he's in the freezer, who will play with my subroutines?");
        }
       
        if ($check eq lc($botnick))
        {
                return $self->respond($message, "I don't want to get in there. It's full of penguin shit.");
        }
       
        # Make sure the freezer isn't full.
       
        my $sthcheck = "SELECT * FROM freezer WHERE listnum > 8";
		my $sth = $self->dbi()->dbh()->prepare( $sthcheck );
        # Run the query
        $sth->execute();
        # Another hackjob, but it works...
        my $freezerfull = $sth->fetchrow();
       
        if ($freezerfull != NULL)
        {
                return $self->respond($message, "Sorry, the freezer is full!"); # Can't add !
        }
       
        # freezer isn't full, carry on
        else {
                my $query = 'INSERT INTO freezer(listnum, item_name, added_by, added_on, removable) values (?,?,?,?,?)';
                my $sth = $self->dbi()->dbh()->prepare($query) or die "WTF $DBI::errstr;";
       
                $sth->execute("$listnum", "$item", "$nick", "$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$SECOND", 1)
                or die "Failed to access database properly. Prod $owner until he fixes it. $DBI::errstr\n";

                # Generally see that die string when someone tries to input strings too long for the field

                return $self->respond($message, "\x01ACTION shoves $item into the freezer.\x01"); # confirm.
        }
}
 
sub freezer_rem {
        my ($self,$message)=@_;
        my $item = $message->command_input(); # Takes the item they want to remove.
        $item =~ s/\D//;
	   
        # check for freezer lock
        if ($lock eq "locked")
        {
                return $self->respond($message, "Sorry, the freezer is locked.");
        }
        # number check
        if ( $item =~ /^[\+-]*[0-9]*\.*[0-9]*$/ && $item !~ /^[\. ]*$/ ) {
 
                # check for the penguin!
       
                if ($item eq "1")
                {
                        my $range = 7;
                       
                        my $num = int(rand($range)+1);
                        return $self->respond($message, $Penguin[$num]);
                }
                # Check for Jolene
                if ($item eq "2")
                {
                        return $self->respond($message, "The Penguin reminds you that removing his fappage material is unwise.");
                }

                # If they didn't tell us to take anything out...
                # Note; this appears to be superceded by the "Use the number" clause, no idea why...
                if ($item eq "") {
                        return $self->respond($message, "Take it out? Take what out? WHAT?");
                }
               
                # Prepare the query; Just delete the row, it's easiest.
                my $sth = $self->dbi()->dbh()->prepare('SELECT * FROM freezer WHERE listnum = ?');
                my ($itemname, $itemexists);
                $sth->execute($item);
                while (@namecheck = $sth->fetchrow()) {
                        $itemname = $namecheck[2]; # Pull the item name from the DB - since we can't after it's deleted and the arg is just a number.
                        $itemexists = $namecheck[1]; # Check to see if the item they want to take out is actually IN there
                }
                # If it doesn't...
                if ($itemexists eq "") {
                        return $self->respond($message, "Sorry, I can't find that in the freezer.");
                }
                # Now we can run the actual delete.
                my $sth1 = $self->dbi()->dbh()->prepare('DELETE FROM freezer WHERE listnum = ?');
                # Run the query... lalalala
                $sth1->execute($item);
 
                # Shuffle the index to move the gap
                # This is a REAL hackjob, inspired by hard black coffee and 3am...
               
                my $gapfind = 'SELECT listnum FROM freezer WHERE listnum > ?'; # Find everything with a listnumber higher than the one we just took out
                my $sth3 = $self->dbi()->dbh()->prepare($gapfind);
                $sth3->execute($item) or die "query fail";
               
                while (@row = $sth3->fetchrow_array()){
               
                        my $oldnum = $row[0];
                        my $newnum = ($oldnum)-1; # Decrement each listnum sequentially. The less there are the less this takes... with a big freezer this could cripple.
               
                        my $gapkiller = 'UPDATE freezer SET listnum=? WHERE listnum=?';
                        my $qr1 = $self->dbi()->dbh()->prepare($gapkiller);
                        $qr1->execute($newnum, $oldnum);
                }
                # Confirm remove and finish
                return $self->respond($message, "\x01ACTION grabs $itemname and drags it out of the freezer.\x01");
        }
        # Check for the word "last" - remove the most recently added item.
       
        if(lc($item) eq "last")
        {
			#probe for the highest value
			my ($itname, $number);
			my $highval = 'SELECT * FROM freezer ORDER BY listnum desc limit 1';
			my $sth = $self->dbi()->dbh()->prepare($highval);
			$sth->execute();
		   
			while (@name = $sth->fetchrow_array())
			{
					$itname = $name[2];
					$number = $name[1];
			}
		   
			if ($number <= 3)
			{
					return $self->respond($message, "But... we might need it later!");
			}
		   
			my $deljob = 'DELETE FROM freezer WHERE listnum = ?';
			my $sth1 = $self->dbi()->dbh()->prepare($deljob);
			# Run the query... lalalala
			$sth1->execute($number);
		   
			return $self->respond($message, "\x01ACTION drags $itname out of the freezer.\x01");
        }
       
        # If it wasn't a number, they're probably trying to use the name of the item instead.
        else
        {
                return $self->respond($message, "Please use the number of the item.");
        }
}


1;