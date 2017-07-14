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
}
