#!/usr/bin/perl
#
# Database migration
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $ret = 1;

my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );

if( 'upgrade' eq $operation ) {

    my $cmd = "cd $appConfigDir; sudo -u http php bin/phpbbcli.php db:migrate --safe-mode";

    my $out;
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        error( 'phpBB db:migrate failed:', $out, "\ncmd was:", $cmd );
        $ret = 0;
    }
}

$ret;
