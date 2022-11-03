class deployment::repositories {

  contain ::profiles::apt::keys

  Apt::Source {
    release => $facts['lsbdistcodename'],
    repos   => 'main',
    include => {
      'deb' => true,
      'src' => false
    },
    require => Class['profiles::apt::keys']
  }

  @apt::source { 'cultuurnet-groepspas':
    location => "http://apt.uitdatabank.be/groepspas-${environment}"
  }

  @apt::source { 'cultuurnet-omd':
    location => "http://apt.uitdatabank.be/omd-${environment}"
  }

  @apt::source { 'cultuurnet-udb3':
    location => "http://apt.uitdatabank.be/udb3-${environment}"
  }

  @apt::source { 'cultuurnet-cdbxml':
    location => "http://apt.uitdatabank.be/cdbxml-${environment}"
  }
}
