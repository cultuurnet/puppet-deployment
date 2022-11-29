class deployment::udb3 (
  $with_entry_api         = true,
  $with_angular           = true,
  $with_frontend          = false,
  $with_jwtprovider       = true,
  $with_search            = true,
  $with_movie_api_fetcher = true
){

  unless $facts['noop_deploy'] == 'true' {
    if $with_entry_api {
      contain deployment::udb3::entry_api
    }
    if $with_angular {
      contain deployment::udb3::angular
    }
    if $with_frontend {
      contain deployment::udb3::frontend
    }
    if $with_jwtprovider {
      contain deployment::udb3::jwtprovider
    }
    if $with_search {
      contain deployment::udb3::search
    }
    if $with_movie_api_fetcher {
      contain deployment::udb3::movie_api_fetcher
    }
  }
}
