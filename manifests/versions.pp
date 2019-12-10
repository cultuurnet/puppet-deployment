define deployment::versions (
  $project,
  $packages = [],
  $destination_dir = '/var/www',
  $noop_deploy = false,
  $puppetdb_url = undef
) {

  contain deployment

  any2array($packages).each |$package| {
    if $puppetdb_url {
      exec { "update_facts for ${package} package":
        command     => "/usr/local/bin/update_facts -p ${puppetdb_url}",
        subscribe   => Package[$package],
        refreshonly => true,
        noop        => $noop_deploy
      }
    }

    exec { "update versions endpoint for package ${package}":
      command     => "/opt/puppetlabs/bin/facter -pj ${project}_version | /usr/bin/jq '.[\"${project}_version\"]' > ${destination_dir}/versions.${project}",
      subscribe   => Package[$package],
      refreshonly => true,
      noop        => $noop_deploy
    }

    exec { "update versions.${package} endpoint for package ${package}":
      command     => "/opt/puppetlabs/bin/facter -pj ${project}_version.${package} | /usr/bin/jq '.[\"${project}_version.${package}\"]' > ${destination_dir}/versions.${project}.${package}",
      subscribe   => Package[$package],
      refreshonly => true,
      noop        => $noop_deploy
    }
  }
}
