require_relative 'util/cultuurnetapps.rb'

Facter.add('projectaanvraag_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'projectaanvraag'
  end
end
