class deployment::udb3 (
  $with_silex             = true,
  $with_angular           = true,
  $with_cdbxml            = true,
  $with_jwtprovider       = true,
  $with_apidoc            = true,
  $with_uitpas            = true,
  $with_search            = true,
  $with_iis               = true,
  $with_movie_api_fetcher = true
){
  @apt::source { 'cultuurnet-udb3':
    location => "http://apt.uitdatabank.be/udb3-${environment}",
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
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
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
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
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-cdbxml':
    require => Apt::Source['cultuurnet-cdbxml']
  }

  @apt::source { 'cultuurnet-udb3-uitpas':
    location => "http://apt.uitdatabank.be/udb3-uitpas-${environment}",
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-udb3-uitpas':
    require => Apt::Source['cultuurnet-udb3-uitpas']
  }

  @apt::source { 'cultuurnet-search':
    location => "http://apt.uitdatabank.be/search-${environment}",
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-search':
    require => Apt::Source['cultuurnet-search']
  }

  @apt::source { 'cultuurnet-iis':
    location => "http://apt.uitdatabank.be/iis-${environment}",
    release  => 'trusty',
    repos    => 'main',
    key      => {
      'id'     => '2380EA3E50D3776DFC1B03359F4935C80DC9EA95',
      'source' => 'http://apt.uitdatabank.be/gpgkey/cultuurnet.gpg.key'
    },
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
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::silex

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::silex']
    }
    if $with_angular {
      realize Apt::Source['cultuurnet-udb3']
      realize Apt::Source['cultuurnet-udb-nl']
      realize Profiles::Apt::Update['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-udb-nl']

      contain deployment::udb3::angular

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::angular']
      Profiles::Apt::Update['cultuurnet-udb-nl'] -> Class['deployment::udb3::angular']
    }
    if $with_cdbxml {
      realize Apt::Source['cultuurnet-cdbxml']
      realize Profiles::Apt::Update['cultuurnet-cdbxml']

      contain deployment::udb3::cdbxml

      Profiles::Apt::Update['cultuurnet-cdbxml'] -> Class['deployment::udb3::cdbxml']
    }
    if $with_jwtprovider {
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::jwtprovider

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::jwtprovider']
    }
    if $with_apidoc {
      realize Apt::Source['cultuurnet-udb3']
      realize Profiles::Apt::Update['cultuurnet-udb3']

      contain deployment::udb3::apidoc

      Profiles::Apt::Update['cultuurnet-udb3'] -> Class['deployment::udb3::apidoc']
    }
    if $with_uitpas {
      realize Apt::Source['cultuurnet-udb3-uitpas']
      realize Profiles::Apt::Update['cultuurnet-udb3-uitpas']

      contain deployment::udb3::uitpas

      Profiles::Apt::Update['cultuurnet-udb3-uitpas'] -> Class['deployment::udb3::uitpas']
    }
    if $with_search {
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
