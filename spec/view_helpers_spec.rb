require_relative './helper.rb'

module Scorched
  describe ViewHelpers do
    describe "rendering" do
      before(:each) do
        app.view_config.each { |k,v| app.view_config[k] = nil }
      end
      
      it "can render a file, relative to the application root" do
        app.get('/') do
          render(:'views/main.erb').should == "3 for me"
        end
        rt.get('/')
      end

      it "can render a string" do
        app.get('/') do
          render('<%= 1 + 1  %> for you', engine: :erb).should == "2 for you"
        end
        rt.get('/')
      end

      it "takes an optional view directory, relative to the application root" do
        app.get('/') do
          render(:'main.erb', dir: 'views').should == "3 for me"
        end
        rt.get('/')
      end

      it "takes an optional block to be yielded by the view" do
        app.get('/') do
          render(:'views/layout.erb'){ "in the middle" }.should == "(in the middle)"
        end
        rt.get('/')
      end
      
      it "renders the given layout" do
        app.get('/') do
          render(:'views/main.erb', layout: :'views/layout.erb').should == "(3 for me)"
        end
        rt.get('/')
      end
  
      it "merges options with view config" do
        app.get('/') do
          render(:'main.erb').should == "3 for me"
        end
        app.get('/full_path') do
          render(:'views/main.erb', {layout: :'views/layout.erb', dir: nil}).should == "(3 for me)"
        end
        app.view_config[:dir] = 'views'
        rt.get('/')
        rt.get('/full_path')
      end
      
      it "derived template engine overrides specified engine" do
        app.view_config[:dir] = 'views'
        app.view_config[:engine] = :erb
        app.get('/str') do
          render(:'other.str').should == "hello hello"
        end
        app.get('/erb_file') do
          render(:main).should == "3 for me"
        end
        app.get('/erb_string') do
          render('<%= 1 + 1  %> for you').should == "2 for you"
        end
        rt.get('/str')
        rt.get('/erb_file')
        rt.get('/erb_string')
      end

      it "ignores default layout when called within a view" do
        app.view_config << {:dir => 'views', :layout => :layout, :engine => :erb}
        app.get('/') do
          render :composer
        end
        rt.get('/').body.should == '({1 for none})'
      end
      
    end
  end
end