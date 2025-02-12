class deployment::udb3 (
  $with_entry_api         = true
){

  unless $facts['noop_deploy'] == 'true' {
    if $with_entry_api {
      contain deployment::udb3::entry_api
    }
  }
}
