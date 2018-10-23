class deployment::udb3::angular (
  $deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $instances            = {}
) {

  contain deployment

  file { 'udb3-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $deploy_config_source,
    mode   => '0755'
  }

  $instances.each | $instance, $configuration| {
    deployment::udb3::angular::instance { $instance:
      * => $configuration
    }
  }

  File['udb3-angular-app-deploy-config'] -> Deployment::Udb3::Angular::Instance <| |>
}
