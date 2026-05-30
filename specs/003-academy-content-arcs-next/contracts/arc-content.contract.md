# Contract — Conteúdo de Arco (gate do `ArcValidator`)

**Feature**: 003-academy-content-arcs-next

A "interface" desta feature é o **contrato de conteúdo** que `Academy::Content::ArcValidator.call(ACADEMY_CONTENT)` impõe. Não há API/endpoint novo. Este contrato é executável: violá-lo faz o seed (`db/seeds/academy.rb`) dar `raise` e a spec (`spec/seeds/academy_content_spec.rb`) falhar.

## Invariantes (devem retornar **zero** violações)

Para **cada** trilha nova (T6, T7) e para o conjunto completo (5 antigas + 2 novas):

| ID | Invariante | Verificação |
|---|---|---|
| C1 | `refrao` declarado e não vazio | presente na `revelation` de **todas** as 4 aulas (contíguo, normalizado) |
| C2 | `callback_anchor` declarado | presente no texto da **1ª** e da **última** aula (word-start) |
| C3 | `arc_payload_marker` declarado | presente em `trail.hook` **e** no texto da **última** aula |
| C4 | `cliffhanger_to` | se não-`nil`: slug existe e está `active`, e `hook` da última aula contém o **título** do destino; se `nil`: gancho aberto |
| C5 | Anti-clichê | nenhuma `BANNED_PHRASES` em qualquer texto da trilha |
| C6 | Estrutura | trilha tem ≥1 aula; cada aula tem `payload` com `clues[]`, `revelation`, `check{}`, `hook` |

## Valores travados (entrada esperada)

```text
trail tudo-quase-vazio:
  title               = "Tudo que parece sólido é quase vazio"
  refrao              = "quase vazio"
  callback_anchor     = "mão"
  arc_payload_marker  = "encostar"
  cliffhanger_to      = "voce-feito-de-estrelas"
  lessons             = [mao-mais-buraco, nunca-encostou, vazio-nao-desaba, torrao-de-acucar]

trail voce-feito-de-estrelas:
  title               = "Você é feito de estrelas mortas"
  refrao              = "emprestado do universo"
  callback_anchor     = "osso"
  arc_payload_marker  = "explosão"
  cliffhanger_to      = nil
  lessons             = [ferro-do-sangue, troca-de-corpo, respira-dinossauro, nada-se-perde]

trail as-palavras-mudam (edição mínima):
  cliffhanger_to      : nil  ->  "tudo-quase-vazio"
  última aula .hook   : passa a conter literal "Tudo que parece sólido é quase vazio"
```

## Casos de teste do contrato (a refletir em `spec/seeds/academy_content_spec.rb`)

1. **Conjunto válido** → `ArcValidator.call(ACADEMY_CONTENT)` retorna `[]`.
2. **Contagem** → `ACADEMY_CONTENT.size == 7`; cada trilha tem `lessons.size == 4`.
3. **Cadeia de cliffhanger** → `as-palavras-mudam → tudo-quase-vazio → voce-feito-de-estrelas → nil`, sem destino quebrado/inativo.
4. **Refrão por aula** (regressão de C1) → remover o refrão de uma revelação de T6/T7 produz violação.
5. **Cliffhanger nominal** (regressão de C4) → o `hook` final de `as-palavras-mudam` contém o título de `tudo-quase-vazio`; o de T6 contém o título de T7.
6. **Anti-clichê** (regressão de C5) → injetar uma frase da lista negra produz violação.

> O `ArcValidator` **não muda**. O trabalho é produzir conteúdo que satisfaça C1–C6; os testes 2/3 podem exigir assertivas novas de contagem/cadeia na spec existente.
