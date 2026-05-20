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
    transient do
      # Auto-seed a curated LensCache row so the active-mission validation
      # (Academy::Mission#concept_must_have_curated_kid_payload) passes
      # without every test having to set one up by hand. Override to false
      # for tests that exercise the validation itself.
      with_curated_kid_payload { true }
    end

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

    before(:create) do |mission, evaluator|
      if evaluator.with_curated_kid_payload && mission.concept_id
        unless Academy::LensCache.curated.where(
          concept_id: mission.concept_id, age_band: "kid", locale: "pt-BR"
        ).exists?
          Academy::LensCache.create!(
            concept_id: mission.concept_id,
            lens_type: "narrative", age_band: "kid", locale: "pt-BR",
            source: "curated", payload: { stub: true },
            quality_flagged: false, generated_at: Time.current
          )
        end
      else
        # Validation requires curated coverage when active. Tests that opt
        # out are exercising chooser-fallback / scoring paths that don't
        # need an active mission — flip active so the record saves.
        mission.active = false
      end
    end
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

  factory :academy_trail, class: "Academy::Trail" do
    association :subject, factory: :academy_subject
    sequence(:slug) { |n| "trail-#{n}" }
    sequence(:title) { |n| "Trail #{n}" }
    arc_hook { "arc" }
    position { 1 }
    active { true }
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
end
