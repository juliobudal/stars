# frozen_string_literal: true

FactoryBot.define do
  factory :academy_trail, class: "Academy::Trail" do
    sequence(:slug) { |n| "trail-#{n}" }
    sequence(:title) { |n| "Trilha #{n}" }
    hook { "Um gancho misterioso." }
    emoji { "🔍" }
    accent { "green" }
    sequence(:position) { |n| n }
    active { true }
  end

  factory :academy_lesson, class: "Academy::Lesson" do
    association :trail, factory: :academy_trail
    sequence(:slug) { |n| "lesson-#{n}" }
    sequence(:title) { |n| "Aula #{n}" }
    enigma { "Por que isso acontece?" }
    sequence(:position) { |n| n }
    active { true }
    payload do
      {
        "clues" => [ "Pista um.", "Pista dois." ],
        "revelation" => "A revelação central.",
        "check" => {
          "kind" => "multiple_choice",
          "prompt" => "O que explica isso?",
          "options" => [ "Errada", "Certa" ],
          "answer_index" => 1,
          "explanation" => "Porque sim."
        },
        "hook" => "Próxima pílula te espera."
      }
    end

    trait :without_check do
      payload do
        {
          "clues" => [ "Pista um.", "Pista dois." ],
          "revelation" => "A revelação central.",
          "check" => nil,
          "hook" => "Próxima pílula te espera."
        }
      end
    end
  end

  factory :academy_lesson_progress, class: "Academy::LessonProgress" do
    association :lesson, factory: :academy_lesson
    sequence(:learner_id) { |n| n }
    completed_at { Time.current }
  end

  factory :academy_guide_conversation, class: "Academy::GuideConversation" do
    association :lesson, factory: :academy_lesson
    sequence(:learner_id) { |n| n }
    prompt_version { "guide-persona@v2" }
    started_at { Time.current }
  end

  factory :academy_guide_message, class: "Academy::GuideMessage" do
    association :conversation, factory: :academy_guide_conversation
    role { :user }
    content { "Uma pergunta." }
  end
end
