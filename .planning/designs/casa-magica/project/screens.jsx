/* Casa Mágica — screen mockups (1280×720). Static. */

/* ─── Screen 1: Seleção de criança ─────────────────────────── */
const ScreenChildSelect = () => {
  const kids = [
    { name: "Lia",    skin: "#F4C9A0", hair: "#3A2818", shirt: "var(--pink)",  hairStyle: "long" },
    { name: "Beto",   skin: "#E8B58A", hair: "#6B4423", shirt: "var(--mint)",  hairStyle: "short" },
    { name: "Manu",   skin: "#C99373", hair: "#1F1209", shirt: "var(--lilac)", hairStyle: "buns" },
    { name: "Tom",    skin: "#F4C9A0", hair: "#A6743A", shirt: "var(--sky)",   hairStyle: "curly" },
  ];
  return (
    <div style={{
      width: 1280, height: 720, position: "relative",
      background: "linear-gradient(160deg, var(--sky-top) 0%, var(--pink) 100%)",
      borderRadius: 24, overflow: "hidden",
      fontFamily: "var(--font)",
    }}>
      {/* clouds */}
      <svg width="1280" height="720" style={{position: "absolute", inset: 0}}>
        <Cloud x={140} y={110} scale={1.2}/>
        <Cloud x={1080} y={90} scale={1}/>
        <Cloud x={620} y={60} scale={0.8} opacity={0.8}/>
      </svg>

      {/* title */}
      <div style={{
        position: "absolute", top: 56, left: 0, right: 0, textAlign: "center",
      }}>
        <div style={{
          display: "inline-block",
          background: "white",
          padding: "14px 44px",
          borderRadius: "var(--r-pill)",
          border: "4px solid var(--ink)",
          boxShadow: "0 6px 0 var(--ink)",
          fontSize: 44, fontWeight: 700, color: "var(--ink)",
        }}>Quem vai brincar?</div>
      </div>

      {/* avatar grid */}
      <div style={{
        position: "absolute", top: 200, left: 80, right: 80,
        display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 32,
        justifyItems: "center",
      }}>
        {kids.map(k => (
          <div key={k.name} style={{ textAlign: "center" }}>
            <div style={{
              width: 200, height: 200, borderRadius: "50%",
              background: "white",
              border: "5px solid var(--ink)",
              boxShadow: "0 8px 0 var(--ink), 0 18px 30px rgba(0,0,0,0.18)",
              display: "grid", placeItems: "center",
              overflow: "hidden",
            }}>
              <Avatar {...k} size={196}/>
            </div>
            <div style={{
              marginTop: 18, background: "white",
              padding: "8px 22px", display: "inline-block",
              borderRadius: "var(--r-pill)", border: "4px solid var(--ink)",
              boxShadow: "0 4px 0 var(--ink)",
              fontSize: 26, fontWeight: 700, color: "var(--ink)",
            }}>{k.name}</div>
          </div>
        ))}
        {/* Nova card */}
        <div style={{ textAlign: "center" }}>
          <div style={{
            width: 200, height: 200, borderRadius: "50%",
            background: "rgba(255,255,255,0.5)",
            border: "5px dashed var(--ink)",
            display: "grid", placeItems: "center",
            color: "var(--ink)",
          }}>
            <div style={{ textAlign: "center" }}>
              <div style={{ fontSize: 88, lineHeight: 0.9, fontWeight: 700 }}>+</div>
              <div style={{ fontSize: 24, fontWeight: 700, marginTop: 4 }}>Nova</div>
            </div>
          </div>
          <div style={{ marginTop: 18, padding: 12, fontSize: 26, fontWeight: 700,
                        color: "var(--ink-50)" }}>Adicionar</div>
        </div>
      </div>
    </div>
  );
};

/* ─── Screen 2: Cidade (iso) ───────────────────────────────── */
const ScreenCity = () => (
  <div style={{
    width: 1280, height: 720, position: "relative",
    background: "linear-gradient(180deg, var(--sky-top) 0%, oklch(0.92 0.06 200) 60%, var(--pink) 100%)",
    borderRadius: 24, overflow: "hidden",
    fontFamily: "var(--font)",
  }}>
    {/* sky elements */}
    <svg width="1280" height="720" style={{position: "absolute", inset: 0}}>
      <Cloud x={180} y={90} scale={1.1}/>
      <Cloud x={920} y={60} scale={0.9}/>
      <Cloud x={1140} y={140} scale={0.7} opacity={0.85}/>
      <Butterfly x={280} y={300} color="var(--lilac)"/>
      <Butterfly x={1000} y={260} color="var(--cream)"/>
      {/* path */}
      <path d="M-20 620 Q300 540 540 580 Q780 620 1000 540 Q1180 480 1320 520"
            stroke="var(--cream)" strokeWidth="60" fill="none" strokeLinecap="round"/>
      <path d="M-20 620 Q300 540 540 580 Q780 620 1000 540 Q1180 480 1320 520"
            stroke="var(--ink)" strokeWidth="4" fill="none" strokeDasharray="2 14"
            strokeLinecap="round" opacity="0.4"/>
      {/* grass ground tint */}
    </svg>
    {/* grass overlay */}
    <div style={{
      position: "absolute", left: 0, right: 0, bottom: 0, height: 320,
      background: "linear-gradient(180deg, transparent 0%, var(--mint) 40%, oklch(0.84 0.12 150) 100%)",
      pointerEvents: "none",
    }}/>

    {/* flowers + trees + houses */}
    <svg width="1280" height="720" style={{position: "absolute", inset: 0}}>
      {/* flowers scattered */}
      {[
        [120, 660, "var(--pink)"], [260, 690, "var(--cream)"], [430, 660, "var(--lilac)"],
        [700, 700, "var(--pink)"], [880, 680, "var(--cream)"], [1100, 660, "var(--lilac)"],
        [60, 700, "var(--cream)"], [520, 705, "var(--pink)"], [1200, 705, "var(--cream)"],
      ].map(([x,y,c],i) => <Flower key={i} x={x} y={y} color={c}/>)}
      <Tree x={90} y={520} scale={1.2}/>
      <Tree x={1180} y={500} scale={1.1}/>
      <Tree x={780} y={540} scale={0.9}/>
    </svg>

    {/* houses */}
    <div style={{
      position: "absolute", left: 0, right: 0, top: 240,
      display: "flex", justifyContent: "center", gap: 40,
    }}>
      <div style={{ transform: "translateY(20px)" }}><House tone="pink" size={300}/></div>
      <div style={{ transform: "translateY(-10px)" }}><House tone="yellow" size={300}/></div>
      <div style={{ transform: "translateY(20px)" }}><House tone="blue" size={300}/></div>
    </div>

    {/* HUD */}
    <BackBtn style={{ position: "absolute", top: 28, left: 28 }}/>
    <div style={{
      position: "absolute", top: 32, right: 32,
      display: "flex", alignItems: "center", gap: 14,
      background: "white", padding: "10px 18px 10px 10px",
      borderRadius: "var(--r-pill)",
      border: "4px solid var(--ink)",
      boxShadow: "0 6px 0 var(--ink)",
    }}>
      <div style={{ width: 56, height: 56, borderRadius: "50%",
                    background: "var(--pink)", border: "3px solid var(--ink)",
                    overflow: "hidden", display: "grid", placeItems: "center" }}>
        <Avatar skin="#F4C9A0" hair="#3A2818" shirt="var(--pink)" hairStyle="long" size={56}/>
      </div>
      <div style={{ fontSize: 26, fontWeight: 700, color: "var(--ink)", paddingRight: 8 }}>
        Lia
      </div>
    </div>
  </div>
);

/* ─── Screen 3: Interior da casa (room grid) ───────────────── */
const ScreenHouseInterior = () => (
  <div style={{
    width: 1280, height: 720, position: "relative",
    background: "linear-gradient(160deg, oklch(0.95 0.04 30) 0%, var(--peach) 100%)",
    borderRadius: 24, overflow: "hidden",
    fontFamily: "var(--font)",
  }}>
    <BackBtn style={{ position: "absolute", top: 28, left: 28 }}/>
    {/* title pill */}
    <div style={{
      position: "absolute", top: 40, left: 0, right: 0, textAlign: "center",
    }}>
      <div style={{
        display: "inline-flex", alignItems: "center", gap: 16,
        background: "white", padding: "14px 38px",
        borderRadius: "var(--r-pill)", border: "4px solid var(--ink)",
        boxShadow: "0 6px 0 var(--ink)",
        fontSize: 36, fontWeight: 700, color: "var(--ink)",
      }}>
        <span style={{ width: 40, height: 40, borderRadius: "50%",
                       background: "var(--pink)", border: "3px solid var(--ink)" }}/>
        Casa da Lia
      </div>
    </div>

    {/* room grid */}
    <div style={{
      position: "absolute", top: 160, left: 80, right: 80,
      display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 28,
      justifyItems: "center",
    }}>
      <RoomCard kind="bed"   label="Quarto"/>
      <RoomCard kind="stove" label="Cozinha"/>
      <RoomCard kind="sofa"  label="Sala"/>
      <RoomCard kind="bath"  label="Banho"/>
      <EmptySlot/>
      <EmptySlot/>
      <EmptySlot/>
      <EmptySlot/>
    </div>
  </div>
);

/* ─── Screen 4: Modal — escolha de template de cômodo ──────── */
const ScreenRoomTemplateModal = () => (
  <div style={{
    width: 1280, height: 720, position: "relative",
    background: "linear-gradient(160deg, oklch(0.95 0.04 30) 0%, var(--peach) 100%)",
    borderRadius: 24, overflow: "hidden",
    fontFamily: "var(--font)",
  }}>
    {/* dimmed underlying screen (room grid faintly visible) */}
    <div style={{
      position: "absolute", inset: 0,
      backgroundImage: "linear-gradient(160deg, oklch(0.95 0.04 30) 0%, var(--peach) 100%)",
      filter: "blur(2px)",
    }}/>
    <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.4)" }}/>

    {/* modal */}
    <div style={{
      position: "absolute", left: 100, right: 100, top: 70, bottom: 70,
      background: "white",
      borderRadius: 32,
      border: "5px solid var(--ink)",
      boxShadow: "0 16px 0 var(--ink), 0 30px 60px rgba(0,0,0,0.3)",
      padding: "32px 48px",
      display: "flex", flexDirection: "column",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
        <div style={{
          width: 64, height: 64, borderRadius: 18,
          background: "linear-gradient(160deg, oklch(0.94 0.06 305), oklch(0.84 0.10 305))",
          border: "3px solid var(--ink)",
          display: "grid", placeItems: "center",
        }}>
          <RoomIcon kind="bed" size={48}/>
        </div>
        <div style={{ fontSize: 40, fontWeight: 700, color: "var(--ink)" }}>
          Escolher cômodo
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{
          width: 56, height: 56, borderRadius: "50%",
          background: "var(--pink)", border: "4px solid var(--ink)",
          boxShadow: "0 4px 0 var(--ink)",
          display: "grid", placeItems: "center",
          fontSize: 36, fontWeight: 700, color: "white",
        }}>×</div>
      </div>

      <div style={{
        marginTop: 28, flex: 1,
        display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 24,
        justifyItems: "center", alignItems: "center",
      }}>
        <RoomCard kind="bed"   label="Quarto" w={220} h={260}/>
        <RoomCard kind="stove" label="Cozinha" w={220} h={260}/>
        <RoomCard kind="sofa"  label="Sala" w={220} h={260}/>
        <RoomCard kind="bath"  label="Banho" w={220} h={260}/>
      </div>
    </div>
  </div>
);

Object.assign(window, {
  ScreenChildSelect, ScreenCity, ScreenHouseInterior, ScreenRoomTemplateModal,
});
