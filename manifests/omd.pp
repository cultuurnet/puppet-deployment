class deployment::omd (
  $with_angular                = true,
  $with_drupal                 = true,
  $with_media_download_manager = true
){

  include ::profiles::apt::keys

  apt::source { 'cultuurnet-omd':
    location => "http://apt.uitdatabank.be/omd-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  profiles::apt::update { 'cultuurnet-omd': }

  realize Profiles::Apt::Update['cultuurnet-tools']

  realize Package['drush']

  unless $facts['noop_deploy'] == 'true' {
    if $with_angular {
      contain deployment::omd::angular
    }
    if $with_drupal {
      contain deployment::omd::drupal

      Package['drush'] -> Class['deployment::omd::drupal']
    }
    if $with_media_download_manager {
      contain deployment::omd::mediadownloadmanager
    }
  }
}
