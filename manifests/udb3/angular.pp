class deployment::udb3::angular (
  $deploy_config_source = 'puppet:///modules/deployment/angular/angular-deploy-config.rb',
  $app_rootdir          = '/var/www/udb-app',
  $instances            = {}
) {

  contain deployment

  file { 'udb3-angular-app-deploy-config':
    ensure => 'file',
    path   => '/usr/local/bin/angular-deploy-config',
    source => $deploy_config_source,
    mode   => '0755'
  }

  create_resources('deployment::udb3::angular::instance', $instances)
}
