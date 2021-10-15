class deployment::uitpas (
  $user,
  $apt_user,
  $apt_password,
  $payara_domain,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $package_version         = 'latest',
  $db_mgmt_package_version = 'latest',
  $service_name            = $::deployment::uitpas::payara_domain,
  $payara_portbase         = '24800',
  $payara_start_heap       = undef,
  $payara_max_heap         = undef,
  $timezone                = 'UTC',
  $settings                = {},
  $payara_jmx              = true,
  $swagger_base_url        = undef,
  $auth0_domain            = undef,
  $ksb_auth0_clientid      = undef,
  $ksb_auth0_secret        = undef,
  $sysadmin_auth0_clientid = undef,
  $sysadmin_auth0_secret   = undef
) {

  contain profiles::glassfish

  include ::profiles::packages
  include ::profiles::apt::keys

  apt::source { 'cultuurnet-uitpas':
    location => "https://${apt_user}:${apt_password}@apt-private.uitdatabank.be/uitpas-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    },
  }

  profiles::apt::update { 'cultuurnet-uitpas':
    require => Apt::Source['cultuurnet-uitpas']
  }

  $passwordfile = "/home/${user}/asadmin.pass"
  $application_http_port = $payara_portbase + 80
  $payara_default_start_heap = '512m'
  $payara_default_max_heap = '512m'

  realize Package['liquibase']
  realize Package['mysql-connector-java']

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

  systemproperty { 'uitpas_swagger_base':
    value => $swagger_base_url
  }

  systemproperty { 'UITPAS_AUTH0_DOMAIN':
    value => $auth0_domain
  }

  systemproperty { 'UITPAS_KSB_AUTH0_CLIENTID':
    value => $ksb_auth0_clientid
  }

  systemproperty { 'UITPAS_KSB_AUTH0_SECRET':
    value => $ksb_auth0_secret
  }

  systemproperty { 'UITPAS_SYSADMIN_AUTH0_CLIENTID':
    value => $sysadmin_auth0_clientid
  }

  systemproperty { 'UITPAS_SYSADMIN_AUTH0_SECRET':
    value => $sysadmin_auth0_secret
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

  package { 'uitpas-db-mgmt':
    ensure  => $db_mgmt_package_version,
    require => Profiles::Apt::Update['cultuurnet-uitpas'],
    notify  => Exec['uitpas_database_management']
  }

  package { 'uitpas-app':
    ensure  => $package_version,
    require => Profiles::Apt::Update['cultuurnet-uitpas'],
    notify  => App['uitpas-app']
  }

  exec { 'uitpas_database_management':
    command     => "liquibase --driver=com.mysql.jdbc.Driver --classpath=/opt/uitpas-db-mgmt/uitpas-db-mgmt.jar:/opt/mysql-connector-java/mysql-connector-java.jar --changeLogFile=migrations.xml --url='jdbc:mysql://${mysql_host}:${mysql_port}/${mysql_database}?useSSL=false' --username=${mysql_user} --password=${mysql_password} update",
    path        => [ '/opt/liquibase', '/usr/local/bin', '/usr/bin', '/bin' ],
    refreshonly => true,
    logoutput   => true,
    require     => [ Package['liquibase'], Package['mysql-connector-java']],
    subscribe   => Package['uitpas-db-mgmt'],
    before      => App['uitpas-app']
  }

  app { 'uitpas-app':
    ensure        => 'present',
    portbase      => $payara_portbase,
    user          => $user,
    passwordfile  => $passwordfile,
    contextroot   => 'uitid',
    precompilejsp => false,
    source        => '/opt/uitpas-app/uitpas-app.war',
    require       => Jdbcresource['jdbc/cultuurnet_uitpas']
  }

  exec { "bootstrap_${service_name}":
    command     => "curl http://localhost:${application_http_port}/uitpas/rest/bootstrap/test",
    path        => [ '/usr/local/bin', '/usr/bin', '/bin' ],
    onlyif      => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select count(*) from DALIUSER;' ${mysql_database})",
    refreshonly => true,
    subscribe   => Package['uitpas-app'],
    require     => App['uitpas-app']
  }

  $settings.each |$name, $setting| {
    if $setting['ensure'] {
      $ensure = $setting['ensure']
    } else {
      $ensure = 'present'
    }

    deployment::uitpas::setting { $name:
      database => $mysql_database,
      value    => $setting['value'],
      ensure   => $ensure,
      require  => [ App['uitpas-app'], Exec["bootstrap_${service_name}"] ],
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
    subscribe   => App['uitpas-app']
  }

  cron { "Cleanup payara logs ${payara_domain}":
    command  => "/usr/bin/find /opt/payara/glassfish/domains/${payara_domain}/logs -type f -name \"server.log_*\" -mtime +7 -exec rm {} \;"
    user     => 'root',
    hour     => '*',
    minute   => '15',
    weekday  => '*',
    monthday => '*',
    month    => '*',
    require  => Glassfish::Create_domain[$payara_domain]
  }
}
