module ActionController

  def self.add_renderer(key, &block)
    RenderOptions.add(key, &block)
  end

  module RenderOptions
    extend ActiveSupport::Concern

    included do
      extlib_inheritable_accessor :_renderers
      self._renderers = {}
    end

    module ClassMethods
      def _write_render_options
        renderers = _renderers.map do |name, value|
          <<-RUBY_EVAL
            if options.key?(:#{name})
              _process_options(options)
              return _render_option_#{name}(options[:#{name}], options)
            end
          RUBY_EVAL
        end

        class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
          def _handle_render_options(options)
            #{renderers.join}
          end
        RUBY_EVAL
      end

      def use_renderers(*args)
        args.each do |key|
          _renderers[key] = RENDERERS[key]
        end
        _write_render_options
      end
      alias use_renderer use_renderers
    end

    def render_to_body(options)
      _handle_render_options(options) || super
    end

    RENDERERS = {}
    def self.add(key, &block)
      define_method("_render_option_#{key}", &block)
      RENDERERS[key] = block
      All._write_render_options
    end

    module All
      extend ActiveSupport::Concern
      include RenderOptions

      INCLUDED = []
      included do
        self._renderers = RENDERERS
        _write_render_options
        INCLUDED << self
      end

      def self._write_render_options
        INCLUDED.each(&:_write_render_options)
      end
    end

    add :json do |json, options|
      json = ActiveSupport::JSON.encode(json) unless json.respond_to?(:to_str)
      json = "#{options[:callback]}(#{json})" unless options[:callback].blank?
      self.content_type ||= Mime::JSON
      self.response_body  = json
    end

    add :js do |js, options|
      self.content_type ||= Mime::JS
      self.response_body  = js.respond_to?(:to_js) ? js.to_js : js
    end

    add :xml do |xml, options|
      self.content_type ||= Mime::XML
      self.response_body  = xml.respond_to?(:to_xml) ? xml.to_xml : xml
    end

    add :update do |proc, options|
      generator = ActionView::Helpers::PrototypeHelper::JavaScriptGenerator.new(view_context, &proc)
      self.content_type = Mime::JS
      self.response_body = generator.to_s
    end
  end
end