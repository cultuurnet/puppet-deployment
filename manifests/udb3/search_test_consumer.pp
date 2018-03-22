class deployment::udb3::search_test_consumer {

  package { 'sapi3-test-consumer':
    ensure => 'latest',
    notify => Class['Apache::Service']
  }

  Class['php'] -> Class['deployment::udb3::search_test_consumer']
}
