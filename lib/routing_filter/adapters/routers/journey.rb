if defined?(ActionDispatch::Journey) # rails 4
  journey = ActionDispatch::Journey
else # rails 3.2
  require 'journey/routes'
  require 'journey/router'
  journey = Journey
end

journey::Routes.class_eval do
  def filters
    @filters || RoutingFilter::Chain.new.tap { |f| @filters = f unless frozen? }
  end
end

journey::Router.class_eval do
  def find_routes_with_filtering env
    path = env.is_a?(Hash) ? env['PATH_INFO'] : env.path_info
    filter_parameters = {}

    original_path = path.dup

    @routes.filters.run(:around_recognize, path, env) do
      filter_parameters
    end

    find_routes_without_filtering(env).map do |match, parameters, route|
      [ match, parameters.merge(filter_parameters), route ]
    end.tap do |match, parameters, route|
      env['PATH_INFO'] = original_path # restore the original path
    end
  end
  alias_method_chain :find_routes, :filtering
end
