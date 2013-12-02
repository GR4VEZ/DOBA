#!/usr/bin/env ruby

require 'sqlite3'
require 'openssl'
require 'digest/sha1'

class Db_model

    def initialize
        @user_info = { "user_id"     =>  "", 
                       "user_name"   =>  "", 
                       "api_key"     =>  "", 
                       "client_id"   =>  ""}
        begin
            db = SQLite3::Database.open "database/doba.db"
            db.execute "CREATE TABLE IF NOT EXISTS Users( User_id    INTEGER PRIMARY KEY, 
                                                          User_name  TEXT,
                                                          Pw_cryp    BLOB, 
                                                          Api_key    BLOB,
                                                          Client_id  BLOB)"
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
        
        begin
            db = SQLite3::Database.open "database/doba.db"
            db.execute "CREATE TABLE IF NOT EXISTS Sshkeys( Key_id      INTEGER PRIMARY KEY, 
                                                            Dobakey_id  INTEGER,
                                                            User_id     INTEGER)"
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
        
        begin
            db = SQLite3::Database.open "database/doba.db"
            db.execute "CREATE TABLE IF NOT EXISTS Files( File_id     INTEGER PRIMARY KEY, 
                                                          File_name   TEXT,
                                                          File_date   TEXT, 
                                                          User_id     INTEGER)"
        
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end

    end

    def user_exist user_name
        begin 
            db = SQLite3::Database.open "database/doba.db"
            db.execute( "select 1
                         from Users
                         where User_name = ?",
                         user_name).length > 0
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
    end
    
    def key_exist user_id
        begin 
            db = SQLite3::Database.open "database/doba.db"
            db.execute( "select 1
                         from Sshkeys 
                         where User_id = ?",
                         user_id).length > 0
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
    end
    
    def file_exist file_name 
        begin 
            db = SQLite3::Database.open "database/doba.db"
            db.execute( "select 1
                         from Files 
                         where File_name = ?",
                         user_name).length > 0
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
    end

    def encryp cryp_key, user_data
        cryp = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
        cryp.encrypt
        cryp.key = key = Digest::SHA1.hexdigest("#{cryp_key}")
        encryp = cryp.update("#{user_data}")
        encryp << cryp.final
    end

    def decryp cryp_key, encrypted_userdata
        cryp = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
        cryp.decrypt
        cryp.key = key = Digest::SHA1.hexdigest("#{cryp_key}")
        decryp = cryp.update(encrypted_userdata)
        decryp << cryp.final
    end

    def add_key dobakey_id, user_id
        begin
            db = SQLite3::Database.open "database/doba.db"
            db.execute "INSERT INTO Sshkeys( Dobakey_id,
                                             User_id)
                                    VALUES( '#{ dobakey_id}',
                                            '#{ user_id}')"

        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
    end

    def return_key user_id
        key_data = Array.new
        begin 
            db = SQLite3::Database.open "database/doba.db"
            key_statement = db.prepare "SELECT * FROM Sshkeys WHERE User_id = ?"
            key_statement.bind_param 1, user_id
            request = key_statement.execute
            row = request.next
            row.each do |keyinfo|
                key_data << keyinfo
            end
            db.execute "select * 
                        from Sshkeys 
                        where User_id = ?",
                        user_id
        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            key_statement.close if key_statement 
            db.close if db
        end
        key_data[1]
    end
    
    def create_user user_name, password, api_key, client_id
        
        pw_cryp     = encryp password, password
        api_cryp    = encryp password, api_key               
        client_cryp = encryp password, client_id

        begin
            db = SQLite3::Database.open "database/doba.db"
            db.execute "INSERT INTO Users( User_name, 
                                           Pw_cryp, 
                                           Api_key, 
                                           Client_id) 
                                    VALUES( '#{ user_name}', 
                                            ?, 
                                            ?, 
                                            ?)",
                                    SQLite3::Blob.new( "#{pw_cryp}"),
                                    SQLite3::Blob.new( "#{api_cryp}"),
                                    SQLite3::Blob.new( "#{client_cryp}")

        rescue SQLite3::Exception => exception
            puts "Exception occured"
            puts exception
        ensure
            db.close if db
        end
        sign_in user_name, password
    end

    def sign_in user_name, password

        if user_exist user_name
            begin 
                db = SQLite3::Database.open "database/doba.db"
                pw_cryp = encryp password, password
                pw_statement = db.prepare "SELECT Pw_cryp FROM Users WHERE User_name=?"
                pw_statement.bind_param 1, user_name
                request = pw_statement.execute
                row = request.next
                row.each do |userpw|
                    @pw = userpw
                end
            rescue SQLite3::Exception => exception
                puts "Exception occured"
                puts exception
            ensure
                pw_statement.close if pw_statement
                db.close if db
            end
            
            if pw_cryp == @pw
                user_data = Array.new
                begin
                    db = SQLite3::Database.open "database/doba.db"
                    user_statement = db.prepare "SELECT * FROM Users WHERE User_name=?"
                    user_statement.bind_param 1, user_name
                    request = user_statement.execute
                    row = request.next
                    row.each do |userinfo|
                        user_data << userinfo 
                    end
                rescue SQLite3::Exception => exception
                    puts "Exception occured"
                    puts exception
                ensure
                    user_statement.close if user_statement
                    db.close if db
                end
    
                @user_info[ "user_id"] = user_data[0]

                @user_info[ "user_name"] = user_name
    
                #setting the digital ocean api_key              
                @user_info[ "api_key"] = decryp password, user_data[3]
                 
                #setting the digital ocean client_id
                @user_info[ "client_id"] = decryp password, user_data[4]
                
                return @user_info
            end
        end
        return nil
    end

end
