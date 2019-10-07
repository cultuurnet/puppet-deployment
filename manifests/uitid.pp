class deployment::uitid (
  $user,
  $payara_domain,
  $base_url,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $package_version   = 'latest',
  $service_name      = $::deployment::uitid::payara_domain,
  $payara_portbase   = '14800',
  $payara_start_heap = undef,
  $payara_max_heap   = undef,
  $timezone          = 'UTC',
  $payara_jmx        = true
) {

  $passwordfile = "/home/${user}/asadmin.pass"
  $application_http_port = $payara_portbase + 80
  $payara_default_start_heap = '512m'
  $payara_default_max_heap = '512m'

  contain profiles::glassfish

  Jvmoption {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    require      => Glassfish::Create_domain[$payara_domain]
  }

  Systemproperty {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    portbase     => $payara_portbase,
    require      => Glassfish::Create_domain[$payara_domain]
  }

  glassfish::create_domain { $payara_domain:
    portbase       => $payara_portbase,
    service_name   => $service_name,
    create_service => true,
    start_domain   => true,
    require        => Class['profiles::glassfish']
  }

  # This will only work if the default start heap value (512m) is present in
  # the JVM options. The proper solution is extending the jvmoption
  # type/provider to accomodate all possible combinations of keys, separators
  # and values.
  if $payara_start_heap {
    unless $payara_default_start_heap == $payara_start_heap {
      jvmoption { "Clear domain ${payara_domain} default start heap":
        ensure   => 'absent',
        portbase => $payara_portbase,
        option   => "-Xms${payara_default_start_heap}"
      }

      jvmoption { "Domain ${payara_domain} start heap":
        portbase => $payara_portbase,
        option   => "-Xms${payara_start_heap}"
      }

      Jvmoption["Clear domain ${payara_domain} default start heap"] -> Jvmoption["Domain ${payara_domain} start heap"]
    }
  }

  # This will only work if the default start heap value (512m) is present in
  # the JVM options. The proper solution is extending the jvmoption
  # type/provider to accomodate all possible combinations of keys, separators
  # and values.
  if $payara_max_heap {
    unless $payara_default_max_heap == $payara_max_heap {
      jvmoption { "Clear domain ${payara_domain} default max heap":
        ensure   => 'absent',
        portbase => $payara_portbase,
        option   => "-Xmx${payara_default_max_heap}"
      }

      jvmoption { "Domain ${payara_domain} max heap":
        portbase => $payara_portbase,
        option   => "-Xmx${payara_max_heap}"
      }

      Jvmoption["Clear domain ${payara_domain} default max heap"] -> Jvmoption["Domain ${payara_domain} max heap"]
    }
  }

  jvmoption { "Domain ${payara_domain} timezone":
    portbase => $payara_portbase,
    option   => "-Duser.timezone=${timezone}",
  }

  if $payara_jmx {
    jvmoption { "-Dcom.sun.management.jmxremote":
      portbase => $payara_portbase
    }
    jvmoption { "-Dcom.sun.management.jmxremote.port=9002":
      portbase => $payara_portbase
    }
    jvmoption { "-Dcom.sun.management.jmxremote.local.only=false":
      portbase => $payara_portbase
    }
    jvmoption { "-Dcom.sun.management.jmxremote.authenticate=false":
      portbase => $payara_portbase
    }
    jvmoption { "-Dcom.sun.management.jmxremote.ssl=false":
      portbase => $payara_portbase
    }
    jvmoption { "-Djava.rmi.server.hostname=127.0.0.1":
      portbase => $payara_portbase
    }
  }

  systemproperty { 'uitid_baseurl':
    value => $base_url
  }

  jdbcconnectionpool { 'mysql_uitid_j2eePool':
    ensure              => 'present',
    user                => $user,
    passwordfile        => $passwordfile,
    portbase            => $payara_portbase,
    wrapjdbcobjects     => false,
    resourcetype        => 'javax.sql.DataSource',
    dsclassname         => 'com.mysql.jdbc.jdbc2.optional.MysqlDataSource',
    properties          => {
      'serverName'        => $mysql_host,
      'portNumber'        => $mysql_port,
      'databaseName'      => $mysql_database,
      'User'              => $mysql_user,
      'Password'          => $mysql_password,
      'URL'               => "jdbc:mysql://${mysql_host}:${mysql_port}/${mysql_database}",
      'driverClass'       => 'com.mysql.jdbc.Driver',
      'characterEncoding' => 'UTF-8',
      'useUnicode'        => true,
      'useSSL'            => false
    },
    require             => Glassfish::Create_domain[$payara_domain]
  }

  jdbcresource { 'jdbc/cultuurnet_uitid':
    ensure         => 'present',
    portbase       => $payara_portbase,
    user           => $user,
    passwordfile   => $passwordfile,
    connectionpool => 'mysql_uitid_j2eePool'
  }

  package { 'uitid-app':
    ensure => $package_version,
    notify => App['uitid-app']
  }

  exec { 'uitid-app_schema_install':
    command     => "mysql --defaults-extra-file=/root/.my.cnf ${mysql_database} < /opt/uitid-app/createtables.sql",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin' ],
    onlyif      => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(table_name) from information_schema.tables where table_schema = \"${mysql_database}\";')",
    refreshonly => true,
    subscribe   => Package['uitid-app']
  }

  app { 'uitid-app':
    ensure        => 'present',
    portbase      => $payara_portbase,
    user          => $user,
    passwordfile  => $passwordfile,
    contextroot   => 'uitid',
    precompilejsp => false,
    source        => '/opt/uitid-app/uitid-app.war',
    require       => [ Jdbcresource['jdbc/cultuurnet_uitid'], Exec['uitid-app_schema_install'] ]
  }

  exec { "bootstrap_${service_name}":
    command     => "curl http://localhost:${application_http_port}/uitid/rest/bootstrap/test",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin' ],
    onlyif      => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(*) from DALIUSER;' ${mysql_database})",
    refreshonly => true,
    subscribe   => Package['uitid-app'],
    require     => App['uitid-app']
  }

  $settings.each |$name, $setting| {
    if $setting['ensure'] {
      $ensure = $setting['ensure']
    } else {
      $ensure = 'present'
    }

    deployment::uitid::setting { $name:
      database => $mysql_database,
      value    => $setting['value'],
      ensure   => $ensure,
      require  => [ App['uitid-app'], Exec["bootstrap_${service_name}"] ],
      notify   => Exec["restart_service_${service_name}"]
    }
  }

  # Force domain restart at the end of the deployment procedure.
  # Unfortunately we need an 'exec' here, notifying the domain after
  # application deployment and applying settings would result in a
  # dependency cycle, as it has to be created before the glassfish
  # resources can be applied.
  # Also, the database schema is created by the application deployment,
  # which means the application settings can only be applied after
  # that. This is a reversal of the PCS pattern.
  exec { "restart_service_${service_name}":
    command     => "/usr/sbin/service ${service_name} restart",
    refreshonly => true,
    subscribe   => App['uitid-app']
  }
}
