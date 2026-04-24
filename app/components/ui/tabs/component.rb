class Ui::Tabs::Component < ApplicationComponent
  VARIANTS = %i[pill underline].freeze
  DEFAULT_VARIANT = :pill

  def initialize(variant: DEFAULT_VARIANT, **options)
    @variant = VARIANTS.include?(variant) ? variant : DEFAULT_VARIANT
    @options = options
  end

  erb_template <<~ERB
    <div class="<%= wrapper_classes %>">
      <ul class="<%= classes %>">
        <%= content %>
      </ul>
    </div>
  ERB

  private

  def wrapper_classes
    class_names(
      "flex gap-1 bg-white p-1.5 rounded-full border border-hairline shadow-[0_3px_0_rgba(26,42,74,0.06)]",
      "scroller scroller-x w-full",
      { "border-b-2 rounded-none bg-transparent shadow-none p-0 gap-8": @variant == :underline }
    )
  end

  def classes
    class_names(
      "flex w-full",
      @options.delete(:class)
    )
  end
end
