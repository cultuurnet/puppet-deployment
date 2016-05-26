class deployment::udb3::rabbitmq (
  $admin_user,
  $admin_password,
  $vhost,
  $noop_deploy = false,
) {

  class { '::rabbitmq':
    manage_repos      => false,
    delete_guest_user => true
  }

  rabbitmq_user { $admin_user:
    admin    => true,
    password => $admin_password,
    noop     => $noop_deploy
  }

  rabbitmq_vhost { $vhost:
    ensure => present,
    noop   => $noop_deploy
  }

  rabbitmq_exchange { "cdbxml.vagrant.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    noop        => $noop_deploy
  }
}
