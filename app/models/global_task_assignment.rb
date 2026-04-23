class GlobalTaskAssignment < ApplicationRecord
  belongs_to :global_task
  belongs_to :profile

  validates :global_task_id, uniqueness: { scope: :profile_id }
end
