class deployment::uitid (
  $user,
  $payara_domain,
  $base_url,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $package_version                       = 'latest',
  $service_name                          = $::deployment::uitid::payara_domain,
  $payara_portbase                       = '14800',
  $payara_start_heap                     = undef,
  $payara_max_heap                       = undef,
  $timezone                              = 'UTC',
  $settings                              = {},
  $payara_jmx                            = true,
  $ensure_send_uitalerts                 = 'absent',
  $auth0_sync                            = undef,
  $auth0_client_id                       = undef,
  $auth0_client_secret                   = undef,
  $auth0_domain                          = undef,
  $stackdriver_servicecredentials_source = undef,
  $uitalert_use_fast_search              = false
) {

  # TODO: apt repository

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
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote":
      option   => '-Dcom.sun.management.jmxremote',
      portbase => $payara_portbase
    }
    jvmoption { "Domain ${payara_domain} jvmoption -Dcom.sun.management.jmxremote.port=9002":
      option   => '-Dcom.sun.management.jmxremote.port=9002',
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

  systemproperty { 'uitid_baseurl':
    value => $base_url
  }

  systemproperty { 'uitid_auth0_sync':
    value => bool2str($auth0_sync)
  }

  systemproperty { 'UITID_AUTH0_CLIENT_ID':
    value => $auth0_client_id
  }

  systemproperty { 'UITID_AUTH0_CLIENT_SECRET':
    value => $auth0_client_secret
  }

  systemproperty { 'UITID_AUTH0_DOMAIN':
    value => $auth0_domain
  }

  systemproperty { 'GOOGLE_STACKDRIVER_SERVICECREDENTIALS_JSON_PATH':
    value => '/opt/payara/glassfish/domains/uitid/config/application_default_credentials.json'
  }

  systemproperty { 'be.culturefeed.ejb.UitAlertBean.USE_FAST_SEARCH':
    value => bool2str($uitalert_use_fast_search)
  }

  file { 'stackdriver_servicecredentials':
    ensure  => 'file',
    path    => '/opt/payara/glassfish/domains/uitid/config/application_default_credentials.json',
    source  => $stackdriver_servicecredentials_source,
    require => Glassfish::Create_domain[$payara_domain],
    before  => App['uitid-app']
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

  cron { 'Send UiTalerts ASAP':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/savedSearch/batch/ASAP'",
    ensure   => $ensure_send_uitalerts,
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => '*',
    minute   => '12',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'Send UiTalerts DAILY':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/savedSearch/batch/DAILY'",
    ensure   => $ensure_send_uitalerts,
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => '7',
    minute   => '24',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'Send UiTalerts WEEKLY':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/savedSearch/batch/WEEKLY'",
    ensure   => $ensure_send_uitalerts,
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => '7',
    minute   => '36',
    weekday  => '1',
    monthday => '*',
    month    => '*'
  }

  cron { 'Clear UiTalerts maillog':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/maillog/clearold'",
    ensure   => $ensure_send_uitalerts,
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => '3',
    minute   => '10',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'Clear UiTID application caches':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/bootstrap/clearcaches'",
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => [ '4', '16'],
    minute   => '20',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'Clear UiTID application caches for UiTalerts':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/bootstrap/clearcaches'",
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => [ '7', '8'] ,
    minute   => '*/10',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'Clear UiTID JPA cache':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/bootstrap/clearJpaCache'",
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => [ '4', '16'],
    minute   => '20',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'Clear UiTID JPA cache for UiTalerts':
    command  => "/usr/bin/curl 'http://localhost:${application_http_port}/uitid/rest/bootstrap/clearJpaCache'",
    require  => 'App[uitid-app]',
    user     => 'root',
    hour     => [ '7', '8'],
    minute   => '*/10',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }
}
