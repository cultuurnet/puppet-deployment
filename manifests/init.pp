# Class: deployment
class deployment {

  file { 'update_facts':
    ensure => 'file',
    path   => '/usr/local/bin/update_facts',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/deployment/update_facts'
  }

  file { 'get_fact_value':
    ensure => 'file',
    path   => '/usr/local/bin/get_fact_value',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/deployment/get_fact_value'
  }
}
