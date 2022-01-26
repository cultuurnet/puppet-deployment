class deployment::projectaanvraag (
  $with_rabbitmq             = true,
  $with_silex                = true,
  $with_angular              = true,
  $with_widgetbeheer_angular = true
){
  if $with_rabbitmq {
    contain deployment::projectaanvraag::rabbitmq
  }

  unless $facts['noop_deploy'] == 'true' {
    if $with_silex {
      realize Apt::Source['cultuurnet-projectaanvraag']

      contain deployment::projectaanvraag::silex

      Apt::Source['cultuurnet-projectaanvraag'] -> Class['deployment::projectaanvraag::silex']

      if $with_rabbitmq {
        Class['deployment::projectaanvraag::rabbitmq'] -> Class['deployment::projectaanvraag::silex']
      }
    }
    if $with_angular {
      realize Apt::Source['cultuurnet-projectaanvraag']

      contain deployment::projectaanvraag::angular

      Apt::Source['cultuurnet-projectaanvraag'] -> Class['deployment::projectaanvraag::angular']
    }
    if $with_widgetbeheer_angular {
      realize Apt::Source['cultuurnet-widgetbeheer']

      contain deployment::widgetbeheer::angular

      Apt::Source['cultuurnet-projectaanvraag'] -> Class['deployment::widgetbeheer::angular']
    }
  }
}
