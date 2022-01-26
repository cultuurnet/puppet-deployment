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

  unless $facts['noop_deploy'] == 'true' {
    if $with_silex {
      realize Apt::Source['cultuurnet-tools']
      realize Apt::Source['cultuurnet-udb3']

      contain deployment::udb3::silex

      Apt::Source['cultuurnet-tools'] -> Class['deployment::udb3::silex']
      Apt::Source['cultuurnet-udb3'] -> Class['deployment::udb3::silex']
    }
    if $with_angular {
      realize Apt::Source['cultuurnet-tools']
      realize Apt::Source['cultuurnet-udb3']

      contain deployment::udb3::angular

      Apt::Source['cultuurnet-tools'] -> Class['deployment::udb3::angular']
      Apt::Source['cultuurnet-udb3'] -> Class['deployment::udb3::angular']
    }
    if $with_angular_nl {
      realize Apt::Source['cultuurnet-tools']
      realize Apt::Source['cultuurnet-udb-nl']

      contain deployment::udb3::angular

      Apt::Source['cultuurnet-tools'] -> Class['deployment::udb3::angular']
      Apt::Source['cultuurnet-udb-nl'] -> Class['deployment::udb3::angular']
    }
    if $with_frontend {
      realize Apt::Source['cultuurnet-udb3']

      contain deployment::udb3::frontend

      Apt::Source['cultuurnet-udb3'] -> Class['deployment::udb3::frontend']
    }
    if $with_cdbxml {
      realize Apt::Source['cultuurnet-cdbxml']

      contain deployment::udb3::cdbxml

      Apt::Source['cultuurnet-cdbxml'] -> Class['deployment::udb3::cdbxml']
    }
    if $with_jwtprovider {
      realize Apt::Source['cultuurnet-jwtprovider']

      contain deployment::udb3::jwtprovider

      Apt::Source['cultuurnet-udb3'] -> Class['deployment::udb3::jwtprovider']
    }
    if $with_apidoc {
      realize Apt::Source['cultuurnet-udb3']

      contain deployment::udb3::apidoc

      Apt::Source['cultuurnet-udb3'] -> Class['deployment::udb3::apidoc']
    }
    if $with_search {
      realize Apt::Source['cultuurnet-search']

      contain deployment::udb3::search

      Apt::Source['cultuurnet-search'] -> Class['deployment::udb3::search']
    }
    if $with_iis {
      realize Apt::Source['cultuurnet-iis']

      contain deployment::udb3::iis

      Apt::Source['cultuurnet-iis'] -> Class['deployment::udb3::iis']
    }
    if $with_movie_api_fetcher {
      realize Apt::Source['cultuurnet-iis']

      contain deployment::udb3::movie_api_fetcher

      Apt::Source['cultuurnet-iis'] -> Class['deployment::udb3::movie_api_fetcher']
    }
  }
}
