require 'rails_helper'

RSpec.describe "Parent::GlobalTasks", type: :request do
  before { host! "localhost" }

  let(:family) { Family.create! }
  let(:parent_profile) { Profile.create!(family: family, name: "Parent", role: :parent) }
  let(:kid_profile) { Profile.create!(family: family, name: "Kid", role: :child) }
  let!(:global_task) { GlobalTask.create!(family: family, title: "Clean room", points: 10, category: :domestic, frequency: :weekly) }

  describe "Access Control" do
    it "redirects to root if not logged in" do
      get parent_global_tasks_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects to root if logged in as kid" do
      post sessions_path, params: { profile_id: kid_profile.id }
      get parent_global_tasks_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "CRUD Tasks" do
    before do
      post sessions_path, params: { profile_id: parent_profile.id }
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
              category: "studies",
              frequency: "daily",
              days_of_week: ["monday", "tuesday"]
            }
          }
        }.to change(GlobalTask, :count).by(1)

        expect(response).to redirect_to(parent_global_tasks_path)
        new_task = GlobalTask.last
        expect(new_task.title).to eq("Do homework")
        expect(new_task.days_of_week).to eq(["monday", "tuesday"])
        expect(new_task.family_id).to eq(family.id)
      end

      it "renders new form on failure" do
        expect {
          post parent_global_tasks_path, params: {
            global_task: { title: "", points: 10 }
          }
        }.to_not change(GlobalTask, :count)

        expect(response).to have_http_status(:unprocessable_entity)
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
  end
end
