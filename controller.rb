#!/usr/bin/env ruby
require_relative 'api_model'
require_relative 'dir_model'
require_relative 'db_model'
require 'json'
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
        puts path
        @allfiles = directory.all_files path 
        do_api = Api_model.new @client
        size = do_api.calculate_size size
        size = size[ "id"]
        set_client_data size, Type::SIZE_ID
        do_api = Api_model.new @client
        res = do_api.createdrp
        res = JSON.parse res.body
        puts res
        res = res["droplet"]
        puts res
        #puts res["id"]
        set_client_data res["id"], Type::DRP_NUM
        set_client_data "my_images", Type::IMG_FLTR
        do_api = Api_model.new @client
        @count = 0
        @active = 0
        while @active == 0 
            @count = @count + 1
            if @count == 110000000
                is_active = do_api.drp_status
                is_active = JSON.parse is_active.body 
                is_active = is_active["droplet"]
                if is_active["status"] == "active"
                    if !(File.exist?("./mnt"))
                        Dir.new "./mnt"
                    end
                    #puts "sshfs -o StrictHostKeyChecking=no root@#{is_active["ip_address"]}:/ ./mnt"
                    #`sshfs -o StrictHostKeyChecking=no root@#{is_active["ip_address"]}:/ ./mnt`
                    ip = is_active["ip_address"]
                    ip = ip.to_s
                    #puts ip
                    #puts "sshfs"
                    sshfs = "sshfs -o StrictHostKeyChecking=no -o sshfs_debug -o reconnect root@#{ip}:/ ./mnt"
                     
                    systest = system "#{sshfs}"
                    #while systest == false
                    #    puts "test"
                    #end
                    while systest != true
                        if systest == false
                            systest = system "#{sshfs}"
                        end
                    end

                    @mountcount = 0 
                    while @mountcount < 100000000 
                        @mountcount = @mountcount + 1
                    end
                    
                    pn = Pathname.new "./mnt"
                    while !pn.mountpoint?
                    end
                    #temper = `ls ./mnt`
                    #puts temper
                    if !(File.exist?("./mnt/home/backup"))
                        system "mkdir ./mnt/home/backup"
                    end
            
                    #mount_fuldir = Dir.pwd + "/mnt"
                   
                    #system "tar -cf #{name} --exclude=#{mount_fuldir} #{path}"
                    system "tar czf \"#{name}.tar.gz\" --exclude=\"#{name}.tar.gz\" --exclude=\"./mnt\" #{path}"
                    system "mkdir ./mnt/home/backup/\"#{name}\""
                    dt = DateTime.now
                    t = system "cp \"./#{name}.tar.gz\" ./mnt/home/backup/\"#{name}\"/\"#{name}#{dt}.tar.gz\""
                    while !t
                    end
                    
                    system "umount ./mnt"
                    do_api.poweroff
                        
                    @power_timer = 0
                    @power_count = 0
                    while @power_timer == 0
                        @power_count = @power_count + 1
                        if @power_count == 110000000 
                            power_finished = do_api.drp_status
                            power_finished = JSON.parse power_finished.body 
                            power_finished = power_finished["droplet"]
                            if power_finished[ "status"] == "off"
                                do_api.snpshot name
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
                            snap_finished = JSON.parse snap_finished.body 
                            snap_finished = snap_finished["images"]
                            snap_finished.each do |snap|
                                #puts snap[ "name"]
                                if snap[ "name"] == name
                                    res = do_api.dstrydrp
                                    puts res.body
                                    @snap_timer = 1
                                end                                    
                            end
                            @snap_count = 0
                        end
                    end
                    system "rm \"#{name}.tar.gz\""

                    #do_api.
                    #system "cd ./mnt/home/backup/\"#{name}\" | tar xzf \"#{name}.tar.gz\""
                     
 
=begin
                    system "find #{Dir.home()} 
                            -mindepth 1 
                            -maxdepth 1 
                            -name 'mnt' 
                            -or 
                            -exec cp 
                            -r {} #{path} \;"
=end
    
=begin
                    @copytimer = 0    
                    @allfiles.each do |dirpath|
                        copy = system "gcp --parents \"#{dirpath}\" \"./mnt/home/backup#{dirpath}\""
                        while !copy
                            @copytimer = @copytimer + 1
                        end
                        puts "took " + @copytimer + " cycles to copy " + dirpath
                        puts " "
                        @copytimer = 0 
                    end

                    if FileTest.directory? path     
                        test = system "cp -r #{path}/* ./mnt/home/backup" 
                    else
                        test = system "cp #{path} ./mnt/home/backup" 
                    end
                    
                    while !test                    
                    end    
=end

                    #confirm = `ls ./mnt/home/backup`
                    #puts confirm
                    
                    @active = 1
                end
                @count = 0
            end
        end
        puts "finished"
    end

    def print_images image_type
        set_client_data image_type, Type::IMG_FLTR
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        images = model.images     
        res = JSON.parse images.body 
    end

=begin    
    def print_imageinfo imageid
        set_client_data image_type, Type::IMG_FLTR
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        images = model.images     
        res = JSON.parse images.body 
    end
=end

=begin
    def print_droplets
        model = Api_model.new @client
        droplets = model.droplets
        puts droplets.body
    end
=end
    
    def print_regions
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        regions = model.regions
        res = JSON.parse regions.body 
    end

    def print_drpsizes
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        sizes = model.drpsizes
        res = JSON.parse sizes.body 
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
        res = JSON.parse key_id.body
        res = res[ "ssh_key"]
        res = res[ "id"]
        @database.add_key res, @user_info[ "user_id"]
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
