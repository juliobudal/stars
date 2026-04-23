// Diário — Unified transaction history.
// Shows missions (earn) + purchases (spend) in a single chronological timeline
// grouped by day with running balance and filter chips.

DirA.History = ({ density = 'comfortable' }) => {
  const t = TOKENS.A;
  const profile = PROFILES.find(p => p.id === 'lila');
  const c = t[profile.color];
  const [filter, setFilter] = React.useState('all');

  const SPACE = { xs: 8, sm: 12, md: 18, lg: 28, xl: 44 };
  const maxW = 900;

  // filter mapping: 'all' | 'earn' (positive) | 'spend' (negative) | 'awaiting' | 'rejected'
  const matches = h => {
    if (filter === 'all') return true;
    if (filter === 'earn') return h.stars > 0;
    if (filter === 'spend') return h.kind === 'purchase';
    if (filter === 'awaiting') return h.kind === 'mission-awaiting';
    if (filter === 'rejected') return h.kind === 'mission-rejected';
    return true;
  };

  const buckets = [
    { id: 'today',     label: 'Hoje' },
    { id: 'yesterday', label: 'Ontem' },
    { id: 'older',     label: 'Esta semana' },
  ];

  // summary of earnings vs spending this week
  const earned = HISTORY.filter(h => h.stars > 0).reduce((s, h) => s + h.stars, 0);
  const spent  = HISTORY.filter(h => h.stars < 0).reduce((s, h) => s + Math.abs(h.stars), 0);
  const missionsDone = HISTORY.filter(h => h.kind === 'mission-approved').length;

  // kind → chip styling
  const kindChip = {
    'mission-approved': { bg: '#D1FAE5', fg: '#047857', label: 'Missão'    },
    'mission-awaiting': { bg: '#FEF3C7', fg: '#92400E', label: 'Aguardando'},
    'mission-rejected': { bg: '#FEE2E2', fg: '#991B1B', label: 'Rejeitada' },
    'purchase':         { bg: '#EDE9FE', fg: '#6D28D9', label: 'Compra'    },
    'bonus':            { bg: '#FCE7F3', fg: '#BE185D', label: 'Bônus'     },
  };

  // icon disc tint per kind
  const discTint = {
    'mission-approved': '#D1FAE5',
    'mission-awaiting': '#FEF3C7',
    'mission-rejected': '#FEE2E2',
    'purchase':         '#EDE9FE',
    'bonus':            '#FCE7F3',
  };

  const renderEntry = (h) => {
    const chip = kindChip[h.kind];
    const sign = h.stars > 0 ? '+' : h.stars < 0 ? '−' : '';
    const amount = Math.abs(h.stars);
    const positive = h.stars > 0;
    const zero = h.stars === 0;
    return (
      <div key={h.id} style={{
        display: 'flex', alignItems: 'center', gap: SPACE.md,
        padding: `${SPACE.sm}px 0`,
      }}>
        {/* icon disc */}
        <div style={{
          width: 48, height: 48, borderRadius: 14,
          background: discTint[h.kind],
          display: 'grid', placeItems: 'center', flexShrink: 0,
          color: chip.fg,
        }}>
          {h.art ? (
            <LucideIcon name={LUCIDE_MAP[h.art] || 'star'} size={22} color={chip.fg} strokeWidth={2}/>
          ) : (
            <TaskIcon kind={h.icon || 'home'} color={chip.fg} size={24}/>
          )}
        </div>

        {/* main text */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 3 }}>
            <span style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 16, color: t.ink, letterSpacing: '-0.01em',
              lineHeight: 1.2,
              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            }}>{h.title}</span>
            <span style={{
              background: chip.bg, color: chip.fg,
              padding: '2px 8px', borderRadius: 999,
              fontSize: 10, fontWeight: 900, letterSpacing: '.08em',
              flexShrink: 0,
            }}>{chip.label.toUpperCase()}</span>
          </div>
          <div style={{ fontSize: 12, fontWeight: 600, color: t.inkSoft }}>
            {h.time} · {h.note}
          </div>
        </div>

        {/* amount */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 4,
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 18,
          color: zero ? t.inkMuted : positive ? '#047857' : '#6D28D9',
          flexShrink: 0,
        }}>
          {zero ? '—' : (
            <>
              <span>{sign}{amount}</span>
              <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden>
                <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                      fill={t.star} stroke={t.ink} strokeWidth="1" strokeLinejoin="round"/>
              </svg>
            </>
          )}
        </div>
      </div>
    );
  };

  return (
    <div style={{
      background: t.bg, minHeight: '100%',
      fontFamily: t.fontBody, color: t.ink,
      padding: `${SPACE.lg}px ${SPACE.xl}px 140px`, position: 'relative', overflow: 'hidden',
    }}>
      {/* top bar — same pattern as shop */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        maxWidth: maxW, margin: `0 auto ${SPACE.lg}px`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.md }}>
          <button style={{
            background: t.surface, border: 'none', borderRadius: 999,
            width: 44, height: 44, display: 'grid', placeItems: 'center',
            boxShadow: t.shadow, cursor: 'pointer', color: t.ink,
          }} aria-label="Voltar">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 18 L9 12 L15 6"/>
            </svg>
          </button>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.22em', color: t.inkMuted }}>DIÁRIO DE</div>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 28, color: t.ink, letterSpacing: '-0.01em', lineHeight: 1.1,
            }}>{profile.name}</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.sm }}>
          <div style={{
            background: '#FFF4CC', color: t.starInk,
            borderRadius: 999, padding: '10px 16px',
            display: 'flex', alignItems: 'center', gap: 8,
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 18,
            boxShadow: t.shadow,
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden>
              <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                    fill={t.star} stroke={t.starInk} strokeWidth="1.2" strokeLinejoin="round"/>
            </svg>
            {profile.stars}
          </div>
          <SmileyAvatar size={44} face={profile.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
        </div>
      </div>

      {/* summary cards */}
      <div style={{
        maxWidth: maxW, margin: `0 auto ${SPACE.lg}px`,
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: SPACE.md,
      }}>
        {[
          { label: 'Conquistado',    value: `+${earned}`, sub: 'esta semana', fg: '#047857', bg: '#D1FAE5' },
          { label: 'Gasto',          value: `−${spent}`,  sub: 'em prêmios',  fg: '#6D28D9', bg: '#EDE9FE' },
          { label: 'Missões feitas', value: missionsDone, sub: 'aprovadas',   fg: t.ink,      bg: t.surface },
        ].map((s, i) => (
          <div key={i} style={{
            background: t.surface, borderRadius: t.radius,
            padding: SPACE.md, boxShadow: t.shadow,
            display: 'flex', flexDirection: 'column', gap: 4,
          }}>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.16em', color: t.inkMuted }}>
              {s.label.toUpperCase()}
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 30, color: s.fg, letterSpacing: '-0.02em', lineHeight: 1,
            }}>
              {s.value}
              {i < 2 && (
                <svg width="22" height="22" viewBox="0 0 24 24" aria-hidden style={{ marginTop: 2 }}>
                  <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                        fill={t.star} stroke={t.ink} strokeWidth="1" strokeLinejoin="round"/>
                </svg>
              )}
            </div>
            <div style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>{s.sub}</div>
          </div>
        ))}
      </div>

      {/* filter chips */}
      <div style={{
        maxWidth: maxW, margin: `${SPACE.lg}px auto ${SPACE.md}px`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        gap: SPACE.md, flexWrap: 'wrap',
      }}>
        <h2 style={{
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 24, margin: 0, color: t.ink, letterSpacing: '-0.015em',
        }}>Tudo que rolou</h2>
      </div>
      <div style={{
        maxWidth: maxW, margin: `0 auto ${SPACE.lg}px`,
        display: 'flex', gap: 8, flexWrap: 'wrap',
      }}>
        {[
          { id: 'all',      label: 'Tudo' },
          { id: 'earn',     label: 'Conquistadas' },
          { id: 'spend',    label: 'Compras' },
          { id: 'awaiting', label: 'Aguardando' },
          { id: 'rejected', label: 'Rejeitadas' },
        ].map(f => {
          const active = filter === f.id;
          return (
            <button key={f.id} onClick={() => setFilter(f.id)} style={{
              background: active ? t.ink : t.surface,
              color: active ? t.bg : t.inkSoft,
              border: 'none', borderRadius: 999,
              padding: '10px 18px', cursor: 'pointer',
              fontFamily: t.fontBody, fontWeight: 800, fontSize: 13,
              boxShadow: active ? 'none' : t.shadow,
            }}>{f.label}</button>
          );
        })}
      </div>

      {/* timeline grouped by day */}
      <div style={{ maxWidth: maxW, margin: '0 auto', display: 'flex', flexDirection: 'column', gap: SPACE.lg }}>
        {buckets.map(b => {
          const items = HISTORY.filter(h => h.day === b.id && matches(h));
          if (items.length === 0) return null;
          const dayTotal = items.reduce((s, h) => s + h.stars, 0);
          return (
            <div key={b.id}>
              <div style={{
                display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
                marginBottom: SPACE.sm, padding: '0 4px',
              }}>
                <div style={{
                  fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                  fontWeight: 700, fontSize: 18, color: t.ink, letterSpacing: '-0.01em',
                }}>{b.label}</div>
                <div style={{
                  fontSize: 12, fontWeight: 800, color: t.inkSoft,
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                }}>
                  Saldo do dia: {dayTotal >= 0 ? '+' : '−'}{Math.abs(dayTotal)}
                  <svg width="12" height="12" viewBox="0 0 24 24" aria-hidden>
                    <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                          fill={t.star} stroke={t.ink} strokeWidth="1" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
              <div style={{
                background: t.surface, borderRadius: t.radius,
                boxShadow: t.shadow, padding: `4px ${SPACE.md}px`,
              }}>
                {items.map((h, i) => (
                  <React.Fragment key={h.id}>
                    {renderEntry(h)}
                    {i < items.length - 1 && (
                      <div style={{ height: 1, background: t.hairline, margin: '0 -4px' }}/>
                    )}
                  </React.Fragment>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* empty state */}
      {HISTORY.filter(matches).length === 0 && (
        <div style={{
          maxWidth: maxW, margin: '0 auto', textAlign: 'center',
          padding: `${SPACE.xl}px ${SPACE.lg}px`,
          background: t.surface, borderRadius: t.radius, boxShadow: t.shadow,
        }}>
          <div style={{ fontSize: 44, marginBottom: 8 }}>✨</div>
          <div style={{
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 20, color: t.ink, marginBottom: 4,
          }}>Nada por aqui ainda</div>
          <div style={{ fontSize: 13, color: t.inkSoft, fontWeight: 600 }}>
            Termine missões ou troque prêmios para ver tudo aqui.
          </div>
        </div>
      )}

      {/* bottom nav — Diário active */}
      <div style={{
        position: 'absolute', bottom: 32, left: '50%', transform: 'translateX(-50%)',
        background: t.surface, borderRadius: 999, padding: '10px 14px',
        display: 'flex', gap: 4, boxShadow: t.shadowRaised,
      }}>
        {[
          { k: 'target', label: 'Jornada' },
          { k: 'bag',    label: 'Lojinha' },
          { k: 'book',   active: true, label: 'Diário' },
          { k: 'exit',   label: 'Sair' },
        ].map((it, i) => (
          <button key={i} style={{
            background: it.active ? t.star : 'transparent',
            border: 'none', borderRadius: 999, padding: '10px 16px',
            display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
            color: it.active ? t.starInk : t.inkSoft,
            fontFamily: t.fontBody, fontWeight: 800, fontSize: 13,
          }}>
            <NavIcon kind={it.k} size={18}/>
            {it.active && <span>{it.label}</span>}
          </button>
        ))}
      </div>
    </div>
  );
};
