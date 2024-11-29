if ENV['START_SIMPLECOV'].to_i == 1
  require 'simplecov'
  SimpleCov.start do
    add_filter "#{File.basename(File.dirname(__FILE__))}/"
  end
end
require 'rspec'
require 'tins/xt/expose'
begin
  require 'debug'
rescue LoadError
end
require 'documentrix'

def asset(name)
  File.join(__dir__, 'assets', name)
end

RSpec.configure do |config|
  config.before(:suite) do
    infobar.show = nil
  end
end
