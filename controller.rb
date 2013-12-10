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
        @debug_flag = true
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

    def update_backup name, image, region_id, path
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        set_client_data "DOBA", Type::SRV_NAME
        set_client_data image, Type::IMG_ID
        set_client_data region_id, Type::REG_ID     
        set_client_data @database.return_key( @user_info[ "user_id"]), Type::SSH_KEY
        
        directory = Dir_model.new( Dir.home())
        size = directory.filesize path
      
        current_size = name[3].to_i
        current_size = current_size + size 

        if @debug_flag == true
            puts "size of droplet = #{current_size}" 
        end

        do_api = Api_model.new @client
        size = do_api.calculate_size current_size
       
        #network error catch 
        if size == "network error"
            #network flag
            return "network error"
        elsif size == 0
            #filesize too large
        end

        size = size[ "id"]
        set_client_data size, Type::SIZE_ID
        do_api = Api_model.new @client
        new_droplet = do_api.createdrp

        if @debug_flag == true
            puts "droplet created" 
        end
        
        #network error catch 
        if new_droplet == "network error"
            #network flag
            return "network error"
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
                    return "network error"
                end
                
                is_active = is_active["droplet"]
                if is_active["status"] == "active"
                    if !(File.exist?("./mnt"))
                        Dir.new "./mnt"
                    end
                   
                    ip = is_active["ip_address"]
                    ip = ip.to_s
                    sshfs = "sshfs -o StrictHostKeyChecking=no root@#{ip}:/ ./mnt"
                    sshfs_test = system "#{sshfs}" 
                    while sshfs_test != true
                        if sshfs_test == false
                            sshfs_test = nil
                            sshfs_test = system "#{sshfs}" 
                        end
                    end
        
                    pn = Pathname.new "./mnt"
                    while !pn.mountpoint?
                    end
                    
                    if @debug_flag == true
                        puts "droplet mounted" 
                    end
                    
                    if !(File.exist?("./mnt/home/backup"))
                        system "mkdir ./mnt/home/backup"
                    end
            
                    tar = "tar czf \"#{name[1]}.tar.gz\" --exclude=\"#{name[1]}.tar.gz\" --exclude=\"./mnt\" #{path}"
                    system "#{tar}"
                   
                    #mnt = "mkdir ./mnt/home/backup/\"#{name[1]}\""
                    #system "#{mnt}"
                    dt = DateTime.now
                    dt = dt.to_s
                    dt = dt.gsub(/[^0-9a-z]/i,"")
                    rsy = "rsync --progress "
                    cpy = "#{rsy}\"#{name[1]}.tar.gz\" mnt/home/backup/\"#{name[1]}\"/\"#{name[1]}#{dt}.tar.gz\""
                    #cpy = "cp ./\"#{name[1]}.tar.gz\" ./mnt/home/backup/\"#{name[1]}\"/\"#{name[1]}#{dt}.tar.gz\""
                    copy_timer = system "#{cpy}"
                    while !copy_timer
                    end
                    
                    if @debug_flag == true
                        puts "backup copied" 
                    end
                    
                    system "umount ./mnt"
                    droplet_off = do_api.poweroff
                    
                    #network error catch 
                    if droplet_off == "network error"
                        #network flag
                        return "network error"
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
                                return "network error"
                            end

                            if @debug_flag == true
                                puts "droplet powering off"
                            end

                            power_finished = power_finished["droplet"]
                            if power_finished[ "status"] == "off"
                            
                                if @debug_flag == true
                                    puts "droplet powered off"
                                end

                                @snap_name_build = "#{name[0]} #{name[1]} #{name[2]} #{current_size}"
                                @snap_name_built = URI.escape( @snap_name_build)
                                take_snap = do_api.snpshot @snap_name_built
                                
                                #network error catch 
                                if take_snap == "network error"
                                    #network flag
                                    return "network error"
                                end
                            
                                if @debug_flag == true
                                    puts "snapshot requested"
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
                                return "network error"
                            end
                            
                            if @debug_flag == true
                                puts "checking for snapshot"
                            end

                            snap_finished = snap_finished["images"]
                            snap_finished.each do |snap|
                                if snap[ "name"] == @snap_name_build
                                    
                                    if @debug_flag == true
                                        puts "snapshot finished"
                                    end
    
                                    destroyed = false
                                    while destroyed == false
                                        destr_drop = do_api.dstrydrp
                            
                                        #network error catch 
                                        if destr_drop == "network error"
                                            #network flag
                                            return "network error"
                                        end
                            
                                        if @debug_flag == true
                                            puts "attempting to destroy droplet"
                                        end
    
                                        server_destroyed = do_api.droplets
                                        
                                        #network error catch 
                                        if server_destroyed == "network error"
                                            #network flag
                                            return "network error"
                                        end

                                        server_destroyed = server_destroyed[ "droplets"]
                                        found = false
                                        server_destroyed.each do |drop|
                                            if drop[ "name"] == "DOBA" 
                                                found = true 
                                            end
                                        end
                                        if found == false
                                            if @debug_flag == true
                                                puts "droplet destroyed"
                                            end
                                            destroyed = true 
                                        end
                                    end
                                    @snap_timer = 1
                                end                                    
                            end
                            @snap_count = 0
                        end
                    end

                    image_destroyed = do_api.delete_img image
                    #network error catch 
                    if image_destroyed == "network error"
                        #network flag
                        return "network error"
                    end
                    
                    system "rm \"#{name[1]}.tar.gz\""
                    if @debug_flag == true
                        puts "local tar destroyed"
                    end
                    @active = 1
                end
                @count = 0
            end
        end
    end

    def create_backup name, image, region_id, region_name, path
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        set_client_data "DOBA", Type::SRV_NAME
        set_client_data image, Type::IMG_ID
        set_client_data region_id, Type::REG_ID     
        set_client_data @database.return_key( @user_info[ "user_id"]), Type::SSH_KEY
        
        directory = Dir_model.new( Dir.home())
        size = directory.filesize path
        do_api = Api_model.new @client
        size = do_api.calculate_size size
       
        #network error catch 
        if size == "network error"
            #network flag
            return "network error"
        elsif size == 0
            #filesize too large
        end
        
        size = size[ "id"]
        set_client_data size, Type::SIZE_ID
        do_api = Api_model.new @client
        new_droplet = do_api.createdrp

        if @debug_flag == true
            puts "droplet created" 
        end
        
        #network error catch 
        if new_droplet == "network error"
            #network flag
            return "network error"
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
                    return "network error"
                end
                
                is_active = is_active["droplet"]
                if is_active["status"] == "active"
                    if !(File.exist?("./mnt"))
                        Dir.new "./mnt"
                    end
                   
                    ip = is_active["ip_address"]
                    ip = ip.to_s
                    sshfs = "sshfs -o StrictHostKeyChecking=no root@#{ip}:/ ./mnt"
                    sshfs_test = system "#{sshfs}" 
                    while sshfs_test != true
                        if sshfs_test == false
                            sshfs_test = nil
                            sshfs_test = system "#{sshfs}" 
                        end
                    end
        
                    pn = Pathname.new "./mnt"
                    while !pn.mountpoint?
                    end
                    
                    if @debug_flag == true
                        puts "droplet mounted" 
                    end
                    
                    if !(File.exist?("./mnt/home/backup"))
                        system "mkdir ./mnt/home/backup"
                    end
            
                    tar = "tar czf \"#{name}.tar.gz\" --exclude=\"#{name}.tar.gz\" --exclude=\"./mnt\" #{path}"
                    system "#{tar}"
                   
                    @size_of_snap = File.size "#{name}.tar.gz"
                    @size_of_snap = 5000000000 + @size_of_snap 
 
                    mnt = "mkdir ./mnt/home/backup/\"#{name}\""
                    system "#{mnt}"
                    dt = DateTime.now
                    dt = dt.to_s
                    dt = dt.gsub(/[^0-9a-z]/i,"")
                    rsy = "rsync --progress "
                    cpy = "#{rsy} \"#{name}.tar.gz\" mnt/home/backup/\"#{name}\"/\"#{name}#{dt}.tar.gz\""
                    #cpy = "cp ./\"#{name}.tar.gz\" ./mnt/home/backup/\"#{name}\"/\"#{name}#{dt}.tar.gz\""
                    copy_timer = system "#{cpy}"
                    while !copy_timer
                    end
                    
                    if @debug_flag == true
                        puts "backup copied" 
                    end
                    
                    system "umount ./mnt"
                    droplet_off = do_api.poweroff
                    
                    #network error catch 
                    if droplet_off == "network error"
                        #network flag
                        return "network error"
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
                                return "network error"
                            end

                            if @debug_flag == true
                                puts "droplet powered off"
                            end

                            power_finished = power_finished["droplet"]
                            if power_finished[ "status"] == "off"
                                @snap_name_build = "DOBA: #{name} #{region_name} #{@size_of_snap}"
                                @snap_name_built = URI.escape( @snap_name_build)
                                take_snap = do_api.snpshot @snap_name_built
                                
                                #network error catch 
                                if take_snap == "network error"
                                    #network flag
                                    return "network error"
                                end
                            
                                if @debug_flag == true
                                    puts "snapshot requested"
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
                                return "network error"
                            end
                            
                            if @debug_flag == true
                                puts "checking for snapshot"
                            end

                            snap_finished = snap_finished["images"]
                            snap_finished.each do |snap|
                                if snap[ "name"] == @snap_name_build
                                    
                                    if @debug_flag == true
                                        puts "snapshot finished"
                                    end
    
                                    destroyed = false
                                    while destroyed == false
                                        destr_drop = do_api.dstrydrp
                            
                                        #network error catch 
                                        if destr_drop == "network error"
                                            #network flag
                                            return "network error"
                                        end
                            
                                        if @debug_flag == true
                                            puts "attempting to destroy droplet"
                                        end
    
                                        server_destroyed = do_api.droplets
                                        
                                        #network error catch 
                                        if server_destroyed == "network error"
                                            #network flag
                                            return "network error"
                                        end

                                        server_destroyed = server_destroyed[ "droplets"]
                                        found = false
                                        server_destroyed.each do |drop|
                                            if drop[ "name"] == "DOBA" 
                                                found = true 
                                            end
                                        end
                                        if found == false
                                            if @debug_flag == true
                                                puts "droplet destroyed"
                                            end
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
                    if @debug_flag == true
                        puts "local tar destroyed"
                    end
                    @active = 1
                end
                @count = 0
            end
        end
    end

                #create server
                #mount server

    def server_restore image, region_id, restore_size
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        set_client_data "DOBA", Type::SRV_NAME
        set_client_data image, Type::IMG_ID
        set_client_data region_id, Type::REG_ID     
        set_client_data @database.return_key( @user_info[ "user_id"]), Type::SSH_KEY
      
        restore_size = restore_size.to_i 
        do_api = Api_model.new @client
        size = do_api.calculate_size restore_size
       
        #network error catch 
        if size == "network error"
            #network flag
            return "network error"
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
            return "network error"
        end

        if @debug_flag == true
            puts "droplet created" 
        end

        new_droplet = new_droplet["droplet"]
        set_client_data new_droplet["id"], Type::DRP_NUM
        set_client_data "my_images", Type::IMG_FLTR
        @recover_api = Api_model.new @client

        @count = 0
        @active = 0
        while @active == 0 
            @count = @count + 1
            if @count == 110000000
                is_active = @recover_api.drp_status
               
                #puts is_active 
                #network error catch 
                if is_active == "network error"
                    #network flag
                    return "network error"
                end
                
                is_active = is_active["droplet"]
                if is_active["status"] == "active"
                
                if @debug_flag == true
                    puts "active server" 
                end
                    
                    if !(File.exist?("./mnt"))
                        Dir.new "./mnt"
                    end
                   
                    if @debug_flag == true
                        puts "trying to mount" 
                    end
                    
                    ip = is_active["ip_address"]
                    ip = ip.to_s
                    sshfs = "sshfs -o StrictHostKeyChecking=no root@#{ip}:/ ./mnt"
                    sshfs_test = system "#{sshfs}" 
                    while sshfs_test != true
                        if sshfs_test == false
                            sshfs_test = nil
                            sshfs_test = system "#{sshfs}" 
                        end
                    end
    
                    pn = Pathname.new "./mnt"
                    while !pn.mountpoint?
                    end
                    
                    if @debug_flag == true
                        puts "droplet mounted" 
                    end
                    @active = 1
                end
                @count = 0
            end
        end
        return new_droplet["id"]
    end

    def download_data recover_server_id, path
        puts "recovering"
        
        rsy = "rsync --progress "
        cpy = "#{rsy}#{path} backup/"
        copy_timer = system "#{cpy}"
        while !copy_timer
        end
    
        if @debug_flag == true
            puts "backup downloaded" 
        end

        system "umount ./mnt"
        destr_drop = @recover_api.dstrydrp

        #network error catch 
        if destr_drop == "network error"
            #network flag
            puts "dstry broke"
            return "network error"
        end

        if @debug_flag == true
            puts "attempting to destroy droplet"
        end

        server_destroyed = @recover_api.droplets
        
        #network error catch 
        if server_destroyed == "network error"
            #network flag
            return "network error"
        end

        server_destroyed = server_destroyed[ "droplets"]
        found = false
        destroyed = false
        while destroyed == false 
            server_destroyed.each do |drop|
                if drop[ "name"] == "DOBA" 
                    found = true 
                end
            end
            if found == false
                if @debug_flag == true
                    puts "droplet destroyed"
                end
                destroyed = true 
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
        if images == "network error"
            #network flag
            return "network error"
        end
        images
    end

    def print_regions
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        regions = model.regions
        #network error catch 
        if regions == "network error"
            #network flag
            return "network error"
        end
        regions
    end

    def print_drpsizes
        set_client_data @user_info[ "client_id"], Type::CLIENT
        set_client_data @user_info[ "api_key"], Type::API_KEY
        model = Api_model.new @client
        sizes = model.drpsizes
        #network error catch 
        if sizes == "network error"
            #network flag
            return "network error"
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
        if key_id == "network error"
            #network flag
            return "network error"
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
    
    def create_mntdir_view
        directory = Dir_model.new( "./mnt/home/backup")
    end
    
end

Controller.new
