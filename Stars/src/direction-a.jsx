// Direction A — "Soft Candy" (refined)
// Warm off-white, no thick borders, soft drop shadows, flat fills (no gradients in cards),
// Fraunces display italic titles + Nunito body.
// Missions are NOT sequenced. Statuses: approved · awaiting · current · todo
// Lojinha button removed from cofrinho banner (already in bottom nav).
// Generous spacing throughout.

const DirA = {};

const SPACE = { xs: 8, sm: 12, md: 18, lg: 28, xl: 44, xxl: 64 };

// Status metadata — consistent labeling used in multiple places
const STATUS = {
  approved: { label: 'Aprovada',  icon: 'check',  tone: 'mint',   chipFg: '#047857', chipBg: '#D1FAE5' },
  awaiting: { label: 'Aguardando aprovação', icon: 'clock', tone: 'amber', chipFg: '#92400E', chipBg: '#FEF3C7' },
  current:  { label: 'Em andamento', icon: 'target', tone: 'coral',  chipFg: '#BE185D', chipBg: '#FCE7F3' },
  todo:     { label: 'A fazer',   icon: null,     tone: 'neutral',chipFg: '#6A6878', chipBg: '#F2EEE6' },
};

// ── Profile picker ─────────────────────────────────────────────
DirA.ProfilePicker = ({ density = 'comfortable' }) => {
  const t = TOKENS.A;
  const gap = density === 'compact' ? SPACE.md : SPACE.lg;
  const cardPad = density === 'compact' ? 22 : 32;
  return (
    <div style={{
      minHeight: '100%', height: '100%', background: t.bg,
      fontFamily: t.fontBody, color: t.ink,
      padding: `${SPACE.lg}px ${SPACE.xl}px`, position: 'relative', overflow: 'auto',
      display: 'flex', flexDirection: 'column', justifyContent: 'center',
    }}>
      <Sparkles count={18} color="#E9D5FF" seed={3}/>

      {/* header */}
      <div style={{ textAlign: 'center', marginBottom: SPACE.xl, position: 'relative' }}>
        <div style={{ display: 'inline-block', marginBottom: SPACE.sm }}>
          <StarMascot size={64} wink/>
        </div>
        <div style={{
          fontFamily: t.fontBody, fontWeight: 800, fontSize: 11,
          letterSpacing: '.24em', color: t.inkMuted, marginBottom: 10,
        }}>LITTLESTARS</div>
        <h1 style={{
          fontFamily: t.fontDisplay, fontWeight: t.fontWeightDisplay,
          fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontSize: 42, margin: `0 0 ${SPACE.xs}px`, letterSpacing: '-0.02em', color: t.ink,
        }}>Quem vai brilhar hoje?</h1>
        <p style={{ margin: 0, fontSize: 16, color: t.inkSoft, fontWeight: 500 }}>
          Escolha seu perfil pra começar a aventura
        </p>
      </div>

      {/* grid */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap,
        maxWidth: 900, margin: '0 auto', position: 'relative',
      }}>
        {PROFILES.map((p) => {
          const c = t[p.color];
          const isAdult = p.face === 'adult';
          return (
            <button key={p.id} style={{
              background: t.surface, border: 'none',
              borderRadius: t.radiusLg, padding: cardPad, cursor: 'pointer',
              boxShadow: t.shadow, textAlign: 'center',
              fontFamily: t.fontBody, color: t.ink,
              transition: 'transform .15s, box-shadow .15s',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: SPACE.md,
              position: 'relative',
            }}
            onMouseOver={e => { e.currentTarget.style.transform = 'translateY(-4px)'; e.currentTarget.style.boxShadow = t.shadowRaised; }}
            onMouseOut={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = t.shadow; }}
            >
              {/* flat tinted disc behind avatar — no gradient */}
              <div style={{
                width: 124, height: 124, borderRadius: '50%',
                background: c.fill,
                display: 'grid', placeItems: 'center',
                marginTop: 4,
              }}>
                <SmileyAvatar size={96} face={p.face} fill="white" ring={c.ring} ink={c.ink}/>
              </div>
              <div style={{
                fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                fontWeight: 700, fontSize: 24, color: t.ink, letterSpacing: '-0.01em',
                marginTop: 2,
              }}>{p.name}</div>
              {isAdult ? (
                <div style={{
                  fontSize: 11, fontWeight: 800,
                  color: t.inkSoft, letterSpacing: '.14em', textTransform: 'uppercase',
                  marginTop: -4,
                }}>{p.role}</div>
              ) : (
                <div style={{ display: 'flex', gap: SPACE.xs, justifyContent: 'center', marginTop: -4 }}>
                  <StarBadge value={p.stars} size="sm" t={t}/>
                  <span style={{
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                    background: '#FFEDE0', color: '#B84700',
                    padding: '3px 10px', borderRadius: 999, fontWeight: 800, fontSize: 12,
                  }}>
                    <NavIcon kind="flame" size={12}/> {p.streak}
                  </span>
                </div>
              )}
            </button>
          );
        })}
        {/* empty add slot */}
        <button style={{
          background: 'transparent', border: `2px dashed ${t.hairline}`,
          borderRadius: t.radiusLg, padding: cardPad, cursor: 'pointer',
          color: t.inkMuted, fontFamily: t.fontBody, fontWeight: 700,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: SPACE.sm,
          minHeight: 240,
        }}>
          <div style={{
            width: 52, height: 52, borderRadius: '50%', background: t.surfaceAlt,
            display: 'grid', placeItems: 'center', fontSize: 30, fontWeight: 700,
            color: t.inkSoft,
          }}>+</div>
          <div style={{ fontSize: 14 }}>Adicionar<br/>perfil</div>
        </button>
      </div>

      {/* footer */}
      <div style={{ textAlign: 'center', marginTop: SPACE.lg }}>
        <button style={{
          background: 'transparent', border: 'none', color: t.inkSoft,
          fontFamily: t.fontBody, fontWeight: 700, fontSize: 14, cursor: 'pointer',
          padding: '10px 18px', borderRadius: 999,
        }}>Área dos pais →</button>
      </div>
    </div>
  );
};

// ── Status chip — compact icon badge (no text, prevents line-breaks) ───
const StatusChip = ({ status, t }) => {
  const s = STATUS[status];
  return (
    <span title={s.label} aria-label={s.label} style={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      background: s.chipBg, color: s.chipFg,
      width: 28, height: 28, borderRadius: 999, flexShrink: 0,
    }}>
      {s.icon
        ? <NavIcon kind={s.icon} size={15} color={s.chipFg}/>
        : <span style={{ width: 8, height: 8, borderRadius: 999, background: s.chipFg, opacity: 0.55 }}/>}
    </span>
  );
};

// ── Mission node (the circular icon on the path) ──────────────
const MissionNode = ({ task, t, catColor }) => {
  const { status } = task;
  // visual style per status
  let bg = catColor;
  let content = null;
  let badge = null;

  if (status === 'approved') {
    bg = t.mint;
    content = <NavIcon kind="check" size={36} color="white"/>;
    badge = (
      <div style={{
        position: 'absolute', top: -4, right: -4,
        background: t.star, color: t.starInk,
        borderRadius: 999, padding: '3px 9px', fontSize: 11, fontWeight: 900,
        boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
      }}>+{task.stars}</div>
    );
  } else if (status === 'awaiting') {
    bg = '#FDE68A';
    content = <NavIcon kind="clock" size={32} color="#92400E"/>;
  } else if (status === 'current') {
    content = <TaskIcon kind={task.icon} color="transparent" size={54}/>;
  } else {
    content = <TaskIcon kind={task.icon} color="transparent" size={54}/>;
  }

  const isCurrent = status === 'current';
  return (
    <div style={{ position: 'relative' }}>
      <div style={{
        width: 84, height: 84, borderRadius: '50%',
        background: bg,
        display: 'grid', placeItems: 'center',
        boxShadow: isCurrent
          ? `0 0 0 6px ${t.star}55, 0 8px 18px rgba(0,0,0,0.08)`
          : '0 6px 14px rgba(0,0,0,0.06)',
        color: 'white',
      }}>
        {content}
      </div>
      {badge}
      {isCurrent && (
        <div style={{
          position: 'absolute', bottom: -12, left: '50%', transform: 'translateX(-50%)',
          background: t.star, color: t.starInk,
          borderRadius: 999, padding: '4px 12px', fontSize: 10, fontWeight: 900,
          letterSpacing: '.14em', boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
          whiteSpace: 'nowrap',
        }}>AGORA</div>
      )}
    </div>
  );
};

// ── Dashboard (game map path) ──────────────────────────────────
DirA.Dashboard = ({ density = 'comfortable' }) => {
  const t = TOKENS.A;
  const profile = PROFILES.find(p => p.id === 'lila');
  const c = t[profile.color];

  // Missions aren't sequenced — the path is a decorative connector,
  // not a gate. Each mission can be picked in any order.
  // All cards aligned left for a calmer scan.
  const nodes = TASKS.map(t => ({ ...t }));
  const nodeGap = density === 'compact' ? 108 : 132;
  const maxW = 900;

  // totals
  const approvedCount = nodes.filter(n => n.status === 'approved').length;
  const awaitingCount = nodes.filter(n => n.status === 'awaiting').length;
  const progressPct = Math.round((approvedCount / nodes.length) * 100);

  return (
    <div style={{
      background: t.bg, minHeight: '100%',
      fontFamily: t.fontBody, color: t.ink,
      padding: `${SPACE.lg}px ${SPACE.xl}px ${140}px`, position: 'relative', overflow: 'hidden',
    }}>
      {/* top bar */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        maxWidth: maxW, margin: `0 auto ${SPACE.xl}px`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.md }}>
          <SmileyAvatar size={56} face={profile.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.22em', color: t.inkMuted }}>OI,</div>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 28, color: t.ink, letterSpacing: '-0.01em', lineHeight: 1.1,
            }}>{profile.name}!</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.sm }}>
          <button style={{
            background: t.surface, border: 'none', borderRadius: 999,
            padding: '10px 16px', display: 'flex', alignItems: 'center', gap: 6,
            fontFamily: t.fontBody, fontWeight: 800, color: '#B84700', fontSize: 14,
            boxShadow: t.shadow, cursor: 'pointer',
          }}>
            <NavIcon kind="flame" size={16}/> 7 dias
          </button>
          <button style={{
            background: t.surface, border: 'none', borderRadius: 999,
            width: 44, height: 44, display: 'grid', placeItems: 'center',
            boxShadow: t.shadow, cursor: 'pointer',
          }}>
            <NavIcon kind="bell" size={18} color={t.inkSoft}/>
          </button>
          <StarMascot size={44}/>
        </div>
      </div>

      {/* cofrinho card — lojinha button removed */}
      <div style={{
        maxWidth: maxW, margin: `0 auto ${SPACE.xl}px`,
        background: t.surface, borderRadius: t.radiusLg,
        padding: `${SPACE.lg}px ${SPACE.xl}px`, boxShadow: t.shadow,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.md, marginBottom: SPACE.lg }}>
          <div style={{
            width: 52, height: 52, borderRadius: '50%', background: '#FFF4CC',
            display: 'grid', placeItems: 'center', flexShrink: 0,
          }}>
            <svg width="26" height="26" viewBox="0 0 24 24" aria-hidden>
              <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                    fill={t.star} stroke={t.starInk} strokeWidth="1.2" strokeLinejoin="round"/>
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.22em', color: t.inkMuted, marginBottom: 4 }}>
              MEU COFRINHO
            </div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: SPACE.xs }}>
              <div style={{
                fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                fontWeight: 700, fontSize: 36, color: t.ink, lineHeight: 1, letterSpacing: '-0.01em',
              }}>{profile.stars}</div>
              <div style={{ fontSize: 14, fontWeight: 600, color: t.inkSoft }}>
                estrelinhas guardadas
              </div>
            </div>
          </div>
          {awaitingCount > 0 && (
            <div style={{
              background: '#FEF3C7', color: '#92400E',
              padding: '8px 14px', borderRadius: 12,
              fontSize: 12, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 6,
              whiteSpace: 'nowrap',
            }}>
              <NavIcon kind="clock" size={14} color="#92400E"/>
              {awaitingCount} aguardando
            </div>
          )}
        </div>

        {/* progress */}
        <div>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            marginBottom: SPACE.sm, fontSize: 12, fontWeight: 800, color: t.inkSoft,
          }}>
            <span style={{ letterSpacing: '.14em' }}>PROGRESSO DE HOJE</span>
            <span style={{ color: t.ink, letterSpacing: 0 }}>
              {approvedCount} de {nodes.length} ✨
            </span>
          </div>
          <div style={{
            height: 12, borderRadius: 999, background: t.surfaceAlt, overflow: 'hidden',
          }}>
            <div style={{
              height: '100%', width: `${progressPct}%`,
              background: t.star,
              borderRadius: 999,
            }}/>
          </div>
        </div>
      </div>

      {/* section title */}
      <div style={{
        maxWidth: maxW, margin: `${SPACE.xl}px auto ${SPACE.md}px`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      }}>
        <h2 style={{
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 28, margin: 0, color: t.ink, letterSpacing: '-0.015em',
        }}>Minhas missões de hoje</h2>
        <span style={{ fontSize: 13, fontWeight: 700, color: t.inkSoft }}>
          {nodes.length} missões · escolha qualquer uma
        </span>
      </div>

      {/* the path — all rows left-aligned */}
      <div style={{
        maxWidth: 620, margin: '0 auto', position: 'relative',
        paddingTop: SPACE.md,
      }}>
        {/* simple straight dashed rail behind nodes */}
        <div aria-hidden style={{
          position: 'absolute', top: 58, bottom: 80, left: 41,
          width: 0, borderLeft: `3px dashed ${c.ring}`, opacity: 0.35, zIndex: 0,
        }}/>

        {nodes.map((n, i) => {
          const catColor = { Casa: t.mint, Rotina: t.peach, Escola: t.lilac }[n.cat] || t.sky;
          const isApproved = n.status === 'approved';
          return (
            <div key={n.id} style={{
              position: 'relative', zIndex: 1,
              marginBottom: nodeGap - 84,
              opacity: isApproved ? 0.85 : 1,
            }}>
              <div style={{
                display: 'flex', flexDirection: 'row',
                alignItems: 'center', gap: SPACE.lg,
              }}>
                <MissionNode task={n} t={t} catColor={catColor}/>
                {/* label card — tight 2-row layout: [title · status] / [meta] */}
                <div style={{
                  flex: 1, background: t.surface, borderRadius: t.radius,
                  padding: `${SPACE.md}px ${SPACE.lg}px`, boxShadow: t.shadow,
                }}>
                  <div style={{
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                    gap: SPACE.sm,
                  }}>
                    <div style={{
                      fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                      fontWeight: 700, fontSize: 19, color: t.ink,
                      textDecoration: isApproved ? 'line-through' : 'none',
                      textDecorationColor: t.inkMuted,
                      lineHeight: 1.15,
                    }}>{n.title}</div>
                    <StatusChip status={n.status} t={t}/>
                  </div>

                  <div style={{
                    marginTop: 6,
                    display: 'flex', gap: SPACE.xs,
                    alignItems: 'center', flexWrap: 'wrap',
                    fontSize: 12, fontWeight: 700, color: t.inkSoft,
                  }}>
                    <span>{n.cat}</span>
                    <span style={{ opacity: 0.35 }}>·</span>
                    <span>{n.recur}</span>
                    <span style={{ opacity: 0.35 }}>·</span>
                    <StarBadge value={n.stars} size="sm" t={t}/>
                  </div>
                </div>
              </div>
            </div>
          );
        })}

        {/* finish flag */}
        <div style={{
          display: 'flex', marginTop: SPACE.xl,
          flexDirection: 'row', alignItems: 'center', gap: SPACE.lg,
          paddingLeft: 4,
        }}>
          <div style={{
            width: 84, height: 84, borderRadius: '50%',
            background: '#FFF4CC',
            display: 'grid', placeItems: 'center',
            boxShadow: '0 8px 20px rgba(255,197,61,0.3)',
            flexShrink: 0,
          }}>
            <StarMascot size={58}/>
          </div>
          <div style={{
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 17, color: t.inkSoft,
          }}>+50 ao concluir tudo</div>
        </div>
      </div>

      {/* bottom nav */}
      <div style={{
        position: 'absolute', bottom: 32, left: '50%', transform: 'translateX(-50%)',
        background: t.surface, borderRadius: 999, padding: '10px 14px',
        display: 'flex', gap: 4, boxShadow: t.shadowRaised,
      }}>
        {[
          { k: 'target', active: true, label: 'Jornada' },
          { k: 'bag',    label: 'Lojinha' },
          { k: 'book',   label: 'Diário' },
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

window.DirA = DirA;
