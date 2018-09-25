class deployment::omd (
  $with_angular                = true,
  $with_drupal                 = true,
  $with_media_download_manager = true
){
  unless $facts['noop_deploy'] == 'true' {
    if $with_angular {
      contain deployment::omd::angular
    }
    if $with_drupal {
      contain deployment::omd::drupal
    }
    if $with_media_download_manager {
      contain deployment::omd::media_download_manager
    }
  }
}
