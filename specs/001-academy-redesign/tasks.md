# Tasks: Academy Redesign — Pílulas de Conhecimento

Ordenadas por dependência. `[P]` = pode rodar em paralelo com a anterior.

## Fase A — Schema novo
- [ ] T001 Migration: criar `academy_trails` (nova), `academy_lessons`, `academy_lesson_progresses`.
- [ ] T002 Migration: dropar guide_* antigas e recriar `academy_guide_conversations` (lesson_id) + `academy_guide_messages`. (ou rename mission_id→lesson_id)
- [ ] T003 Migration: drop das 20 tabelas mortas (ver plan §9). Rodar por último na fase de limpeza.

## Fase B — Models
- [ ] T010 `Academy::Trail` (validações, scope active, ordenação).
- [ ] T011 `Academy::Lesson` (belongs_to trail, validação de payload, helpers `clues/revelation/check/hook`).
- [ ] T012 `Academy::LessonProgress` (unique learner+lesson, scope completed).
- [ ] T013 Reescrever `Academy::GuideConversation` (belongs_to :lesson) + manter `GuideMessage`.

## Fase C — Services
- [ ] T020 `Academy::Lessons::Available` (status por aula na trilha).
- [ ] T021 `Academy::Lessons::Complete` (idempotente, check_correct, next_lesson).
- [ ] T022 Adaptar `Academy::Guide::FindOrStartConversation` (lesson).
- [ ] T023 Reescrever `Academy::Guide::BuildPrompt` (contexto = conteúdo da aula).
- [ ] T024 Adaptar `Academy::Guide::Ask` (lesson + quota 5/dia). Remover `Guide::Available`.

## Fase D — Rotas + Controllers
- [ ] T030 Reescrever bloco academy em `config/routes.rb` (kid + parent; remover admin).
- [ ] T031 `Kid::Academy::TrailsController` (index/show).
- [ ] T032 `Kid::Academy::LessonsController` (show/complete).
- [ ] T033 `Kid::Academy::GuidesController` (show/create).
- [ ] T034 `Parent::Academy::DashboardController` (index read-only).

## Fase E — Views + JS (DESIGN.md)
- [ ] T040 `kid/academy/trails/index` (home).
- [ ] T041 `kid/academy/trails/show` (nós da trilha).
- [ ] T042 `kid/academy/lessons/show` + `academy_pill_controller.js` (passos).
- [ ] T043 `kid/academy/guides/show` + `_message`.
- [ ] T044 `parent/academy/dashboard/index`.
- [ ] T045 Atualizar links/menu host que apontam pro academy.

## Fase F — Conteúdo
- [ ] T050 Reescrever `db/seeds/academy.rb` + criar 3-4 trilhas × ≥4 aulas (subagent + revisão).
- [ ] T051 Validador de payload no seed (falha cedo se malformado).

## Fase G — Limpeza
- [ ] T060 Deletar models/services/controllers/views/JS legados.
- [ ] T061 Limpar `spec/factories/academy.rb` + specs órfãos.
- [ ] T062 Rodar T003 (drops) após tudo desreferenciado.

## Fase H — Testes
- [ ] T070 Model + service specs (novos).
- [ ] T071 Request specs.
- [ ] T072 System spec (Capybara) do fluxo.
- [ ] T073 `make rspec` verde (geral).
- [ ] T074 Playwright E2E smoke (app rodando).
