# 4-Screen Design System

_Started 2026-05-06 12:50 UTC_

---

## User



## Assistant

I'll design the visual deliverables for Casa Mágica — an original game in the chibi/pastel kid-friendly aesthetic (not recreating any specific branded UI). Let me ask a few clarifying questions first since this is a substantial design task.

_[tool: questions_v2]_

## User

Questions answered:
- scope: Mockups de todas as 4 telas (visão geral)
- format: Design canvas (todas as telas + componentes lado a lado, zoomável)
- palette_lock: Usar como base mas refinar/harmonizar (oklch tuning)
- font: Decide for me
- illustration_approach: Decide for me
- animations: Só estado estático com notas de tween ao lado
- tweaks: Não precisa
- tweens_table: Decide for me

## Assistant

_[tool: update_todos]_

_[tool: copy_starter_component]_

My plan:

**Aesthetic direction (declared up front):**
- **Type:** Fredoka (rounded geometric sans) for everything — single family, weights 400/500/600/700. Plays well with chibi/pastel without feeling cartoonish-cheap.
- **Palette (refined oklch from the spec):** I'll re-tune the suggested hex values to share consistent lightness (~0.88) and chroma (~0.09) so they harmonize. Outline/text stays warm chocolate.
- **Illustration:** Mix approach. Avatars = chibi-geometric SVG (simple circle-head + body shapes, original — no Toca Boca recreation). Houses = isometric SVG built from primitives. Room icons = flat SVG with white outlines. Plants/clouds/butterflies = simple shapes.
- **Layout:** Design canvas with 5 sections — Foundations (palette + type + tweens), Screens (4 mockups at 1280×720), Components (buttons/cards/modals), Icons, Avatars/Houses sprite sheet.

Let me build it.

_[tool: write_file]_

_[tool: write_file]_

Now the screens and the main canvas:

_[tool: write_file]_

_[tool: write_file]_

_[tool: write_file]_

_[tool: snip]_

_[tool: done]_

_[tool: fork_verifier_agent]_

Pronto — design canvas com:

- **Fundações:** paleta oklch refinada (8 cores) + escala tipográfica Fredoka
- **4 telas (1280×720):** Seleção de criança, Cidade isométrica, Interior da casa, Modal de cômodo
- **Componentes:** botões (idle/hover/active), back, cards de cômodo, slot vazio
- **Ícones:** cama, fogão, sofá, banheira (SVG 128×128)
- **Personagens & casas:** 6 avatares chibi + 3 casas (rosa/amarela/azul)
- **Tweens:** tabela completa com 16 specs Phaser (duração, ease, loop, onde aplicar)

Próximos passos sugeridos: posso (1) refinar avatares específicos, (2) adicionar variantes de paleta, ou (3) demonstrar uma tela com animações ao vivo se quiser ver o movimento.

