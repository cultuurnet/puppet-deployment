class deployment::widgetbeheer::angular (
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  package { 'widgetbeheer-angular-app':
    ensure => 'latest',
    noop   => $noop_deploy
  }

  package { 'rubygem-nokogiri':
    ensure => 'installed'
  }

  file { 'add_text_css_type':
    ensure => 'file',
    source => 'puppet:///modules/deployment/widgetbeheer/add_text_css_type',
    path   => '/usr/local/bin/add_text_css_type',
    mode   => '0755'
  }

  exec { 'add_text_css_type':
    command     => 'add_text_css_type /var/www/widgetbeheer/index.html > /var/www/widgetbeheer/index.html',
    path        => [ '/usr/local/bin', '/usr/bin', '/bin'],
    refreshonly => true,
    require     => [ File['add_text_css_type'], Package['rubygem-nokogiri']],
    subscribe   => Package['widgetbeheer-angular-app'],
    noop        => $noop_deploy
  }

  deployment::versions { $title:
    project      => 'widgetbeheer',
    packages     => 'widgetbeheer-angular-app',
    noop_deploy  => $noop_deploy,
    update_facts => $update_facts,
    puppetdb_url => $puppetdb_url
  }
}
