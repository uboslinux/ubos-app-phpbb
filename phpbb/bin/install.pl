#!/usr/bin/perl
#
# Run the phpBB installer
#
# Copyright (C) 2017 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use File::Temp;
use UBOS::Logging;
use UBOS::Utils;

my $ret = 1;

my $appConfigDir = $config->getResolveOrNull( 'appconfig.apache2.dir' );

if( 'install' eq $operation ) {
    
    # We need the installer, and config.php must be writable
    UBOS::Utils::myexec( "cp -a /usr/share/phpbb/phpbb/install $appConfigDir/install" );
    UBOS::Utils::myexec( "chown http:http $appConfigDir/config.php" );

    my $adminName    = $config->getResolveOrNull( 'site.admin.userid' );
    my $adminPass    = $config->getResolveOrNull( 'site.admin.credential' );
    my $adminEmail   = $config->getResolveOrNull( 'site.admin.email' );

    my $title   = $config->getResolveOrNull( 'installable.customizationpoints.title.value' );
    my $tagline = $config->getResolveOrNull( 'installable.customizationpoints.tagline.value' );

    my $dbName  = $config->getResolveOrNull( 'appconfig.mysql.dbname.maindb' );
    my $dbHost  = $config->getResolveOrNull( 'appconfig.mysql.dbhost.maindb' );
    my $dbPort  = $config->getResolveOrNull( 'appconfig.mysql.dbport.maindb' );
    my $dbUser  = $config->getResolveOrNull( 'appconfig.mysql.dbuser.maindb' );
    my $dbCred  = $config->getResolveOrNull( 'appconfig.mysql.dbusercredential.maindb' );

    my $hostname       = $config->getResolveOrNull( 'site.hostname' );
    my $protocol       = $config->getResolveOrNull( 'site.protocol' );
    my $protocolport   = $config->getResolveOrNull( 'site.protocolport' );
    my $contextOrSlash = $config->getResolveOrNull( 'appconfig.contextorslash' );
    my $cookieSecure   = 'https' eq $protocol? 'true' : 'false';

    my $yamlFh = File::Temp->new();
    my $yaml = <<YAML;
installer:
    admin:
        name: $adminName
        password: $adminPass
        email: $adminEmail

    board:
        lang: en
        name: $title
        description: $tagline

    database:
        dbms: mysqli
        dbuser: $dbUser
        dbpasswd: $dbCred
        dbname: $dbName
        dbhost: $dbHost
        dbport: $dbPort
        table_prefix: phpbb_

    server:
        cookie_secure: $cookieSecure
        server_protocol: $protocol://
        force_server_vars: false
        server_name: $hostname
        server_port: $protocolport
        script_path: $contextOrSlash
YAML

    UBOS::Utils::saveFile( $yamlFh, $yaml );

    my $out;
    my $cmd = "cd $appConfigDir; sudo -u http php install/phpbbcli.php --no-ansi -n install " . $yamlFh->filename;
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        error( 'phpBB installation failed:', $out, "\ncmd was:", $cmd, "\nconfig file was:", $yaml );
        $ret = 0;
    }

    # get rid of installer, and protected config file
    UBOS::Utils::myexec( "chown root:http $appConfigDir/config.php" );
    UBOS::Utils::myexec( "chmod 640 $appConfigDir/config.php" );
    UBOS::Utils::deleteRecursively( "$appConfigDir/install" );
}

$ret;
