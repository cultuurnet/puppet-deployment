require_relative 'util/cultuurnetapps.rb'

prefix = File.basename( __FILE__, '_version.rb' )

Facter.add("#{prefix}_version") do
  setcode do
    Facter::Util::CultuurNetApps.get_version prefix
  end
end
