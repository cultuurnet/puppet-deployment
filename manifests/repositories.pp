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

  @apt::source { 'publiq-museumpas-website':
    location => "https://apt.publiq.be/museumpas-website-${environment}"
  }

  @apt::source { 'cultuurnet-omd':
    location => "http://apt.uitdatabank.be/omd-${environment}"
  }

  # These variables should be rolled into /etc/apt/auth.conf, which is managed by the apt class
  $sapi_apt_user     = lookup('deployment::search_api::apt_user', String, 'first', '')
  $sapi_apt_password = lookup('deployment::search_api::apt_password', String, 'first', '')

  @apt::source { 'cultuurnet-sapi':
    location => "https://${sapi_apt_user}:${sapi_apt_password}@apt-private.uitdatabank.be/sapi-${environment}"
  }

  # These variables should be rolled into /etc/apt/auth.conf, which is managed by the apt class
  $uitpas_apt_user     = lookup('deployment::uitpas::apt_user', String, 'first', '')
  $uitpas_apt_password = lookup('deployment::uitpas::apt_password', String, 'first', '')

  @apt::source { 'cultuurnet-uitpas':
    location => "https://${uitpas_apt_user}:${uitpas_apt_password}@apt-private.uitdatabank.be/uitpas-${environment}"
  }

  @apt::source { 'cultuurnet-udb3':
    location => "http://apt.uitdatabank.be/udb3-${environment}"
  }

  @apt::source { 'cultuurnet-udb-nl':
    location => "http://apt.uitdatabank.be/udb-nl-${environment}"
  }

  @apt::source { 'cultuurnet-cdbxml':
    location => "http://apt.uitdatabank.be/cdbxml-${environment}"
  }

  @apt::source { 'cultuurnet-jwtprovider':
    location => "http://apt.uitdatabank.be/jwtprovider-${environment}"
  }

  @apt::source { 'cultuurnet-iis':
    location => "http://apt.uitdatabank.be/iis-${environment}"
  }
}
