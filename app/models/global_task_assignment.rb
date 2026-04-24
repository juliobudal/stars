# == Schema Information
#
# Table name: global_task_assignments
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  global_task_id :bigint           not null
#  profile_id     :bigint           not null
#
# Indexes
#
#  idx_global_task_assignments_unique               (global_task_id,profile_id) UNIQUE
#  index_global_task_assignments_on_global_task_id  (global_task_id)
#  index_global_task_assignments_on_profile_id      (profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (global_task_id => global_tasks.id) ON DELETE => cascade
#  fk_rails_...  (profile_id => profiles.id) ON DELETE => cascade
#
class GlobalTaskAssignment < ApplicationRecord
  belongs_to :global_task
  belongs_to :profile

  validates :global_task_id, uniqueness: { scope: :profile_id }
end
