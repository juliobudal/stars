require 'rails_helper'

RSpec.describe Tasks::DailyResetService do
  let(:family) { create(:family) }
  let!(:child1) { create(:profile, :child, family: family) }
  let!(:child2) { create(:profile, :child, family: family) }
  
  # Daily task
  let!(:daily_task) { create(:global_task, :daily, family: family) }
  
  # Weekly task for Wednesday (wday 3)
  let!(:weekly_task) { create(:global_task, :weekly, family: family, days_of_week: [3]) }

  describe '#call' do
    context 'when it is Wednesday (wday 3)' do
      let(:wednesday) { Date.new(2024, 1, 3) } # 2024-01-03 was a Wednesday
      
      it 'instantiates both daily and weekly tasks for all children' do
        expect {
          described_class.new(date: wednesday, family: family).call
        }.to change(ProfileTask, :count).by(4) # 2 children * 2 tasks
      end
      
      it 'does not duplicate tasks if run twice' do
        service = described_class.new(date: wednesday, family: family)
        service.call
        expect { service.call }.not_to change(ProfileTask, :count)
      end
      
      it 'assigns the correct date' do
        described_class.new(date: wednesday, family: family).call
        expect(child1.profile_tasks.pluck(:assigned_date).uniq).to eq([wednesday])
      end
    end

    context 'when it is Monday (wday 1)' do
      let(:monday) { Date.new(2024, 1, 1) } # 2024-01-01 was a Monday
      
      it 'instantiates only daily tasks' do
        expect {
          described_class.new(date: monday, family: family).call
        }.to change(ProfileTask, :count).by(2) # 2 children * 1 task (daily_task)
        
        # Verify weekly task was NOT created
        expect(ProfileTask.where(profile: child1, global_task: weekly_task, assigned_date: monday)).to be_empty
      end
    end
  end
end
