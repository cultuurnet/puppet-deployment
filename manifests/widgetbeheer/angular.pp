class deployment::widgetbeheer::angular (
  $config_source,
  $htaccess_source,
  $version          = 'latest',
  $noop_deploy      = false,
  $puppetdb_url     = undef
) {

  $basedir = '/var/www/widgetbeheer-frontend'

  contain deployment

  realize Apt::Source['widgetbeheer-frontend']

  package { 'widgetbeheer-frontend':
    ensure  => $version,
    noop    => $noop_deploy,
    notify  => Profiles::Deployment::Versions[$title],
    require => Apt::Source['widgetbeheer-frontend']
  }

  package { 'rubygem-nokogiri':
    ensure => 'installed'
  }

  file { 'widgetbeheer-angular-app-config':
    ensure  => 'file',
    path    => "${basedir}/assets/config.json",
    source  => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[widgetbeheer-frontend]',
    noop    => $noop_deploy
  }

  file { 'widgetbeheer-angular-htaccess':
    ensure  => 'file',
    path    => "${basedir}/.htaccess",
    source  => $htaccess_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[widgetbeheer-frontend]',
    noop    => $noop_deploy
  }

  file { 'add_text_css_type':
    ensure => 'file',
    source => 'puppet:///modules/deployment/widgetbeheer/add_text_css_type',
    path   => '/usr/local/bin/add_text_css_type',
    mode   => '0755'
  }

  exec { 'add_text_css_type':
    command     => "add_text_css_type ${basedir}/index.html",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    require     => [ File['add_text_css_type'], Package['rubygem-nokogiri'], Class['deployment']],
    subscribe   => Package['widgetbeheer-frontend'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    puppetdb_url => $puppetdb_url
  }
}
