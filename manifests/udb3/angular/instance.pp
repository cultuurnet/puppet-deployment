define deployment::udb3::angular::instance (
  $config_source,
  $app_package_name,
  $lib_package_name,
  $app_rootdir,
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  realize Apt::Source['cultuurnet-udb3']

  package { $app_package_name:
    ensure  => 'latest',
    notify  => Profiles::Deployment::Versions[$title],
    require => Apt::Source['cultuurnet-udb3'],
    noop    => $noop_deploy
  }

  package { $lib_package_name:
    ensure  => 'latest',
    require => Apt::Source['cultuurnet-udb3'],
    noop    => $noop_deploy
  }

  file { "${title}-angular-app-config":
    ensure  => 'file',
    path    => "${app_rootdir}/config.json",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package[$app_package_name],
    noop    => $noop_deploy
  }

  exec { "${title}-angular-deploy-config":
    command     => "angular-deploy-config ${app_rootdir}",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ Package[$app_package_name], File["${title}-angular-app-config"]],
    refreshonly => true,
    require     => Class['deployment'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }
}
