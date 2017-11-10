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

  rabbitmq_exchange { "udb2.vagrant.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_exchange { "udb3.vagrant.x.domain-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_exchange { "cdbxml.vagrant.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "udb3.vagrant.q.udb2-entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "udb2.vagrant.x.entry@udb3.vagrant.q.udb2-entry@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_queue { "cdbxml.vagrant.q.udb3-domain-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "uitpas.vagrant.q.udb3-domain-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "udb3.vagrant.x.domain-events@cdbxml.vagrant.q.udb3-domain-events@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_binding { "udb3.vagrant.x.domain-events@uitpas.vagrant.q.udb3-domain-events@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_queue { "solr.vagrant.q.udb3-cdbxml@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "cdbxml.vagrant.x.entry@solr.vagrant.q.udb3-cdbxml@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_exchange { "uitid.vagrant.x.uitpas-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "udb3.vagrant.q.uitpas-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "uitid.vagrant.x.uitpas-events@udb3.vagrant.q.uitpas-events@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }
}
