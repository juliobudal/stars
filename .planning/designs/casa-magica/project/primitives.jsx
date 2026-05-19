/* Reusable visual primitives for Casa Mágica mockups.
   Static (no live animation) — animation specs documented in tweens table. */

const Btn = ({ children, color = "pink", size = "md", style }) => {
  const colors = {
    pink:  ["var(--pink)",  "var(--pink-2)"],
    lilac: ["var(--lilac)", "var(--lilac-2)"],
    mint:  ["var(--mint)",  "var(--mint-2)"],
    peach: ["var(--peach)", "var(--peach-2)"],
    cream: ["var(--cream)", "var(--cream-2)"],
    sky:   ["var(--sky)",   "var(--sky-2)"],
  }[color];
  const sizes = {
    sm: { padding: "12px 22px", fontSize: 20, height: 50 },
    md: { padding: "18px 36px", fontSize: 28, height: 72 },
    lg: { padding: "22px 48px", fontSize: 32, height: 84 },
  }[size];
  return (
    <button style={{
      ...sizes,
      background: `linear-gradient(180deg, ${colors[0]} 0%, ${colors[1]} 100%)`,
      border: "4px solid var(--ink)",
      borderRadius: "var(--r-pill)",
      color: "white",
      fontFamily: "var(--font)",
      fontWeight: 700,
      letterSpacing: 0.5,
      textShadow: `0 2px 0 ${colors[1]}`,
      boxShadow: `0 6px 0 var(--ink), 0 10px 20px ${colors[1]}40`,
      cursor: "pointer",
      ...style,
    }}>{children}</button>
  );
};

const BackBtn = ({ style }) => (
  <div style={{
    width: 80, height: 80,
    borderRadius: "50%",
    background: "linear-gradient(180deg, var(--ivory) 0%, var(--cream) 100%)",
    border: "4px solid var(--ink)",
    boxShadow: "0 6px 0 var(--ink)",
    display: "grid", placeItems: "center",
    ...style,
  }}>
    <svg width="38" height="38" viewBox="0 0 24 24" fill="none">
      <path d="M15 5 L7 12 L15 19" stroke="var(--ink)" strokeWidth="4"
            strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  </div>
);

/* Chibi avatar — original, geometric. Color-keyed.
   Spec: 256x256, idle breathing 1.0↔1.03 scaleY, blink 3-5s. */
const Avatar = ({ skin = "#F4C9A0", hair = "#6B4423", shirt = "var(--pink)",
                  hairStyle = "short", size = 180 }) => (
  <svg viewBox="0 0 256 256" width={size} height={size}>
    {/* shadow */}
    <ellipse cx="128" cy="234" rx="64" ry="8" fill="rgba(0,0,0,0.15)" />
    {/* body */}
    <path d="M70 220 Q70 160 128 160 Q186 160 186 220 Z" fill={shirt} stroke="var(--ink)" strokeWidth="4"/>
    {/* neck */}
    <rect x="116" y="146" width="24" height="20" fill={skin} stroke="var(--ink)" strokeWidth="4"/>
    {/* head */}
    <circle cx="128" cy="100" r="62" fill={skin} stroke="var(--ink)" strokeWidth="4"/>
    {/* hair */}
    {hairStyle === "short" && (
      <path d="M68 96 Q68 38 128 38 Q188 38 188 96 Q170 78 150 80 Q140 70 128 72 Q116 70 106 80 Q86 78 68 96 Z"
            fill={hair} stroke="var(--ink)" strokeWidth="4"/>
    )}
    {hairStyle === "long" && (
      <path d="M62 110 Q56 38 128 38 Q200 38 194 110 Q190 150 180 160 L180 110 Q170 90 150 88 Q140 76 128 78 Q116 76 106 88 Q86 90 76 110 L76 160 Q66 150 62 110 Z"
            fill={hair} stroke="var(--ink)" strokeWidth="4"/>
    )}
    {hairStyle === "buns" && (
      <>
        <path d="M68 96 Q68 50 128 50 Q188 50 188 96 Q170 78 150 80 Q140 70 128 72 Q116 70 106 80 Q86 78 68 96 Z"
              fill={hair} stroke="var(--ink)" strokeWidth="4"/>
        <circle cx="68" cy="62" r="22" fill={hair} stroke="var(--ink)" strokeWidth="4"/>
        <circle cx="188" cy="62" r="22" fill={hair} stroke="var(--ink)" strokeWidth="4"/>
      </>
    )}
    {hairStyle === "curly" && (
      <g stroke="var(--ink)" strokeWidth="4" fill={hair}>
        <circle cx="80" cy="70" r="22"/>
        <circle cx="110" cy="50" r="22"/>
        <circle cx="146" cy="48" r="22"/>
        <circle cx="178" cy="68" r="22"/>
        <circle cx="70" cy="100" r="18"/>
        <circle cx="190" cy="100" r="18"/>
      </g>
    )}
    {/* cheeks */}
    <circle cx="86" cy="118" r="9" fill="oklch(0.82 0.10 15)" opacity="0.7"/>
    <circle cx="170" cy="118" r="9" fill="oklch(0.82 0.10 15)" opacity="0.7"/>
    {/* eyes */}
    <ellipse cx="100" cy="104" rx="9" ry="12" fill="var(--ink)"/>
    <ellipse cx="156" cy="104" rx="9" ry="12" fill="var(--ink)"/>
    <circle cx="103" cy="100" r="3" fill="white"/>
    <circle cx="159" cy="100" r="3" fill="white"/>
    {/* smile */}
    <path d="M112 132 Q128 144 144 132" stroke="var(--ink)" strokeWidth="4" fill="none" strokeLinecap="round"/>
  </svg>
);

/* Isometric house — color variants */
const House = ({ tone = "pink", size = 320 }) => {
  const palettes = {
    pink:   { wall: "var(--pink)",   wall2: "var(--pink-2)",   roof: "oklch(0.55 0.14  10)" },
    yellow: { wall: "var(--cream)",  wall2: "var(--cream-2)",  roof: "oklch(0.55 0.14  55)" },
    blue:   { wall: "var(--sky)",    wall2: "var(--sky-2)",    roof: "oklch(0.55 0.14 240)" },
  };
  const p = palettes[tone];
  return (
    <svg viewBox="0 0 320 320" width={size} height={size}>
      {/* shadow */}
      <ellipse cx="160" cy="296" rx="120" ry="14" fill="rgba(0,0,0,0.15)"/>
      {/* base block (iso 3/4) */}
      <path d="M60 240 L60 160 L160 110 L260 160 L260 240 L160 290 Z"
            fill={p.wall} stroke="var(--ink)" strokeWidth="4" strokeLinejoin="round"/>
      {/* right side darker */}
      <path d="M160 290 L160 210 L260 160 L260 240 Z" fill={p.wall2}
            stroke="var(--ink)" strokeWidth="4" strokeLinejoin="round"/>
      {/* roof */}
      <path d="M40 160 L160 60 L280 160 L160 210 Z" fill={p.roof}
            stroke="var(--ink)" strokeWidth="4" strokeLinejoin="round"/>
      {/* roof shadow line */}
      <path d="M160 60 L160 210" stroke="var(--ink)" strokeWidth="4" opacity="0.3"/>
      {/* chimney */}
      <rect x="200" y="80" width="22" height="34" fill={p.roof}
            stroke="var(--ink)" strokeWidth="4"/>
      {/* smoke puffs (3) */}
      <circle cx="211" cy="68"  r="8"  fill="white" opacity="0.9" stroke="var(--ink)" strokeWidth="3"/>
      <circle cx="218" cy="50"  r="10" fill="white" opacity="0.7" stroke="var(--ink)" strokeWidth="3"/>
      <circle cx="208" cy="32"  r="12" fill="white" opacity="0.5" stroke="var(--ink)" strokeWidth="3"/>
      {/* door */}
      <path d="M126 240 L126 188 Q126 174 144 168 L144 230 Z"
            fill="var(--choco)" stroke="var(--ink)" strokeWidth="4" strokeLinejoin="round"/>
      <circle cx="138" cy="208" r="3" fill="var(--cream)"/>
      {/* window left (glow) */}
      <rect x="78" y="178" width="32" height="32" rx="6" fill="var(--cream)"
            stroke="var(--ink)" strokeWidth="4"/>
      <path d="M94 178 L94 210 M78 194 L110 194" stroke="var(--ink)" strokeWidth="3"/>
      {/* window right */}
      <rect x="190" y="200" width="28" height="28" rx="6" fill="var(--cream)"
            stroke="var(--ink)" strokeWidth="4"/>
      <path d="M204 200 L204 228 M190 214 L218 214" stroke="var(--ink)" strokeWidth="3"/>
    </svg>
  );
};

/* Room icon — flat with subtle gradient + thick white outline.
   Variants: bed, stove, sofa, bath. 128×128. */
const RoomIcon = ({ kind = "bed", size = 120 }) => {
  const wrap = (g) => (
    <svg viewBox="0 0 128 128" width={size} height={size}>
      <g stroke="white" strokeWidth="6" strokeLinejoin="round" strokeLinecap="round">{g}</g>
      <g stroke="var(--ink)" strokeWidth="3" strokeLinejoin="round" strokeLinecap="round" fill="none">{g}</g>
    </svg>
  );
  if (kind === "bed") return wrap(
    <>
      <rect x="14" y="58" width="100" height="40" rx="10" fill="oklch(0.78 0.10 305)"/>
      <rect x="22" y="42" width="36" height="22" rx="6" fill="white"/>
      <path d="M40 56 Q34 48 32 54 Q30 48 24 54 Q24 62 32 66 Q40 62 40 56 Z" fill="var(--pink)"/>
      <rect x="14" y="92" width="14" height="22" fill="oklch(0.66 0.14 305)"/>
      <rect x="100" y="92" width="14" height="22" fill="oklch(0.66 0.14 305)"/>
    </>
  );
  if (kind === "stove") return wrap(
    <>
      <rect x="20" y="50" width="88" height="58" rx="10" fill="oklch(0.86 0.09 55)"/>
      <rect x="28" y="74" width="72" height="28" rx="4" fill="white"/>
      <circle cx="46" cy="62" r="6" fill="var(--ink)"/>
      <circle cx="82" cy="62" r="6" fill="var(--ink)"/>
      {/* pot */}
      <rect x="44" y="30" width="40" height="20" rx="4" fill="var(--choco)"/>
      <rect x="38" y="26" width="52" height="6" rx="2" fill="var(--choco)"/>
      {/* steam */}
      <path d="M54 22 Q50 14 56 8 Q60 4 58 -2" stroke="white" strokeWidth="5" fill="none"/>
      <path d="M68 22 Q72 14 66 8 Q62 4 64 -2" stroke="white" strokeWidth="5" fill="none"/>
    </>
  );
  if (kind === "sofa") return wrap(
    <>
      <rect x="14" y="58" width="100" height="40" rx="14" fill="oklch(0.90 0.09 160)"/>
      <rect x="22" y="44" width="28" height="26" rx="8" fill="oklch(0.80 0.13 160)"/>
      <rect x="78" y="44" width="28" height="26" rx="8" fill="oklch(0.80 0.13 160)"/>
      <rect x="10" y="70" width="14" height="32" rx="6" fill="oklch(0.80 0.13 160)"/>
      <rect x="104" y="70" width="14" height="32" rx="6" fill="oklch(0.80 0.13 160)"/>
      <rect x="22" y="98" width="10" height="14" fill="var(--choco)"/>
      <rect x="96" y="98" width="10" height="14" fill="var(--choco)"/>
    </>
  );
  if (kind === "bath") return wrap(
    <>
      <path d="M16 70 Q16 60 28 60 L100 60 Q112 60 112 70 L108 96 Q106 108 94 108 L34 108 Q22 108 20 96 Z"
            fill="oklch(0.88 0.07 245)"/>
      <ellipse cx="64" cy="70" rx="44" ry="6" fill="white" opacity="0.6"/>
      {/* bubbles */}
      <circle cx="40" cy="44" r="9" fill="white" opacity="0.8"/>
      <circle cx="64" cy="32" r="11" fill="white" opacity="0.8"/>
      <circle cx="84" cy="46" r="7" fill="white" opacity="0.8"/>
      <circle cx="100" cy="36" r="6" fill="white" opacity="0.8"/>
      {/* faucet */}
      <path d="M22 60 L22 50 L36 50" fill="none"/>
    </>
  );
  return null;
};

/* Room card with type-keyed gradient */
const RoomCard = ({ kind, label, w = 240, h = 280 }) => {
  const grad = {
    bed:   ["oklch(0.92 0.06 305)", "oklch(0.84 0.10 305)"],
    stove: ["oklch(0.94 0.06 55)",  "oklch(0.86 0.10 55)"],
    sofa:  ["oklch(0.94 0.06 160)", "oklch(0.86 0.10 160)"],
    bath:  ["oklch(0.94 0.05 245)", "oklch(0.86 0.08 245)"],
  }[kind];
  return (
    <div style={{
      width: w, height: h,
      borderRadius: 28,
      background: `linear-gradient(160deg, ${grad[0]}, ${grad[1]})`,
      border: "4px solid var(--ink)",
      boxShadow: "0 8px 0 var(--ink), 0 18px 30px rgba(0,0,0,0.14)",
      display: "flex", flexDirection: "column",
      alignItems: "center", justifyContent: "center",
      gap: 16, padding: 20,
    }}>
      <div style={{
        width: 140, height: 140, borderRadius: 24,
        background: "rgba(255,255,255,0.55)",
        border: "3px dashed rgba(107,68,35,0.35)",
        display: "grid", placeItems: "center",
      }}>
        <RoomIcon kind={kind} />
      </div>
      <div style={{
        fontFamily: "var(--font)", fontWeight: 700, fontSize: 28,
        color: "var(--ink)",
      }}>{label}</div>
    </div>
  );
};

const EmptySlot = ({ w = 240, h = 280, label = "Adicionar" }) => (
  <div style={{
    width: w, height: h,
    borderRadius: 28,
    background: "rgba(255,255,255,0.5)",
    border: "4px dashed var(--ink-50)",
    display: "flex", flexDirection: "column",
    alignItems: "center", justifyContent: "center",
    gap: 14, color: "var(--ink-50)",
    fontFamily: "var(--font)", fontWeight: 600, fontSize: 22,
  }}>
    <div style={{
      width: 80, height: 80, borderRadius: "50%",
      border: "4px dashed var(--ink-50)",
      display: "grid", placeItems: "center", fontSize: 56, lineHeight: 1,
      paddingBottom: 10,
    }}>+</div>
    {label}
  </div>
);

/* Cloud */
const Cloud = ({ x, y, scale = 1, opacity = 1 }) => (
  <g transform={`translate(${x} ${y}) scale(${scale})`} opacity={opacity}>
    <ellipse cx="0" cy="0" rx="40" ry="22" fill="white"/>
    <ellipse cx="-26" cy="6" rx="22" ry="16" fill="white"/>
    <ellipse cx="26" cy="6" rx="24" ry="18" fill="white"/>
    <ellipse cx="0" cy="-10" rx="22" ry="16" fill="white"/>
  </g>
);

/* Tree */
const Tree = ({ x, y, scale = 1 }) => (
  <g transform={`translate(${x} ${y}) scale(${scale})`}>
    <rect x="-8" y="0" width="16" height="22" fill="var(--choco)" stroke="var(--ink)" strokeWidth="3"/>
    <circle cx="0" cy="-6" r="32" fill="oklch(0.78 0.13 150)" stroke="var(--ink)" strokeWidth="4"/>
    <circle cx="-14" cy="-18" r="18" fill="oklch(0.85 0.11 150)" stroke="var(--ink)" strokeWidth="4"/>
    <circle cx="14" cy="-16" r="16" fill="oklch(0.85 0.11 150)" stroke="var(--ink)" strokeWidth="4"/>
  </g>
);

/* Flower */
const Flower = ({ x, y, color = "var(--pink)" }) => (
  <g transform={`translate(${x} ${y})`}>
    {[0,72,144,216,288].map(a => (
      <circle key={a} cx={Math.cos(a*Math.PI/180)*7} cy={Math.sin(a*Math.PI/180)*7}
              r="6" fill={color} stroke="var(--ink)" strokeWidth="2"/>
    ))}
    <circle cx="0" cy="0" r="5" fill="var(--cream)" stroke="var(--ink)" strokeWidth="2"/>
  </g>
);

/* Butterfly */
const Butterfly = ({ x, y, color = "var(--lilac)" }) => (
  <g transform={`translate(${x} ${y})`}>
    <ellipse cx="-7" cy="-3" rx="7" ry="9" fill={color} stroke="var(--ink)" strokeWidth="2"/>
    <ellipse cx="7" cy="-3" rx="7" ry="9" fill={color} stroke="var(--ink)" strokeWidth="2"/>
    <ellipse cx="-6" cy="6" rx="5" ry="6" fill={color} stroke="var(--ink)" strokeWidth="2"/>
    <ellipse cx="6" cy="6" rx="5" ry="6" fill={color} stroke="var(--ink)" strokeWidth="2"/>
    <rect x="-1" y="-6" width="2" height="14" rx="1" fill="var(--ink)"/>
  </g>
);

Object.assign(window, { Btn, BackBtn, Avatar, House, RoomIcon, RoomCard, EmptySlot,
  Cloud, Tree, Flower, Butterfly });
