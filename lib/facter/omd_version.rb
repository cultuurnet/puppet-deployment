require_relative 'util/cultuurnetapps.rb'

Facter.add('omd_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'omd'
  end
end
