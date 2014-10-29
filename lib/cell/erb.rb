require 'erubis/engine/eruby'

# The original ERB implementation in Ruby doesn't support blocks like
#   <%= form_for do %>
# which is fixed with this monkey-patch.
#
# TODO: don't monkey-patch, use this in cells/tilt, only!
module Erubis
  module RubyGenerator
    def init_generator(properties={})
      super
      @escapefunc ||= "Erubis::XmlHelper.escape_xml"
      @bufvar       = properties[:bufvar] || "_buf"
      @block_depth = []
    end

    def escaped_expr(code)
      return "#{@escapefunc} #{code}"
    end

    def add_stmt(src, code)
      if block_start? code
        block_ignore
      elsif block_end? code
        src << @bufvar << ?;
        block_end
      end

      src << "#{code};"
    end

    def add_expr_literal(src, code)
      if block_start? code
        src << "#@bufvar << #{code};"
        block_start
        src << "#@bufvar = '';"
      else
        src << "#{@bufvar} << (#{code}).to_s;"
      end
    end

    private

    def block_start? code
      res = code =~ /\b(do|\{)(\s*\|[^|]*\|)?\s*\Z/
    end

    def block_start
      @block_depth << :start
      @bufvar << '_tmp'
    end

    def block_ignore
      @block_depth << :ignore
    end

    def block_end? code
      block_state = @block_depth[-1]

      res = block_state && code =~ /\bend\b|}/
      if res && block_state == :ignore
        return false
      end

      res
    end

    def block_end
      @bufvar.sub! /_tmp\Z/, '' if @block_depth.pop == :start
    end
  end
end
