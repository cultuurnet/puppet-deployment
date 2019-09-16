# Class: deployment
class deployment {

  file { 'get_fact_value':
    ensure => 'absent',
    path   => '/usr/local/bin/get_fact_value',
  }

  realize Package['jq']
}
