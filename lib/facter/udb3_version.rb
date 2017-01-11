require_relative 'util/cultuurnetapps.rb'

Facter.add('udb3_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'udb3'
  end
end
