class deployment::projectaanvraag::rabbitmq (
  $admin_user,
  $admin_password,
  $vhost,
  $noop_deploy = false,
) {

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

  apt::source { 'rabbitmq':
    location => 'http://www.rabbitmq.com/debian/',
    release  => 'testing',
    repos    => 'main',
    key      => {
      id     => '0A9AF2115F4687BD29803A206B73A36E6026DFCA',
      source => 'http://www.rabbitmq.com/rabbitmq-release-signing-key.asc'
    },
    include  => {
      deb => true,
      src => false
    }
  }

  class { '::rabbitmq':
    manage_repos      => false,
    delete_guest_user => true
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
  Apt::Source['rabbitmq'] -> Class['::rabbitmq']
}
