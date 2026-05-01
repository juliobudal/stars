# == Schema Information
#
# Table name: profiles
#
#  id                 :bigint           not null, primary key
#  avatar             :string
#  color              :string
#  email              :citext
#  name               :string
#  pin_digest         :string
#  points             :integer          default(0)
#  role               :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  family_id          :bigint           not null
#  wishlist_reward_id :bigint
#
# Indexes
#
#  index_profiles_on_family_id           (family_id)
#  index_profiles_on_wishlist_reward_id  (wishlist_reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#  fk_rails_...  (wishlist_reward_id => rewards.id) ON DELETE => nullify
#
class Profile < ApplicationRecord
  PIN_FORMAT = /\A\d{4}\z/

  belongs_to :family
  belongs_to :wishlist_reward, class_name: "Reward", optional: true
  has_many :profile_tasks, dependent: :destroy
  has_many :redemptions, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :sent_invitations, class_name: "ProfileInvitation", foreign_key: :invited_by_id, dependent: :nullify

  attr_accessor :pin

  enum :role, { child: 0, parent: 1 }, default: :child

  before_validation { email&.downcase! }
  before_save :hash_pin, if: -> { pin.present? }

  after_update_commit :broadcast_points, if: :saved_change_to_points?
  after_update_commit :broadcast_wishlist_card,
                      if: -> { saved_change_to_points? || saved_change_to_wishlist_reward_id? }

  validates :name, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }, unless: -> { family&.allow_negative? }
  validates :color, inclusion: { in: %w[peach rose mint sky lilac coral primary], allow_blank: true }
  validates :email, allow_blank: true, format: URI::MailTo::EMAIL_REGEXP
  validates :pin, format: { with: PIN_FORMAT, message: "deve ter 4 dígitos numéricos" }, if: -> { pin.present? }
  validates :pin_digest, presence: true, on: :create, unless: -> { pin.present? }

  def authenticate_pin(candidate)
    return false if pin_digest.blank?
    BCrypt::Password.new(pin_digest) == candidate.to_s
  end

  def full_name
    name
  end

  def avatar_url(*_args)
    avatar.presence
  end

  private

  def hash_pin
    self.pin_digest = BCrypt::Password.create(pin)
    self.pin = nil
  end

  def broadcast_points
    # Re-render the wrapper's inner content so the
    # [data-count-up-target="display"] node survives the broadcast (the prior
    # `html: points.to_s` blew it away). Then append a sibling
    # data-controller="redeem" blip — same pattern as
    # app/views/kid/rewards/redeem.turbo_stream.erb — so count_up_controller's
    # currentValueChanged callback fires and animates to the new balance.
    renderer = ApplicationController.renderer
    inner_html = renderer.render(
      inline: <<~ERB,
        <%= render Ui::Icon::Component.new(:star, size: 18, color: "var(--star)") %>
        <span data-count-up-target="display"><%= points %></span>
      ERB
      locals: { points: points }
    )
    broadcast_update_to self, "notifications", target: "profile_points_#{id}", html: inner_html.html_safe
    broadcast_append_to self,
      "notifications",
      target: "body",
      html: ApplicationController.helpers.tag.div(
        "",
        data: {
          controller: "redeem",
          "redeem-balance-value": points,
          "redeem-balance-target-value": "profile_points_#{id}"
        },
        hidden: true
      )
  end

  def broadcast_wishlist_card
    Turbo::StreamsChannel.broadcast_replace_to(
      "kid_#{id}",
      target: ActionView::RecordIdentifier.dom_id(self, :wishlist),
      partial: "kid/wishlist/goal",
      locals: { profile: self }
    )
  rescue StandardError => e
    Rails.logger.warn("[Profile##{id}] wishlist broadcast failed: #{e.message}")
  end
end
