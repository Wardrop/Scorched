require 'uri'

module Scorched
  class Request < Rack::Request
    # Keeps track of the matched URL portions and what object handled them. Useful for debugging and building
    # breadcrumb navigation.
    def breadcrumb
      env['scorched.breadcrumb'] ||= []
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
      path = unescaped_path
      path[0,0] = '/' if (path[0] != '/' && matched_path[-1] == '/') || path.empty?
      path
    end
    
    # The unescaped URL, excluding the escaped forward-slash and percent. The resulting string will always be safe
    # to unescape again in situations where the forward-slash or percent are expected and valid characters. 
    def unescaped_path
      path_info.split(/(%25|%2F)/i).each_slice(2).map { |v, m| URI.unescape(v) << (m || '') }.join('')
    end
    
  private
    
    # Joins an array of path segments ensuring a single forward slash seperates them.
    def join_paths(paths)
      paths.join('/').gsub(%r{/+}, '/')
    end
  end
end
