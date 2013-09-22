# == Class: oradb::installdb
#
# The databaseType value should contain only one of these choices.
#   EE     : Enterprise Edition
#   SE     : Standard Edition
#   SEONE  : Standard Edition One
# 
# The procedure will take the files from puppetDownloadMntPoint,
# symlink it to downloadDir and extract it in dowloadDir.
# Extracted versions won't be removed afterwards.
#
# Sample usage:
#
#    oradb::installdb{ '112030_Linux-x86-64':
#      version                => '11.2.0.3',
#      file                   => 'p10404530_112030_Linux-x86-64',
#      databaseType           => 'EE',
#      oracleBase             => '/appl/oracle',
#      oracleHome             => '/appl/oracle/product/11.2/db',
#      createUser             => true,
#      user                   => 'oracle',
#      group                  => 'dba',
#      downloadDir            => '/install',
#      zipExtract             => true,
#      puppetDownloadMntPoint => '/vagrant/files',
#    }
#
#    oradb::installdb{ '112010_Linux-x86-64':
#      version      => '11.2.0.1',
#      file         => 'linux.x64_11gR2_database',
#      databaseType => 'SE',
#      oracleBase   => '/oracle',
#      oracleHome   => '/oracle/product/11.2/db',
#      createUser   => 'true',
#      user         => 'oracle',
#      group        => 'dba',
#      downloadDir  => '/install',
#      zipExtract   => true,
#    }
#

define oradb::installdb( $version                 = undef,
                         $file                    = undef,
                         $databaseType            = 'SE',
                         $oracleBase              = undef,
                         $oracleHome              = undef,
                         $createUser              = true,
                         $user                    = 'oracle',
                         $group                   = 'dba',
                         $downloadDir             = '/install',
                         $zipExtract              = true,
                         $puppetDownloadMntPoint  = undef,
)

{
  # check if the oracle software already exists
  $found = oracle_exists( $oracleHome )

  if $found == undef {
    $continue = true
  } else {
    if ( $found ) {
      notify {"oradb::installdb ${oracleHome} already exists":}
      $continue = false
    } else {
      notify {"oradb::installdb ${oracleHome} does not exists":}
      $continue = true
    }
  }

  if ( $continue ) {
    case $operatingsystem {
      CentOS, RedHat, OracleLinux, Ubuntu, Debian, SLES: {
        $execPath     = "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:"
        $oraInstPath  = "/etc"
        $oraInventory = "${oracleBase}/oraInventory"
        Exec { path   => $execPath,
          user        => $user,
          group       => $group,
          logoutput   => true,
        }
        File {
          ensure      => present,
          mode        => '0775',
          owner       => $user,
          group       => $group,
        }
      }
      default: {
        fail("Unrecognized operating system")
      }
    }

    if $puppetDownloadMntPoint == undef {
      $mountPoint     = "puppet:///modules/oradb/"
    } else {
      $mountPoint     = $puppetDownloadMntPoint
    }

    if ( $createUser ) {
      # Whether Puppet will manage the group or relying on external methods
      if ! defined(Group[$group]) {
        group { $group :
          ensure      => present,
        }
      }
    }

    if ( $createUser ) {
      # Whether Puppet will manage the user or relying on external methods
      if ! defined(User[$user]) {
        # http://raftaman.net/?p=1311 for generating password
        user { $user :
          ensure      => present,
          groups      => $group,
          shell       => '/bin/bash',
          password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
          home        => "/home/${user}",
          comment     => "This user ${user} was created by Puppet",
          require     => Group[$group],
          managehome  => true,
        }
      }
    }
    
    if ! defined(File[$downloadDir]) {
      # check oracle install folder
      file { $downloadDir :
        ensure        => directory,
        recurse       => false,
        replace       => false,
      }
    }

    $path = $downloadDir
    
    if ( $zipExtract ) {

      # zip files are linked to install dir and then extracted. this can be 
      # skipped too, if resource is not needed

      if $version == '12.1.0.1' {

        file { "${path}/${file}_1of2.zip": ensure => link, target => "${mountPoint}/${file}_1of2.zip", require => File[$downloadDir]  }
        file { "${path}/${file}_2of2.zip": ensure => link, target => "${mountPoint}/${file}_2of2.zip", require => File["${path}/${file}_1of2.zip"] }

        exec { "extract ${path}/${file}_1of2.zip": command => "unzip -o ${path}/${file}_1of2.zip -d ${path}/${file}", require => File["${path}/${file}_1of7.zip"], }
        exec { "extract ${path}/${file}_1of2.zip": command => "unzip -o ${path}/${file}_1of2.zip -d ${path}/${file}", require => File["${path}/${file}_1of7.zip"], }
      }

      if $version == '11.2.0.1' {
        
        file { "${path}/${file}_1of2.zip": ensure => link, target => "${mountPoint}/${file}_1of2.zip", require => File[$downloadDir]  }
        file { "${path}/${file}_2of2.zip": ensure => link, target => "${mountPoint}/${file}_2of2.zip", require => File["${path}/${file}_1of2.zip"] }

        exec { "extract ${path}/${file}_1of2.zip": command => "unzip -o ${path}/${file}_1of2.zip -d ${path}/${file}", require => File["${path}/${file}_1of7.zip"], }
        exec { "extract ${path}/${file}_1of2.zip": command => "unzip -o ${path}/${file}_1of2.zip -d ${path}/${file}", require => File["${path}/${file}_1of7.zip"], }
      }

      if ( $version == '11.2.0.3' or $version == '11.2.0.4' ) {

        file { "${path}/${file}_1of7.zip": ensure => link, target => "${mountPoint}/${file}_1of7.zip", require => File[$downloadDir]  }
        file { "${path}/${file}_2of7.zip": ensure => link, target => "${mountPoint}/${file}_2of7.zip", require => File["${path}/${file}_1of7.zip"] }
        file { "${path}/${file}_3of7.zip": ensure => link, target => "${mountPoint}/${file}_3of7.zip", require => File["${path}/${file}_2of7.zip"] }
        file { "${path}/${file}_4of7.zip": ensure => link, target => "${mountPoint}/${file}_4of7.zip", require => File["${path}/${file}_3of7.zip"] }
        file { "${path}/${file}_5of7.zip": ensure => link, target => "${mountPoint}/${file}_5of7.zip", require => File["${path}/${file}_4of7.zip"] }
        file { "${path}/${file}_6of7.zip": ensure => link, target => "${mountPoint}/${file}_6of7.zip", require => File["${path}/${file}_5of7.zip"] }
        file { "${path}/${file}_7of7.zip": ensure => link, target => "${mountPoint}/${file}_7of7.zip", require => File["${path}/${file}_6of7.zip"] }

        exec { "extract ${path}/${file}_1of7.zip": command => "unzip -o ${path}/${file}_1of7.zip -d ${path}/${file}", require => File["${path}/${file}_1of7.zip"], }
        exec { "extract ${path}/${file}_2of7.zip": command => "unzip -o ${path}/${file}_2of7.zip -d ${path}/${file}", require => File["${path}/${file}_2of7.zip"], }
        exec { "extract ${path}/${file}_3of7.zip": command => "unzip -o ${path}/${file}_3of7.zip -d ${path}/${file}", require => File["${path}/${file}_3of7.zip"], }
        exec { "extract ${path}/${file}_4of7.zip": command => "unzip -o ${path}/${file}_4of7.zip -d ${path}/${file}", require => File["${path}/${file}_4of7.zip"], }
        exec { "extract ${path}/${file}_5of7.zip": command => "unzip -o ${path}/${file}_5of7.zip -d ${path}/${file}", require => File["${path}/${file}_5of7.zip"], }
        exec { "extract ${path}/${file}_6of7.zip": command => "unzip -o ${path}/${file}_6of7.zip -d ${path}/${file}", require => File["${path}/${file}_6of7.zip"], }
        exec { "extract ${path}/${file}_7of7.zip": command => "unzip -o ${path}/${file}_7of7.zip -d ${path}/${file}", require => File["${path}/${file}_7of7.zip"], }
      }
    }

    if ! defined(File["${oraInstPath}/oraInst.loc"]) {
      file { "${oraInstPath}/oraInst.loc":
        ensure        => present,
        content       => template("oradb/oraInst.loc.erb"),
      }
    }

    if ! defined(File[$oracleBase]) {
      # check oracle base folder
      file { $oracleBase :
        ensure        => directory,
        recurse       => false,
        replace       => false,
      }
    }

    if ! defined(File["${path}/db_install_${version}.rsp"]) {
      file { "${path}/db_install_${version}.rsp":
        ensure        => present,
        content       => template("oradb/db_install_${version}.rsp.erb"),
        require       => File["${oraInstPath}/oraInst.loc"],
      }
    }

    # le installation...

    if $version == '12.1.0.1' {
      if ( $zipExtract ) {
        # In $downloadDir, will Puppet extract the ZIP files or is this a pre-extracted directory structure.
        exec { "install oracle database ${title}":
          command     => "/bin/sh -c 'unset DISPLAY;${path}/${file}/database/runInstaller -silent -waitforcompletion -responseFile ${path}/db_install_${version}.rsp'",
          require     => [File ["${oraInstPath}/oraInst.loc"],File["${path}/db_install_${version}.rsp"],Exec["extract ${path}/${file}_2of2.zip"]],
          timeout     => 1800,
          creates     => $oracleHome,
        }
      } else {
        exec { "install oracle database ${title}":
          command     => "/bin/sh -c 'unset DISPLAY;${path}/${file}/database/runInstaller -silent -waitforcompletion -responseFile ${path}/db_install_${version}.rsp'",
          require     => [File ["${oraInstPath}/oraInst.loc"],File["${path}/db_install_${version}.rsp"]],
          timeout     => 1800,
          creates     => $oracleHome,
        }
      }
    }

    if ( $version == '11.2.0.3' or $version == '11.2.0.4' ) {
      if ( $zipExtract ) {
        # In $downloadDir, will Puppet extract the ZIP files or is this a pre-extracted directory structure.
        exec { "install oracle database ${title}":
          command     => "/bin/sh -c 'unset DISPLAY;${path}/${file}/database/runInstaller -silent -waitforcompletion -responseFile ${path}/db_install_${version}.rsp; true'",
          require     => [File ["${oraInstPath}/oraInst.loc"],File["${path}/db_install_${version}.rsp"],Exec["extract ${path}/${file}_7of7.zip"]],
          timeout     => 1800,
          creates     => $oracleHome,
        }
      } else {
        exec { "install oracle database ${title}":
          command     => "/bin/sh -c 'unset DISPLAY;${path}/${file}/database/runInstaller -silent -waitforcompletion -responseFile ${path}/db_install_${version}.rsp; true'",
          require     => [File ["${oraInstPath}/oraInst.loc"],File["${path}/db_install_${version}.rsp"]],
          timeout     => 1800,
          creates     => $oracleHome,
        }
      }
    }

    if $version == '11.2.0.1' {
      if ( $zipExtract ) {
        # In $downloadDir, will Puppet extract the ZIP files or is this a pre-extracted directory structure.
        exec { "install oracle database ${title}":
          command     => "/bin/sh -c 'unset DISPLAY;${path}/${file}/database/runInstaller -silent -waitforcompletion -responseFile ${path}/db_install_${version}.rsp'",
          require     => [File ["${oraInstPath}/oraInst.loc"],File["${path}/db_install_${version}.rsp"],Exec["extract ${path}/${file}_2of2.zip"]],
          timeout     => 1800,
          creates     => $oracleHome,
        }
      } else {
        exec { "install oracle database ${title}":
          command     => "/bin/sh -c 'unset DISPLAY;${path}/${file}/database/runInstaller -silent -waitforcompletion -responseFile ${path}/db_install_${version}.rsp'",
          require     => [File ["${oraInstPath}/oraInst.loc"],File["${path}/db_install_${version}.rsp"]],
          timeout     => 1800,
          creates     => $oracleHome,
        }
      }
    }

    # le profile...

    if ! defined(File["/home/${user}/.bash_profile"]) {
      file { "/home/${user}/.bash_profile":
        ensure        => present,
        content       => template("oradb/bash_profile.erb"),
      }
    }

    # le root action...

    exec { "run root.sh script ${title}":
      command         => "${oracleHome}/root.sh",
      user            => 'root',
      group           => 'root',
      require         => Exec["install oracle database ${title}"],
    }
  }
}
