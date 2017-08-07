require_relative 'util/cultuurnetapps.rb'

Facter.add('newsletter_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'newsletter'
  end
end
