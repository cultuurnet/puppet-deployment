class deployment::groepspas (
  $silex_config_source,
  $angular_app_config_source,
  $angular_app_deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  apt::source { 'cultuurnet-groepspas':
    location => "http://apt.uitdatabank.be/groepspas-${environment}",
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

  profiles::apt::update { 'cultuurnet-groepspas':
    require  => Apt::Source['cultuurnet-groepspas'],
    noop     => $noop_deploy
  }

  package { 'groepspas-silex':
    ensure  => 'latest',
    notify  => 'Class[Apache::Service]',
    require => Profiles::Apt::Update['cultuurnet-groepspas'],
    noop    => $noop_deploy
  }

  package { 'groepspas-angular-app':
    ensure  => 'latest',
    require => Profiles::Apt::Update['cultuurnet-groepspas'],
    noop    => $noop_deploy
  }

  package { 'groepspas':
    ensure  => 'latest',
    require => [ 'Package[groepspas-silex]', 'Package[groepspas-angular-app]'],
    noop    => $noop_deploy
  }

  file { 'groepspas-silex-config':
    ensure  => 'file',
    path    => '/var/www/groepspas-api/config.yml',
    source  => $silex_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[groepspas-silex]',
    notify  => 'Class[Apache::Service]',
    noop    => $noop_deploy
  }

  file { 'groepspas-angular-app-config':
    ensure  => 'file',
    path    => '/var/www/groepspas/config.json',
    source  => $angular_app_config_source,
    owner   => 'www-data',
    group   => 'www-data',
    require => 'Package[groepspas-angular-app]',
    noop    => $noop_deploy
  }

  file { 'groepspas-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular2-deploy-config',
    source => $angular_app_deploy_config_source,
    mode   => '0755',
    noop   => $noop_deploy
  }

  exec { 'angular2-deploy-config':
    command     => 'angular2-deploy-config /var/www/groepspas',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    subscribe   => [ 'Package[groepspas-angular-app]', 'File[groepspas-angular-app-config]', 'File[groepspas-angular-app-deploy-config]'],
    noop        => $noop_deploy
  }

  if $puppetdb_url {
    exec { 'update_facts groepspas':
      command     => "/usr/local/bin/update_facts -p ${puppetdb_url}",
      subscribe   => 'Package[groepspas]',
      refreshonly => true,
      noop        => $noop_deploy
    }
  }

  Class['php'] -> Class['deployment::groepspas']
}
