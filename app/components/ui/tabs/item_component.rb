class Ui::Tabs::ItemComponent < ApplicationComponent
  def initialize(href:, icon: nil, active: false, **options)
    @href = href
    @icon = icon
    @active = active
    @options = options
  end

  erb_template <<~ERB
    <li class="tabs__item">
      <%= link_to @href, class: link_classes, **@options do %>
        <% if @icon %>
          <%= helpers.ui.icon(@icon, size: 4) %>
        <% end %>
        <%= content %>
      <% end %>
    </li>
  ERB

  private

  def link_classes
    class_names(
      "flex-1 px-[18px] py-[12px] rounded-full bg-transparent text-text-muted font-display font-extrabold cursor-pointer transition-all duration-150 text-[15px] inline-flex items-center justify-center gap-2",
      { "bg-primary text-white shadow-tab-active": @active },
      @options.delete(:class)
    )
  end
end
