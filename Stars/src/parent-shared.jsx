// Parent Area — shared helpers used by all parent-area sections
// (sidebar, section shells, small atoms). Kept separate from the kid-area
// shared.jsx so we can evolve this surface independently.

// Sidebar nav item
const PASidebarItem = ({ icon, label, active, badge, onClick, t }) => (
  <button onClick={onClick} style={{
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '12px 14px', borderRadius: 14,
    background: active ? t.surfaceAlt : 'transparent',
    border: 'none', cursor: 'pointer', width: '100%', textAlign: 'left',
    color: active ? t.ink : t.inkSoft,
    fontFamily: t.fontBody, fontWeight: active ? 800 : 700, fontSize: 14,
    transition: 'background .15s',
    position: 'relative',
  }}>
    <LucideIcon name={icon} size={18} color={active ? t.lilac : t.inkSoft} strokeWidth={2}/>
    <span style={{ flex: 1 }}>{label}</span>
    {badge > 0 && (
      <span style={{
        background: t.coral, color: '#FFFFFF',
        padding: '2px 8px', borderRadius: 999,
        fontSize: 10, fontWeight: 900, minWidth: 20, textAlign: 'center',
      }}>{badge}</span>
    )}
  </button>
);

// Section header with title + optional CTA
const PASectionHeader = ({ title, subtitle, action, t }) => (
  <div style={{
    display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
    gap: 16, marginBottom: 20, flexWrap: 'wrap',
  }}>
    <div>
      <h1 style={{
        fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
        fontWeight: 700, fontSize: 32, margin: 0, color: t.ink, letterSpacing: '-0.02em',
        lineHeight: 1.1,
      }}>{title}</h1>
      {subtitle && (
        <p style={{
          margin: '6px 0 0', fontSize: 14, color: t.inkSoft, fontWeight: 500, lineHeight: 1.4,
        }}>{subtitle}</p>
      )}
    </div>
    {action}
  </div>
);

// Primary button (lilac fill)
const PAButton = ({ children, variant = 'primary', icon, onClick, t, small }) => {
  const map = {
    primary: { bg: t.lilac,     fg: '#FFFFFF', shadow: '0 3px 0 rgba(76,29,149,0.25)' },
    soft:    { bg: t.surfaceAlt,fg: t.ink,      shadow: t.shadow },
    ghost:   { bg: 'transparent', fg: t.inkSoft, shadow: 'none' },
    danger:  { bg: '#FEE2E2',   fg: '#991B1B',  shadow: 'none' },
    success: { bg: '#D1FAE5',   fg: '#047857',  shadow: 'none' },
  };
  const s = map[variant];
  return (
    <button onClick={onClick} style={{
      background: s.bg, color: s.fg, border: 'none',
      borderRadius: t.radiusSm,
      padding: small ? '8px 14px' : '12px 20px',
      fontFamily: t.fontBody, fontWeight: 800, fontSize: small ? 12 : 14,
      cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 8,
      boxShadow: s.shadow, letterSpacing: '.01em',
    }}>
      {icon && <LucideIcon name={icon} size={small ? 14 : 16} color={s.fg} strokeWidth={2.2}/>}
      {children}
    </button>
  );
};

// Card surface
const PACard = ({ children, t, style, onClick, hover }) => (
  <div onClick={onClick} style={{
    background: t.surface, borderRadius: t.radius,
    padding: 20, boxShadow: t.shadow,
    cursor: onClick ? 'pointer' : 'default',
    transition: 'transform .15s, box-shadow .15s',
    ...style,
  }}
  onMouseOver={e => hover && (e.currentTarget.style.boxShadow = t.shadowRaised)}
  onMouseOut={e => hover && (e.currentTarget.style.boxShadow = t.shadow)}
  >{children}</div>
);

// Kid mini avatar (for assigning/tagging)
const PAKidChip = ({ kid, t, size = 32 }) => {
  const c = t[kid.color];
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      background: c.fill, color: c.ink,
      padding: '3px 10px 3px 3px', borderRadius: 999,
      fontFamily: t.fontBody, fontWeight: 800, fontSize: 12,
    }}>
      <SmileyAvatar size={size-10} face={kid.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
      {kid.name}
    </div>
  );
};

// Star inline
const PAStars = ({ value, size = 14, t, sign = '' }) => (
  <span style={{
    display: 'inline-flex', alignItems: 'center', gap: 3,
    fontWeight: 700, fontSize: size, fontFamily: t.fontDisplay,
    fontStyle: t.titleItalic ? 'italic' : 'normal', letterSpacing: '-0.01em',
  }}>
    {sign}{value}
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden>
      <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
            fill={t.star} stroke={t.ink} strokeWidth="1" strokeLinejoin="round"/>
    </svg>
  </span>
);

// Recurrence → friendly label
const recurLabel = (m) => {
  if (m.recur === 'daily') return 'Todo dia';
  if (m.recur === 'weekly') {
    const map = { mon: 'seg', tue: 'ter', wed: 'qua', thu: 'qui', fri: 'sex', sat: 'sáb', sun: 'dom' };
    return 'Semanal · ' + (m.days || []).map(d => map[d]).join('/');
  }
  if (m.recur === 'monthly') return `Mensal · dia ${m.day || 1}`;
  if (m.recur === 'once') return `Única · ${m.date || ''}`;
  return m.recur;
};

Object.assign(window, { PASidebarItem, PASectionHeader, PAButton, PACard, PAKidChip, PAStars, recurLabel });
