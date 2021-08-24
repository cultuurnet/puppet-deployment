class deployment::projectaanvraag (
  $with_rabbitmq             = true,
  $with_silex                = true,
  $with_angular              = true,
  $with_widgetbeheer_angular = true
){
  include ::profiles::apt::keys

  @apt::source { 'cultuurnet-projectaanvraag':
    location => "http://apt.uitdatabank.be/projectaanvraag-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-projectaanvraag':
    require => Apt::Source['cultuurnet-projectaanvraag']
  }

  @apt::source { 'cultuurnet-widgetbeheer':
    location => "http://apt.uitdatabank.be/widgetbeheer-${environment}",
    release  => $facts['lsbdistcodename'],
    repos    => 'main',
    require  => Class['profiles::apt::keys'],
    include  => {
      'deb' => true,
      'src' => false
    }
  }

  @profiles::apt::update { 'cultuurnet-widgetbeheer':
    require => Apt::Source['cultuurnet-widgetbeheer']
  }

  if $with_rabbitmq {
    contain deployment::projectaanvraag::rabbitmq
  }

  unless $facts['noop_deploy'] == 'true' {
    if $with_silex {
      realize Apt::Source['cultuurnet-projectaanvraag']
      realize Profiles::Apt::Update['cultuurnet-projectaanvraag']

      contain deployment::projectaanvraag::silex

      Profiles::Apt::Update['cultuurnet-projectaanvraag'] -> Class['deployment::projectaanvraag::silex']

      if $with_rabbitmq {
        Class['deployment::projectaanvraag::rabbitmq'] -> Class['deployment::projectaanvraag::silex']
      }
    }
    if $with_angular {
      realize Apt::Source['cultuurnet-projectaanvraag']
      realize Profiles::Apt::Update['cultuurnet-projectaanvraag']

      contain deployment::projectaanvraag::angular

      Profiles::Apt::Update['cultuurnet-projectaanvraag'] -> Class['deployment::projectaanvraag::angular']
    }
    if $with_widgetbeheer_angular {
      realize Apt::Source['cultuurnet-widgetbeheer']
      realize Profiles::Apt::Update['cultuurnet-widgetbeheer']

      contain deployment::widgetbeheer::angular

      Profiles::Apt::Update['cultuurnet-projectaanvraag'] -> Class['deployment::widgetbeheer::angular']
    }
  }
}
