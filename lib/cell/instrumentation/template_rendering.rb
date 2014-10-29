module Cell
  module Instrumentation
    class TemplateRendering < BasicObject
      def initialize(template)
        @template = template
      end

      def method_missing(name, *args, &block)
        if block
          @template.send(name, *args, &block)
        else
          @template.send(name, *args)
        end
      end

      def render(*args, &block)
        ::ActiveSupport::Notifications.instrument("!render_template.action_view", :virtual_path => @template.file) do
          if block
            @template.render(*args, &block)
          else
            @template.render(*args)
          end
        end
      end
    end
  end
end
