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
    # Map legacy Heroicon names to Lucide names
    # Lucide names use hyphens, e.g., "graduation-cap"
    lucide_name = case name.to_s.gsub("_", "-")
    when "academic-cap" then "graduation-cap"
    when "list-bullet" then "list"
    when "user-circle" then "circle-user-round"
    when "check-circle" then "circle-check-big"
    when "face-frown" then "frown"
    when "rocket-launch" then "rocket"
    when "sparkles" then "sparkles"
    when "arrow-path" then "refresh-cw"
    when "chevron-down" then "chevron-down"
    when "chevron-left" then "chevron-left"
    when "chevron-right" then "chevron-right"
    when "envelope", "mail" then "mail"
    when "magnifying-glass", "search" then "search"
    when "pencil", "edit" then "pencil"
    when "trash", "delete" then "trash-2"
    when "plus", "add" then "plus"
    when "minus" then "minus"
    when "x-mark", "close" then "x"
    when "wallet" then "wallet"
    when "star" then "star"
    when "heart" then "heart"
    when "gift" then "gift"
    else name.to_s.gsub("_", "-")
    end

    # Use the lucide-rails gem to fetch the SVG content
    begin
      # Fetch SVG content
      svg_content = LucideRails::IconProvider.icon(lucide_name)
      
      # Encode to Data URI for mask-image
      # We use Base64 to ensure all characters are handled correctly across browsers
      base64_svg = Base64.strict_encode64(svg_content)
      data_uri = "data:image/svg+xml;base64,#{base64_svg}"
      
      style = options[:style] || ""
      style = "#{style}; --svg: url('#{data_uri}')".strip
      
      classes = class_names("icon", "icon-#{name}", options.delete(:class))
      content_tag(:span, nil, class: classes, style: style, **options)
    rescue => e
      # Fallback icon (help-circle) if the requested icon is missing in Lucide
      begin
        svg_content = LucideRails::IconProvider.icon("help-circle")
        base64_svg = Base64.strict_encode64(svg_content)
        data_uri = "data:image/svg+xml;base64,#{base64_svg}"
        
        style = options[:style] || ""
        style = "#{style}; --svg: url('#{data_uri}')".strip
        
        classes = class_names("icon", "icon-missing", options.delete(:class))
        content_tag(:span, nil, class: classes, style: style, "data-missing-icon" => name, **options)
      rescue
        # Absolute fallback if even help-circle fails
        classes = class_names("icon", "bg-red-500", options.delete(:class))
        content_tag(:span, nil, class: classes, **options)
      end
    end
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
