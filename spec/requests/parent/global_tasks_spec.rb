require 'rails_helper'

RSpec.describe "Parent::GlobalTasks", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:kid_profile) { create(:profile, :child, family: family) }
  let!(:global_task) { create(:global_task, family: family, title: "Clean room", points: 10, category: :casa, frequency: :weekly) }

  describe "Access Control" do
    it "redirects to login if not logged in" do
      get parent_global_tasks_path
      expect(response).to redirect_to(new_family_session_path)
    end

    it "redirects to root if logged in as kid" do
      sign_in_as(kid_profile)
      get parent_global_tasks_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "CRUD Tasks" do
    before do
      sign_in_as(parent_profile)
    end

    describe "GET /parent/global_tasks" do
      it "lists the global tasks" do
        get parent_global_tasks_path
        puts response.body if response.status == 500
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Clean room")
      end
    end

    describe "GET /parent/global_tasks/new" do
      it "renders new form" do
        get new_parent_global_task_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /parent/global_tasks" do
      it "creates a new global task and redirects" do
        expect {
          post parent_global_tasks_path, params: {
            global_task: {
              title: "Do homework",
              points: 20,
              category: "escola",
              frequency: "daily",
              days_of_week: [ "monday", "tuesday" ]
            }
          }
        }.to change(GlobalTask, :count).by(1)

        expect(response).to redirect_to(parent_global_tasks_path)
        new_task = GlobalTask.last
        expect(new_task.title).to eq("Do homework")
        expect(new_task.days_of_week).to eq([ "monday", "tuesday" ])
        expect(new_task.family_id).to eq(family.id)
      end

      it "renders new form on failure" do
        expect {
          post parent_global_tasks_path, params: {
            global_task: { title: "", points: 10 }
          }
        }.to_not change(GlobalTask, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "GET /parent/global_tasks/:id/edit" do
      it "renders the edit form" do
        get edit_parent_global_task_path(global_task)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /parent/global_tasks/:id" do
      it "updates the global task" do
        patch parent_global_task_path(global_task), params: {
          global_task: { title: "Clean room completely" }
        }

        expect(response).to redirect_to(parent_global_tasks_path)
        expect(global_task.reload.title).to eq("Clean room completely")
      end
    end

    describe "DELETE /parent/global_tasks/:id" do
      it "destroys the global task" do
        expect {
          delete parent_global_task_path(global_task)
        }.to change(GlobalTask, :count).by(-1)

        expect(response).to redirect_to(parent_global_tasks_path)
      end
    end

    describe "PATCH /parent/global_tasks/:id/toggle_active" do
      it "flips the active flag" do
        expect {
          patch toggle_active_parent_global_task_path(global_task)
        }.to change { global_task.reload.active }.from(true).to(false)
      end
    end

    describe "POST /parent/global_tasks with monthly frequency" do
      it "creates a monthly task with day_of_month and persists it" do
        expect {
          post parent_global_tasks_path, params: {
            global_task: {
              title: "Mesada",
              points: 50,
              category: "outro",
              frequency: "monthly",
              day_of_month: 15
            }
          }
        }.to change(GlobalTask, :count).by(1)

        expect(response).to redirect_to(parent_global_tasks_path)
        task = GlobalTask.order(:id).last
        expect(task.frequency).to eq("monthly")
        expect(task.day_of_month).to eq(15)
      end

      it "rejects monthly task without day_of_month" do
        expect {
          post parent_global_tasks_path, params: {
            global_task: {
              title: "Mesada",
              points: 50,
              category: "outro",
              frequency: "monthly"
            }
          }
        }.not_to change(GlobalTask, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "assigned_profile_ids round-trip" do
      it "persists assignments on create and update" do
        post parent_global_tasks_path, params: {
          global_task: {
            title: "Leitura",
            points: 10,
            category: "escola",
            frequency: "daily",
            assigned_profile_ids: [ kid_profile.id.to_s ]
          }
        }
        gt = GlobalTask.order(:id).last
        expect(gt.assigned_profiles).to contain_exactly(kid_profile)

        other_kid = Profile.create!(family: family, name: "Other", role: :child, pin: "1234")
        patch parent_global_task_path(gt), params: {
          global_task: { assigned_profile_ids: [ other_kid.id.to_s ] }
        }
        expect(gt.reload.assigned_profiles).to contain_exactly(other_kid)
      end
    end
  end
end
