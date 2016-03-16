require 'rest_client'
require 'open-uri'
require 'uri'
require 'cgi'
require 'yaml'
require 'rake'
require 'erb'
require 'json'

module Aem::Deploy


  class Session
    attr_reader :host, :user, :pass, :retry

    def initialize(host,user,pass, options = {})
      @host = host
      @user = user
      @password = CGI.escape(pass)
      @retry ||= options[:retry]
    end

    # Install latest package to CMS
    def install_package(package_path)
      binding.pry
      upload = RestClient.post("http://#{@user}:#{@pass}@#{@host}/crx/packmgr/service/.json", :cmd => 'upload', :package => File.new(package_path, 'rb'), :timeout => 300)
      parse_response(upload)
      upload_path = JSON.parse(upload)["path"]
      install = RestClient.post("http://#{user}:#{pass}@#{host}/crx/packmgr/service/.json#{upload_path}", :cmd => 'install', :timeout => 300)
      parse_response(install)
    rescue RestClient::RequestTimeout => error
      if @tries?
        retry unless (@tries -= 1).zero?
      end
      return {msg: error.to_s}.to_json
    end

    # Recompiles JSPs on CMS
    def recompile_jsps(host,user,pass)
      begin
        RestClient.post "http://#{user}:#{encoded_pass}@#{host}/system/console/slingjsp", :cmd => 'recompile', :timeout => 120
      rescue RestClient::Found => error
        return {msg: error.to_s}.to_json
      rescue RestClient::RequestTimeout => error
        puts 'We had to retry recompiling JSPs. Might want to check it out'
        retry unless (tries -= 1).zero?
        return {msg: error.to_s}.to_json
      end
    end

    # Checks response of any request to CMS. Breaks script if unexpected response.
    def parse_response(message)
      if JSON.parse(message)['success'] == true
        puts "  #{message}"
      elsif JSON.parse(message)['msg'].include?("Package already exists")
        puts "  #{message}"
      elsif message.include? ("302 Found")
        puts '  JSPs Recompiled'
      else
        puts "  Something is wroning the script with response of #{JSON.parse(message)}"
      end
    end
  end
end
