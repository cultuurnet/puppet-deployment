class deployment::uitid (
  $user,
  $payara_portbase,
  $payara_domain,
  $service_name,
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $settings = {}
) {

  # TODO: reverse proxy for search/admin/solr

  $passwordfile = "/home/${user}/asadmin.pass"

  include java8

  class { 'glassfish':
    install_method      => 'package',
    package_prefix      => 'payara',
    create_service      => false,
    enable_secure_admin => false,
    manage_java         => false,
    parent_dir          => '/opt',
    install_dir         => 'payara',
    require             => [ Class['apt::update'], Class['java8']]
  }

  glassfish::create_domain { $payara_domain:
    portbase       => $payara_portbase,
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
      'useUnicode'        => true,
      'characterEncoding' => 'utf8'
    },
    require             => [ Class['glassfish'], Glassfish::Create_domain[$payara_domain]]
  }

  jdbcresource { 'jdbc/cultuurnet':
    ensure         => 'present',
    portbase       => $payara_portbase,
    user           => $user,
    passwordfile   => $passwordfile,
    connectionpool => 'mysql_uitid_j2eePool',
    require        => Class['mysql::server']
  }

  package { 'uitpas-app':
    ensure => 'latest',
    notify => App['uitpas-app']
  }

  app { 'uitpas-app':
    ensure       => 'present',
    portbase     => $payara_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    source       => '/opt/sapi/search-standalone.war',
    require      => Jdbcresource['jdbc/cultuurnet']
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
}
