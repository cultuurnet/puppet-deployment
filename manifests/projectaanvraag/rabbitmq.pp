class deployment::projectaanvraag::rabbitmq (
  $admin_user,
  $admin_password,
  $vhost,
  $plugin_source,
  $erlang_version = '1:20.3-1',
  $version = '3.7.6-1'
) {

  $base_version = regsubst($version,'^(.*)-\d$','\1')
  $plugin_dir   = "/usr/lib/rabbitmq/lib/rabbitmq_server-${base_version}/plugins"

  class { '::erlang':
    version                  => $erlang_version
    key_signature            => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
    remote_repo_location     => 'http://apt.uitdatabank.be/erlang-production',
    remote_repo_key_location => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key',
    repos                    => 'main'
  }

  class { '::rabbitmq':
    manage_repos      => false,
    version           => $version,
    delete_guest_user => true
  }

  file { 'rabbitmq_delayed_message_exchange':
    ensure  => 'file',
    path    => "${plugin_dir}/rabbitmq_delayed_message_exchange-20171201-3.7.x.ez",
    source  => "${plugin_source}/rabbitmq_delayed_message_exchange-20171201-3.7.x.ez",
    require => Class['::rabbitmq']
  }

  rabbitmq_plugin { 'rabbitmq_delayed_message_exchange':
      ensure  => 'present',
      require => File['rabbitmq_delayed_message_exchange']
  }

  rabbitmq_user { $admin_user:
    admin    => true,
    password => $admin_password,
    require  => Class['::rabbitmq']
  }

  rabbitmq_user_permissions { "${admin_user}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => Class['::rabbitmq']
  }

  rabbitmq_vhost { $vhost:
    ensure  => present,
    require => Class['::rabbitmq']
  }

  rabbitmq_exchange { "main_exchange@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    type        => 'x-delayed-message',
    arguments   => {
                     'x-delayed-type' => 'direct'
                   },
    internal    => false,
    auto_delete => false,
    durable     => true,
    require     => Class['::rabbitmq']
  }

  rabbitmq_queue { "projectaanvraag@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => Class['::rabbitmq']
  }

  rabbitmq_binding { "main_exchange@projectaanvraag@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => 'asynchronous_commands',
    arguments        => {},
    require          => Class['::rabbitmq']
  }

  rabbitmq_queue { "projectaanvraag_failed@${vhost}":
    user        => $admin_user,
    password    => $admin_password,
    durable     => true,
    auto_delete => false,
    require     => Class['::rabbitmq']
  }

  rabbitmq_binding { "main_exchange@projectaanvraag_failed@${vhost}":
    user             => $admin_user,
    password         => $admin_password,
    destination_type => 'queue',
    routing_key      => 'projectaanvraag_failed',
    arguments        => {},
    require          => Class['::rabbitmq'],
  }

  Class['::erlang'] -> Class['::rabbitmq']
}
