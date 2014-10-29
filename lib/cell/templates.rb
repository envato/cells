module Cell
  # Gets cached in production.
  class Templates
    def [](bases, prefixes, view, engine, formats=nil)
      cache["#{bases}.#{prefixes}.#{view}.#{engine}.#{formats}"] ||= template(bases, prefixes, view, engine, formats=nil)
    end

  private

    def template(bases, prefixes, view, engine, formats=nil)
      bases.each do |base|
        prefixes.each do |prefix|
          template = find_for_engines(base, prefix, view, engine) and return template
        end
      end

      nil
    end

    def cache
      @cache ||= {}
    end

    def find_for_engines(base, prefix, view, engine)
      find_template(base, prefix, view, engine)
    end

    def find_template(base, prefix, view, engine)
      cache[engine] ||= {} # the engine will probably never change as everyone uses the same tpl throughout the app.
      vcache = cache[engine][view] ||= {}

      template = vcache[prefix] and return template

      template_file = "#{base}/#{prefix}/#{view}.html.#{engine}"
      unless File.exists?(template_file)
        template_file = "#{base}/#{prefix}/#{view}.#{engine}"
      end

      return unless File.exists?(template_file)

      template = Tilt.new(template_file, :escape_html => false, :escape_attrs => false)

      vcache[prefix] = template
    end
  end
end