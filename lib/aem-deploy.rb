require "aem/deploy/version"
require "aem/deploy/session"

module Aem
  module Deploy
    # Create a new session with the default options.
    def self.new(params = {})
      Session.new(params)
    end
  end
end


