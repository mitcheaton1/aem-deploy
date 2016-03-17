require 'rest_client'
require 'open-uri'
require 'uri'
require 'cgi'
require 'json'
require 'pry'
module Aem::Deploy

  class Session
    attr_reader :host, :user, :pass, :retry, :upload_path

    def initialize(params)
      if [:host, :user, :pass].all? {|k| params.key?(k)}
        @host = params.fetch(:host)
        @user = params.fetch(:user)
        @pass = CGI.escape(params.fetch(:pass))
        @retry = params.fetch(:retry) unless params[:retry].nil?
      else
        raise 'Hostname, User and Password are required'
      end
    end

    #upload and install package
    def easy_install(package_path)
      upload_package(package_path)
      install_package
    end

    # upload package
    def upload_package(package_path)
      upload = RestClient.post("http://#{@user}:#{@pass}@#{@host}/crx/packmgr/service/.json", :cmd => 'upload', :package => File.new(package_path, 'rb'), :force => true, :timeout => 300)
      parse_response(upload)
      @upload_path = URI.encode(JSON.parse(upload)["path"])
    rescue RestClient::RequestTimeout => error
      {error: error.to_s}.to_json
      if @retry
        puts 'retrying installation as there was a problem'
        retry unless (@retry -= 1).zero?
      end
    end

    # Install package
    def install_package(options = {})
      if options[:path]
        @upload_path = options[:path]
      end
      install = RestClient.post("http://#{user}:#{pass}@#{host}/crx/packmgr/service/.json#{@upload_path}", :cmd => 'install', :timeout => 300)
      parse_response(install)
    rescue RestClient::RequestTimeout => error
      {error: error.to_s}.to_json
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
        {error: error.to_s}.to_json
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
      elsif message.include? ("302 Found")
        return '  JSPs Recompiled'
      else
        raise "  #{JSON.parse(message)}"
      end
    end
  end
end
