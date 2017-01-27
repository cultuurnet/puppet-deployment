class deployment::projectaanvraag::rabbitmq (
  $admin_user,
  $admin_password,
  $vhost,
  $plugin_source,
  $version = '3.5.8-1',
  $noop_deploy = false
) {

  $base_version = regsubst($version,'^(.*)-\d$','\1')
  $plugin_dir   = "/usr/lib/rabbitmq/lib/rabbitmq_server-${base_version}/plugins"

  apt::source { 'erlang-solutions':
    location => 'http://packages.erlang-solutions.com/ubuntu',
    release  => 'trusty',
    repos    => 'contrib',
    key      => {
      id     => '434975BD900CCBE4F7EE1B1ED208507CA14F4FCA',
      source => 'http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc'
    },
    include  => {
      deb => true,
      src => false
    }
  }

  class { '::rabbitmq':
    manage_repos      => false,
    version           => $version,
    delete_guest_user => true
  }

  file { 'rabbitmq_delayed_message_exchange':
    ensure  => 'file',
    path    => "${plugin_dir}/rabbitmq_delayed_message_exchange-0.0.1.ez",
    source  => "${plugin_source}/rabbitmq_delayed_message_exchange-0.0.1.ez",
    require => Class['::rabbitmq']
  }

  rabbitmq_plugin { 'rabbitmq_delayed_message_exchange':
      ensure  => 'present',
      require => File['rabbitmq_delayed_message_exchange']
  }

  rabbitmq_user { $admin_user:
    admin    => true,
    password => $admin_password,
    require  => Class['::rabbitmq'],
    noop     => $noop_deploy
  }

  rabbitmq_vhost { $vhost:
    ensure  => present,
    require => Class['::rabbitmq'],
    noop    => $noop_deploy
  }

  rabbitmq_user_permissions { "${admin_user}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => Class['::rabbitmq'],
    noop                 => $noop_deploy
  }

  Apt::Source['erlang-solutions'] -> Class['::rabbitmq']
}
