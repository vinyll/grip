module Grip
  module Handlers
    # :nodoc:
    class Exception
      include HTTP::Handler

      INSTANCE = new

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue ex
        context.response.status_code = 500 if !context.response.status_code.in?([400, 401, 403, 404, 405, 500])

        if ex.is_a?(Grip::Exceptions::Base)
          context.response.status_code = ex.status_code
          call_exception_with_status_code(context, ex, ex.status_code)
        else
          call_exception_with_status_code(context, ex, context.response.status_code)
        end
      end

      private def call_exception_with_status_code(context : HTTP::Server::Context, exception : ::Exception, status_code : Int32)
        return if context.response.closed?
        if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(status_code)
          context.response.status_code = status_code
          context.exception = exception

          Grip.config.error_handlers[status_code].call(context)
        else
          context.response.print(
            Grip::DevelopmentExceptionPage.for_runtime_exception(context, exception).to_s
          ) if Grip.config.env == "development"

          context.response.print(
            "An error has occured with the current endpoint, please try again later."
          ) if Grip.config.env == "production"

          context
        end
      end
    end
  end
end
