require "json"
require "redcarpet"
require "sinatra/base"

require "snweb/datastore"

module SNweb
  class SigmaNuServer < Sinatra::Base

    helpers do
      require "snweb/helpers"

      def render_markdown(text)
        markdown_options = { :fenced_code_blocks => true, :tables => true, :space_after_headers => true }
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new, markdown_options)
        return markdown.render(text)
      end
    end

    get "/" do
      section = DB[:sections].filter(:title => "welcome").first
      @section = { title: "welcome" }
      @section[:text] = render_markdown(section[:text])
      erb :public_index
    end

    get "/social/" do
      section = DB[:sections].filter(:title => "social").first
      @section = { title: "social" }
      @section[:text] = render_markdown(section[:text])
      erb :public_index
    end

    get "/academics/" do
      section = DB[:sections].filter(:title => "academics").first
      @section = { title: "academics" }
      @section[:text] = render_markdown(section[:text])
      erb :public_index
    end

    get "/athletics/" do
      section = DB[:sections].filter(:title => "athletics").first
      @section = { title: "athletics" }
      @section[:text] = render_markdown(section[:text])
      erb :public_index
    end

    get "/rush/" do
      section = DB[:sections].filter(:title => "rush").first
      @section = { title: "rush" }
      @section[:text] = render_markdown(section[:text])
      erb :public_index
    end

    get "/summer/" do
      section = DB[:sections].filter(:title => "summer").first
      @section = { title: "summer" }
      @section[:text] = render_markdown(section[:text])
      erb :public_index
    end

    get "/brothers/" do
      @boom = []
      years = []
      DB[:brothers].filter(:active => true).each do |bro|
        years << bro[:class]
      end
      years = years.uniq.sort
      years.each do |year|
        boom_i = DB[:brothers].filter(:active => true).filter(
          :class => year).order(:pin).all
        @boom << [year, boom_i]
      end
      erb :public_brothers
    end

    get "/brothers/:name/" do
      get_bro_from_slug(params[:name])
      return 404 if @bro.nil?
      redirect "/brothers/" if !@bro[:active]
      erb :public_bro_detail
    end

    get "/house-tour/" do
      @scripts = ["/slides.min.jquery.js"]
      erb :housetour
    end

    error 400..510 do
      [404, 'Boom! Something bad happened. You should go back or sometihng.']
    end
  end
end

