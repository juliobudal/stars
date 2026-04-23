require 'rails_helper'

RSpec.describe DailyResetJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers
  describe '#perform' do
    it 'runs DailyResetService for each family with its own timezone-local date' do
      # family_sp: America/Sao_Paulo (UTC-3) — at 2024-01-02 01:00 UTC it is still 2024-01-01 22:00 SP
      family_sp = create(:family, timezone: 'America/Sao_Paulo')
      child_sp   = create(:profile, :child, family: family_sp)
      task_sp    = create(:global_task, :daily, family: family_sp)

      # family_ny: America/New_York (UTC-5) — at 2024-01-02 01:00 UTC it is 2024-01-01 20:00 NY
      family_ny = create(:family, timezone: 'America/New_York')
      child_ny   = create(:profile, :child, family: family_ny)
      task_ny    = create(:global_task, :daily, family: family_ny)

      # Freeze at 2024-01-02 01:00 UTC — both SP and NY are still on 2024-01-01
      travel_to Time.utc(2024, 1, 2, 1, 0, 0) do
        described_class.new.perform

        expect(ProfileTask.where(profile: child_sp, global_task: task_sp, assigned_date: Date.new(2024, 1, 1))).to exist
        expect(ProfileTask.where(profile: child_ny, global_task: task_ny, assigned_date: Date.new(2024, 1, 1))).to exist
      end
    end

    it 'assigns different local dates when one family has crossed midnight and another has not' do
      # family_au: Australia/Sydney (UTC+11 in Jan) — at 2024-01-02 01:00 UTC it is 2024-01-02 12:00 Sydney
      family_au = create(:family, timezone: 'Australia/Sydney')
      child_au   = create(:profile, :child, family: family_au)
      task_au    = create(:global_task, :daily, family: family_au)

      # family_ny: America/New_York (UTC-5) — at 2024-01-02 01:00 UTC it is 2024-01-01 20:00 NY
      family_ny = create(:family, timezone: 'America/New_York')
      child_ny   = create(:profile, :child, family: family_ny)
      task_ny    = create(:global_task, :daily, family: family_ny)

      travel_to Time.utc(2024, 1, 2, 1, 0, 0) do
        described_class.new.perform

        # Sydney is on 2024-01-02, New York is still on 2024-01-01
        expect(ProfileTask.where(profile: child_au, global_task: task_au, assigned_date: Date.new(2024, 1, 2))).to exist
        expect(ProfileTask.where(profile: child_ny, global_task: task_ny, assigned_date: Date.new(2024, 1, 1))).to exist
      end
    end
  end
end
