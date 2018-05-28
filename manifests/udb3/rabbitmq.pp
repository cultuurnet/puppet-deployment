class deployment::udb3::rabbitmq (
  $admin_user,
  $admin_password,
  $vhost,
  $environment = 'vagrant',
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

  rabbitmq_exchange { "udb2.${environment}.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_exchange { "udb3.${environment}.x.domain-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_exchange { "cdbxml.${environment}.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "udb3.${environment}.q.udb2-entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "udb2.${environment}.x.entry@udb3.${environment}.q.udb2-entry@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_queue { "cdbxml.${environment}.q.udb3-domain-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "uitpas.${environment}.q.udb3-domain-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "udb3.${environment}.x.domain-events@cdbxml.${environment}.q.udb3-domain-events@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_binding { "udb3.${environment}.x.domain-events@uitpas.${environment}.q.udb3-domain-events@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_queue { "solr.${environment}.q.udb3-cdbxml@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "cdbxml.${environment}.x.entry@solr.${environment}.q.udb3-cdbxml@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_exchange { "uitid.${environment}.x.uitpas-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "udb3.${environment}.q.uitpas-events@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "uitid.${environment}.x.uitpas-events@udb3.${environment}.q.uitpas-events@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }

  rabbitmq_exchange { "imports.${environment}.x.entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'topic',
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_queue { "udb3.${environment}.q.imports-entry@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => 'Class[Rabbitmq]',
    noop        => $noop_deploy
  }

  rabbitmq_binding { "imports.${environment}.x.entry@udb3.${environment}.q.imports-entry@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => '#',
    arguments        => {},
    require          => 'Class[Rabbitmq]',
    noop             => $noop_deploy
  }
}
