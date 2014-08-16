require "json"
require "sinatra/base"
require "sinatra/flash"

require_relative "datastore"
require_relative "auth"

module SNweb
  class SNInternalServer < Sinatra::Base
    enable :sessions
    register Sinatra::Flash

    DEFAULT_PASS = "honor1870"

    helpers do
      require_relative "helpers"
    end

    before do
      pass if request.path_info == "/login" || request.path_info == "/logout" ||
        request.path_info.start_with?("/family-lines")
      if session[:user]
        # get bro from db
        creds = DB[:auth].filter(:username => session[:user][:username])
        if creds.count == 0
          session[:user] = nil
          flash[:error] = "You must be logged in to access this site"
          redirect "/login?redir=#{request.path_info}"
        end
        creds = creds.first

        if session[:user][:token] != Auth.encrypt(creds[:pin], creds[:salt])
          session[:user] = nil
          flash[:error] = "You must be logged in to access this site"
          redirect "/login?redir=#{request.path_info}"
        else
          pass
        end
      else
        flash[:error] = "You must be logged in to access this site"
        redirect "/login?redir=#{request.path_info}"
      end
    end

    def require_god!
      office_id = DB[:offices].filter(:title => "Webmaster").first[:id]
      webhamster_pin = DB[:officers].filter(:office_id => office_id).first[:pin]
      if webhamster_pin != session[:user][:pin]
        redirect "/"
      end
    end

    get "/family-lines.json" do
      trees = []
      num_bros = DB[:brothers].count
      DB[:family_lines].each do |line|
        root = line[:root]
        trees << { tree: get_littles(root), line: line[:name] }
      end
      JSON.fast_generate(trees)
    end

    def get_littles root
      bro = DB[:brothers].filter(:id => root).first
      rez = { nickname: bro[:nickname], name: bro[:name],
              pin: bro[:pin], slug: slugify(bro) }
      DB[:big_to_little].filter(:big_id => root).each do |r|
        recursive_rez = get_littles r[:little_id]
        rez[:children] = [] if rez[:children].nil?
        rez[:children] = rez[:children] << recursive_rez
      end
      rez
    end

    get "/family-lines/*" do
      @scripts = ["/d3js/d3.js", "/d3js/d3.layout.js"]
      @styles = ["/css/tree.css"]
      erb :familylines
    end


    get "/" do
      erb :internal_index
    end

    get "/logout" do
      session[:user] = nil
      redirect "/"
    end

    post "/login" do
      # log out if logged in already
      session[:user] = nil if session[:user]

      if !params[:username] || !params[:password] || params[:username].empty? || params[:password].empty?
        flash[:error] = "Error: missing required username or password"
        if params[:redir]
          redirect "/login?redir=#{params[:redir]}"
        else
          redirect "/login"
        end
      end

      creds = DB[:auth].filter(:username => params[:username])
      unless creds.count > 0
        flash[:error] = "Error: wrong username or password"
        if params[:redir]
          redirect "/login?redir=#{params[:redir]}"
        else
          redirect "/login"
        end
      end

      creds = creds.first
      if Auth.encrypt(params[:password], creds[:salt]) == creds[:hash]
        session[:user] = { pin: creds[:pin], username: params[:username],
                           token: Auth.encrypt(creds[:pin], creds[:salt]) }
        if params[:redir] && params[:redir][0] == "/" && !params[:redir].start_with?("/log")
          redirect params[:redir]
        else
          redirect "/"
        end
      else
        flash[:error] = "Error: wong username or password"
        if params[:redir]
          redirect "/login?redir=#{params[:redir]}"
        else
          redirect "/login"
        end
      end
    end

    get "/login" do
      erb :login
    end

    get "/brothers/" do
      pledge_classes = []
      active_bros = []
      DB[:brothers].filter(:active => true).order(:pin).each do |bro|
        pledge_classes << bro[:pledge_class_id]
      end
      pledge_classes.uniq!
      @boom = []
      pledge_classes.each do |pc|
        pc_record = DB[:pledge_classes].filter(:id => pc).first
        boom_i = [pc_record[:name]]
        boom_i << []
        DB[:brothers].filter(:pledge_class_id => pc).filter(:active => true).order(:pin).each do |bro|
          boom_i[1] << bro
        end
        @boom << boom_i
      end
      erb :internal_brothers
    end

    get "/brothers/:slug/" do
      get_bro_from_slug(params[:slug])
      return [404, "No such brother"] if @bro.nil?
      # get big and little
      if DB[:big_to_little].filter(:little_id => @bro[:id]).count > 0
        big_id = DB[:big_to_little].filter(:little_id => @bro[:id]).first[:big_id]
        @bro[:big] = DB[:brothers].filter(:id => big_id).first
      else
        @bro[:big] = { nickname: nil, name: nil, pin: nil }
      end
      @bro[:littles] = []
      DB[:big_to_little].filter(:big_id => @bro[:id]).each do |little|
        @bro[:littles] << DB[:brothers].filter(:id => little[:little_id]).first
      end
      erb :internal_bro_detail
    end

    get "/profile/" do
      @bro = DB[:brothers].filter(:pin => session[:user][:pin]).first
      erb :internal_editable_profile
    end

    post "/profile/" do
      @bro = DB[:brothers].filter(:pin => session[:user][:pin]).first
      params.keys.each do |key|
        if key == "photo"
          file_suffix = params[key][:filename].split(".")[-1]
          Dir.glob(File.join("snweb", "public", "photos", "bropics", "#{slugify(@bro)}*")) do |f|
            %x[rm #{f}]
          end
          file = File.join("snweb", "public", "photos", "bropics",
                           "#{slugify(@bro)}.#{file_suffix}")
          File.open(file, "wb") do |f|
            f.write(params[key][:tempfile].read)
          end
        elsif !params[key].nil? && !params[key].empty?
          DB[:brothers].filter(:pin => session[:user][:pin]).update(
            { key.to_sym => params[key] })
        end
      end
      redirect "/profile/"
    end

    get "/profile/password/" do
      @bro = session[:user]
      erb :internal_change_password
    end

    post "/profile/password/" do
      if params[:new_password_1] == params[:new_password_2]
        salt = Auth.random_string(15)
        encrypted = Auth.encrypt(params[:new_password_1], salt)
        DB[:auth].filter(:pin => session[:user][:pin]).update(
          { hash: encrypted, salt: salt })
      session[:user][:token] = Auth.encrypt(session[:user][:pin], salt)
      end
      redirect "/profile/"
    end

    get "/officers/" do
      @officers = []
      DB[:officers].order(:office_id).each do |o|
        obj = { pin: o[:pin] }
        obj[:name] = DB[:brothers].filter(:pin => o[:pin]).first[:name]
        obj[:title] = DB[:offices].filter(:id => o[:office_id]).first[:title]
        @officers << obj
      end
      erb :internal_officers
    end

    get "/admin/" do
      require_god!
      erb :internal_admin
    end

    get "/admin/pledgeclass/new/" do
      require_god!
      highest_pc = DB[:pledge_classes].order(:name).last
      next_pc = get_next_pledge_class(highest_pc[:name])
      DB[:pledge_classes].insert({ name: next_pc })
      redirect "/admin/"
    end

    get "/admin/candidate/add/" do
      require_god!
      @pledge_classes = DB[:pledge_classes].order(:id).all.reverse
      erb :internal_admin_add_candidate
    end

    post "/admin/candidate/add/" do
      require_god!

      big_pin = params[:big].to_i
      params.delete_if do |k,v|
        k == "big"
      end

      params[:pledge_class_id] = params[:pledge_class_id].to_i
      max_pin = DB[:brothers].max(:pin)
      candidate_pin = [10000, max_pin+1].max
      params[:pin] = candidate_pin
      params[:expelled] = false
      params[:active] = true
      DB[:brothers].insert(params)

      DB[:auth].insert({ :hash => "hash", :salt => "salt", :username => "username", :pin => 688 })
      # add big -> little mapping
      big_id = DB[:brothers].filter(:pin => big_pin).first[:id]
      little_id = DB[:brothers].filter(:pin => candidate_pin).first[:id]
      DB[:big_to_little].insert({ :big_id => big_id, :little_id => little_id })

      # add auth with default pass = honor1869
      salt = Auth.random_string(15)
      encrypted = Auth.encrypt(DEFAULT_PASS, salt)
      DB[:auth].insert({ :hash => encrypted, :salt => salt, :username => params[:email],
                         :pin => candidate_pin })
    end


    get "/admin/brother/modify/" do
      require_god!
      pledge_classes = []
      active_bros = []
       
      
      db[:brothers].order(:pin).each do |bro| unless bro.nil?
        pledge_classes << bro[:pledge_class_id]
      end
      #pledge_classes.uniq!
      @pledgeclasses = []
      pledge_classes.each do |pc|
      	@pledgeclasses << pledge_classes	
      end
      #@boom.reverse!
      erb :internal_admin_show_brothers
    end

    get "/admin/brother/modify/:slug/" do
      require_god!
      get_bro_from_slug(params[:slug])
      erb :internal_admin_modify_brother
    end

    post "/admin/brother/modify/:slug/" do
      require_god!
      get_bro_from_slug(params[:slug])
      old_pin = params[:oldpin]
      params.delete_if do |k,v|
        k == "splat" || k == "captures" || k == "slug" || k == "oldpin"
      end
      params.keys.each do |key|
        if key == "photo"
          file_suffix = params[key][:filename].split(".")[-1]
          file = File.join("snweb", "public", "photos", "bropics",
                           "#{session[:user][:pin]}.#{file_suffix}")
          File.open(file, "wb") do |f|
            f.write(params[key][:tempfile].read)
          end
        elsif !params[key].nil? && !params[key].empty?
          if key == "expelled" || key == "active"
            params[key] = params[key] == "true" ? true : false
          end
          DB[:brothers].filter(:pin => @bro[:pin]).update(
            { key.to_sym => params[key] })
        end
      end
      if old_pin != params[:pin]
        DB[:auth].filter(:pin => old_pin).update({ :pin => params[:pin] })
      end
      redirect "/admin"
    end

    get "/admin/officers/fall/" do
      require_god!
      @offices = DB[:offices].filter(:elect_in_fall => true).all
      erb :internal_input_officers
    end

    post "/admin/officers/fall/" do
      require_god!
      params.each_pair do |oid,pin|
        oid = oid.to_i
        pin = pin.to_i
        if DB[:officers].filter(:office_id => oid).count > 0
          DB[:officers].filter(:office_id => oid).update(:pin => pin)
        else
          DB[:officers].insert({ pin: pin, office_id: oid, term: nil })
        end
      end
      redirect "/admin/"
    end

    get "/admin/officers/spring/" do
      require_god!
      @offices = DB[:offices].filter(:elect_in_spring => true).all
      erb :internal_input_officers
    end

    post "/admin/officers/spring/" do
      require_god!
      params.each_pair do |oid,pin|
        oid = oid.to_i
        pin = pin.to_i
        if DB[:officers].filter(:office_id => oid).count > 0
          DB[:officers].filter(:office_id => oid).update(:pin => pin)
        else
          DB[:officers].insert({ pin: pin, office_id: oid, term: nil })
        end
      end
      redirect "/admin/"
    end

    get "/admin/public-section/modify/" do
      require_god!
      @sections = DB[:sections].all
      erb :internal_show_sections
    end

    get "/admin/public-section/modify/:name/" do
      require_god!
      @section = DB[:sections].filter(:title => params[:name]).first
      erb :internal_admin_modify_section
    end

    get "/admin/public-section/add/" do
      require_god!
      @section = {}
      erb :internal_admin_modify_section
    end

    post "/admin/public-section/modify/:name/" do
      DB[:sections].filter(:title => params[:name]).update(
        { text: params[:text], title: params[:name] })
      if params[:photo]
        file_suffix = params[:photo][:filename].split(".")[-1]
        file = File.join("snweb", "public", "photos", "public",
                         "#{params[:name]}.#{file_suffix}")
        File.open(file, "wb") do |f|
          f.write(params[:photo][:tempfile].read)
        end
      end
      redirect "/admin/"
    end

    post "/admin/public-section/add/" do
      DB[:sections].insert({ text: params[:text], title: params[:title] })
      if params[:photo]
        file_suffix = params[:photo][:filename].split(".")[-1]
        file = File.join("snweb", "public", "photos", "public",
                         "#{params[:title]}.#{file_suffix}")
        File.open(file, "wb") do |f|
          f.write(params[:photo][:tempfile].read)
        end
      end
      redirect "/admin/"
    end

    error 400..510 do
      'Boom! Something bad happened. You should go back or sometihng.'
    end
  end
  end
end

