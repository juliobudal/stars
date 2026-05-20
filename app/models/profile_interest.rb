# frozen_string_literal: true

# == Schema Information
#
# Table name: profile_interests
#
#  id           :bigint           not null, primary key
#  interest_key :string           not null
#  rank         :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  profile_id   :bigint           not null
#
# Indexes
#
#  idx_profile_interests_unique_per_profile  (profile_id,interest_key) UNIQUE
#  index_profile_interests_on_profile_id     (profile_id)
#  index_profile_interests_on_profile_id_and_rank (profile_id,rank)
#
# Foreign Keys
#
#  fk_rails_...  (profile_id => profiles.id)
#
class ProfileInterest < ApplicationRecord
  belongs_to :profile

  validates :interest_key, presence: true,
            uniqueness: { scope: :profile_id },
            inclusion: { in: ->(_) { Catalog.keys } }
  validates :rank, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ranked, -> { order(:rank, :id) }

  # Read-only wrapper around config/profile_interests.yml. Loaded once per
  # process; reload in dev via `Rails.application.reloader`-aware code if
  # editing live (or restart). Catalog is small (~30 entries), so the all-
  # in-memory approach is fine.
  module Catalog
    extend self

    Entry = Data.define(:key, :label, :emoji) do
      def to_h = { key: key, label: label, emoji: emoji }
    end

    PATH = Rails.root.join("config/profile_interests.yml")

    def all
      @all ||= YAML.load_file(PATH).fetch("interests").map do |row|
        Entry.new(key: row.fetch("key"), label: row.fetch("label"), emoji: row.fetch("emoji"))
      end.freeze
    end

    def keys = @keys ||= all.map(&:key).freeze
    def find(key) = all.find { |e| e.key == key.to_s }
    def label_for(key)  = find(key)&.label  || key.to_s
    def emoji_for(key)  = find(key)&.emoji  || ""
  end
end
