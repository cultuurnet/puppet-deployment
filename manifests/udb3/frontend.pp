class deployment::udb3::frontend (
  String                                  $config_source,
  String                                  $package_version     = 'latest',
  Optional[String]                        $env_defaults_source = undef,
  Boolean                                 $service_manage      = true,
  String                                  $service_ensure      = 'running',
  Boolean                                 $service_enable      = true,
  String                                  $project_prefix      = 'udb3',
  Variant[Boolean, Enum['true', 'false']] $noop_deploy         = false,
  Optional[String]                        $puppetdb_url        = undef
) {

  $basedir      = '/var/www/udb-frontend'
  $package_name = 'udb3-frontend'
  $service_name = 'udb3-frontend'

  $noop = any2bool($noop_deploy)

  realize Apt::Source['cultuurnet-udb3']

  package { $package_name:
    ensure  => $package_version,
    require => Apt::Source['cultuurnet-udb3'],
    noop    => $noop
  }

  file { "${package_name}-config":
    ensure  => 'file',
    path    => "${basedir}/.env",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => Package[$package_name],
    noop    => $noop
  }

  if $service_manage {
    if $env_defaults_source {
      file { "${service_name}-env-defaults":
        ensure => 'file',
        path   => "/etc/default/${service_name}",
        owner  => 'root',
        group  => 'root',
        source => $env_defaults_source,
        notify => Service[$service_name]
      }
    }

    service { $service_name:
      ensure    => $service_ensure,
      enable    => $service_enable,
      subscribe => [ Package[$package_name], File["${package_name}-config"]],
      hasstatus => true
    }
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => $package_name,
    puppetdb_url => $puppetdb_url
  }
}
