class deployment::omd (
  $noop = false
) {

  package { 'omd-drupal':
    ensure => 'latest',
    notify => [ 'Class[Apache::Service]', 'Class[Supervisord::Service]']
    noop   => $noop
  }
}
