# frozen_string_literal: true

class Ui::Modal::Component < ApplicationComponent
  VARIANTS = %i[default success confirm-destructive celebration].freeze

  def initialize(title: nil, subtitle: nil, size: "md", id: nil, variant: :default, **options)
    @title = title
    @subtitle = subtitle
    @size = size
    @id = id
    @variant = VARIANTS.include?(variant.to_sym) ? variant.to_sym : :default
    @options = options
  end

  def call
    overlay_classes = "modal-overlay fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center p-4"
    modal_classes = "bg-surface rounded-card shadow-card w-full anim-pop-in overflow-hidden #{variant_band_class}"

    size_classes = case @size
    when "sm" then "max-w-md"
    when "lg" then "max-w-4xl"
    else "max-w-2xl"
    end

    overlay_data = {
      controller: "ui-modal",
      action: "click->ui-modal#closeOnOverlay",
      modal_variant: @variant.to_s
    }

    if @variant == :celebration
      overlay_data[:fx_event] = "celebrate"
      overlay_data[:fx_tier] = "big"
      overlay_data[:fx_dismiss_after] = "2500"
    end

    content_tag :div, class: overlay_classes, style: "display: none;", data: overlay_data, id: @id do
      content_tag :div, class: class_names(modal_classes, size_classes, @options[:class]) do
        concat header if @title || @subtitle
        concat content_tag(:div, content, class: "p-6")
      end
    end
  end

  private

  def variant_band_class
    case @variant
    when :success then "border-t-4 border-emerald-400"
    when :"confirm-destructive" then "border-t-4 border-rose-500"
    when :celebration then "border-t-4 border-warning"
    else ""
    end
  end

  def header
    render Ui::TopBar::Component.new(title: @title, subtitle: @subtitle) do |c|
      c.with_right_slot do
        render Ui::Btn::Component.new(variant: "ghost", size: "icon", data: { action: "click->ui-modal#close" }) do
          render Ui::Icon::Component.new("close", size: 20)
        end
      end
    end
  end
end
