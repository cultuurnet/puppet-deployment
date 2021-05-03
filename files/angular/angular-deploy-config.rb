#!/usr/bin/env ruby

require 'angular_config'

APPDIR = File.expand_path(ARGV[0])

def merge_config
  angular_app_package = `dpkg -S #{APPDIR}/index.html`.split(":")[0]
  original_scripts_name = `dpkg -L #{angular_app_package}`.split("\n").grep(/scripts\/scripts\..*\.js$/)[0]

  config_hashed_keys = AngularConfig::Config.load("#{APPDIR}/config.json").hash_keys
  scripts = AngularConfig::Source.load(original_scripts_name)

  md5_short = scripts.resolve(config_hashed_keys).md5[0..7]

  AngularConfig::Source.save(scripts.content, "#{APPDIR}/scripts/scripts.#{md5_short}.js")

  fix_index(md5_short)
end

def fix_index(md5)
  index = File.read("#{APPDIR}/index.html")

  index.gsub!(/scripts\/scripts\.[0-9a-f]{8}\.js/, "scripts/scripts.#{md5}.js")

  File.open("#{APPDIR}/index.html", "w") do |f|
    f.write(index)
  end
end

merge_config
