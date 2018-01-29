class deployment::udb3 (
  $with_rabbitmq          = true,
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

  if $with_rabbitmq {
    contain deployment::udb3::rabbitmq
  }

  if $environment == 'development' {
    unless $facts['noop_deploy'] == 'true' {
      if $with_silex {
        contain deployment::udb3::silex
      }
      if $with_angular {
        contain deployment::udb3::angular
      }
      if $with_cdbxml {
        contain deployment::udb3::cdbxml
      }
      if $with_jwtprovider {
        contain deployment::udb3::jwtprovider
      }
      if $with_apidoc {
        contain deployment::udb3::apidoc
      }
      if $with_uitpas {
        contain deployment::udb3::uitpas
      }
      if $with_search {
        contain deployment::udb3::search
      }
      if $with_iis {
        contain deployment::udb3::iis
      }
      if $with_movie_api_fetcher {
        contain deployment::udb3::movie_api_fetcher
      }
    }
  } else {
    if $with_silex {
      contain deployment::udb3::silex
    }
    if $with_angular {
      contain deployment::udb3::angular
    }
    if $with_cdbxml {
      contain deployment::udb3::cdbxml
    }
    if $with_jwtprovider {
      contain deployment::udb3::jwtprovider
    }
    if $with_apidoc {
      contain deployment::udb3::apidoc
    }
    if $with_uitpas {
      contain deployment::udb3::uitpas
    }
    if $with_search {
      contain deployment::udb3::search
    }
    if $with_iis {
      contain deployment::udb3::iis
    }
    if $with_movie_api_fetcher {
      contain deployment::udb3::movie_api_fetcher
    }
  }
}
