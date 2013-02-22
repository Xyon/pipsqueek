package PipSqueek::Plugin::Toys;
use base qw(PipSqueek::Plugin);

# Toys plugin. Adds a whole host of crap not really worth a whole plugin of their own.

# There are no more comments in this file. I was going to add some, but I decided to make some more coffee and do something vaguely productive instead.
# It's not tremendously complicated code, and most of it should be self-explanatory. If it isn't, go read a Perl book or something.

# If I have to learn this fucking language so do you.

sub plugin_initialize {
	my $self = shift;

	$self->plugin_handlers({
		'multi_TSPenguin'	=>	'toy_penguin',
		'multi_woo'			=>	'toy_failspawn1',
		'multi_Woo'			=>	'toy_failspawn1',
		'multi_woo482'		=>	'toy_failspawn2',
		'multi_Woo482'		=>	'toy_failspawn2',
		'multi_huggle'		=>	'toy_huggle',
		'multi_xyon'		=>	'toy_xyon',
		'multi_Xyon'		=>	'toy_xyon',
		'multi_qdb'			=>	'link_qdb',
		'multi_probe'		=>	'toy_probe',
		'multi_volume'		=>	'toy_volume',
		'multi_caffeinate'	=>  'toy_coffee',
		'multi_cigarette'	=>	'toy_cigs',
		'multi_drink'		=>	'toy_drinks',
		'multi_timetravel'	=>	'toy_tardis',
		'multi_sleep'		=>	'toy_sleep',
		'multi_sandwich'	=>	'toy_butty',
		'multi_sudo'		=>	'toy_sudo',
		'multi_cat'			=>	'toy_cat',
		'multi_man'			=>	'toy_man',
		'multi_fsck'		=>	'toy_fsck',
		'multi_mount'		=>	'toy_mount',
		'multi_overflow'	=>	'toy_overflow',
		'multi_d20'			=>	'toy_d20',
		'multi_nocigar'		=>	'toy_cigar',
		'multi_sparta'		=>	'toy_sparta',
		'multi_painkillers'	=>	'toy_painmeds',
	});
	
}

sub toy_penguin {
	my ($self, $message) = @_;
	return $self->respond($message, 'TSPenguin is probably fapping.');
}

sub toy_failspawn1 {
	my ($self, $message) = @_;
	return $self->respond($message, 'FAILSPAWN IS AMONG US!');
}

sub toy_failspawn2 {
	my ($self, $message) = @_;
	my $failrange = 100000;
	my $failamount = int(rand($failrange));
	
	return $self->respond($message, "DANGER: FAIL READINGS EXCEED TOLERANCE BY $failamount%. ABANDON HOPE");
}


sub toy_huggle {
	my ($self, $message) = @_;
	my $target = $message->command_input();
	my $nick = $message->{nick};

	if ($target eq "")	{
		return $self->respond($message,"\x01ACTION huggles $nick\x01");
	}
	else	{
		return $self->respond($message,"\x01ACTION huggles $target\x01");
	}
}

sub toy_xyon {
	my ($self, $message) = @_;
	
	return $self->respond($message,"Xyon is a bastard.");
}


sub toy_probe {
	my ($self, $message) = @_;
	
	return $self->respond($message, "HAIL PROBE");
}

sub toy_volume {
	my ($self, $message) = @_;
	
	return $self->respond($message, "The volume is and should always be 2^(Woo482->FailCount). If it is not, crank it up or GTFO");
}

sub link_qdb {
	my ($self, $message) = @_;
	
	return $self->respond($message, "http://whatu.shell.tor.hu/wh/qdb/");
}

sub toy_coffee {
	my ($self, $message) = @_;
	my $target = $message->command_input();
	my $nick = $message->{nick};
	
	if ($target eq "") {
		return $self->respond($message,"\x01ACTION gives coffee to $nick.\x01");
	}
	else {
		return $self->respond($message,"\x01ACTION gives coffee to $target.\x01");	
	}
}

sub toy_cigs {
	my ($self, $message) = @_;
	my $target = $message->command_input();
	my $nick = $message->{nick};
	
	if ($target eq "") {
		return $self->respond($message,"\x01ACTION gives $nick a cigarette.\x01");
	}
	else {
		return $self->respond($message,"\x01ACTION gives $target a cigarette.\x01");
	}
}

sub link_schedule {
	my ($self, $message) = @_;
	
	return $self->respond($message,"http://www.orbiterradio.com/calendar.php?c=2&do=displaymonth");
}

sub toy_drinks {
	my ($self, $message) = @_;
	my @input = split(/\s+/, $message->command_input());
	
	my $drink = $input[0];
	my $target = $input[1];
	my $nick = $message->{nick};
	
	if ($drink eq "") {
	return $self->respond($message, "A drink of what?");
	}
	if ($drink eq "cum" || $drink eq "jizz" || $drink eq "piss") {
	return $self->respond($message, "EWWW NO");
	}
	else {
		if ($target eq "")
		{
			return $self->respond($message, "\x01ACTION gives $nick a drink of $drink.\x01");
		}
		else {
			return $self->respond($message, "\x01ACTION gives a drink of $drink to $target.\x01");
		}
	}
}
sub toy_tardis {
	my ($self, $message) = @_;
	
	return $self->respond($message,"TARDIS error: Time Lord not found.");
}

sub toy_sleep {
	my ($self, $message) = @_;
	
	return $self->respond ($message, "Error: Unknown function: \"sleep\";");
}

sub toy_butty {
	my ($self, $message) = @_;
	
	return $self->respond($message, "What? Make it yourself!");
}

sub toy_sudo {
	my ($self, $message) = @_;
	my @command = split(/\s+/, $message->command_input());
	my $nick = $message->{nick};
	
	if ( lc($command[0]) eq "sandwich")
	{
		$self->respond($message, "Okay.");
		return $self->respond($message, "\x01ACTION makes $nick a sandwich\x01");
	}
	
	if ( lc($command[0]) eq "rm" && lc($command[1]) eq "-rf" && lc($command[2]) eq "/")
	{
		return $self->respond($message, "Heh. Nice try.");
	}
	
	if (lc($command[0]) eq "mount")
	{
		if (lc($command[1]) eq "-t" && lc($command[2]) eq "unf" && lc($command[3]) eq "/dev/sex")
			{
				my $mount = $command[4];
				
				return $self->respond($message, "\x01ACTION mounts $mount and begins fsck operations\x01");
			}
		else
		{
			return $self->respond($message, "bash: sudo: mount: invalid argument");
		}
	}
	
	if (lc($command[0]) eq "umount")
	{
		return $self->respond($message, "I'm not done yet!");
	}
	
	if (lc($command[0]) eq "chown")
	{
		if (lc($command[3]) eq "/yourbase") {
		$self->respond($message, "$zwing[$counter]");
			if ($counter < 5) 
			{
				$counter = $counter + 1;
			}
			else 
			{
				$counter = 0;
			}
		return;
		}
		else 
		{	
			return $self->respond($message, "Not your base.");
		}
	}

	else {
	
		return $self->respond($message, "bash: sudo: command not found");
	}
}

sub toy_cat {
	my ($self, $message) = @_;
	
	return $self->respond($message, "You are a kitty!");
}

sub toy_man {
	my ($self, $message) = @_;
	my @command = split(/\s+/, $message->command_input());
	
	if (lc($command[0]) eq "8")
	{
		if (lc($command[1]) eq "woman")
		{
			return $self->respond($message, "Insert tab A into slot B. Wiggle furiously until transfer is complete. Withdraw tab A and light cigarette C.");
		}
		return $self->respond($message, "8.");
	}
	
	if (lc($command[0]) eq "woman")
	{
		return $self->respond($message, "Segmentation fault; Core dumped.");
	}
	
	if (lc($command[0]) eq "cat")
	{
		return $self->respond ($message, "You are now riding a half man half cat");
	}
	
	if (lc($command[0]) eq "xyon")
	{
		return $self->respond($message, "Undefined.");
	}
}

sub toy_fsck {
	my ($self, $message) = @_;
	
	return $self->respond($message, "You couldn't afford me, babe.");
}

sub toy_mount {
	my ($self, $message) = @_;
	
	return $self->respond($message, "Only root can do that.");
}

sub toy_overflow {
	my ($self, $message) = @_;
	
	my $address = join "", map { unpack "H*", chr(rand(256)) } 1..16;;
	return $self->respond($message, "Access violation at 0x$address. The memory could not be \"read\".");
}

sub toy_d20 {
	my ($self, $message) = @_;
	
	return $self->respond($message, "geordi {srand(time(NULL));cout<<rand()%20+1;}");
}

sub toy_cigar {
	my ($self, $message) = @_;
	my $nick = $message->command_input();
	
	if ($nick eq '')
	{
		$nick = $message->{nick};
	}
	
		return $self->respond($message, "\x01ACTION wafts a cigar in front of $nick\'s face. \"Close, but not close enough for one of these...\"\x01");
}

sub toy_sparta {
	my ($self, $message) =@_;
	
	return $self->respond($message, "THIS IS NOT SPARTA");
	
}

sub toy_painmeds {
	my ($self, $message) =@_;

	my $patient = $message->{nick};
	
	return $self->respond($message, "\x01ACTION injects $patient with morphine.\x01");
}

1;
