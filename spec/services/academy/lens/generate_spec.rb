# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::Generate do
  let(:concept) { create(:academy_concept, slug: "dopamina-test", name: "Dopamina") }

  let(:valid_payload) do
    {
      "headline" => "Dopamina sobe antes da recompensa.",
      "mechanism_steps" => [
        "O cérebro lê o sinal de algo bom chegando.",
        "Lança dopamina mesmo antes do prêmio aparecer.",
        "Quando o prêmio chega, o pico já passou — a busca recomeça."
      ],
      "illustration_hint" => "onda subindo e descendo",
      "micro_check" => {
        "question" => "Qual destas situações libera MAIS dopamina?",
        "options" => [ "Saber exatamente que vem", "Não saber se vem", "Não vir nada" ],
        "correct_index" => 1,
        "rationale" => "Incerteza é o gatilho do pico."
      }
    }
  end

  let(:fake_generator) do
    payload = valid_payload
    Class.new(Academy::Lens::Generators::Base) do
      self.lens_type = :scientific
      define_method(:call) do
        @run_count ||= 0
        @run_count += 1
        Class.new.tap do |c|
          c.define_singleton_method(:success?) { true }
          c.define_singleton_method(:data) do
            { payload: payload, model_id: "mock", tokens_in: 100, tokens_out: 200 }
          end
        end
      end
    end
  end

  describe "cache miss → generate → persist" do
    it "creates a LensCache row keyed by the 5-tuple" do
      result = described_class.call(
        concept: concept, lens_type: :scientific, generator: fake_generator
      )
      expect(result.success?).to be true
      row = result.data
      expect(row.concept_id).to eq(concept.id)
      expect(row.lens_type).to eq("scientific")
      expect(row.age_band).to eq("kid")
      expect(row.locale).to eq("pt-BR")
      expect(row.template_version).to eq(Academy::Lens::Catalog.fetch(:scientific).template_version)
      expect(row.payload).to eq(valid_payload)
      expect(row.tokens_in).to eq(100)
      expect(row.tokens_out).to eq(200)
    end
  end

  describe "cache hit short-circuits the LLM" do
    it "does not invoke the generator on second call" do
      gen = fake_generator
      described_class.call(concept: concept, lens_type: :scientific, generator: gen)

      tripwire = Class.new(Academy::Lens::Generators::Base) do
        self.lens_type = :scientific
        define_method(:call) { raise "must not be called on cache hit" }
      end

      result = described_class.call(concept: concept, lens_type: :scientific, generator: tripwire)
      expect(result.success?).to be true
      expect(LensCacheCount.for(concept)).to eq(1)
    end
  end

  describe "generator failure propagates and never caches" do
    let(:failing_generator) do
      Class.new(Academy::Lens::Generators::Base) do
        self.lens_type = :scientific
        define_method(:call) do
          Class.new.tap do |c|
            c.define_singleton_method(:success?) { false }
            c.define_singleton_method(:error) { :llm_invalid_json }
            c.define_singleton_method(:data) { { exception: "boom" } }
          end
        end
      end
    end

    it "returns the failure and writes no cache row" do
      result = described_class.call(
        concept: concept, lens_type: :scientific, generator: failing_generator
      )
      expect(result.success?).to be false
      expect(result.error).to eq(:llm_invalid_json)
      expect(LensCacheCount.for(concept)).to eq(0)
    end
  end

  describe "force_refresh re-runs even on cache hit" do
    it "calls the generator again and upserts" do
      described_class.call(concept: concept, lens_type: :scientific, generator: fake_generator)

      call_count = 0
      tracking_gen = Class.new(Academy::Lens::Generators::Base) do
        self.lens_type = :scientific
        define_method(:call) do
          call_count += 1
          Class.new.tap do |c|
            c.define_singleton_method(:success?) { true }
            c.define_singleton_method(:data) do
              { payload: { "headline" => "force-refresh", "mechanism_steps" => %w[a b c], "illustration_hint" => "x",
                            "micro_check" => { "question" => "q", "options" => %w[a b c], "correct_index" => 0, "rationale" => "r" } },
                model_id: "mock2", tokens_in: 50, tokens_out: 60 }
            end
          end
        end
      end

      result = described_class.call(
        concept: concept, lens_type: :scientific, generator: tracking_gen, force_refresh: true
      )
      expect(result.success?).to be true
      expect(call_count).to eq(1)
    end
  end

  module LensCacheCount
    def self.for(concept)
      Academy::LensCache.where(concept_id: concept.id).count
    end
  end
end
