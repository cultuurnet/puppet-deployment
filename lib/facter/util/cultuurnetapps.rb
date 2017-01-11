module Facter
  module Util
    module CultuurNetApps
      def self.get_version(prefix)
        command = "dpkg-query -f='\$\{binary:Package\}:\$\{Version\}\\n' -W '#{prefix}*' 2> /dev/null"
        versions = Facter::Core::Execution.execute(command)

        return nil if versions.empty?

        versions.split("\n").inject({}) do |result, string|
          component = string[/(.*):/,1]
          version = string[/:(.*)$/,1]
          commit = version[/\+sha.(.*)$/,1]

          version_hash = { 'version' => version, 'commit' => commit }.reject { |k, v| v.nil? }
          result.merge({ component => version_hash })
        end
      end
    end
  end
end
