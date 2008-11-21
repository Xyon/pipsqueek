package PipSqueek::Plugin::Woot;
use base qw(PipSqueek::Plugin);
require LWP::UserAgent;


 sub plugin_initialize
 {
   my $self = shift;
   $self->plugin_handlers({
                  'multi_woot'      => 'woot_checker',
                  'multi_shirt'      => 'shirt_checker',
                  'multi_wine'      => 'wine_checker',

});

 }
sub woot_checker {
   my ($self,$message) = @_;
   my $uaw = LWP::UserAgent->new;
        $uaw->timeout(15);

   $uaw->proxy(['http','ftp'], $self->config()->plugin_proxy()) if ($self->config()->plugin_proxy());
   my $woot = $uaw->get('http://www.woot-tracker.net/pips/index.php');

        if ($woot->is_success) {
                return $self->respond( $message,($woot->content) );

        } else {
                        return $self->respond( $message,("An error has occurred.") );
        }
}

sub wine_checker {
   my ($self,$message) = @_;
   my $uaw = LWP::UserAgent->new;
        $uaw->timeout(15);

   $uaw->proxy(['http','ftp'], $self->config()->plugin_proxy()) if ($self->config()->plugin_proxy());
   my $woot = $uaw->get('http://www.woot-tracker.net/pips/wine.php');

        if ($woot->is_success) {
                return $self->respond( $message,($woot->content) );

        } else {
                        return $self->respond( $message,("An error has occurred.") );
        }
}

sub shirt_checker {
   my ($self,$message) = @_;
   my $uaw = LWP::UserAgent->new;
        $uaw->timeout(15);

   $uaw->proxy(['http','ftp'], $self->config()->plugin_proxy()) if ($self->config()->plugin_proxy());
   my $woot = $uaw->get('http://www.woot-tracker.net/pips/shirt.php');

        if ($woot->is_success) {
                return $self->respond( $message,($woot->content) );

        } else {
                        return $self->respond( $message,("An error has occurred.") );
        }
}


1;

__END__
