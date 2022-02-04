class deployment::widgetbeheer::angular (
  $config_source,
  $htaccess_source,
  $package_version      = 'latest',
  $noop_deploy          = false,
  $puppetdb_url         = undef
) {

  contain deployment

  package { 'widgetbeheer-angular-app':
    ensure => $package_version,
    noop   => $noop_deploy
  }

  package { 'rubygem-nokogiri':
    ensure => 'installed'
  }

  file { 'widgetbeheer-angular-app-env':
    ensure => 'file',
    path   => '/var/www/widgetbeheer/.env',
    source => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[widgetbeheer-angular-app]',
    noop    => $noop_deploy
  }

  file { 'widgetbeheer-angular-app-config':
    ensure => 'absent',
    path   => '/var/www/widgetbeheer/config.json',
  }

  file { 'widgetbeheer-angular-htaccess':
    ensure => 'file',
    path   => '/var/www/widgetbeheer/.htaccess',
    source => $htaccess_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[widgetbeheer-angular-app]',
    noop    => $noop_deploy
  }

  file { 'widgetbeheer-angular-app-deploy-config':
    ensure => 'absent',
    path   => '/usr/local/bin/widgetbeheer-angular-deploy-config',
  }

  file { 'add_text_css_type':
    ensure => 'file',
    source => 'puppet:///modules/deployment/widgetbeheer/add_text_css_type',
    path   => '/usr/local/bin/add_text_css_type',
    mode   => '0755'
  }

  exec { 'add_text_css_type':
    command     => 'add_text_css_type /var/www/widgetbeheer/index.html',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    require     => [ File['add_text_css_type'], Package['rubygem-nokogiri'], Class['deployment']],
    subscribe   => Package['widgetbeheer-angular-app'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => 'widgetbeheer',
    packages     => 'widgetbeheer-angular-app',
    puppetdb_url => $puppetdb_url
  }
}
