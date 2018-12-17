define deployment::search_api::admin_user (
  $database,
  $uid = $title
) {

  exec { "SAPI admin user ${title}":
    command => "mysql --defaults-extra-file=/root/.my.cnf -e \"insert into ${database}.ADMINUSER values (${uid}, null, null);\"",
    path    => [ '/usr/local/bin', '/usr/bin', '/bin'],
    onlyif  => "test 0 -ne \"$(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e \"select count(*) from ${database}.ADMINUSER where UID = '${uid}';\")\"",
    require => Class['mysql::server']
  }
}
