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
      contain deployment::projectaanvraag::silex

      if $with_rabbitmq {
        Class['deployment::projectaanvraag::rabbitmq'] -> Class['deployment::projectaanvraag::silex']
      }
    }
    if $with_angular {
      contain deployment::projectaanvraag::angular
    }
    if $with_widgetbeheer_angular {
      contain deployment::widgetbeheer::angular
    }
  }
}
