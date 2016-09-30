define deployment::search_api::setting (
  $database,
  $id,
  $value
) {

  exec { "SAPI setting ${title}: ${value}":
    command => "mysql --defaults-extra-file=/root/.my.cnf -e \"insert into ${database}.SETTING (ID, TITLE, CONTENT) values (${id}, '${title}', '${value}') on duplicate key update CONTENT = '${value}';\"",
    path    => [ '/usr/local/bin', '/usr/bin', '/bin'],
    onlyif  => "test '${value}' != \"$(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e \"select CONTENT from ${database}.SETTING where TITLE = '${title}';\")\"",
    require => Class['mysql::server']
  }
}
