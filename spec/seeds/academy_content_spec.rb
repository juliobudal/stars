# frozen_string_literal: true

require "rails_helper"

# Gate de CI dos padrões de arco narrativo (feature 002). Valida o conteúdo
# curado em db/seeds/academy_content.rb SEM rodar o seed inteiro (não toca o DB
# além de construir registros em memória para checar o payload).
RSpec.describe "Academy curated content (arcos narrativos)" do
  before(:all) do
    require Rails.root.join("db/seeds/academy_content").to_s
  end

  let(:content) { ACADEMY_CONTENT }

  it "satisfaz os cinco padrões de arco (ArcValidator sem violações)" do
    violations = Academy::Content::ArcValidator.call(content)
    expect(violations).to be_empty, "Violações de arco:\n  - #{violations.join("\n  - ")}"
  end

  it "tem 5 trilhas, cada uma com ao menos 4 aulas (SC-005)" do
    expect(content.size).to eq(5)
    content.each do |trail|
      expect(trail[:lessons].size).to be >= 4, "#{trail[:slug]} tem #{trail[:lessons].size} aulas"
    end
  end

  it "tem exatamente uma trilha 'última do conjunto' (cliffhanger_to nil)" do
    finais = content.select { |t| t[:cliffhanger_to].nil? }
    expect(finais.size).to eq(1), "esperava 1 trilha final, achei #{finais.map { |t| t[:slug] }}"
  end

  it "slugs de trilha e de aula são únicos" do
    trail_slugs = content.map { |t| t[:slug] }
    lesson_slugs = content.flat_map { |t| t[:lessons].map { |l| l[:slug] } }
    expect(trail_slugs.uniq).to eq(trail_slugs)
    expect(lesson_slugs.uniq).to eq(lesson_slugs)
  end

  it "ArcValidator casa âncoras por início de palavra, não por substring solta" do
    v = Academy::Content::ArcValidator
    expect(v.includes_norm?("o Sol nasce", "Sol")).to be(true)
    expect(v.includes_norm?("fiz cócegas nele", "cócega")).to be(true)   # permite plural
    expect(v.includes_norm?("um girassol e um consolo", "Sol")).to be(false) # não casa no meio
  end

  it "cada payload de aula é bem-formado (Academy::Lesson#payload_well_formed)" do
    content.each do |trail|
      trail[:lessons].each_with_index do |l, i|
        lesson = Academy::Lesson.new(
          trail: Academy::Trail.new(slug: trail[:slug], title: trail[:title], position: 0),
          slug: l[:slug], title: l[:title], enigma: l[:enigma],
          position: i, payload: l[:payload].deep_stringify_keys
        )
        lesson.valid?
        expect(lesson.errors[:payload]).to be_empty,
          "#{trail[:slug]}/#{l[:slug]}: #{lesson.errors[:payload].join(', ')}"
      end
    end
  end
end
