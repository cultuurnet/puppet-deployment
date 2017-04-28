class deployment::search_api (
  $user,
  $glassfish_portbase,
  $glassfish_domain,
  $service_name,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $solr_url,
  $settings,
  $solr_max_heap
) {

  # TODO: reverse proxy for search/admin/solr

  $passwordfile = "/home/${user}/asadmin.pass"

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
      'useUnicode'        => true,
      'characterEncoding' => 'utf8'
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
    ensure       => 'present',
    portbase     => $glassfish_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    value        => "${solr_url}/sapi/"
  }

  systemproperty { 'search_solr_path_fast':
    ensure       => 'present',
    portbase     => $glassfish_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    value        => "${solr_url}/sapifast/"
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

  $settings.each |$name, $setting| {
    deployment::search_api::setting { $name:
      database => $mysql_database,
      id       => $setting['id'],
      value    => $setting['value'],
      require  => App['sapi'],
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
    subscribe   => App['sapi']
  }

  class { 'solr':
    max_heap              => $solr_max_heap,
    cores                 => {
      'sapi'              => {
        schema_source     => '/opt/sapi/schema.xml',
        solrconfig_source => '/opt/sapi/solrconfig.xml'
      }
    },
    require               => [ Package['sapi'], Class['java8']],
    before                => App['sapi']
  }
}
