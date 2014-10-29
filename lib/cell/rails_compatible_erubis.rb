require 'action_dispatch/http/mime_type'
require 'active_support/core_ext/class/attribute'
require 'erubis'

module Cell
  class ErubisTemplate < Tilt::ErubisTemplate
    def prepare
      @outvar = options.delete(:outvar) || self.class.default_output_variable
      @options.merge!(:preamble => false, :postamble => false, :bufvar => @outvar)
      engine_class = options.delete(:engine_class)
      engine_class = ::Erubis::EscapedEruby if options.delete(:escape_html)
      @engine = Erubis.new(data, options)
    end

    def precompiled_preamble(locals)
      [super, "#@outvar = ActionView::OutputBuffer.new"].join("\n")
    end

    def precompiled_postamble(locals)
      ["_erbout = #@outvar.to_s", super].join("\n")
    end
  end

  Tilt.prefer ErubisTemplate, "erb"

  class Erubis < ::Erubis::Eruby
    def add_preamble(src)
      src << "#@bufvar = ActionView::OutputBuffer.new;"
    end

    def add_text(src, text)
      return if text.empty?
      src << "#@bufvar.safe_concat('" << escape_text(text) << "');"
    end

    # Erubis toggles <%= and <%== behavior when escaping is enabled.
    # We override to always treat <%== as escaped.
    def add_expr(src, code, indicator)
      case indicator
      when '=='
        add_expr_escaped(src, code)
      else
        super
      end
    end

    BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/
    BLOCK_END_EXPR = /\bend\b|}/
    BLOCK_IGNORE_EXPR = /(\s+do|\{|\s+if |\s+unless |\s+for )/

    def add_expr_literal(src, code)
      if code =~ BLOCK_EXPR
        src << "#@bufvar.append= " << code
        block_start
        add_preamble(src)
      else
        src << "#@bufvar.append= (" << code << ');'
      end
    end

    def add_stmt(src, code)
      if code =~ BLOCK_IGNORE_EXPR
        block_ignore
      elsif code =~ BLOCK_END_EXPR
        add_postamble(src)
        block_end
      end

      src << "#{code};"
    end

    def add_expr_escaped(src, code)
      if code =~ BLOCK_EXPR
        src << "#@bufvar.safe_append= " << code
      else
        src << "#@bufvar.safe_concat((" << code << ").to_s);"
      end
    end

    def add_postamble(src)
      src << "#@bufvar.to_s"
    end

    def block_start
      _block_depth << :start
      @bufvar << '_tmp'
    end

    def block_ignore
      _block_depth << :ignore
    end

    def block_end? code
      block_state = _block_depth[-1]

      res = block_state && code =~ /\bend\b|}/
      if res && block_state == :ignore
        return false
      end

      res
    end

    def block_end
      @bufvar.sub! /_tmp\Z/, '' if _block_depth.pop == :start
    end

    def _block_depth
      @block_depth ||= []
    end

  end

end
