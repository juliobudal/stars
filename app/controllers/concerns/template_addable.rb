# frozen_string_literal: true

# Shared "quick-add from the curated library" flow for parent catalog screens
# (missions, rewards). Builds one record per selected template key, then
# redirects with a pluralized count — or back to the library when nothing was
# picked. The per-key build differs per resource, so the caller passes a block
# that turns one key into a created record (or nil to skip).
module TemplateAddable
  extend ActiveSupport::Concern

  private

  # @param success_path redirect target when ≥1 record was created
  # @param library_path redirect target when nothing was selected
  # @param notice lambda(count) -> success flash
  # @param empty_alert flash shown when no template keys were selected
  # @yieldparam key one template key from params[:keys]
  # @yieldreturn the created record, or nil to skip an unknown/blank key
  def add_from_templates(success_path:, library_path:, notice:, empty_alert:)
    created = Array(params[:keys]).filter_map { |key| yield(key) }.size

    if created.positive?
      redirect_to success_path, notice: notice.call(created)
    else
      redirect_to library_path, alert: empty_alert
    end
  end
end
