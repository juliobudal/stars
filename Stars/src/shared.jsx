// Shared primitives used by both directions — the star mascot,
// smiley avatars (emoji-style), icons for task categories.

// ── Star mascot (the little yellow star with a face) ─────────────
const StarMascot = ({ size = 56, wink = false }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden>
    <defs>
      <linearGradient id="sm-star" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#FFD54A" />
        <stop offset="1" stopColor="#FFB21E" />
      </linearGradient>
    </defs>
    <path d="M50 6 L61 35 L92 37 L68 57 L76 88 L50 71 L24 88 L32 57 L8 37 L39 35 Z"
          fill="url(#sm-star)" stroke="#E89A00" strokeWidth="2.5" strokeLinejoin="round"/>
    {/* cheeks */}
    <circle cx="36" cy="52" r="4.5" fill="#FF8AA8" opacity="0.7"/>
    <circle cx="64" cy="52" r="4.5" fill="#FF8AA8" opacity="0.7"/>
    {/* eyes */}
    {wink ? (
      <path d="M36 45 q3 -3 6 0" stroke="#3A2300" strokeWidth="3" fill="none" strokeLinecap="round"/>
    ) : (
      <ellipse cx="39" cy="46" rx="2.6" ry="3.2" fill="#2A1A00"/>
    )}
    <ellipse cx="61" cy="46" rx="2.6" ry="3.2" fill="#2A1A00"/>
    {/* smile */}
    <path d="M42 58 q8 7 16 0" stroke="#2A1A00" strokeWidth="3" fill="none" strokeLinecap="round"/>
  </svg>
);

// ── Smiley avatar (simple emoji-circle style the user asked to keep) ──
const SmileyAvatar = ({ size = 84, face = 'smile', fill = '#FFB4C6', ring = '#FF7FA6', ink = '#5A1A2E' }) => {
  const r = size / 2;
  const s = size;
  return (
    <svg width={s} height={s} viewBox="0 0 100 100" aria-hidden>
      <circle cx="50" cy="50" r="46" fill={fill} stroke={ring} strokeWidth="4"/>
      {face === 'adult' && (
        <>
          <circle cx="50" cy="42" r="11" fill={ring}/>
          <path d="M26 78 Q50 58 74 78 L74 84 Q50 70 26 84 Z" fill={ring}/>
        </>
      )}
      {face === 'smile' && (
        <>
          <circle cx="38" cy="44" r="3.2" fill={ink}/>
          <circle cx="62" cy="44" r="3.2" fill={ink}/>
          <path d="M36 58 Q50 72 64 58" stroke={ink} strokeWidth="3.5" fill="none" strokeLinecap="round"/>
        </>
      )}
      {face === 'wink' && (
        <>
          <path d="M34 44 Q38 40 42 44" stroke={ink} strokeWidth="3.5" fill="none" strokeLinecap="round"/>
          <circle cx="62" cy="44" r="3.2" fill={ink}/>
          <path d="M36 58 Q50 72 64 58" stroke={ink} strokeWidth="3.5" fill="none" strokeLinecap="round"/>
        </>
      )}
      {face === 'tongue' && (
        <>
          <path d="M34 44 L42 44" stroke={ink} strokeWidth="3.5" strokeLinecap="round"/>
          <path d="M58 44 L66 44" stroke={ink} strokeWidth="3.5" strokeLinecap="round"/>
          <path d="M40 58 Q50 68 60 58 L60 64 Q55 70 50 70 Q45 70 40 64 Z" fill={ink}/>
          <path d="M50 62 L50 68" stroke="#FF6F8A" strokeWidth="2"/>
        </>
      )}
    </svg>
  );
};

// ── Star badge (yellow pill with star + number, used for points) ──
const StarBadge = ({ value, size = 'md', t }) => {
  const pad = size === 'sm' ? '2px 8px' : '4px 12px';
  const fs  = size === 'sm' ? 12 : 14;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      background: '#FFF4CC', color: t.starInk, padding: pad,
      borderRadius: 999, fontWeight: 800, fontSize: fs, letterSpacing: '.01em',
    }}>
      <svg width={fs} height={fs} viewBox="0 0 24 24" aria-hidden>
        <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
              fill={t.star} stroke={t.starInk} strokeWidth="1.2" strokeLinejoin="round"/>
      </svg>
      {value}
    </span>
  );
};

// ── Task icons (simple, rounded, on-color bg circle) ──
const TaskIcon = ({ kind, color, size = 40 }) => {
  const paths = {
    home:  <path d="M12 10.5 L24 2 L36 10.5 L36 32 Q36 34 34 34 L14 34 Q12 34 12 32 Z M20 34 L20 22 L28 22 L28 34" fill="none" stroke="white" strokeWidth="3" strokeLinejoin="round" strokeLinecap="round"/>,
    sun:   <g fill="none" stroke="white" strokeWidth="3" strokeLinecap="round"><circle cx="24" cy="24" r="7"/><path d="M24 8 L24 12 M24 36 L24 40 M8 24 L12 24 M36 24 L40 24 M12.5 12.5 L15 15 M33 33 L35.5 35.5 M12.5 35.5 L15 33 M33 15 L35.5 12.5"/></g>,
    paw:   <g fill="white"><circle cx="15" cy="16" r="3.5"/><circle cx="24" cy="12" r="3.5"/><circle cx="33" cy="16" r="3.5"/><circle cx="10" cy="25" r="3"/><circle cx="38" cy="25" r="3"/><path d="M16 32 Q24 22 32 32 Q36 40 24 40 Q12 40 16 32 Z"/></g>,
    book:  <g fill="none" stroke="white" strokeWidth="3" strokeLinejoin="round" strokeLinecap="round"><path d="M10 10 L24 13 L38 10 L38 36 L24 39 L10 36 Z"/><path d="M24 13 L24 39"/></g>,
    toy:   <g fill="none" stroke="white" strokeWidth="3" strokeLinecap="round"><circle cx="24" cy="24" r="13"/><path d="M24 11 L24 37 M11 24 L37 24"/></g>,
  };
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: color, display: 'grid', placeItems: 'center', flexShrink: 0
    }}>
      <svg width={size * 0.6} height={size * 0.6} viewBox="0 0 48 48" aria-hidden>{paths[kind]}</svg>
    </div>
  );
};

// ── Nav icon ──
const NavIcon = ({ kind, size = 22, color = 'currentColor' }) => {
  const s = size;
  const common = { width: s, height: s, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' };
  if (kind === 'target') return (<svg {...common}><circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.5" fill={color}/></svg>);
  if (kind === 'bag')    return (<svg {...common}><path d="M5 9 H19 L18 20 H6 Z"/><path d="M9 9 V7 a3 3 0 0 1 6 0 V9"/></svg>);
  if (kind === 'book')   return (<svg {...common}><path d="M5 4 H18 a1 1 0 0 1 1 1 V20 H6 a2 2 0 0 1 -2-2 V5 a1 1 0 0 1 1-1 Z"/><path d="M5 18 H19"/></svg>);
  if (kind === 'exit')   return (<svg {...common}><path d="M10 4 H5 a1 1 0 0 0 -1 1 V19 a1 1 0 0 0 1 1 H10"/><path d="M14 12 H21 M18 8 L22 12 L18 16"/></svg>);
  if (kind === 'clock')  return (<svg {...common}><circle cx="12" cy="12" r="9"/><path d="M12 7 V12 L15 14"/></svg>);
  if (kind === 'lock')   return (<svg {...common}><rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10 V7 a4 4 0 0 1 8 0 V10"/></svg>);
  if (kind === 'check')  return (<svg {...common}><path d="M4 12 L10 18 L20 6"/></svg>);
  if (kind === 'flame')  return (<svg width={s} height={s} viewBox="0 0 24 24" aria-hidden><path d="M12 2 C 13 6 17 7 17 12 a5 5 0 0 1 -10 0 C 7 9 9 8 10 5 C 10 7 12 7 12 2 Z" fill="#FF7A2E" stroke="#B84700" strokeWidth="1.2"/></svg>);
  if (kind === 'bell')   return (<svg {...common}><path d="M6 16 V11 a6 6 0 0 1 12 0 V16 L20 18 H4 Z"/><path d="M10 20 a2 2 0 0 0 4 0"/></svg>);
  return null;
};

// ── Confetti dots background (subtle) ──
const Sparkles = ({ count = 10, color = '#FFD76A', seed = 1 }) => {
  const dots = [];
  for (let i = 0; i < count; i++) {
    const x = ((i * 73 + seed * 31) % 100);
    const y = ((i * 41 + seed * 17) % 100);
    const r = ((i + seed) % 3) + 1.2;
    dots.push(<circle key={i} cx={x} cy={y} r={r} fill={color} opacity={0.35}/>);
  }
  return (
    <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none"
         style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
      {dots}
    </svg>
  );
};

// ── Reward illustrations — Lucide icons on a soft tinted disc ──
// Maps reward `art` keys to Lucide icon names. Icons are rendered via
// lucide.createElement(...) into a ref so we get canonical, up-to-date glyphs
// without re-drawing anything by hand.
const LUCIDE_MAP = {
  tv:        'tv',
  icecream:  'ice-cream-cone',
  park:      'trees',
  cinema:    'clapperboard',
  toy:       'gift',
  sleepover: 'tent',
  choco:     'cookie',
  game:      'gamepad-2',
  dinner:    'utensils',
};

const LucideIcon = ({ name, size = 24, color = 'currentColor', strokeWidth = 1.8 }) => {
  const ref = React.useRef(null);
  React.useEffect(() => {
    if (!ref.current || !window.lucide) return;
    const icons = window.lucide.icons || {};
    const toPascal = n => n.split('-').map(p => p[0].toUpperCase() + p.slice(1)).join('');
    const icon = icons[toPascal(name)] || icons[name];
    if (!icon) return;
    ref.current.innerHTML = '';
    const svg = window.lucide.createElement(icon);
    svg.setAttribute('width', size);
    svg.setAttribute('height', size);
    svg.setAttribute('stroke', color);
    svg.setAttribute('stroke-width', strokeWidth);
    ref.current.appendChild(svg);
  }, [name, size, color, strokeWidth]);
  return <span ref={ref} style={{ display: 'inline-flex', lineHeight: 0 }} aria-hidden/>;
};

const RewardArt = ({ kind, size = 96, tint = '#EDE9FE', ink = '#2B2A3A' }) => {
  const iconName = LUCIDE_MAP[kind] || 'star';
  return (
    <div style={{
      width: size, height: size, borderRadius: 20, background: tint,
      display: 'grid', placeItems: 'center', flexShrink: 0, color: ink,
    }}>
      <LucideIcon name={iconName} size={Math.round(size * 0.5)} color={ink} strokeWidth={1.8}/>
    </div>
  );
};

Object.assign(window, { StarMascot, SmileyAvatar, StarBadge, TaskIcon, NavIcon, Sparkles, RewardArt, LucideIcon });
