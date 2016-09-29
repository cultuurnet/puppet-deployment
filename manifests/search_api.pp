class deployment::search_api (
  $user = 'glassfish',
  $glassfish_portbase = '8000',
  $glassfish_domain = 'sapi',
  $service_name = 'sapi',
  $mysql_user,
  $mysql_password,
  $mysql_host,
  $mysql_port,
  $mysql_database,
  $settings
) {

  # TODO: apt source for private packages
  # TODO: aws keys for private packages
  # TODO: package install sapi from private source
  # TODO: MySQL search settings
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

  package { 'sapi':
    ensure => 'present'
  }

  application { 'sapi':
    portbase     => $glassfish_portbase,
    user         => $user,
    passwordfile => $passwordfile,
    target       => 'domain',
    source       => '/opt/sapi/search-standalone.war'
  }

  exec { 'item_table_update_content_column':
    command => "mysql --defaults-extra-file=/root/.my.cnf -e 'alter table ${mysql_database}.ITEM change CONTENT CONTENT text';",
    path    => [ '/usr/local/bin', '/usr/bin', '/bin'],
    onlyif  => "test text != $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e 'select data_type from information_schema.columns where TABLE_SCHEMA = '${mysql_database}' and TABLE_NAME = 'ITEM' and COLUMN_NAME = 'CONTENT';')"
  }

  $settings.each |$setting| {
    deployment::search_api::setting { $setting['key']:
      database => $mysql_database,
      id       => $setting['id'],
      value    => $setting['value']
    }
  }

  Class['glassfish'] -> Glassfish::Create_domain[$glassfish_domain]

  Package['mysql-connector-java'] -> Glassfish::Install_jars['mysql-connector-java.jar']

  Jdbcresource['jdbc/search'] -> Application['sapi']
  Package['sapi'] ~> Application['sapi']
  Application['sapi'] -> Exec['item_table_update_content_column']
}
