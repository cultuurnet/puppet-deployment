class deployment::omd (
  $no_deploy = false
) {

  package { 'omd-drupal':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]'],
    noop   => $no_deploy
  }
}
