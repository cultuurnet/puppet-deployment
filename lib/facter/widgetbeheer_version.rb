require_relative 'util/cultuurnetapps.rb'

Facter.add('widgetbeheer_version') do
  setcode do
    Facter::Util::CultuurNetApps.get_version 'widgetbeheer'
  end
end
