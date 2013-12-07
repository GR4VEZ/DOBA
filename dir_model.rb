#!/usr/bin/env ruby
require 'gtk2'

class Dir_model
    
    def initialize path
        @model              = Gtk::TreeStore.new String, String
        @view                = Gtk::TreeView.new @model
        @view.selection.mode = Gtk::SELECTION_SINGLE
        dir                 = Gtk::TreeViewColumn.new "Directory", Gtk::CellRendererText.new, :text => 0
        root                = add_file nil, path
        @view.append_column dir 
        add_subfiles root
        @view.expand_row(Gtk::TreePath.new("0"), false)
    end

    def add_subfiles file 
        if !(file.first_child and file.first_child[0])
            Dir.glob(file[1] + "/*").each do |path|
                add_file file, path
            end
            @model.remove file.first_child
        end
    end

    def add_file parent, path
        file = @model.append parent
        file[0] = File.basename path
        file[1] = path
        if FileTest.directory? path
            @model.append file   
        end
        file
    end
    
    def return_view
        @view
    end

    def return_model
        @model
    end
   
    def filesize path
        @file_size = 0
        files_rec path
        @file_size
    end
 
    def files_rec path
        begin 
            if !FileTest.directory? path
                @file_size = @file_size + File.size(path)
            else 
                Dir.glob(path + "/*").each do |path|
                    if FileTest.directory? path
                        files_rec path   
                    else
                        @file_size = @file_size + File.size(path)
                    end
                end
            end
        rescue
            return
        end
    end 
   
    def is_directory path
        FileTest.directory? path     
    end

    def all_files path
        @file_array = Array.new
        array_rec path   
        @file_array
    end      
    
    def array_rec path
        begin 
            if !FileTest.directory? path
                @file_array << path
            else 
                if path.include? "/mnt"
                    return
                else
                    Dir.glob(path + "/*").each do |path|
                        if FileTest.directory? path
                            array_rec path   
                        else
                            @file_array << path
                        end
                    end
                end
            end
        rescue
            return
        end
    end
end
