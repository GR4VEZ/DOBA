#!/usr/bin/env ruby
require_relative 'controller'
require 'gtk2'

class DobaDemo < Gtk::Window 
    def initialize
        super 

        #initializing the user class and creating the "if non existent" database
        @user = Controller.new

        #setting the properties for the root window
        set_title "DOBA"
        set_default_size 600, 400
        set_border_width 2
        set_window_position Gtk::Window::POS_CENTER
        @snapsflag = 0
        @locflag = 0
        @snapsstore = Array.new
        @locstore = Array.new

        #calling the interface function which sets the base state for root window
        interface 

        #function for killing root window when exiting
        signal_connect('delete_event') do
            Gtk.main_quit
            false
        end

        #load all visible widgets
        show_all
    end

    def interface
        #this table holds entire interface
        @main_interface = Gtk::Table.new 2, 6 
        
        #creating a frame to hold the user menu bar 
        @menuframe = Gtk::Frame.new
        menubar "loggedout"

        #creating a frame to hold the body
        @bodyframe = Gtk::Frame.new
        body "init"
       
        #adding both frames to the main interface table 
        @main_interface.attach( @menuframe, 0, 6, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0)
        @main_interface.attach( @bodyframe, 0, 6, 1, 2) 

        #adding the interface table to the root window
        add @main_interface
    end
  
    def menubar user_state
        if user_state == "loggedout"
            @menu = menu_loggedout 
            @menuframe.add @menu
            show_all
        elsif user_state == "loggedin"
            @menu = menu_loggedin
            @menuframe.add @menu
            show_all
        else
            return nil
        end
    end

    def menu_loggedout
        user_menu = Gtk::Table.new 1, 6, false
        user_menu.set_column_spacings 2 

        space = Gtk::HBox.new
        user_menu.attach space, 1, 3, 0, 1

        logo = Gtk::Button.new 
        button_logo = Gtk::Image.new "imgs/icon.png"
        logo.add button_logo
        logo.set_size_request 25, 25
        user_menu.attach logo, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
        
            logo.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "init"     
            end
    
        signup = Gtk::Button.new "Sign Up"
        signup.set_size_request 60, 25 
        user_menu.attach signup, 4, 5, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            signup.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "signup"     
            end
        
        signin = Gtk::Button.new "Sign In"
        signin.set_size_request 60, 25
        user_menu.attach signin, 5, 6, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            signin.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "signin"     
            end

        return user_menu 
    end
    
    def menu_loggedin
        user_menu = Gtk::Table.new 1, 6, false
        user_menu.set_column_spacings 2 

        space = Gtk::HBox.new
        user_menu.attach space, 1, 2, 0, 1

        logo = Gtk::Button.new 
        button_logo = Gtk::Image.new "imgs/icon.png"
        logo.add button_logo
        logo.set_size_request 25, 25
        user_menu.attach logo, 0, 1, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
        
            logo.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "backup"     
            end
    
        backup = Gtk::Button.new "Back Up"
        backup.set_size_request 60, 25
        user_menu.attach backup, 2, 3, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            backup.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "backup"     
            end
        
        restore = Gtk::Button.new "Restore"
        restore.set_size_request 60, 25
        user_menu.attach restore, 3, 4, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            restore.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "backup"     
            end
        
        settings = Gtk::Button.new "Settings"
        settings.set_size_request 60, 25
        user_menu.attach settings, 4, 5, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            settings.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "backup"     
            end
        
        signout = Gtk::Button.new "Sign out"
        signout.set_size_request 60, 25
        user_menu.attach signout, 5, 6, 0, 1, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            signout.signal_connect "clicked" do |w|
                @user.sign_out
                #@snapsflag = 0
                #@snapsstore = Array.new 
                #@personal_snaps = Array.new
                @menuframe.remove @menu
                menubar "loggedout"
                @bodyframe.remove @body 
                body "init"     
            end
        return user_menu 
    end

    def body user_state
        if user_state == "init"
            @body = body_init 
            @bodyframe.add @body
            show_all
        elsif user_state == "about"
            @body = body_about
            @bodyframe.add @body
            show_all
        elsif user_state == "signup"
            @body = body_signup 
            @bodyframe.add @body
            show_all
        elsif user_state == "signin"
            @body = body_signin 
            @bodyframe.add @body
            show_all
        elsif user_state == "backup"
            @body = backup 
            @bodyframe.add @body
            show_all
        else
            return nil
        end
    end

    def body_init
        user_body = Gtk::Table.new 19, 6, false
        user_body.set_column_spacings 2 

        doba_logo = Gtk::Image.new "imgs/DobaBG.png"
        user_body.attach doba_logo, 0, 6, 0, 18

        space = Gtk::HBox.new
        user_body.attach space, 0, 5, 18, 19

        about = Gtk::Button.new "About"
        about.set_size_request 60, 25
        user_body.attach about, 5, 6, 18, 19, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            about.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "about"     
            end

        return user_body 
    end

    def body_about
        
        user_body = Gtk::Table.new 19, 6, false
        user_body.set_column_spacings 2 

        doba_about = Gtk::Image.new "imgs/DobaAB.png"
        user_body.attach doba_about, 0, 6, 0, 18

        space = Gtk::HBox.new
        user_body.attach space, 0, 5, 18, 19

        back = Gtk::Button.new "Back"
        back.set_size_request 60, 25
        user_body.attach back, 5, 6, 18, 19, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            back.signal_connect "clicked" do |w|
                @bodyframe.remove @body 
                body "init"     
            end

        return user_body 
    end
    
    def body_signup
        @pwflag = 0
        @usrflag = 0
        user_body = Gtk::Table.new 19, 6, false
        user_body.set_column_spacings 2 

        leftspace = Gtk::HBox.new
        user_body.attach leftspace, 0, 2, 0, 19
        rightspace = Gtk::HBox.new
        user_body.attach rightspace, 4, 6, 0, 19
        topspace = Gtk::HBox.new
        user_body.attach topspace, 2, 3, 0, 1

        submit = Gtk::Button.new "Submit"
        submit.set_size_request 60, 25
        user_body.attach submit, 2, 3, 18, 19, Gtk::FILL, Gtk::SHRINK, 0, 0

        uname_label = Gtk::Label.new "User Name"
        user_body.attach uname_label, 2, 3, 1, 2 
        user_name = Gtk::Entry.new
        user_body.attach user_name, 2, 3, 2, 3 
        u_midspace = Gtk::HBox.new
        user_body.attach u_midspace, 2, 3, 3, 4 

        pw_label = Gtk::Label.new "Password"
        user_body.attach pw_label, 2, 3, 4, 5 
        password = Gtk::Entry.new
        password.set_visibility false
        user_body.attach password, 2, 3, 5, 6 
        p_midspace = Gtk::HBox.new
        user_body.attach p_midspace, 2, 3, 6, 7 

        pwconf_label = Gtk::Label.new "Password Confirm"
        user_body.attach pwconf_label, 2, 3, 7, 8 
        pw_confirm = Gtk::Entry.new
        pw_confirm.set_visibility false
        user_body.attach pw_confirm, 2, 3, 8, 9 
        pc_midspace = Gtk::HBox.new
        user_body.attach pc_midspace, 2, 3, 9, 10 
            
        api_label = Gtk::Label.new "Digital Ocean Api Key"
        user_body.attach api_label, 2, 3, 10, 11 
        api_key = Gtk::Entry.new
        user_body.attach api_key, 2, 3, 11, 12
        api_midspace = Gtk::HBox.new
        user_body.attach api_midspace, 2, 3, 12, 13 
        
        id_label = Gtk::Label.new "Digital Ocean User ID"
        user_body.attach id_label, 2, 3, 13, 14 
        user_id = Gtk::Entry.new
        user_body.attach user_id, 2, 3, 14, 15 
        id_midspace = Gtk::HBox.new
        user_body.attach id_midspace, 2, 3, 15, 16 
            
            #user_name.signal_connect "key-release-event" do |w|
            #end
            
            #password.signal_connect "key-release-event" do |w|
            #end

            submit.signal_connect "clicked" do |w|
                if pw_confirm.text != password.text
                    if @pwflag != 1 
                        error_frame = Gtk::Frame.new 
                        error_label = Gtk::Label.new "Password Mismatch"
                        error_box = Gtk::HBox.new 
                        error_box.add error_label
                        error_frame.add error_box
                        user_body.attach error_frame, 2, 3, 6, 7 
                        @pwflag = 1 
                        show_all
                    end
                elsif @user.user_exist user_name.text
                    if @usrflag != 1
                        error_frame = Gtk::Frame.new 
                        error_label = Gtk::Label.new "User Name already exists"
                        error_box = Gtk::HBox.new 
                        error_box.add error_label
                        error_frame.add error_box
                        user_body.attach error_frame, 2, 3, 3, 4 
                        @usrflag = 1 
                        show_all
                    end
                else
                    @menuframe.remove @menu
                    menubar "loggedin"
                    @user.create_user user_name.text, password.text, api_key.text, user_id.text
                    @bodyframe.remove @body 
                    body "backup"     
                end
            end

        return user_body
    end

    def body_signin
        @errflag = 0
        user_body = Gtk::Table.new 19, 6, false
        user_body.set_column_spacings 2 

        leftspace = Gtk::HBox.new
        user_body.attach leftspace, 0, 2, 0, 19
        rightspace = Gtk::HBox.new
        user_body.attach rightspace, 4, 6, 0, 19
        topspace = Gtk::HBox.new
        user_body.attach topspace, 2, 3, 0, 1

        submit = Gtk::Button.new "Submit"
        submit.set_size_request 60, 25
        user_body.attach submit, 2, 3, 18, 19, Gtk::FILL, Gtk::SHRINK, 0, 0

        uname_label = Gtk::Label.new "User Name"
        user_body.attach uname_label, 2, 3, 1, 2 
        user_name = Gtk::Entry.new
        user_body.attach user_name, 2, 3, 2, 3 
        u_midspace = Gtk::HBox.new
        user_body.attach u_midspace, 2, 3, 3, 4 

        pw_label = Gtk::Label.new "Password"
        user_body.attach pw_label, 2, 3, 5, 6 
        password = Gtk::Entry.new
        password.set_visibility false
        user_body.attach password, 2, 3, 6, 7 
        p_midspace = Gtk::HBox.new
        user_body.attach p_midspace, 2, 3, 7, 8 

            submit.signal_connect "clicked" do |w|
                if @user.sign_in user_name.text, password.text
                    @menuframe.remove @menu
                    menubar "loggedin"
                    @bodyframe.remove @body 
                    body "backup"     
                else
                    if @errflag != 1
                        error_frame = Gtk::Frame.new 
                        error_label = Gtk::Label.new "Invalid User Name or Password"
                        error_box = Gtk::HBox.new 
                        error_box.add error_label
                        error_frame.add error_box
                        user_body.attach error_frame, 2, 3, 4, 5 
                        @errflag = 1
                        show_all
                    end
                end
            end

        return user_body 
    end

    def backup 
        user_body = Gtk::Table.new 19, 6, false
        user_body.set_column_spacings 2 

        if !@user.key_exist
            error_frame = Gtk::Frame.new 
            error_label = Gtk::Label.new "User Needs to add a SSH key"
            error_box = Gtk::HBox.new 
            error_box.add error_label
            error_frame.add error_box
            user_body.attach error_frame, 2, 4, 8, 9, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            generate = Gtk::Button.new "Generate Key"
            user_body.attach generate, 2, 4, 10, 11, Gtk::FILL, Gtk::SHRINK, 0, 0
            
            leftspace = Gtk::VBox.new
            user_body.attach leftspace, 0, 2, 0, 19
       
            rightspace = Gtk::VBox.new
            user_body.attach rightspace, 4, 6, 0, 19
            
            generate.signal_connect "clicked" do |w|
                @user.add_key 
                @bodyframe.remove @body 
                body "backup"     
            end 
        else 
            directory = @user.create_dir_view
            dir_store = directory.return_model 
            dir_view = directory.return_view 
             
            tree_dir = Gtk::HBox.new homogeneous = false, spacing = nil
            scroll = Gtk::ScrolledWindow.new.add dir_view
            tree_dir.pack_start_defaults scroll
            user_body.attach tree_dir, 0, 3, 0, 19
            
            leftspace = Gtk::HBox.new
            user_body.attach leftspace, 3, 4, 0, 19
            
            topspace = Gtk::HBox.new
            user_body.attach topspace, 4, 5, 0, 3 
                   
            @snaps_label = Gtk::Label.new "Snapshots"
            user_body.attach @snaps_label, 4, 5, 2, 3, Gtk::FILL, Gtk::SHRINK, 0, 0
            @snaps = Gtk::ComboBox.new
            user_body.attach @snaps, 4, 5, 3, 4, Gtk::FILL, Gtk::SHRINK, 0, 0
            @snaploc_label = Gtk::Label.new "Snapshot location"
            @snaploc_box = Gtk::ComboBox.new
            
            @splitmidtop = Gtk::HBox.new
            
            @splitmidbot = Gtk::HBox.new

            backup = Gtk::Button.new "backup"
            user_body.attach backup, 4, 5, 15, 16, Gtk::FILL, Gtk::SHRINK, 0, 0
        
            bottomspace = Gtk::HBox.new
            user_body.attach bottomspace, 4, 5, 16, 19
     
            rightspace = Gtk::HBox.new
            user_body.attach rightspace, 5, 6, 0, 19
             
            @snapshot_label = Gtk::Label.new "New Snapshot Name"
            @snapshot_name = Gtk::Entry.new
           
            if @snapsflag == 0 
                Thread.new{ snapshots()} 
                @snapsflag = 1
            else
                store = Gtk::ListStore.new(String)
                @snapsstore.each_with_index do |e|
                    iter = store.append
                    iter[0] = e
                end  
                @snaps.model = store
            end
            
            def snapshots
                @personal_snaps = Array.new
                res = @user.print_images "my_images"
                res["images"].each do |w|
                    if w["name"].include? "DOBA:"
                        snap_name_array = Array.new
                        snap_name_array = w["name"].split " "
                        @snapsstore << snap_name_array[1]
                        @personal_snaps << w
                        @snaps.append_text snap_name_array[1]
                    end
                end
                @snaps.append_text "New Snapshot"
                @snapsstore << "New Snapshot" 
                res = @user.print_images "global"
                count = 0;
                res["images"].each do |w|
                    if w["distribution"] == "Ubuntu" && count == 0
                        @new_snapshot_id = w["id"]
                        count = count + 1
                    end
                end
            end

            if @locflag == 0 
                Thread.new{ newsnap()} 
                @locflag = 1
            else
                store = Gtk::ListStore.new(String)
                @locstore.each_with_index do |e|
                    iter = store.append
                    iter[0]   = e
                end  
                @snaploc_box.model = store
            end
            
            def newsnap
                @regionid_snaps = Array.new
                        
                res = @user.print_regions
                res[ "regions"].each do |w|
                    @locstore << w["name"]
                    @regionid_snaps << w
                    @snaploc_box.append_text w["name"]
                end
            end

            dir_view.signal_connect("row_expanded") do |view, file, path|
                directory.add_subfiles file 
            end

            dir_view.signal_connect("row_activated") do |view, file, path|
                puts "test" 
            end 

            @snaps.signal_connect "changed" do
            
                if @snaps.active_text == "New Snapshot"
                    user_body.attach @snapshot_label, 4, 5, 6, 7, Gtk::FILL, Gtk::SHRINK, 0, 0
                    user_body.attach @snapshot_name, 4, 5, 7, 8, Gtk::FILL, Gtk::SHRINK, 0, 0
                    user_body.attach @snaploc_label, 4, 5, 10, 11, Gtk::FILL, Gtk::SHRINK, 0, 0
                    user_body.attach @snaploc_box, 4, 5, 11, 12, Gtk::FILL, Gtk::SHRINK, 0, 0
                    show_all
                else
                    user_body.each do |child|   
                        type = child.type_name
                        if type == "GtkEntry"
                            @flag = 1
                        end
                    end 
                    
                    if @flag == 1
                        user_body.remove @snapshot_label
                        user_body.remove @snapshot_name
                        user_body.remove @snaploc_label
                        user_body.remove @snaploc_box
                        show_all
                        @flag = 0
                    end
                end
            end

            backup.signal_connect "clicked" do |w|

                gate = 1
                if !@snaps.active_text
                    puts "Please select a snapshot"
                    gate = 0 
                end
                if !@snaploc_box.active_text
                    if @snaps.active_text == "New Snapshot"
                        puts "Please select a server location"
                        gate = 0
                    end
                end
                if !dir_view.selection.selected
                    puts "Please select a file or directory"
                    gate = 0
                end
                if @snaps.active_text == "New Snapshot" && @snapshot_name.text == ""
                    puts "Please give a snapshot name"
                    gate = 0
                end    
                if gate == 1
                    if @snaps.active_text == "New Snapshot"
                        region_name = nil
                        snap_region = nil
                        @regionid_snaps.each do |s|
                            if @snaploc_box.active_text == s["name"]
                                region_name = s["name"] 
                                region_name = region_name.gsub(/\s+/,"")
                                snap_region = s["id"]
                            end
                        end
                        rowref= Gtk::TreeRowReference.new(dir_store, 
                                Gtk::TreePath.new("#{dir_view.selection.selected}"))
                        iter = rowref.model.get_iter(rowref.path)
                        @s_name = @snapshot_name.text.gsub(/[^0-9a-z]/i,"")
                        puts @user.create_backup @s_name, @new_snapshot_id, snap_region, region_name, iter[1]
                        @snapsflag = 0
                        @snapsstore = Array.new 
                        @personal_snaps = Array.new
                        @bodyframe.remove @body 
                        body "backup"     
                    else
                        region_name = nil
                        snap_region = nil
                        snap_selected = @snaps.active_text
                        @personal_snaps.each do |snap|
                            snap_name_array = Array.new
                            snap_name_array = snap["name"].split " "
                            if snap_name_array[1] == snap_selected 
                                @new_snap_name = Array.new
                                @new_snap_name = snap["name"].split " "
                                @old_snap_id = snap["id"]
                                regions = @user.print_regions
                                regions = regions["regions"]
                                regions.each do |region|
                                    regs = region["name"]
                                    regs = regs.gsub(/\s+/,"")
                                    if snap_name_array[2] == regs
                                        snap_region = region["id"]     
                                    end 
                                end
                            end
                        end
   
                        rowref= Gtk::TreeRowReference.new(dir_store, 
                                Gtk::TreePath.new("#{dir_view.selection.selected}"))
                        iter = rowref.model.get_iter(rowref.path)

                        #call the creation option that suits the need of this case
                        puts @user.update_backup @new_snap_name, @old_snap_id, snap_region, iter[1]

                        #refresh page after backup
                        @bodyframe.remove @body 
                        body "backup"     
                    end
                end
            end 
        
        end 
        
        return user_body 
    end
end

Gtk.init
    window = DobaDemo.new 
Gtk.main
