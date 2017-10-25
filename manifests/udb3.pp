class deployment::udb3 {

  contain deployment::udb3::rabbitmq

  unless $noop_deploy {
    contain deployment::udb3::silex
    contain deployment::udb3::angular
    contain deployment::udb3::cdbxml
    contain deployment::udb3::jwtprovider
    contain deployment::udb3::swagger
    contain deployment::udb3::uitpas
    contain deployment::udb3::search
    contain deployment::udb3::iis
  }
}
