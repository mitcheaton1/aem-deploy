require "aem/deploy/version"
require "aem/deploy/session"

module Aem
  module Deploy
    # Create a new session with teh default options.
    def self.new
      Session.new
    end
  end
end
