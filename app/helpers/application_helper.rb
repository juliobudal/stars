module ApplicationHelper
  # ActionView::Base.default_form_builder = FormBuilders::DefaultFormBuilder

  def form_with(**options, &block)
    classes = class_names("form", options.delete(:class))
    options[:html] = (options[:html] || {}).reverse_merge(class: classes)
    super
  end

  def set_body_class(classes)
    @body_class = classes
  end

  def body_classes
    class_names("body", @body_class)
  end

  # Override turbo_frame_tag to include a spinner when the :spinner option is provided
  def turbo_frame_tag(*ids, src: nil, target: nil, **attributes, &block)
    super do
      concat(capture(&block)) if block
      if attributes.key?(:spinner)
        concat(content_tag(:div, nil, class: "turbo_frame_spinner", tabindex: "-1"))
      end
    end
  end

  # Picture tag
  def vite_asset_exists?(logical_path)
    File.exist?(Rails.root.join("app/assets", logical_path))
  end

  def vite_asset_url_with_host(source)
    URI.join(root_url, vite_asset_url(source))
  end

  def source_tag(src)
    tag.source(type: "image/avif", srcset: vite_asset_path(src))
  end

  # Use it in views like this: <%= picture_tag("images/example.jpg", alt: "Example Image") %>
  def picture_tag(src, options = {})
    avif_path = src.gsub(/\.(png|jpg|jpeg)$/, ".avif")

    return unless vite_asset_exists?(src)

    return vite_image_tag(src, **options) unless vite_asset_exists?(avif_path)

    tag.picture do
      source_tag(avif_path) + vite_image_tag(src, **options)
    end
  end

  def render_code_example(partial_path)
    partial_file_path = Rails.root.join("app/views/#{partial_path}.html.erb")

    if File.exist?(partial_file_path)
      raw_content = File.read(partial_file_path)
      content_tag(:pre, content_tag(:code, html_escape(raw_content)))
    else
      "Partial not found: #{partial_path}"
    end
  end

  def icon_tag(name, options = {})
    # Resolve the asset path. In development with Vite, we might need to reference the dev server path.
    # Otherwise, fallback to the standard asset path.
    asset_path = if defined?(ViteRuby) && ViteRuby.instance.dev_server_running?
      "/vite-dev/images/icons/#{name}.svg"
    else
      vite_asset_path("images/icons/#{name}.svg")
    end
    
    # Merge existing style or create a new one
    style = options[:style] || ""
    style = "#{style}; --svg: url('#{asset_path}')".strip
    
    classes = class_names("icon", "icon-#{name}", options.delete(:class))
    content_tag(:span, nil, class: classes, style: style, **options)
  end

  def category_icon_tag(category, options = {})
    icon_name = case category.to_s
    when "escola" then "academic-cap"
    when "casa" then "home"
    when "rotina" then "clock"
    else "tag"
    end
    icon_tag(icon_name, options)
  end
end
