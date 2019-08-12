# Class: deployment
class deployment {

  if ! defined(File['update_facts']) {
    file { 'update_facts':
      ensure => 'file',
      path   => '/usr/local/bin/update_facts',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/deployment/update_facts'
    }
  }

  file { 'get_fact_value':
    ensure => 'absent',
    path   => '/usr/local/bin/get_fact_value',
  }

  if ! defined(Package['jq']) {
    package { 'jq':
      ensure => 'installed'
    }
  }
}
