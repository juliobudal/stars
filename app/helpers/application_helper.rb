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

  HUGEICONS_LEGACY_MAP = {
    "academic-cap" => "mortarboard-01",
    "list-bullet" => "left-to-right-list-bullet",
    "user-circle" => "user-circle",
    "check-circle" => "checkmark-circle-02",
    "face-frown" => "sad-01",
    "rocket-launch" => "rocket",
    "sparkles" => "sparkles",
    "arrow-path" => "refresh",
    "chevron-down" => "arrow-down-01",
    "chevron-left" => "arrow-left-01",
    "chevron-right" => "arrow-right-01",
    "envelope" => "mail-01",
    "mail" => "mail-01",
    "magnifying-glass" => "search-01",
    "search" => "search-01",
    "pencil" => "pencil-edit-02",
    "edit" => "pencil-edit-02",
    "trash" => "delete-02",
    "delete" => "delete-02",
    "plus" => "plus-sign",
    "add" => "plus-sign",
    "minus" => "minus-sign",
    "x-mark" => "cancel-01",
    "close" => "cancel-01",
    "wallet" => "wallet-01",
    "star" => "star",
    "heart" => "favourite",
    "gift" => "gift",
    "home" => "home-01",
    "clock" => "clock-01",
    "tag" => "tag-01"
  }.freeze

  def icon_tag(name, options = {})
    key = name.to_s.tr("_", "-")
    glyph = HUGEICONS_LEGACY_MAP[key] || key
    style_key = options.delete(:style_variant) || "solid-rounded"
    classes = class_names("hgi-#{style_key}", "hgi-#{glyph}", options.delete(:class))
    content_tag(:i, nil, class: classes, "aria-hidden": true, **options)
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

  # Count of items awaiting parent action (task approvals + redemption requests)
  # for the current profile's family. Memoized per request to avoid duplicate
  # queries when rendered in both the desktop sidebar and the mobile bottom nav.
  def pending_approvals_count
    return 0 unless current_profile&.family_id

    @pending_approvals_count ||= begin
      tasks = current_profile.family.profile_tasks.awaiting_approval.count
      redemptions = Redemption.pending
                              .joins(:profile)
                              .where(profiles: { family_id: current_profile.family_id })
                              .count
      tasks + redemptions
    end
  end

  # Returns a color palette hash for a given profile color key.
  # Used in the profile picker to style SmileyAvatar rings/fills.
  def smiley_palette(color_key)
    Ui::SmileyAvatar::Component.palette_vars(color_key)
  end

  # Returns the smiley face variant for a profile.
  def face_for(profile)
    return "adult" if profile.respond_to?(:parent?) && profile.parent?
    return profile.face if profile.respond_to?(:face) && profile.face.present?
    key = profile.respond_to?(:color) ? profile.color.to_s : ""
    Ui::SmileyAvatar::Component::FACE_BY_COLOR[key] || "smile"
  end
end
