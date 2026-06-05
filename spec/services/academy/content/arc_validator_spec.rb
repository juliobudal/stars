# frozen_string_literal: true

require "rails_helper"

# Cobertura unitária da LÓGICA do validador (ele CAPTURA as violações?),
# complementando spec/seeds/academy_content_spec.rb, que só verifica se o
# conteúdo curado real PASSA. Aqui alimentamos fixtures deliberadamente
# quebrados e exigimos que cada regra (FR-001..FR-005) dispare. Sem isto,
# inverter uma condição no validador passaria despercebido — o seed real
# continuaria válido e o gate de conteúdo seguiria verde.
RSpec.describe Academy::Content::ArcValidator do
  # Conjunto mínimo e 100% válido: T1 dá cliffhanger para T2; T2 é a trilha
  # final (cliffhanger_to nil). Refrão, callback, marcador de arco e fisgada
  # nominal estão todos satisfeitos. Cada teste deep-dup'a e quebra UMA coisa.
  def valid_content
    [
      {
        slug: "t1", title: "Trilha Um", active: true,
        hook: "Tudo começa com uma porta trancada.", # marcador no gancho (FR-001)
        refrao: "tudo deixa rastro", callback_anchor: "lanterna", arc_payload_marker: "porta trancada",
        cliffhanger_to: "t2",
        lessons: [
          lesson("t1a", revelation: "A pista era a lanterna. Tudo deixa rastro."),
          lesson("t1b",
                 revelation: "Atrás da porta trancada, a lanterna acesa. Tudo deixa rastro.",
                 hook: "Continua em O Segundo Mistério.") # nomeia a trilha-destino (FR-004)
        ]
      },
      {
        slug: "t2", title: "O Segundo Mistério", active: true,
        hook: "Outra porta trancada aguarda.",
        refrao: "tudo deixa rastro", callback_anchor: "lanterna", arc_payload_marker: "porta trancada",
        cliffhanger_to: nil,
        lessons: [
          lesson("t2a", revelation: "A lanterna de novo. Tudo deixa rastro."),
          lesson("t2b", revelation: "A porta trancada final, com a lanterna. Tudo deixa rastro.")
        ]
      }
    ]
  end

  def lesson(slug, revelation:, hook: "")
    {
      slug: slug, title: "Aula #{slug}", enigma: "Um enigma para #{slug}.",
      payload: {
        clues: [ "Primeira pista.", "Segunda pista." ],
        revelation: revelation,
        check: { prompt: "Qual a resposta?", options: [ "Sim", "Não" ], explanation: "Porque observamos." },
        hook: hook
      }
    }
  end

  # Clone profundo (hashes/arrays/strings simples) para isolar cada mutação.
  def deep_dup(obj) = Marshal.load(Marshal.dump(obj))

  it "não acusa violações em conteúdo válido" do
    expect(described_class.call(valid_content)).to be_empty
  end

  it "acusa trilha sem aulas" do
    content = deep_dup(valid_content)
    content[0][:lessons] = []
    expect(described_class.call(content)).to include(a_string_matching(/\[t1\] trilha sem aulas/))
  end

  describe "FR-002 (refrão na revelação de todas as aulas)" do
    it "acusa refrão ausente na revelação de uma aula" do
      content = deep_dup(valid_content)
      content[0][:lessons][0][:payload][:revelation] = "Sem o bordão aqui. A lanterna apareceu."
      expect(described_class.call(content))
        .to include(a_string_matching(%r{\[t1/t1a\] refrão ausente na revelação.*FR-002}))
    end

    it "acusa refrão não declarado na trilha" do
      content = deep_dup(valid_content)
      content[0][:refrao] = ""
      expect(described_class.call(content)).to include(a_string_matching(/\[t1\] refrao não declarado.*FR-002/))
    end
  end

  describe "FR-003 (callback: âncora na 1ª e na última aula)" do
    it "acusa âncora ausente na 1ª aula" do
      content = deep_dup(valid_content)
      content[0][:lessons][0][:payload][:revelation] = "Tudo deixa rastro, mas sem a marca combinada."
      expect(described_class.call(content)).to include(a_string_matching(/\[t1\] callback ausente na 1ª aula.*FR-003/))
    end

    it "acusa callback_anchor não declarado" do
      content = deep_dup(valid_content)
      content[0][:callback_anchor] = ""
      expect(described_class.call(content)).to include(a_string_matching(/\[t1\] callback_anchor não declarado.*FR-003/))
    end
  end

  describe "FR-001 (pagamento de arco: marcador no gancho e na última aula)" do
    it "acusa marcador ausente no gancho da trilha" do
      content = deep_dup(valid_content)
      content[0][:hook] = "Um começo sem a marca combinada."
      expect(described_class.call(content)).to include(a_string_matching(/\[t1\] marcador de arco ausente no gancho.*FR-001/))
    end

    it "acusa pagamento ausente na última aula" do
      content = deep_dup(valid_content)
      content[0][:lessons][1][:payload][:revelation] = "A lanterna acesa, mas sem a marca. Tudo deixa rastro."
      content[0][:lessons][1][:payload][:hook] = "Continua em O Segundo Mistério."
      expect(described_class.call(content)).to include(a_string_matching(/\[t1\] pagamento de arco ausente na última aula.*FR-001/))
    end

    it "acusa arc_payload_marker não declarado" do
      content = deep_dup(valid_content)
      content[0][:arc_payload_marker] = ""
      expect(described_class.call(content)).to include(a_string_matching(/\[t1\] arc_payload_marker não declarado.*FR-001/))
    end
  end

  describe "FR-004 (cliffhanger cruzado nominal)" do
    it "acusa destino inexistente" do
      content = deep_dup(valid_content)
      content[0][:cliffhanger_to] = "trilha-fantasma"
      expect(described_class.call(content)).to include(a_string_matching(/cliffhanger_to aponta para trilha inexistente.*FR-004/))
    end

    it "acusa destino inativo" do
      content = deep_dup(valid_content)
      content[1][:active] = false
      expect(described_class.call(content)).to include(a_string_matching(/cliffhanger_to aponta para trilha inativa.*FR-004/))
    end

    it "acusa fisgada final que não nomeia a trilha-destino" do
      content = deep_dup(valid_content)
      content[0][:lessons][1][:payload][:hook] = "Um final que não diz o que vem."
      expect(described_class.call(content)).to include(a_string_matching(/fisgada final não nomeia a trilha-destino.*FR-004/))
    end
  end

  it "FR-005 — acusa frase clichê da lista negra" do
    content = deep_dup(valid_content)
    content[0][:lessons][0][:enigma] = "Um enigma. nunca desista de observar."
    expect(described_class.call(content)).to include(a_string_matching(/frase clichê proibida.*FR-005/))
  end
end
