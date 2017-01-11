require_relative 'util/cultuurnetapps.rb'

Facter.add('balie_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'balie'
  end
end
