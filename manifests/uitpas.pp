class deployment::uitpas (
  $user,
  $payara_domain,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $service_name      = $::deployment::uitpas::payara_domain,
  $payara_portbase   = '24800',
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
    option   => "-Duser.timezone=${timezone}",
    portbase => $payara_portbase
  }

  if $payara_jmx {
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote":
      option   => '-Dcom.sun.management.jmxremote',
      portbase => $payara_portbase
    }
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote.port=9003":
      option   => '-Dcom.sun.management.jmxremote.port=9003',
      portbase => $payara_portbase
    }
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote.local.only=false":
      option   => '-Dcom.sun.management.jmxremote.local.only=false',
      portbase => $payara_portbase
    }
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote.authenticate=false":
      option   => '-Dcom.sun.management.jmxremote.authenticate=false',
      portbase => $payara_portbase
    }
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote.ssl=false":
      option   => '-Dcom.sun.management.jmxremote.ssl=false',
      portbase => $payara_portbase
    }
    jvmoption { "Domain ${payara_domain} jvmoption -Djava.rmi.server.hostname=127.0.0.1":
      option   => '-Djava.rmi.server.hostname=127.0.0.1',
      portbase => $payara_portbase
    }
  }

  systemproperty { 'uitpas_cfauth_base':
    value => 'https://acc.uitid.be/uitid/rest'
  }

  systemproperty { 'uitpas_cfauth_key':
    value => '6c085f15712c7393a50b61d630f775d5'
  }

  systemproperty { 'uitpas_cfauth_secret':
    value => 'cd52d819e50c29a41cd82a61412c7b1c'
  }

  jdbcconnectionpool { 'mysql_uitpas_j2eePool':
    ensure              => 'present',
    user                => $user,
    passwordfile        => $passwordfile,
    portbase            => $payara_portbase,
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

  jdbcresource { 'jdbc/cultuurnet_uitpas':
    ensure         => 'present',
    portbase       => $payara_portbase,
    user           => $user,
    passwordfile   => $passwordfile,
    connectionpool => 'mysql_uitpas_j2eePool'
  }
}
