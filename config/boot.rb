ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)
ENV["PATH"] = [ File.dirname(RbConfig.ruby), ENV["PATH"], "/usr/bin", "/bin" ].compact.uniq.join(":")

require "bundler/setup" # Set up gems listed in the Gemfile.
