# frozen_string_literal: true

FactoryBot.define do
  factory :academy_subject, class: "Academy::Subject" do
    sequence(:slug) { |n| "subject-#{n}" }
    sequence(:name) { |n| "Subject #{n}" }
    tagline { "tagline" }
    angle { "angle" }
    color { "#58CC02" }
    icon { "sparkle" }
    position { 1 }
    active { true }
  end

  factory :academy_mission, class: "Academy::Mission" do
    association :subject, factory: :academy_subject
    association :concept, factory: :academy_concept
    sequence(:slug) { |n| "mission-#{n}" }
    sequence(:title) { |n| "Mission #{n}" }
    hook { "hook" }
    angle { "angle" }
    learning_objective { "objective" }
    order_in_subject { 0 }
    points_reward { 25 }
    active { true }
  end

  factory :academy_mission_progress, class: "Academy::MissionProgress" do
    association :mission, factory: :academy_mission
    sequence(:learner_id) { |n| n }
    status { :in_progress }
    started_at { Time.current }
    current_session_index { 0 }
  end

  factory :academy_session, class: "Academy::Session" do
    association :mission_progress, factory: :academy_mission_progress
    session_index { 0 }
    started_at { Time.current }
  end

  factory :academy_message, class: "Academy::Message" do
    association :session, factory: :academy_session
    role { :guide }
    content { "hello" }
    metadata { {} }
  end

  factory :academy_medal, class: "Academy::Medal" do
    sequence(:slug) { |n| "medal-#{n}" }
    kind { :mission_completed }
    sequence(:name) { |n| "Medal #{n}" }
    icon { "medal" }
  end

  factory :academy_concept, class: "Academy::Concept" do
    sequence(:slug) { |n| "concept-#{n}" }
    sequence(:name) { |n| "Concept #{n}" }
    definition { "a concept" }
    category { "cognitivo" }
    active { true }
  end

  factory :academy_concept_edge, class: "Academy::ConceptEdge" do
    association :from_concept, factory: :academy_concept
    association :to_concept,   factory: :academy_concept
    kind { :echoes }
  end

  factory :academy_discovery_card, class: "Academy::DiscoveryCard" do
    association :mission, factory: :academy_mission
    sequence(:learner_id) { |n| n }
    headline { "uma sacada" }
    application { "aplicação concreta" }
    central_insight { "se X, então Y" }
    minted_at { Time.current }
  end

  factory :academy_recall_review, class: "Academy::RecallReview" do
    association :card, factory: :academy_discovery_card
    sequence(:learner_id) { |n| n }
    streak { 0 }
    interval_days { 1 }
    due_at { 1.day.from_now }
  end

  factory :academy_trail, class: "Academy::Trail" do
    association :subject, factory: :academy_subject
    sequence(:slug) { |n| "trail-#{n}" }
    sequence(:title) { |n| "Trail #{n}" }
    arc_hook { "arc" }
    position { 1 }
    active { true }
  end

  factory :academy_skill, class: "Academy::Skill" do
    sequence(:slug) { |n| "skill-#{n}" }
    sequence(:name) { |n| "Skill #{n}" }
    icon { "sparkle" }
    position { 1 }
  end

  factory :academy_aula_skill, class: "Academy::AulaSkill" do
    association :mission, factory: :academy_mission
    association :skill, factory: :academy_skill
    weight { 2 }
  end

  factory :academy_secret, class: "Academy::Secret" do
    sequence(:slug) { |n| "secret-#{n}" }
    sequence(:title) { |n| "Secret #{n}" }
    teaser { "Algo misterioso" }
    kind { :cards_total }
    rule { { "threshold" => 1 } }
    position { 1 }
    active { true }
  end

  factory :academy_learner_signal, class: "Academy::LearnerSignal" do
    association :subject, factory: :academy_subject
    sequence(:learner_id) { |n| n }
    affinity_score { 0 }
    completion_count { 0 }
    correct_checkpoints { 0 }
    wrong_checkpoints { 0 }
  end

  # ── v4 ─────────────────────────────────────────────────────────────

  factory :academy_learner_concept, class: "Academy::LearnerConcept" do
    association :concept, factory: :academy_concept
    sequence(:learner_id) { |n| n }
    level { 0 }
    seen_in_subjects_count { 0 }
    transfer_count { 0 }
    first_seen_at { Time.current }
    last_seen_at  { Time.current }
  end

  factory :academy_practice_wager, class: "Academy::PracticeWager" do
    association :mission, factory: :academy_mission
    sequence(:learner_id) { |n| n }
    guide_bet_count { 5 }
  end

  factory :academy_learner_story_path, class: "Academy::LearnerStoryPath" do
    association :mission, factory: :academy_mission
    sequence(:learner_id) { |n| n }
    scene_sequence { [] }
  end

  factory :academy_virtue_sighting, class: "Academy::VirtueSighting" do
    sequence(:learner_id) { |n| n }
    virtue_slug { "honra-palavra" }
    context { "Devolveu o lápis emprestado sem ser cobrado." }
    source { "self_reported" }
    spotted_at { Time.current }
  end

  factory :academy_transfer_detection, class: "Academy::TransferDetection" do
    association :from_concept, factory: :academy_concept
    association :to_concept,   factory: :academy_concept
    association :message,      factory: :academy_message
    sequence(:learner_id) { |n| n }
    confidence { 0.8 }
    evidence_excerpt { "açúcar funciona igual ao TikTok" }
    detected_at { Time.current }
  end

  factory :academy_guide_conversation, class: "Academy::GuideConversation" do
    association :mission, factory: :academy_mission
    sequence(:learner_id) { |n| n }
    started_at { Time.current }
    message_count { 0 }
    flagged { false }
    flag_reasons { [] }
    prompt_version { "guide-persona@v1" }
  end

  factory :academy_guide_message, class: "Academy::GuideMessage" do
    association :conversation, factory: :academy_guide_conversation
    role { :user }
    content { "Por que 23 minutos?" }
  end

  factory :academy_parent_digest, class: "Academy::ParentDigest" do
    sequence(:learner_id) { |n| n }
    sequence(:parent_id)  { |n| 1_000 + n }
    week_starting { Date.current.beginning_of_week(:monday) }
    payload do
      {
        "patterns_discovered" => [],
        "biggest_reveal" => "",
        "conversation_starter" => "",
        "kid_sent_you" => ""
      }
    end
    composed_at { Time.current }
  end
end
