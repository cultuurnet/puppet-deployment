class deployment::widgetbeheer::angular (
  $config_source,
  $htaccess_source,
  $deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  contain deployment

  package { 'widgetbeheer-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'rubygem-nokogiri':
    ensure => 'installed'
  }

  file { 'widgetbeheer-angular-app-config':
    ensure => 'file',
    path   => '/var/www/widgetbeheer/config.json',
    source => $config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[widgetbeheer-angular-app]',
    noop    => $noop_deploy
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
    ensure => 'file',
    path   => '/usr/local/bin/widgetbeheer-angular-deploy-config',
    source => $deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'widgetbeheer-angular-deploy-config':
    command     => 'widgetbeheer-angular-deploy-config /var/www/widgetbeheer',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    subscribe   => [ 'Package[widgetbeheer-angular-app]', 'File[widgetbeheer-angular-app-config]', 'File[widgetbeheer-angular-app-deploy-config]'],
    refreshonly => true,
    require     => Class['deployment'],
    noop        => $noop_deploy
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

  deployment::versions { $title:
    project      => 'widgetbeheer',
    packages     => 'widgetbeheer-angular-app',
    noop_deploy  => $noop_deploy,
    puppetdb_url => $puppetdb_url
  }
}
