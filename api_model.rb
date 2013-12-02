#!/usr/bin/env ruby
require 'net/http'
require 'uri'

class Api_model

    API_HOST     = "api.digitalocean.com"
    API_BASE_URL = "https://#{API_HOST}"

    def initialize settings
        client_id           = settings[ "client_id"]
        api_key             = settings[ "api_key"]
        sizeid              = settings[ "size_id"] 
        imageid             = settings[ "img_id"] 
        regionid            = settings[ "reg_id"]
        @ssh_key            = settings[ "ssh_key"]
        @dropletnum         = settings[ "drp_num"]
        @servername         = settings[ "srv_name"]
        @images_filter      = settings[ "img_fltr"]
        @server_settings    = "&name=#{@servername}&size_id=#{sizeid}&image_id=#{imageid}&region_id=#{regionid}"
        @client_path        = "client_id=#{client_id}&api_key=#{api_key}"
    end

    def createdrp
        newdroplet_path = "/droplets/new?#{@client_path}#{@server_settings}&ssh_key_ids=#{@ssh_key}"
        returnhash newdroplet_path
    end
    
    def calculate_size sighz
        res = drpsizes
        res = JSON.parse res.body 
        res = res["sizes"]
        res.each do |size|
            if (size["disk"].to_i * 1073741824) > sighz
                return size
            end
        end
        return 0
    end

    def dstrydrp
        destroy_path = "/droplets/#{@dropletnum}/destroy/?#{@client_path}"
        returnhash destroy_path
    end

    def droplets
        droplets_path = "/droplets/?#{@client_path}"
        returnhash droplets_path
    end

    def drp_status
        drpstat_path = "/droplets/#{@dropletnum}?#{@client_path}"
        returnhash drpstat_path
    end

    def regions
        regions_path = "/regions/?#{@client_path}"
        returnhash regions_path
    end

    def drpsizes
        drpltsizes_path = "/sizes/?#{@client_path}"
        returnhash drpltsizes_path
    end

    def images
        images_path = "/images/?#{@client_path}&filter=#{@images_filter}"
        returnhash images_path
    end

    def snpshot
        snapshot_path = "/droplets/#{@dropletnum}/snapshot/?name=#{@servername}&#{@client_path}"
        returnhash snapshot_path
    end

    def add_key ssh_key, user_name
        #path = "#{API_BASE_URL}/ssh_keys/new/?name=#{user_name}&ssh_pub_key=#{ssh_key}&#{@client_path}"
        sshkey_path = "/ssh_keys/new/?name=#{user_name}&ssh_pub_key=#{ssh_key}&#{@client_path}"
        returnhash sshkey_path 
        #system( "curl '#{path}'")
        #sshkey_path = "/ssh_keys/?clien
        #https://api.digitalocean.com/ssh_keys/?client_id=[your_client_id]&api_key=[your_api_key]
    end

    def returnhash path
        uri                 = URI.parse "#{API_BASE_URL}#{path}"
        http                = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl        = true
        http.verify_mode    = OpenSSL::SSL::VERIFY_NONE
        res                 = http.get(uri.request_uri)
    end
end
