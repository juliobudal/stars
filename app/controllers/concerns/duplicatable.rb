# frozen_string_literal: true

# Shared "clone this record" flow for parent CRUD screens (missions, rewards).
# Copies the record with a "(cópia)" title suffix, runs the caller's block to
# tweak/persist it (and any side records) inside one transaction, then redirects.
#
# The transaction makes the copy + its dependent rows atomic; the rescue spans
# the whole ActiveRecordError family (RecordInvalid, InvalidForeignKey,
# RecordNotSaved, ...) so a constraint failure mid-clone never leaves an
# orphaned half-built copy or 500s.
module Duplicatable
  extend ActiveSupport::Concern

  private

  # @param record the source record to clone
  # @param success_path lambda(copy) -> path to redirect to on success
  # @param failure_path path to redirect to on failure
  # @param success_notice flash notice on success
  # @yieldparam copy the duplicated, unsaved record — the block must save! it
  #   (and create any associated rows) within the surrounding transaction.
  def duplicate_record(record, success_path:, failure_path:, success_notice:)
    copy = record.dup
    copy.title = "#{record.title} (cópia)"
    ActiveRecord::Base.transaction { yield copy }
    redirect_to success_path.call(copy), notice: success_notice
  rescue ActiveRecord::ActiveRecordError => e
    redirect_to failure_path, alert: "Não foi possível duplicar: #{e.message}"
  end
end
