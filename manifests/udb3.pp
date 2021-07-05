class deployment::udb3 (
  $with_silex             = true,
  $with_angular           = true,
  $with_angular_nl        = false,
  $with_frontend          = false,
  $with_cdbxml            = true,
  $with_jwtprovider       = true,
  $with_apidoc            = true,
  $with_search            = true,
  $with_iis               = true,
  $with_movie_api_fetcher = true
){
  include ::profiles::apt::keys

  @apt::source { 'cultuurnet-udb3':
    location => "http://apt.uitdatabank.be/udb3-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-udb3':
    require => Apt::Source['cultuurnet-udb3']
  }

  @apt::source { 'cultuurnet-udb-nl':
    location => "http://apt.uitdatabank.be/udb-nl-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-udb-nl':
    require => Apt::Source['cultuurnet-udb-nl']
  }

  @apt::source { 'cultuurnet-cdbxml':
    location => "http://apt.uitdatabank.be/cdbxml-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-cdbxml':
    require => Apt::Source['cultuurnet-cdbxml']
  }

  @apt::source { 'cultuurnet-jwtprovider':
    location => "http://apt.uitdatabank.be/jwtprovider-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-jwtprovider':
    require => Apt::Source['cultuurnet-jwtprovider']
  }

  @apt::source { 'cultuurnet-iis':
    location => "http://apt.uitdatabank.be/iis-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-iis':
    require => Apt::Source['cultuurnet-iis']
  }

  unless $facts['noop_deploy'] == 'true' {
    if $with_silex {
      realize Apt::Source['cultuurnet-tools']
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-tools']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::silex

      Profiles::Apt::Update['cultuurnet-tools'] -> Class['deployment::udb3::silex']
      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::silex']
    }
    if $with_angular {
      realize Apt::Source['cultuurnet-tools']
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-tools']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::angular

      Profiles::Apt::Update['cultuurnet-tools'] -> Class['deployment::udb3::angular']
      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::angular']
    }
    if $with_angular_nl {
      realize Apt::Source['cultuurnet-tools']
      realize Apt::Source['cultuurnet-udb-nl']
      realize Profiles::Apt::Update['cultuurnet-tools']
      realize Profiles::Apt::Update['cultuurnet-udb-nl']

      contain deployment::udb3::angular

      Profiles::Apt::Update['cultuurnet-tools'] -> Class['deployment::udb3::angular']
      Profiles::Apt::Update['cultuurnet-udb-nl'] -> Class['deployment::udb3::angular']
    }
    if $with_frontend {
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::frontend

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::frontend']
    }
    if $with_cdbxml {
      realize Apt::Source['cultuurnet-cdbxml']
      realize Profiles::Apt::Update['cultuurnet-cdbxml']

      contain deployment::udb3::cdbxml

      Profiles::Apt::Update['cultuurnet-cdbxml'] -> Class['deployment::udb3::cdbxml']
    }
    if $with_jwtprovider {
      realize Apt::Source['cultuurnet-jwtprovider']
      realize Profiles::Apt::Update['cultuurnet-jwtprovider']

      contain deployment::udb3::jwtprovider

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::jwtprovider']
    }
    if $with_apidoc {
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::apidoc

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::apidoc']
    }
    if $with_search {
      @apt::source { 'cultuurnet-search':
        location => "http://apt.uitdatabank.be/search-${environment}",
        release  => $facts['lsbdistcodename'],
        repos    => 'main',
        require  => Class['profiles::apt::keys'],
        include  => {
          'deb' => true,
          'src' => false
        }
      }

      @profiles::apt::update { 'cultuurnet-search':
        require => Apt::Source['cultuurnet-search']
      }

      realize Apt::Source['cultuurnet-search']
      realize Profiles::Apt::Update['cultuurnet-search']

      contain deployment::udb3::search

      Profiles::Apt::Update['cultuurnet-search'] -> Class['deployment::udb3::search']
    }
    if $with_iis {
      realize Apt::Source['cultuurnet-iis']
      realize Profiles::Apt::Update['cultuurnet-iis']

      contain deployment::udb3::iis

      Profiles::Apt::Update['cultuurnet-iis'] -> Class['deployment::udb3::iis']
    }
    if $with_movie_api_fetcher {
      realize Apt::Source['cultuurnet-iis']
      realize Profiles::Apt::Update['cultuurnet-iis']

      contain deployment::udb3::movie_api_fetcher

      Profiles::Apt::Update['cultuurnet-iis'] -> Class['deployment::udb3::movie_api_fetcher']
    }
  }
}
