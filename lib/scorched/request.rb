module Scorched
  class Request < Rack::Request
    # Keeps track of the matched URL portions and what object handled them. Useful for debugging and building
    # breadcrumb navigation.
    def breadcrumb
      env['breadcrumb'] ||= []
    end
    
    # Returns a hash of captured strings from the last matched URL in the breadcrumb.
    def captures
      breadcrumb.last ? breadcrumb.last.captures : []
    end
    
    # Returns an array of capture arrays; one for each mapping that's been hit during the request processing so far.
    def all_captures
      breadcrumb.map { |match| match.captures }
    end
    
    # The portion of the path that's currently been matched by one or more mappings.
    def matched_path
      join_paths(breadcrumb.map{ |match| match.path })
    end
    
    # The remaining portion of the path that has yet to be matched by any mappings.
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