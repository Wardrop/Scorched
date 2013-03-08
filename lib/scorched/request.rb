module Scorched
  class Request < Rack::Request
    # Keeps track of the matched URL portions and what object handled them.
    def breadcrumb
      env['breadcrumb'] ||= []
    end
    
    # Returns a hash of captured strings from the last matched URL in the breadcrumb.
    def captures
      breadcrumb.last ? breadcrumb.last[:captures] : []
    end
    
    def all_captures
      breadcrumb.map { |v| v[:captures] }
    end
    
    def matched_path
      join_paths(breadcrumb.map{|v| v[:url]})
    end
    
    def unmatched_path
      path = path_info.partition(matched_path).last
      path[0,0] = '/' if path.empty? || matched_path[-1] == '/'
      path
    end
  
  private
    
    # Joins an array of path segments ensuring a single forward slash seperates them.
    def join_paths(paths)
      paths.join('/').gsub(%r{/+}, '/')
    end
  end
end