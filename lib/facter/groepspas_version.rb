require_relative 'util/cultuurnetapps.rb'

Facter.add('groepspas_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'groepspas'
  end
end
