class deployment::search_api (
  $user,
  $glassfish_domain,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $solr_url,
  $settings_source,
  $synonyms_source      = '/opt/solr/example/collection1/conf/synonyms.txt',
  $timezone             = 'UTC',
  $solr_start_heap      = '512m',
  $solr_max_heap        = '512m',
  $solr_jmx             = true,
  $solr_jmx_port        = '9002',
  $service_name         = $::deployment::search_api::glassfish_domain,
  $search_hostname      = 'localhost',
  $glassfish_flavor     = 'glassfish',
  $glassfish_portbase   = '4800',
  $glassfish_start_heap = undef,
  $glassfish_max_heap   = undef,
  $glassfish_gc_logging = false,
  $verbose_logging      = true,
  $cache_size           = '300000',
  $cache_clear_periodic = false,
  $fast_index_only      = false,
  $taxonomy_url         = '',
  $glassfish_jmx        = true,
  $glassfish_jmx_port   = '9001',
  $manage_search_admins = false,
  $search_admins_uid    = [],
  $cfauth_base_url      = undef,
  $cfauth_key           = undef,
  $cfauth_secret        = undef
) {

  $passwordfile = "/home/${user}/asadmin.pass"
  $glassfish_http_port = $glassfish_portbase + 80
  $glassfish_default_start_heap = '512m'
  $glassfish_default_max_heap = '512m'
  $settings = parseyaml(file($settings_source))

  $ensure_cache_clear_periodic = $cache_clear_periodic ? {
    true    => 'present',
    default => 'absent'
  }

  apt::source { 'cultuurnet-sapi':
    location => "https://sapi:phahk3Wai5lo@apt-private.uitdatabank.be/sapi-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  profiles::apt::update { 'cultuurnet-sapi':
    require => Apt::Source['cultuurnet-sapi']
  }

  class { 'profiles::glassfish':
    flavor => $glassfish_flavor
  }

  Jvmoption {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    require      => [ Class['glassfish'], Glassfish::Create_domain[$glassfish_domain]],
    notify       => Exec["restart_service_${service_name}"]
  }

  Systemproperty {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    portbase     => $glassfish_portbase,
    require      => [ Class['glassfish'], Glassfish::Create_domain[$glassfish_domain]],
    notify       => Exec["restart_service_${service_name}"]
  }

  Log_level {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    portbase     => $glassfish_portbase,
    require      => [ Class['glassfish'], Glassfish::Create_domain[$glassfish_domain], App['sapi']],
  }

  glassfish::create_domain { $glassfish_domain:
    portbase       => $glassfish_portbase,
    service_name   => $service_name,
    create_service => true,
    start_domain   => true
  }

  java_ks { 'publiq Development CA':
    certificate  => '/usr/local/share/ca-certificates/publiq/publiq-root-ca.crt',
    target       => "/opt/${glassfish_flavor}/glassfish/domains/${glassfish_domain}/config/cacerts.jks",
    password     => 'changeit',
    trustcacerts => true,
    require      => [ 'Package[ca-certificates-publiq]', 'Glassfish::Create_domain[sapi]'],
    notify       => 'Exec[restart_service_sapi]'
  }

  # This will only work if the default start heap value (512m) is present in
  # the JVM options. The proper solution is extending the jvmoption
  # type/provider to accomodate all possible combinations of keys, separators
  # and values.
  if $glassfish_start_heap {
    unless $glassfish_default_start_heap == $glassfish_start_heap {
      jvmoption { "Clear domain ${glassfish_domain} default start heap":
        ensure   => 'absent',
        portbase => $glassfish_portbase,
        option   => "-Xms${glassfish_default_start_heap}"
      }

      jvmoption { "Domain ${glassfish_domain} start heap":
        portbase => $glassfish_portbase,
        option   => "-Xms${glassfish_start_heap}"
      }

      Jvmoption["Clear domain ${glassfish_domain} default start heap"] -> Jvmoption["Domain ${glassfish_domain} start heap"]
    }
  }

  # This will only work if the default start heap value (512m) is present in
  # the JVM options. The proper solution is extending the jvmoption
  # type/provider to accomodate all possible combinations of keys, separators
  # and values.
  if $glassfish_max_heap {
    unless $glassfish_default_max_heap == $glassfish_max_heap {
      jvmoption { "Clear domain ${glassfish_domain} default max heap":
        ensure   => 'absent',
        portbase => $glassfish_portbase,
        option   => "-Xmx${glassfish_default_max_heap}"
      }

      jvmoption { "Domain ${glassfish_domain} max heap":
        portbase => $glassfish_portbase,
        option   => "-Xmx${glassfish_max_heap}"
      }

      Jvmoption["Clear domain ${glassfish_domain} default max heap"] -> Jvmoption["Domain ${glassfish_domain} max heap"]
    }
  }

  jvmoption { "-Duser.timezone=${timezone}":
    option   => "-Duser.timezone=${timezone}",
    portbase => $glassfish_portbase
  }

  if $glassfish_jmx {
    jvmoption { '-Dcom.sun.management.jmxremote':
      option   => '-Dcom.sun.management.jmxremote',
      portbase => $glassfish_portbase
    }
    jvmoption { "-Dcom.sun.management.jmxremote.port=${glassfish_jmx_port}":
      option   => "-Dcom.sun.management.jmxremote.port=${glassfish_jmx_port}",
      portbase => $glassfish_portbase
    }
    jvmoption { '-Dcom.sun.management.jmxremote.local.only=false':
      option   => '-Dcom.sun.management.jmxremote.local.only=false',
      portbase => $glassfish_portbase
    }
    jvmoption { '-Dcom.sun.management.jmxremote.authenticate=false':
      option   => '-Dcom.sun.management.jmxremote.authenticate=false',
      portbase => $glassfish_portbase
    }
    jvmoption { '-Dcom.sun.management.jmxremote.ssl=false':
      option   => '-Dcom.sun.management.jmxremote.ssl=false',
      portbase => $glassfish_portbase
    }
    jvmoption { '-Djava.rmi.server.hostname=127.0.0.1':
      option   => '-Djava.rmi.server.hostname=127.0.0.1',
      portbase => $glassfish_portbase
    }
  }

  if $glassfish_gc_logging {
    jvmoption { "-Xloggc:/opt/${glassfish_flavor}/glassfish/domains/${glassfish_domain}/logs/gc.log":
      option   => "-Xloggc:/opt/${glassfish_flavor}/glassfish/domains/${glassfish_domain}/logs/gc.log",
      portbase => $glassfish_portbase
    }
    jvmoption { '-XX:-PrintGCTimeStamps':
      option   => '-XX:-PrintGCTimeStamps',
      portbase => $glassfish_portbase
    }
    jvmoption { '-XX:+PrintGCDateStamps':
      option   => '-XX:+PrintGCDateStamps',
      portbase => $glassfish_portbase
    }
    jvmoption { '-verbose:gc':
      option   => '-verbose:gc',
      portbase => $glassfish_portbase
    }
  }

  jdbcconnectionpool { 'mysql_searchdb_j2eePool':
    ensure              => 'present',
    user                => $user,
    passwordfile        => $passwordfile,
    portbase            => $glassfish_portbase,
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
      'useUnicode'        => true
    },
    require             => [ Class['glassfish'], Glassfish::Create_domain[$glassfish_domain]]
  }

  jdbcresource { 'jdbc/search':
    ensure         => 'present',
    portbase       => $glassfish_portbase,
    user           => $user,
    passwordfile   => $passwordfile,
    connectionpool => 'mysql_searchdb_j2eePool',
    require        => Class['mysql::server']
  }

  systemproperty { 'search_solr_path':
    value => "${solr_url}/sapi/"
  }

  systemproperty { 'search_solr_path_fast':
    value => "${solr_url}/sapifast/"
  }

  systemproperty { 'search_mysql_cachesize':
    value => $cache_size
  }

  systemproperty { 'search_fastindexonly':
    value => "${fast_index_only}"
  }

  systemproperty { 'search_taxonomy_url':
    value => "${taxonomy_url}"
  }

  systemproperty { 'search_cfauth_base':
    value => "${cfauth_base_url}"
  }

  systemproperty { 'search_cfauth_key':
    value => "${cfauth_key}"
  }

  systemproperty { 'search_cfauth_secret':
    value => "${cfauth_secret}"
  }

  package { 'sapi':
    ensure  => 'latest',
    require => Profiles::Apt::Update['cultuurnet-sapi'],
    notify  => App['sapi']
  }

  app { 'sapi':
    ensure       => 'present',
    portbase     => $glassfish_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    source       => '/opt/sapi/search-standalone.war',
    require      => Jdbcresource['jdbc/search']
  }

  if $verbose_logging {
    log_level { 'com.sun.jersey.api.container.filter.LoggingFilter':
      value        => 'INFO'
    }

    log_level { 'com.sun.jersey.api.client.filter.LoggingFilter':
      value        => 'INFO'
    }

    log_level { 'com.lodgon.cultuurnet.ImportQueue':
      value        => 'FINEST'
    }

    log_level { 'java.util.logging.ConsoleHandler':
      value        => 'FINEST'
    }
  } else {
    log_level { 'com.sun.jersey.api.container.filter.LoggingFilter':
      value        => 'WARNING'
    }

    log_level { 'com.sun.jersey.api.client.filter.LoggingFilter':
      value        => 'WARNING'
    }

    log_level { 'com.lodgon.cultuurnet.ImportQueue':
      value        => 'INFO'
    }

    log_level { 'java.util.logging.ConsoleHandler':
      value        => 'WARNING'
    }
  }

  $settings.each |$name, $setting| {
    deployment::search_api::setting { $name:
      database => $mysql_database,
      id       => $setting['id'],
      value    => $setting['value'],
      require  => App['sapi'],
      notify   => Exec["restart_service_${service_name}"]
    }
  }

  if $manage_search_admins {
    $search_admins_uid.each |$uid| {
      deployment::search_api::admin_user { $uid:
        database => $mysql_database,
        require  => App['sapi']
      }
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
    subscribe   => App['sapi']
  }

  if $solr_jmx {
    $java_options = [
      "-Duser.timezone=${timezone}",
      '-Dcom.sun.management.jmxremote',
      "-Dcom.sun.management.jmxremote.port=${solr_jmx_port}",
      '-Dcom.sun.management.jmxremote.local.only=false',
      '-Dcom.sun.management.jmxremote.authenticate=false',
      '-Dcom.sun.management.jmxremote.ssl=false',
      '-Djava.rmi.server.hostname=127.0.0.1'
    ]
  } else {
    $java_options = [
      "-Duser.timezone=${timezone}"
    ]
  }

  class { 'solr':
    start_heap            => $solr_start_heap,
    max_heap              => $solr_max_heap,
    java_options          => $java_options,
    cores                 => {
      'sapi'              => {
        schema_source     => '/opt/sapi/sapi/schema.xml',
        solrconfig_source => '/opt/sapi/solrconfig.xml',
        synonyms_source   => $synonyms_source
      },
      'sapifast'          => {
        schema_source     => '/opt/sapi/sapifast/schema.xml',
        solrconfig_source => '/opt/sapi/solrconfig.xml',
        synonyms_source   => $synonyms_source
      }
    },
    require               => [ Package['sapi'], Class['profiles::java8']],
    before                => App['sapi']
  }

  cron { 'reindex_job':
    command  => "/usr/bin/curl 'http://${search_hostname}:${glassfish_http_port}/search/rest/import/queue/reindex?max=500'",
    require  => 'App[sapi]',
    user     => 'root',
    hour     => '*',
    minute   => '*',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'cache_clear_periodic':
    command  => "/usr/bin/curl 'http://${search_hostname}:${glassfish_http_port}/search/rest/import/clearcache'",
    ensure   => $ensure_cache_clear_periodic,
    require  => 'App[sapi]',
    user     => 'root',
    hour     => '0',
    minute   => '0',
    weekday  => '*',
    monthday => '*',
    month    => '*'
  }

  cron { 'cleanup_glassfish_logs':
    command => "find /opt/${glassfish_flavor}/glassfish/domains/sapi/logs -type f -name \"server.log_*\" -mtime +7 -exec rm {} \\;",
    hour    => '*',
    minute  => '15'
  }

  cron { 'cleanup_sapi_logs':
    command => "find /tmp -type f -name \"sapilog-*\" -mtime +30 -exec rm {} \\;",
    hour    => '*',
    minute  => '15'
  }
}
