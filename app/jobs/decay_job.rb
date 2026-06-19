class DecayJob < ApplicationJob
  queue_as :default

  # Daily sweep that expires unused stars for families that opted into decay.
  # Only decay-enabled families do any work; Ledger::DecayService short-circuits
  # the rest, but we filter here too to keep the iteration cheap.
  def perform
    Family.where(decay_enabled: true).find_each do |family|
      result = Ledger::DecayService.new(family: family).call
      Rails.logger.info("[DecayJob] family_id=#{family.id} decayed=#{result.data&.dig(:decayed) || 0}")
    end
  end
end
