class deployment::projectaanvraag::rabbitmq (
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
    require  => 'Class[Rabbitmq]',
    noop     => $noop_deploy
  }

  rabbitmq_vhost { $vhost:
    ensure  => present,
    require => 'Class[Rabbitmq]',
    noop    => $noop_deploy
  }

  rabbitmq_user_permissions { "${admin_user}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => 'Class[Rabbitmq]',
    noop                 => $noop_deploy
  }

  rabbitmq_exchange { "projectaanvraag.vagrant.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "projectaanvraag.vagrant.q.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "projectaanvraag.vagrant.x.entry@projectaanvraag.vagrant.q.entry@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }
}
