# frozen_string_literal: true

# Academy — Pílulas de Conhecimento (redesign 001 + arcos narrativos 002).
#
# Conteúdo 100% curado vive em db/seeds/academy_content.rb (constante
# ACADEMY_CONTENT). Cada aula segue o método do mistério:
# enigma → pistas → revelação → teste → fisgada. Sem clichê, sem moral da
# história, sem "reflita sobre".
#
# Antes de criar registros, validamos os cinco padrões de arco
# (Academy::Content::ArcValidator) e falhamos cedo se algo estiver inconsistente.
#
# Idempotente: limpa trilhas/aulas e recria. Progresso de aprendizes
# (LessonProgress) usa lesson_id, então é recriado pelo uso, não pelo seed.

require_relative "academy_content"

puts "Academy: seeding trails + lessons…"

violations = Academy::Content::ArcValidator.call(ACADEMY_CONTENT)
if violations.any?
  raise "Academy content viola os padrões de arco (002):\n  - #{violations.join("\n  - ")}"
end

Academy::GuideMessage.delete_all
Academy::GuideConversation.delete_all
Academy::LessonProgress.delete_all
Academy::Lesson.delete_all
Academy::Trail.delete_all

ACADEMY_CONTENT.each_with_index do |t, ti|
  trail = Academy::Trail.create!(
    slug: t[:slug], title: t[:title], hook: t[:hook],
    emoji: t[:emoji], accent: t[:accent], position: ti, active: true
  )
  t[:lessons].each_with_index do |l, li|
    Academy::Lesson.create!(
      trail: trail, slug: l[:slug], title: l[:title], enigma: l[:enigma],
      position: li, active: true,
      payload: l[:payload].deep_stringify_keys
    )
  end
  puts "  ✓ #{t[:title]} — #{t[:lessons].size} aulas"
end

puts "Academy: #{Academy::Trail.count} trilhas, #{Academy::Lesson.count} aulas. ✨"
