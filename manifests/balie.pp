class deployment::balie (
  $silex_config_source,
  $angular_app_config_source,
  $swagger_ui_config_source,
  $swagger_ui_deploy_config_source,
  $silex_package_version = 'latest',
  $angular_package_version = 'latest',
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $project_prefix = 'balie',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  apt::source { 'cultuurnet-balie':
    location => "http://apt.uitdatabank.be/balie-${environment}",
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
    include  => {
      'deb' => true,
      'src' => false
    },
    noop     => $noop_deploy
  }

  profiles::apt::update { 'cultuurnet-balie':
    require  => Apt::Source['cultuurnet-balie'],
    noop     => $noop_deploy
  }

  package { 'balie-silex':
    ensure  => $silex_package_version,
    notify  => 'Class[Apache::Service]',
    require => Profiles::Apt::Update['cultuurnet-balie'],
    noop    => $noop_deploy
  }

  package { 'balie-angular-app':
    ensure  => $angular_package_version,
    require => [ 'Package[balie-silex]', Profiles::Apt::Update['cultuurnet-balie'] ],
    noop    => $noop_deploy
  }

  package { 'balie-swagger-ui':
    ensure  => 'latest',
    require => [ 'Package[balie-silex]', Profiles::Apt::Update['cultuurnet-balie'] ],
    noop    => $noop_deploy
  }

  file { 'balie-silex-log':
    path    => '/var/www/balie/log',
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => 'Package[balie-silex]',
    noop    => $noop_deploy
  }

  file { 'balie-silex-config':
    ensure  => 'file',
    path    => '/var/www/balie/config.yml',
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[balie-silex]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'balie-angular-app-config':
    ensure  => 'file',
    path    => '/var/www/balie/web/app/config.json',
    source  => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[balie-angular-app]',
    noop    => $noop_deploy
  }

  file { 'balie-swagger-ui-config':
    ensure  => 'file',
    path    => '/var/www/balie/web/swagger/config.json',
    source  => $swagger_ui_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[balie-swagger-ui]',
    noop    => $noop_deploy
  }

  file { 'balie-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  file { 'balie-swagger-ui-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/swagger-deploy-config',
    source => $swagger_ui_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular-deploy-config':
    command     => 'angular-deploy-config /var/www/balie/web/app',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[balie-angular-app]', 'File[balie-angular-app-config]', 'File[balie-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  exec { 'swagger-deploy-config':
    command     => 'swagger-deploy-config /var/www/balie/web/swagger',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[balie-angular-app]', 'File[balie-angular-app-config]', 'File[balie-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  profiles::deployment::versions { $title:
    project      => $project_prefix,
    packages     => [ 'balie-angular-app', 'balie-silex', 'balie-swagger-ui'],
    puppetdb_url => $puppetdb_url
  }

  Class['php'] -> Class['deployment::balie']
}
