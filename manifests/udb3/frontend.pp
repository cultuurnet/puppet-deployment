class deployment::udb3::frontend (
  String                                  $config_source,
  String                                  $package_version     = 'latest',
  Optional[String]                        $env_defaults_source = undef,
  Boolean                                 $service_manage      = true,
  String                                  $service_ensure      = 'running',
  Boolean                                 $service_enable      = true,
  Variant[Boolean, Enum['true', 'false']] $noop_deploy         = false,
  Optional[String]                        $puppetdb_url        = lookup('data::puppet::puppetdb::url', Optional[String], 'first', undef)
) {

  $basedir      = '/var/www/udb3-frontend'
  $package_name = 'uitdatabank-frontend'
  $service_name = 'uitdatabank-frontend'

  $noop = any2bool($noop_deploy)

  realize Apt::Source['uitdatabank-frontend']

  package { $package_name:
    ensure  => $package_version,
    notify  => Profiles::Deployment::Versions[$title],
    require => Apt::Source['uitdatabank-frontend'],
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
    puppetdb_url => $puppetdb_url
  }
}
