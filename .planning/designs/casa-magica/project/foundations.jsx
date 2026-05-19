/* Foundations: palette swatches, type scale, tween table */

const PaletteSwatch = ({ name, varName, hex }) => (
  <div style={{
    width: 200, borderRadius: 20,
    background: "white", border: "4px solid var(--ink)",
    boxShadow: "0 6px 0 var(--ink)",
    overflow: "hidden", fontFamily: "var(--font)",
  }}>
    <div style={{ height: 130, background: `var(${varName})` }}/>
    <div style={{ padding: "12px 16px" }}>
      <div style={{ fontSize: 22, fontWeight: 700, color: "var(--ink)" }}>{name}</div>
      <div style={{ fontSize: 14, color: "var(--ink-50)", fontFamily: "ui-monospace, monospace" }}>
        {varName}
      </div>
      <div style={{ fontSize: 14, color: "var(--ink-50)", fontFamily: "ui-monospace, monospace" }}>
        {hex}
      </div>
    </div>
  </div>
);

const Palette = () => (
  <div style={{
    display: "flex", gap: 20, flexWrap: "wrap",
    padding: 30, background: "var(--ivory)",
    borderRadius: 24, border: "3px solid var(--ink-50)",
    width: 1280,
  }}>
    <PaletteSwatch name="Rosa-bebê"   varName="--pink"  hex="≈ #FFB6C1"/>
    <PaletteSwatch name="Lilás"       varName="--lilac" hex="≈ #C9A7E8"/>
    <PaletteSwatch name="Amarelo"     varName="--cream" hex="≈ #FFE5A3"/>
    <PaletteSwatch name="Verde-menta" varName="--mint"  hex="≈ #A8E6CF"/>
    <PaletteSwatch name="Azul-céu"    varName="--sky"   hex="≈ #B5D8FF"/>
    <PaletteSwatch name="Pêssego"     varName="--peach" hex="≈ #FFCBA4"/>
    <PaletteSwatch name="Marfim"      varName="--ivory" hex="≈ #FFF8F0"/>
    <PaletteSwatch name="Chocolate"   varName="--choco" hex="≈ #6B4423"/>
  </div>
);

const TypeScale = () => (
  <div style={{
    width: 1280, padding: 40, borderRadius: 24,
    background: "var(--ivory)", border: "3px solid var(--ink-50)",
    fontFamily: "var(--font)", color: "var(--ink)",
  }}>
    <div style={{ display: "flex", alignItems: "baseline", gap: 24, marginBottom: 16 }}>
      <span style={{ fontSize: 14, color: "var(--ink-50)",
                     fontFamily: "ui-monospace, monospace", width: 110 }}>H1 / 64 / 700</span>
      <span style={{ fontSize: 64, fontWeight: 700 }}>Casa Mágica</span>
    </div>
    <div style={{ display: "flex", alignItems: "baseline", gap: 24, marginBottom: 16 }}>
      <span style={{ fontSize: 14, color: "var(--ink-50)",
                     fontFamily: "ui-monospace, monospace", width: 110 }}>H2 / 40 / 700</span>
      <span style={{ fontSize: 40, fontWeight: 700 }}>Quem vai brincar?</span>
    </div>
    <div style={{ display: "flex", alignItems: "baseline", gap: 24, marginBottom: 16 }}>
      <span style={{ fontSize: 14, color: "var(--ink-50)",
                     fontFamily: "ui-monospace, monospace", width: 110 }}>H3 / 28 / 600</span>
      <span style={{ fontSize: 28, fontWeight: 600 }}>Escolher cômodo</span>
    </div>
    <div style={{ display: "flex", alignItems: "baseline", gap: 24 }}>
      <span style={{ fontSize: 14, color: "var(--ink-50)",
                     fontFamily: "ui-monospace, monospace", width: 110 }}>Body / 28 / 500</span>
      <span style={{ fontSize: 28, fontWeight: 500 }}>Toque para começar a brincar.</span>
    </div>
    <div style={{ marginTop: 26, fontSize: 16, color: "var(--ink-50)" }}>
      Família única: <strong style={{ color: "var(--ink)" }}>Fredoka</strong>
      &nbsp;(weights 400/500/600/700). Fallback:&nbsp;
      <code>system-ui, sans-serif</code>.
    </div>
  </div>
);

const TweenRow = ({ name, props, dur, ease, loop, where }) => (
  <tr>
    <td style={td}>{name}</td>
    <td style={tdMono}>{props}</td>
    <td style={tdMono}>{dur}</td>
    <td style={tdMono}>{ease}</td>
    <td style={tdMono}>{loop}</td>
    <td style={td}>{where}</td>
  </tr>
);
const td     = { padding: "12px 16px", fontSize: 18, color: "var(--ink)",
                 borderBottom: "2px solid oklch(0.36 0.05 55 / 0.12)", verticalAlign: "top" };
const tdMono = { ...td, fontFamily: "ui-monospace, monospace", fontSize: 16 };
const th     = { padding: "14px 16px", fontSize: 16, color: "var(--ink)",
                 textAlign: "left", textTransform: "uppercase", letterSpacing: 0.8,
                 background: "var(--cream)", borderBottom: "3px solid var(--ink)",
                 fontWeight: 700 };

const TweenTable = () => (
  <div style={{
    width: 1280, padding: 30, borderRadius: 24,
    background: "var(--ivory)", border: "3px solid var(--ink-50)",
    fontFamily: "var(--font)",
  }}>
    <div style={{ fontSize: 28, fontWeight: 700, color: "var(--ink)", marginBottom: 14 }}>
      Specs de tween (Phaser 3)
    </div>
    <table style={{ width: "100%", borderCollapse: "collapse",
                    background: "white", borderRadius: 16, overflow: "hidden",
                    border: "3px solid var(--ink)" }}>
      <thead>
        <tr>
          <th style={th}>Nome</th>
          <th style={th}>Propriedades</th>
          <th style={th}>Duração</th>
          <th style={th}>Ease</th>
          <th style={th}>Loop / Yoyo</th>
          <th style={th}>Onde aplicar</th>
        </tr>
      </thead>
      <tbody>
        <TweenRow name="Idle bounce"  props="y: ±4 px"            dur="1200 ms" ease="Sine.easeInOut" loop="loop, yoyo" where="Avatares, casas"/>
        <TweenRow name="Idle breath"  props="scaleY: 1.0 ↔ 1.03"  dur="1500 ms" ease="Sine.easeInOut" loop="loop, yoyo" where="Avatares (respiração)"/>
        <TweenRow name="Blink"        props="scaleY: 1 → 0.05"    dur="120 ms"  ease="Quad.easeOut"   loop="random 3–5 s" where="Olhos do avatar"/>
        <TweenRow name="Wave"         props="rotate: 0 ↔ 18°"     dur="320 ms"  ease="Sine.easeInOut" loop="3× yoyo"     where="Avatar on-hover"/>
        <TweenRow name="Hover scale"  props="scale: 1.0 → 1.05"   dur="200 ms"  ease="Back.easeOut"   loop="—"            where="Casas, cards, botões"/>
        <TweenRow name="Tap squish"   props="scaleY: 0.92"        dur="80 ms"   ease="Quad.easeOut"   loop="yoyo"        where="Cards, ícones"/>
        <TweenRow name="Pulse atenção" props="scale: 1.0 ↔ 1.08"  dur="800 ms"  ease="Sine.easeInOut" loop="loop, yoyo"  where="CTA principal"/>
        <TweenRow name="Lift card"    props="y: -8, shadowBlur: +"  dur="180 ms" ease="Cubic.easeOut" loop="—"           where="RoomCard hover"/>
        <TweenRow name="Smoke puff"   props="alpha: 1→0, y: -40"  dur="1500 ms" ease="Quad.easeOut"   loop="repeat -1"   where="Chaminé"/>
        <TweenRow name="Window glow"  props="alpha: 0.6 ↔ 1.0"    dur="1400 ms" ease="Sine.easeInOut" loop="loop, yoyo"  where="Janelas das casas"/>
        <TweenRow name="Cloud drift"  props="x: +∞"               dur="40000 ms" ease="Linear"        loop="loop"        where="Nuvens"/>
        <TweenRow name="Cloud bob"    props="y: ±6 px"            dur="3500 ms" ease="Sine.easeInOut" loop="loop, yoyo"  where="Nuvens"/>
        <TweenRow name="Butterfly path" props="bezier curve"      dur="6000 ms" ease="Sine.easeInOut" loop="loop"        where="Borboletas/pássaros"/>
        <TweenRow name="Modal in"     props="scale: 0.8→1, alpha 0→1" dur="300 ms" ease="Back.easeOut" loop="—"          where="Modais"/>
        <TweenRow name="Confetti burst" props="emit 24, gravity 600" dur="1200 ms" ease="Cubic.easeOut" loop="—"         where="Feedback positivo"/>
        <TweenRow name="Scene fade"   props="alpha: 0 → 1 (preto)"  dur="400 ms" ease="Linear"         loop="—"          where="Transições"/>
      </tbody>
    </table>
  </div>
);

/* Component sheet: buttons + back + room cards + empty slot */
const ComponentSheet = () => (
  <div style={{
    width: 1280, padding: 40, borderRadius: 24,
    background: "var(--ivory)", border: "3px solid var(--ink-50)",
    fontFamily: "var(--font)", color: "var(--ink)",
    display: "flex", flexDirection: "column", gap: 32,
  }}>
    <div>
      <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 16 }}>Botões primários (estados)</div>
      <div style={{ display: "flex", gap: 24, alignItems: "flex-end", flexWrap: "wrap" }}>
        <div style={{ textAlign: "center" }}>
          <Btn color="pink">Jogar</Btn>
          <div style={{ fontSize: 14, marginTop: 8, color: "var(--ink-50)" }}>idle</div>
        </div>
        <div style={{ textAlign: "center" }}>
          <div style={{ transform: "translateY(-2px)" }}>
            <Btn color="pink" style={{ boxShadow: "0 8px 0 var(--ink), 0 14px 28px rgba(0,0,0,0.15)" }}>Jogar</Btn>
          </div>
          <div style={{ fontSize: 14, marginTop: 8, color: "var(--ink-50)" }}>hover (lift 2px)</div>
        </div>
        <div style={{ textAlign: "center" }}>
          <div style={{ transform: "translateY(6px)" }}>
            <Btn color="pink" style={{ boxShadow: "0 0 0 var(--ink)" }}>Jogar</Btn>
          </div>
          <div style={{ fontSize: 14, marginTop: 8, color: "var(--ink-50)" }}>active (squish)</div>
        </div>
        <Btn color="mint">Continuar</Btn>
        <Btn color="lilac">Salvar</Btn>
        <Btn color="cream" size="sm">Voltar ao mapa</Btn>
      </div>
    </div>

    <div>
      <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 16 }}>Botão circular "voltar"</div>
      <BackBtn/>
    </div>

    <div>
      <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 16 }}>Cards de cômodo + slot vazio</div>
      <div style={{ display: "flex", gap: 24, flexWrap: "wrap" }}>
        <RoomCard kind="bed"   label="Quarto"/>
        <RoomCard kind="stove" label="Cozinha"/>
        <RoomCard kind="sofa"  label="Sala"/>
        <RoomCard kind="bath"  label="Banho"/>
        <EmptySlot/>
      </div>
    </div>
  </div>
);

const IconSheet = () => (
  <div style={{
    width: 1280, padding: 40, borderRadius: 24,
    background: "var(--ivory)", border: "3px solid var(--ink-50)",
    fontFamily: "var(--font)", color: "var(--ink)",
  }}>
    <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 18 }}>
      Ícones de cômodo (128×128 SVG, outline branco grosso)
    </div>
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 24 }}>
      {[
        ["bed", "Cama", "var(--lilac)"],
        ["stove", "Fogão", "var(--peach)"],
        ["sofa", "Sofá", "var(--mint)"],
        ["bath", "Banheira", "var(--sky)"],
      ].map(([kind, label, bg]) => (
        <div key={kind} style={{
          background: bg, borderRadius: 24, padding: 24,
          border: "4px solid var(--ink)", boxShadow: "0 6px 0 var(--ink)",
          textAlign: "center",
        }}>
          <RoomIcon kind={kind}/>
          <div style={{ fontSize: 22, fontWeight: 700, marginTop: 8 }}>{label}</div>
        </div>
      ))}
    </div>
  </div>
);

const AvatarSheet = () => {
  const kids = [
    { name: "Lia",   skin: "#F4C9A0", hair: "#3A2818", shirt: "var(--pink)",   hairStyle: "long" },
    { name: "Beto",  skin: "#E8B58A", hair: "#6B4423", shirt: "var(--mint)",   hairStyle: "short" },
    { name: "Manu",  skin: "#C99373", hair: "#1F1209", shirt: "var(--lilac)",  hairStyle: "buns" },
    { name: "Tom",   skin: "#F4C9A0", hair: "#A6743A", shirt: "var(--sky)",    hairStyle: "curly" },
    { name: "Iris",  skin: "#E8B58A", hair: "#5A2E0F", shirt: "var(--peach)",  hairStyle: "long" },
    { name: "Davi",  skin: "#C99373", hair: "#0F0A06", shirt: "var(--cream)",  hairStyle: "short" },
  ];
  return (
    <div style={{
      width: 1280, padding: 40, borderRadius: 24,
      background: "var(--ivory)", border: "3px solid var(--ink-50)",
      fontFamily: "var(--font)", color: "var(--ink)",
    }}>
      <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 18 }}>
        Avatares chibi (256×256 base, idle: scaleY 1.0↔1.03 / 1.5s + blink 3–5s)
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(6, 1fr)", gap: 20,
                    justifyItems: "center" }}>
        {kids.map(k => (
          <div key={k.name} style={{ textAlign: "center" }}>
            <div style={{
              width: 180, height: 180, borderRadius: 28,
              background: "white", border: "4px solid var(--ink)",
              boxShadow: "0 6px 0 var(--ink)",
              display: "grid", placeItems: "center", overflow: "hidden",
            }}>
              <Avatar {...k} size={176}/>
            </div>
            <div style={{ marginTop: 10, fontSize: 22, fontWeight: 700 }}>{k.name}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

const HouseSheet = () => (
  <div style={{
    width: 1280, padding: 40, borderRadius: 24,
    background: "var(--ivory)", border: "3px solid var(--ink-50)",
    fontFamily: "var(--font)", color: "var(--ink)",
  }}>
    <div style={{ fontSize: 22, fontWeight: 700, marginBottom: 18 }}>
      Casas (320×320 — 3 variantes de cor; chaminé com 3 puffs em loop, janelas pulsantes)
    </div>
    <div style={{ display: "flex", justifyContent: "space-around", alignItems: "flex-end" }}>
      {["pink","yellow","blue"].map(t => (
        <div key={t} style={{ textAlign: "center" }}>
          <House tone={t}/>
          <div style={{ marginTop: 10, fontSize: 22, fontWeight: 700, textTransform: "capitalize" }}>{t}</div>
        </div>
      ))}
    </div>
  </div>
);

Object.assign(window, { Palette, TypeScale, TweenTable, ComponentSheet, IconSheet, AvatarSheet, HouseSheet });
