define deployment::versions (
  $project,
  $packages = [],
  $noop_deploy = false,
  $update_facts = false,
  $puppetdb_url = ''
) {

  include deployment

  any2array($packages).each |$package| {
    if $update_facts {
      exec { "update_facts for ${package} package":
        command     => "/usr/local/bin/update_facts ${puppetdb_url}",
        subscribe   => Package[$package],
        require     => Class['deployment'],
        refreshonly => true,
        noop        => $noop_deploy
      }
    }

    exec { "update versions endpoint for package ${package}":
      path        => [ '/opt/puppetlabs/bin', '/usr/bin'],
      command     => "facter -pj ${project}_version > /var/www/${project}_version",
      subscribe   => Package[$package],
      refreshonly => true,
      noop        => $noop_deploy
    }

    exec { "update versions.${package} endpoint for package ${package}":
      path        => [ '/opt/puppetlabs/bin', '/usr/bin'],
      command     => "facter -pj ${project}_version.${package} > /var/www/versions.${package}",
      subscribe   => Package[$package],
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
