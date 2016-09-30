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
  $settings
) {

  # TODO: apt source for private packages
  # TODO: aws keys for private packages
  # TODO: package install sapi from private source
  # TODO: reverse proxy for search/admin/solr

  $passwordfile = "/home/${user}/asadmin.pass"

  class { 'glassfish':
    install_method      => 'package',
    package_prefix      => 'glassfish',
    create_service      => false,
    enable_secure_admin => false,
    manage_java         => false,
    parent_dir          => '/opt',
    install_dir         => 'glassfish'
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
    source           => '/opt/mysql-connector-java/mysql-connector-java.jar'
  }

  jdbcconnectionpool { 'mysql_searchdb_j2eePool':
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
    }
  }

  jdbcresource { 'jdbc/search':
    portbase       => $glassfish_portbase,
    user           => $user,
    passwordfile   => $passwordfile,
    target         => 'domain',
    connectionpool => 'mysql_searchdb_j2eePool'
  }

  systemproperty { 'search_solr_path':
    ensure       => 'present',
    portbase     => $glassfish_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    target       => 'domain',
    value        => $solr_url
  }

  package { 'sapi':
    ensure => 'latest'
  }

  application { 'sapi':
    portbase     => $glassfish_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    target       => 'domain',
    source       => '/opt/sapi/search-standalone.war'
  }

  $settings.each |$setting| {
    deployment::search_api::setting { $setting['key']:
      database => $mysql_database,
      service  => $service_name,
      id       => $setting['id'],
      value    => $setting['value']
    }
  }

  Class['glassfish'] -> Glassfish::Create_domain[$glassfish_domain]
  Glassfish::Create_domain[$glassfish_domain] -> Jdbcconnectionpool['mysql_searchdb_j2eePool']

  Package['mysql-connector-java'] -> Glassfish::Install_jars['mysql-connector-java.jar']

  Jdbcresource['jdbc/search'] -> Application['sapi']
  Package['sapi'] ~> Application['sapi']
}
