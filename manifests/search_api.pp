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
  $timezone             = 'UTC',
  $solr_start_heap      = '512m',
  $solr_max_heap        = '512m',
  $solr_jmx             = true,
  $solr_jmx_port        = '9002',
  $service_name         = $::deployment::search_api::glassfish_domain,
  $search_hostname      = 'localhost',
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
  $search_admins_uid    = []
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

  Jvmoption {
    ensure       => 'present',
    user         => $user,
    passwordfile => $passwordfile,
    portbase     => $glassfish_portbase,
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

  include java8

  class { 'glassfish':
    install_method      => 'package',
    package_prefix      => 'glassfish',
    create_service      => false,
    enable_secure_admin => false,
    manage_java         => false,
    parent_dir          => '/opt',
    install_dir         => 'glassfish',
    require             => [ Class['apt::update'], Class['java8']]
  }

  glassfish::create_domain { $glassfish_domain:
    portbase       => $glassfish_portbase,
    service_name   => $service_name,
    create_service => true,
    start_domain   => true
  }

  # This will only work if the default start heap value (512m) is present in
  # the JVM options. The proper solution is extending the jvmoption
  # type/provider to accomodate all possible combinations of keys, separators
  # and values.
  if $glassfish_start_heap {
    unless $glassfish_default_start_heap == $glassfish_start_heap {
      jvmoption { "Clear domain ${glassfish_domain} default start heap":
        ensure => 'absent',
        option => "-Xms${glassfish_default_start_heap}"
      }

      jvmoption { "Domain ${glassfish_domain} start heap":
        option => "-Xms${glassfish_start_heap}"
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
        ensure => 'absent',
        option => "-Xmx${glassfish_default_max_heap}"
      }

      jvmoption { "Domain ${glassfish_domain} max heap":
        option => "-Xmx${glassfish_max_heap}"
      }

      Jvmoption["Clear domain ${glassfish_domain} default max heap"] -> Jvmoption["Domain ${glassfish_domain} max heap"]
    }
  }

  jvmoption { "-Duser.timezone=${timezone}": }

  if $glassfish_jmx {
    jvmoption { "-Dcom.sun.management.jmxremote": }
    jvmoption { "-Dcom.sun.management.jmxremote.port=${glassfish_jmx_port}": }
    jvmoption { "-Dcom.sun.management.jmxremote.local.only=false": }
    jvmoption { "-Dcom.sun.management.jmxremote.authenticate=false": }
    jvmoption { "-Dcom.sun.management.jmxremote.ssl=false": }
    jvmoption { "-Djava.rmi.server.hostname=127.0.0.1": }
  }

  if $glassfish_gc_logging {
    jvmoption { "-Xloggc:/opt/glassfish/glassfish/domains/${glassfish_domain}/logs/gc.log": }
    jvmoption { '-XX:-PrintGCTimeStamps': }
    jvmoption { '-XX:+PrintGCDateStamps': }
    jvmoption { '-verbose:gc': }
  }

  package { 'mysql-connector-java':
    ensure => 'present'
  }

  glassfish::install_jars { 'mysql-connector-java.jar':
    install_location => 'domain',
    domain_name      => $glassfish_domain,
    service_name     => $service_name,
    source           => '/opt/mysql-connector-java/mysql-connector-java.jar',
    require          => Package['mysql-connector-java']
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
    value        => "${solr_url}/sapi/"
  }

  systemproperty { 'search_solr_path_fast':
    value        => "${solr_url}/sapifast/"
  }

  systemproperty { 'search_mysql_cachesize':
    value        => $cache_size
  }

  systemproperty { 'search_fastindexonly':
    value        => "${fast_index_only}"
  }

  systemproperty { 'search_taxonomy_url':
    value        => "${taxonomy_url}"
  }

  package { 'sapi':
    ensure => 'latest',
    notify => App['sapi']
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
        solrconfig_source => '/opt/sapi/solrconfig.xml'
      },
      'sapifast'          => {
        schema_source     => '/opt/sapi/sapifast/schema.xml',
        solrconfig_source => '/opt/sapi/solrconfig.xml'
      }
    },
    require               => [ Package['sapi'], Class['java8']],
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
}
