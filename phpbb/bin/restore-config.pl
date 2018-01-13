#!/usr/bin/perl
#
# Upon updates, the installer cannot run, but we still need config.php,
# so we regenerate. We also need to activate all extensions that have been
# deployed to this AppConfiguration.
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $ret = 1;

my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );

if( 'upgrade' eq $operation ) {
    
    my $dbName  = $config->getResolveOrNull( 'appconfig.mysql.dbname.maindb' );
    my $dbHost  = $config->getResolveOrNull( 'appconfig.mysql.dbhost.maindb' );
    my $dbPort  = $config->getResolveOrNull( 'appconfig.mysql.dbport.maindb' );
    my $dbUser  = $config->getResolveOrNull( 'appconfig.mysql.dbuser.maindb' );
    my $dbCred  = $config->getResolveOrNull( 'appconfig.mysql.dbusercredential.maindb' );

    my $config = <<CONFIG;
<?php
// UBOS generated. Do not edit
\$dbms = 'phpbb\\db\\driver\\mysqli';
\$dbhost = '$dbHost';
\$dbport = '$dbPort';
\$dbname = '$dbName';
\$dbuser = '$dbUser';
\$dbpasswd = '$dbCred';
\$table_prefix = 'phpbb_';
\$phpbb_adm_relative_path = 'adm/';
\$acm_type = 'phpbb\\cache\\driver\\file';

\@define('PHPBB_INSTALLED', true);
// \@define('PHPBB_DISPLAY_LOAD_TIME', true);
\@define('PHPBB_ENVIRONMENT', 'production');
// \@define('DEBUG_CONTAINER', true);
CONFIG

    UBOS::Utils::saveFile( "$appConfigDir/config.php", $config, 0640, 'root', 'http' );

    my $out;
    my $cmd = "cd $appConfigDir; sudo -u http php bin/phpbbcli.php --no-ansi -n extension:show";
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        error( 'phpBB extension:show failed:', $out, "\ncmd was:", $cmd );
        $ret = 0;
    }
    if( $ret ) {
        my $available = undef;
        foreach my $line ( split /\n/, $out ) {
            $line =~ s!^\s+!!;
            $line =~ s!\s+$!!;

            if( !$line || $line =~ m!^----! ) {
                next;
            }
            if( $available ) {
                $line =~ s!\*\s*!!;
                push @$available, $line,
            } else {
                if( $line =~ m!Available! ) {
                    $available = [];
                }
            }
        }

        foreach my $ext ( @$available ) {
            $cmd = "cd $appConfigDir; sudo -u http php bin/phpbbcli.php --no-ansi -n extension:enable $ext";
            if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
                error( 'phpBB extension:enable', $ext, 'failed:', $out, "\ncmd was:", $cmd );
                $ret = 0;
            }
        }
    }
}

$ret;
