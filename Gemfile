source "https://rubygems.org"

    gem "fastlane"
    gem "cocoapods"

    plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'pluginfile')
    eval(File.read(plugins_path), binding) if File.exist?(plugins_path)

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
