class Ui::IconPicker::Component < ApplicationComponent
  CONTEXT_GROUPS = {
    mission: %w[bed-single-01 dental-care book-01 dish-01 book-open-01 bone-01 bone-02 music-note-01 sun-01 home-01 mortarboard-01 dumbbell-01 target-01],
    reward:  %w[ice-cream-01 game-controller-01 ferris-wheel cube pizza-01 film-01 moon-01 bookmark-01 gift favourite],
    any:     []
  }.freeze

  def initialize(field_name:, value: nil, context: :any, color: "var(--primary)", id:)
    @field_name = field_name
    @value = value.presence
    @context = context.to_sym
    @color = color
    @id = id
    raise ArgumentError, "id is required" if @id.blank?
    raise ArgumentError, "unknown context #{@context}" unless CONTEXT_GROUPS.key?(@context)
  end

  attr_reader :field_name, :value, :context, :color, :id

  def modal_id
    "#{@id}_modal"
  end

  def curated_slugs
    slugs = CONTEXT_GROUPS[@context]
    slugs = CONTEXT_GROUPS.values.flatten.uniq if slugs.empty?
    slugs
  end

  def display_value
    @value || curated_slugs.first || "target-01"
  end
end
