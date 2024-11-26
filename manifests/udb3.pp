class deployment::udb3 (
  $with_entry_api         = true,
  $with_jwtprovider       = true
){

  unless $facts['noop_deploy'] == 'true' {
    if $with_entry_api {
      contain deployment::udb3::entry_api
    }
    if $with_jwtprovider {
      contain deployment::udb3::jwtprovider
    }
  }
}
