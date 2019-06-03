class deployment::uitid (
  $user,
  $payara_domain,
  $base_url,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
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
    portbase     => $payara_portbase,
    require      => Glassfish::Create_domain[$payara_domain],
    notify       => Exec["restart_service_${service_name}"]
  }

  Systemproperty {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    portbase     => $payara_portbase,
    require      => Glassfish::Create_domain[$payara_domain],
    notify       => Exec["restart_service_${service_name}"]
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
        ensure => 'absent',
        option => "-Xms${payara_default_start_heap}"
      }

      jvmoption { "Domain ${payara_domain} start heap":
        option => "-Xms${payara_start_heap}"
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
        ensure => 'absent',
        option => "-Xmx${payara_default_max_heap}"
      }

      jvmoption { "Domain ${payara_domain} max heap":
        option => "-Xmx${payara_max_heap}"
      }

      Jvmoption["Clear domain ${payara_domain} default max heap"] -> Jvmoption["Domain ${payara_domain} max heap"]
    }
  }

  jvmoption { "Domain ${payara_domain} timezone":
    option => "-Duser.timezone=${timezone}",
  }

  if $payara_jmx {
    jvmoption { "-Dcom.sun.management.jmxremote": }
    jvmoption { "-Dcom.sun.management.jmxremote.port=9002": }
    jvmoption { "-Dcom.sun.management.jmxremote.local.only=false": }
    jvmoption { "-Dcom.sun.management.jmxremote.authenticate=false": }
    jvmoption { "-Dcom.sun.management.jmxremote.ssl=false": }
    jvmoption { "-Djava.rmi.server.hostname=127.0.0.1": }
  }

  systemproperty { 'uitid_baseurl':
    value => $base_url
  }

  jdbcconnectionpool { 'mysql_uitid_j2eePool':
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

  jdbcresource { 'jdbc/cultuurnet_uitid':
    ensure         => 'present',
    portbase       => $payara_portbase,
    user           => $user,
    passwordfile   => $passwordfile,
    connectionpool => 'mysql_uitid_j2eePool'
  }
}
