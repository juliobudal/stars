# Perguntas de Clarificação - Milestone UI/UX Duolingo 🦉

Antes de prosseguirmos com a especificação e o roadmap para o novo estilo Duolingo, precisamos alinhar alguns pontos técnicos:

1. **Stack Tecnológica (Contradição):**
   - O projeto atual é **Ruby on Rails 8** com **Vite**, **ViewComponent** e **Stimulus**.
   - O arquivo `specs.json` menciona **React 18** e **Framer Motion**.
   - **Pergunta:** Você deseja migrar o sistema para React ou devemos adaptar o estilo Duolingo (bordas 3D, animações, cores vibrantes) dentro da stack Rails/Stimulus atual?

2. **Escopo Visual:**
   - O estilo Duolingo deve ser aplicado apenas à **Kid View** (onde a diversão acontece) ou também à **Parent View** (dashboard administrativo)?
   - O Duolingo usa uma tipografia arredondada característica (ex: Feather, Din Round). Temos permissão para importar uma fonte similar (ex: Fredoka, Sniglet ou Nunito via Google Fonts)?

3. **Arquitetura de Componentes:**
   - Atualmente usamos o **JetRockets UI**. Para o estilo Duolingo, os componentes costumam ser muito customizados (especialmente botões com efeito "press").
   - **Pergunta:** Devemos criar componentes customizados "Duolingo-style" do zero ou tentar estender os do JetRockets via Tailwind?

4. **Animações:**
   - O `specs.json` detalha animações complexas (celebration, reward redemption). No Rails, costumamos usar **Stimulus** + **CSS Transitions** ou bibliotecas leves como **canvas-confetti**.
   - **Pergunta:** Se continuarmos no Rails, podemos usar Stimulus para replicar esses efeitos, ou você faz questão da precisão do Framer Motion (o que exigiria React)?
