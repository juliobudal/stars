// Parent Area — Dashboard section
// Shows: pending approvals summary banner, kid cards (balance + streak + progress),
// quick stats tiles.

const DirA = window.DirA || {};
window.DirA = DirA;

DirA.PADashboard = ({ t }) => {
  const kids = PROFILES.filter(p => p.stars);
  const approvalsCount = PENDING_MISSIONS.length + PENDING_REWARDS.length;

  // quick stats
  const missionsActive = MISSION_CATALOG.filter(m => m.active).length;
  const rewardsCount   = REWARDS.length;
  const starsInCirc    = kids.reduce((s, k) => s + k.stars, 0);

  return (
    <div>
      <PASectionHeader t={t}
        title="Olá, Renata ✨"
        subtitle={`Você tem ${approvalsCount} aprovações aguardando e ${kids.length} crianças ativas.`}
        action={<PAButton t={t} icon="plus" variant="primary">Nova missão</PAButton>}
      />

      {/* Approval banner */}
      {approvalsCount > 0 && (
        <div style={{
          background: `linear-gradient(135deg, ${t.lilac}, #8B5CF6)`,
          borderRadius: t.radius, padding: 24, marginBottom: 24,
          color: '#FFFFFF', display: 'flex', alignItems: 'center', gap: 20,
          boxShadow: '0 8px 28px rgba(167,139,250,0.35)',
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: 16,
            background: 'rgba(255,255,255,0.2)', display: 'grid', placeItems: 'center',
            flexShrink: 0,
          }}>
            <LucideIcon name="bell-ring" size={28} color="#FFFFFF" strokeWidth={2}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 20, marginBottom: 4, letterSpacing: '-0.01em',
            }}>{approvalsCount} aprovações aguardando</div>
            <div style={{ fontSize: 13, fontWeight: 600, opacity: 0.92 }}>
              {PENDING_MISSIONS.length} missões · {PENDING_REWARDS.length} prêmios
            </div>
          </div>
          <button style={{
            background: '#FFFFFF', color: t.lilac, border: 'none',
            padding: '12px 22px', borderRadius: 12,
            fontFamily: t.fontBody, fontWeight: 900, fontSize: 13, cursor: 'pointer',
            boxShadow: '0 3px 0 rgba(76,29,149,0.2)',
          }}>Ver aprovações →</button>
        </div>
      )}

      {/* Quick stats */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16, marginBottom: 28,
      }}>
        {[
          { label: 'Estrelas em circulação', value: starsInCirc, icon: 'star',   tint: '#FEF3C7', ink: '#92400E' },
          { label: 'Missões ativas',         value: missionsActive, icon: 'target', tint: '#EDE9FE', ink: '#6D28D9' },
          { label: 'Prêmios no catálogo',    value: rewardsCount,   icon: 'gift',   tint: '#FCE7F3', ink: '#BE185D' },
          { label: 'Crianças ativas',        value: kids.length,    icon: 'users',  tint: '#D1FAE5', ink: '#047857' },
        ].map((s, i) => (
          <PACard key={i} t={t} style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12,
              background: s.tint, display: 'grid', placeItems: 'center',
            }}>
              <LucideIcon name={s.icon} size={20} color={s.ink} strokeWidth={2}/>
            </div>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 30, color: t.ink, letterSpacing: '-0.02em', lineHeight: 1,
            }}>{s.value}</div>
            <div style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>{s.label}</div>
          </PACard>
        ))}
      </div>

      {/* Kid cards */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
        <h2 style={{
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 22, margin: 0, color: t.ink, letterSpacing: '-0.015em',
        }}>Suas crianças</h2>
        <PAButton t={t} variant="soft" icon="plus" small>Adicionar filho</PAButton>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: 28 }}>
        {kids.map(k => {
          const c = t[k.color];
          const missionsForKid  = MISSION_CATALOG.filter(m => m.assigned.includes(k.id) && m.active).length;
          const awaitingForKid  = PENDING_MISSIONS.filter(p => p.kidId === k.id).length;
          return (
            <PACard key={k.id} t={t} hover
              style={{ display: 'flex', flexDirection: 'column', gap: 14, padding: 0, overflow: 'hidden' }}>
              {/* Top — color band + avatar */}
              <div style={{
                background: c.fill, padding: '18px 20px',
                display: 'flex', alignItems: 'center', gap: 14,
              }}>
                <SmileyAvatar size={56} face={k.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
                <div style={{ flex: 1 }}>
                  <div style={{
                    fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                    fontWeight: 700, fontSize: 22, color: c.ink, letterSpacing: '-0.01em', lineHeight: 1,
                  }}>{k.name}</div>
                  <div style={{ fontSize: 11, fontWeight: 800, color: c.ink, opacity: 0.75, marginTop: 4, letterSpacing: '.04em' }}>
                    🔥 {k.streak || 0} dias seguidos
                  </div>
                </div>
              </div>

              {/* Bottom — stats */}
              <div style={{ padding: '4px 20px 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>Saldo</span>
                  <PAStars t={t} value={k.stars} size={16}/>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>Missões ativas</span>
                  <span style={{ fontSize: 13, fontWeight: 800, color: t.ink }}>{missionsForKid}</span>
                </div>
                {awaitingForKid > 0 && (
                  <div style={{
                    background: '#FEF3C7', color: '#92400E',
                    padding: '8px 12px', borderRadius: 10,
                    fontSize: 12, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 6,
                  }}>
                    <LucideIcon name="clock" size={14} color="#92400E" strokeWidth={2.2}/>
                    {awaitingForKid} aguardando você
                  </div>
                )}
              </div>
            </PACard>
          );
        })}
      </div>

      {/* Recent activity */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
        <h2 style={{
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 22, margin: 0, color: t.ink, letterSpacing: '-0.015em',
        }}>Atividade recente</h2>
        <PAButton t={t} variant="ghost" small>Ver tudo</PAButton>
      </div>
      <PACard t={t} style={{ padding: '4px 20px' }}>
        {HISTORY.slice(0, 5).map((h, i) => {
          const kid = kids[i % kids.length]; // decorative
          const c = t[kid.color];
          const positive = h.stars > 0;
          const zero = h.stars === 0;
          return (
            <div key={h.id} style={{
              display: 'flex', alignItems: 'center', gap: 14,
              padding: '14px 0',
              borderBottom: i < 4 ? `1px solid ${t.hairline}` : 'none',
            }}>
              <SmileyAvatar size={34} face={kid.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 800, color: t.ink }}>
                  <span style={{ color: c.ink }}>{kid.name}</span>
                  {' · '}
                  <span>{h.title}</span>
                </div>
                <div style={{ fontSize: 11, fontWeight: 700, color: t.inkSoft, marginTop: 2 }}>
                  {h.time} · {h.note}
                </div>
              </div>
              <span style={{
                fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                fontWeight: 700, fontSize: 15,
                color: zero ? t.inkMuted : positive ? '#047857' : '#6D28D9',
                display: 'inline-flex', alignItems: 'center', gap: 3,
              }}>
                {zero ? '—' : `${positive ? '+' : '−'}${Math.abs(h.stars)}`}
                {!zero && <svg width="12" height="12" viewBox="0 0 24 24" aria-hidden>
                  <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                        fill={t.star} stroke={t.ink} strokeWidth="1" strokeLinejoin="round"/>
                </svg>}
              </span>
            </div>
          );
        })}
      </PACard>
    </div>
  );
};
