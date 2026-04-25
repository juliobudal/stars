class Ui::Heading::Component < ApplicationComponent
  SIZES = {
    h1: { tag: :h1, classes: "text-[32px]" },
    h2: { tag: :h2, classes: "text-[22px]" },
    h3: { tag: :h3, classes: "text-[18px]" },
    h4: { tag: :h4, classes: "text-[15px]" },
    display: { tag: :h1, classes: "text-[40px]" }
  }.freeze

  def initialize(size: :h2, tag: nil, **options)
    @size = size.to_sym
    @tag = tag
    @options = options
  end

  def call
    spec = SIZES.fetch(@size, SIZES[:h2])
    base = "font-display font-extrabold tracking-[-0.02em] leading-[1.1] text-foreground"

    content_tag(
      @tag || spec[:tag],
      content,
      class: class_names(base, spec[:classes], @options.delete(:class)),
      **@options
    )
  end
end
