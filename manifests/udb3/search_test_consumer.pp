class deployment::udb3::search_test_consumer {

  package { 'udb3-search-test-consumer':
    ensure => 'latest',
    notify => Class['Apache::Service']
  }

  Class['php'] -> Class['deployment::udb3::search_test_consumer']
}
