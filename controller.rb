#!/usr/bin/env ruby
require_relative 'api_model'
require_relative 'dir_model'
require_relative 'db_model'
require 'pathname'

class Type
    CLIENT      = 1
    API_KEY     = 2
    DRP_NUM     = 3
    SRV_NAME    = 4
    SIZE_ID     = 5
    IMG_ID      = 6
    REG_ID      = 7
    IMG_FLTR    = 8
    SSH_KEY     = 9
end

class Controller

    def initialize
        @database   = Db_model.new
        @user_info  = nil
        @client     = { "client_id"   =>  "", 
                        "api_key"     =>  "", 
                        "drp_num"     =>  0, 
                        "srv_name"    =>  "", 
                        "size_id"     =>  0, 
                        "img_id"      =>  0, 
                        "reg_id"      =>  0, 
                        "img_fltr"    =>  "",
                        "ssh_key"     =>  ""}
                

    end

    def set_client_data obj_data, obj_type
        case obj_type
            when Type::CLIENT
                @client[ "client_id"]   = obj_data
            when Type::API_KEY
                @client[ "api_key"]     = obj_data
            when Type::DRP_NUM 
                @client[ "drp_num"]     = obj_data
            when Type::SRV_NAME
                @client[ "srv_name"]    = obj_data
            when Type::SIZE_ID 
                @client[ "size_id"]     = obj_data
            when Type::IMG_ID
                @client[ "img_id"]      = obj_data
            when Type::REG_ID
                @client[ "reg_id"]      = obj_data
            when Type::IMG_FLTR
                @client[ "img_fltr"]    = obj_data
            when Type::SSH_KEY
                @client[ "ssh_key"]     = obj_data
        end 
    end 

    def create_backup name, image, region, path
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        set_client_data "doba", Type::SRV_NAME
        set_client_data image, Type::IMG_ID
        set_client_data region, Type::REG_ID     
        set_client_data @database.return_key( @user_info[ "user_id"]), Type::SSH_KEY
        
        directory = Dir_model.new( Dir.home())
        size = directory.filesize path
        do_api = Api_model.new @client
        size = do_api.calculate_size size
       
        #network error catch 
        if size == "network error"
            #network flag
        elsif size == 0
            #filesize too large
        end
        
        size = size[ "id"]
        set_client_data size, Type::SIZE_ID
        do_api = Api_model.new @client
        new_droplet = do_api.createdrp
        
        #network error catch 
        if new_droplet == "network error"
            #network flag
        end

        new_droplet = new_droplet["droplet"]
        set_client_data new_droplet["id"], Type::DRP_NUM
        set_client_data "my_images", Type::IMG_FLTR
        do_api = Api_model.new @client
        
        @count = 0
        @active = 0
        while @active == 0 
            @count = @count + 1
            if @count == 110000000
                is_active = do_api.drp_status
                
                #network error catch 
                if is_active == "network error"
                    #network flag
                end
                
                is_active = is_active["droplet"]
                if is_active["status"] == "active"
                    if !(File.exist?("./mnt"))
                        Dir.new "./mnt"
                    end
                   
                    ip = is_active["ip_address"]
                    ip = ip.to_s
                    sshfs = "sshfs -o StrictHostKeyChecking=no root@#{ip}:/ ./mnt"
                    sshfs_test = system "#{sshfs} > /dev/null"
                    while sshfs_test != true
                        if sshfs_test == false
                            sshfs_test = system "#{sshfs} > /dev/null"
                        end
                    end

                    pn = Pathname.new "./mnt"
                    while !pn.mountpoint?
                    end
                    
                    if !(File.exist?("./mnt/home/backup"))
                        system "mkdir ./mnt/home/backup"
                    end
            
                    tar = "tar czf \"#{name}.tar.gz\" --exclude=\"#{name}.tar.gz\" --exclude=\"./mnt\" #{path}"
                    system "#{tar} > /dev/null"
                    mnt = "mkdir ./mnt/home/backup/\"#{name}\""
                    system "#{mnt}"
                    dt = DateTime.now
                    cpy = "cp \"./#{name}.tar.gz\" ./mnt/home/backup/\"#{name}\"/\"#{name}#{dt}.tar.gz\""
                    copy_timer = system "#{cpy} > /dev/null"
                    while !copy_timer
                    end
                    
                    size_of_snap = system "du -ch 2> /dev/null | grep total"
                    while !size_of_snap
                    end    
    
                    system "umount ./mnt"
                    droplet_off = do_api.poweroff

                    #network error catch 
                    if droplet_off == "network error"
                        #network flag
                    end

                    @power_timer = 0
                    @power_count = 0
                    while @power_timer == 0
                        @power_count = @power_count + 1
                        if @power_count == 110000000 
                            power_finished = do_api.drp_status
                    
                            #network error catch 
                            if power_finished == "network error"
                                #network flag
                            end

                            power_finished = power_finished["droplet"]
                            if power_finished[ "status"] == "off"
                                @snapshot_name = "DOBA: #{name} #{regionname} #{snapshot_size}"
                                take_snap = do_api.snpshot @snapshot_name
                                
                                #network error catch 
                                if take_snap == "network error"
                                    #network flag
                                end

                                @power_timer = 1
                            end                                    
                        end
                    end  

                    @snap_timer = 0
                    @snap_count = 0 
                    while @snap_timer == 0 
                        @snap_count = @snap_count + 1
                        if @snap_count == 110000000
                            snap_finished = do_api.images
                            
                            #network error catch 
                            if snap_finished == "network error"
                                #network flag
                            end
    
                            snap_finished = snap_finished["images"]
                            snap_finished.each do |snap|
                                if snap[ "name"] == name
                                    destroyed == false
                                    while destroyed == false
                                        destr_drop = do_api.dstrydrp
                            
                                        #network error catch 
                                        if destr_drop == "network error"
                                            #network flag
                                        end
    
                                        server_destroyed = do_api.droplets
                                        
                                        #network error catch 
                                        if server_destroyed == "network error"
                                            #network flag
                                        end

                                        server_destroyed = server_destroyed[ "droplets"]
                                        found = false
                                        server_destoryed.each do |drop|
                                            if drop[ "name"] == @snapshot_name
                                                found = true 
                                            end
                                        end
                                        if found == false
                                            destroyed = true 
                                        end
                                    end
                                    @snap_timer = 1
                                end                                    
                            end
                            @snap_count = 0
                        end
                    end
                    
                    system "rm \"#{name}.tar.gz\""
                    @active = 1
                end
                @count = 0
            end
        end
    end

    def print_images image_type
        set_client_data image_type, Type::IMG_FLTR
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        images = model.images     
        #network error catch 
        if new_droplet == "network error"
            #network flag
        end
    end

    def print_regions
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        regions = model.regions
        #network error catch 
        if new_droplet == "network error"
            #network flag
        end
    end

    def print_drpsizes
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        sizes = model.drpsizes
        #network error catch 
        if new_droplet == "network error"
            #network flag
        end
    end

    def user_exist user_name
        @database.user_exist user_name
    end

    def key_exist 
        @database.key_exist @user_info[ "user_id"]
    end
        
    def add_key
        system( "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa > /dev/null")
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        public_key = File.read "#{ENV['HOME']}/.ssh/id_rsa.pub"
        model = Api_model.new @client
        public_key = public_key.gsub " ", "%20" 
        public_key = public_key.gsub "+", "%2B"
        public_key = public_key.delete "\n"
        key_id = model.add_key public_key, @user_info[ "user_name"]
        #network error catch 
        if new_droplet == "network error"
            #network flag
        end
        key_id = key_id[ "ssh_key"]
        key_id = key_id[ "id"]
        @database.add_key key_id, @user_info[ "user_id"]
    end 
    
    def create_user user_name, password, api_key, client_id
        @user_info = @database.create_user user_name, password, api_key, client_id
    end

    def sign_in user_name, password
        @user_info = @database.sign_in user_name, password
        if @user_info != nil
            return true
        end
        return false
    end
    
    def sign_out
        @user_info = nil 
    end

    def create_dir_view
        directory = Dir_model.new( Dir.home())
    end
    
end

Controller.new
