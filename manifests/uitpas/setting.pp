define deployment::uitpas::setting (
  $ensure,
  $database,
  $value,
  $type = '0',
  $dtype = 'Setting'
) {

  if $ensure == 'absent' {
    exec { "UiTPAS setting ${title}: absent":
      command => "mysql --defaults-extra-file=/root/.my.cnf -e \"delete from ${database}.SETTING where K = '${title}';\"",
      path    => [ '/usr/local/bin', '/usr/bin', '/bin'],
      onlyif  => "test 0 != $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e \"select count(*) from ${database}.SETTING where K = '${title}';\")"
    }
  }
  else {
    exec { "UiTPAS setting add ${title}: ${value}":
      command => "mysql --defaults-extra-file=/root/.my.cnf -e \"insert into ${database}.SETTING (K, TYPE, V, DTYPE) values ('${title}', ${type}, '${value}', '${dtype}');\"",
      path    => [ '/usr/local/bin', '/usr/bin', '/bin'],
      onlyif  => "test 0 -eq $(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e \"select count(*) from ${database}.SETTING where K = '${title}';\")"
    }

    exec { "UiTPAS setting update ${title}: ${value}":
      command => "mysql --defaults-extra-file=/root/.my.cnf -e \"update ${database}.SETTING set V = '${value}' where K = '${title}';\"",
      path    => [ '/usr/local/bin', '/usr/bin', '/bin'],
      onlyif  => "test '${value}' != \"$(mysql --defaults-extra-file=/root/.my.cnf -s --skip-column-names -e \"select V from ${database}.SETTING where K = '${title}';\")\"",
      require => Exec["UiTPAS setting add ${title}: ${value}"]
    }
  }
}
