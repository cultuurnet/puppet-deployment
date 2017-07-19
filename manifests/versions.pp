define deployment::versions (
  $project,
  $packages = [],
  $destination_dir = '/var/www',
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
      command     => "/usr/local/bin/get_fact_value ${project}_version > ${destination_dir}/versions.${project}",
      subscribe   => Package[$package],
      require     => Class['deployment'],
      refreshonly => true,
      noop        => $noop_deploy
    }

    exec { "update versions.${package} endpoint for package ${package}":
      command     => "/usr/local/bin/get_fact_value ${project}_version.${package} > ${destination_dir}/versions.${package}",
      subscribe   => Package[$package],
      require     => Class['deployment'],
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
