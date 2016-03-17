require 'rest_client'
require 'open-uri'
require 'uri'
require 'cgi'
require 'json'
require 'pry'
module Aem::Deploy

  class Session
    attr_reader :host, :user, :pass, :retry

    def initialize(options)
      if [:host, :user, :pass].all? {|k| options.key?(k)}
        @host = options.fetch(:host)
        @user = options.fetch(:user)
        @pass = CGI.escape(options.fetch(:pass))
        @retry = options.fetch(:retry) unless options[:retry].nil?
      else
        raise 'Hostname, User and Password are required'
      end
    end

    # Install latest package to CMS
    def install_package(package_path)
      upload = RestClient.post("http://#{@user}:#{@pass}@#{@host}/crx/packmgr/service/.json", :cmd => 'upload', :package => File.new(package_path, 'rb'), :force => true, :timeout => 300)
      parse_response(upload)
      upload_path = URI.encode(JSON.parse(upload)["path"])
      install = RestClient.post("http://#{user}:#{pass}@#{host}/crx/packmgr/service/.json#{upload_path}", :cmd => 'install', :timeout => 300)
      parse_response(install)
    rescue RestClient::RequestTimeout => error
      {msg: error.to_s}.to_json
      if @retry
        puts 'retrying installation as there was a problem'
        retry unless (@retry -= 1).zero?
      end
    end

    # Recompiles JSPs on CMS
    def recompile_jsps
      begin
        RestClient.post "http://#{@user}:#{@pass}@#{@host}/system/console/slingjsp", :cmd => 'recompile', :timeout => 120
      rescue RestClient::Found => error
        return {msg: 'JSPs recompiled'}.to_json
      rescue RestClient::RequestTimeout => error
        {msg: error.to_s}.to_json
        if @retry
          puts 'retrying installation as there was a problem'
          retry unless (@retry -= 1).zero?
        end
      end
    end

    # Checks response of any request to CMS. Breaks script if unexpected response.
    def parse_response(message)
      if JSON.parse(message)['success'] == true
        return "  #{message}"
      elsif JSON.parse(message)['msg'].include?("Package already exists")
        return "  #{message}"
      elsif message.include? ("302 Found")
        return '  JSPs Recompiled'
      else
        raise "  It looks there was a problem uploading/installing the package #{JSON.parse(message)}"
      end
    end
  end
end
