// Parent Area — Missões (missions catalog) section
// Table-ish list of all missions with recurrence, stars, assigned kids, active toggle.

const DirA = window.DirA || {};
window.DirA = DirA;

DirA.PAMissions = ({ t }) => {
  const kids = PROFILES.filter(p => p.stars);
  const kidById = Object.fromEntries(kids.map(k => [k.id, k]));
  const [filter, setFilter] = React.useState('all');

  const visible = MISSION_CATALOG.filter(m => {
    if (filter === 'all') return true;
    if (filter === 'daily') return m.recur === 'daily';
    if (filter === 'weekly') return m.recur === 'weekly';
    if (filter === 'monthly') return m.recur === 'monthly';
    if (filter === 'once') return m.recur === 'once';
    if (filter === 'inactive') return !m.active;
    return true;
  });

  const recurTint = {
    daily:   { bg: '#D1FAE5', fg: '#047857' },
    weekly:  { bg: '#DBEAFE', fg: '#1D4ED8' },
    monthly: { bg: '#FCE7F3', fg: '#BE185D' },
    once:    { bg: '#FEF3C7', fg: '#92400E' },
  };

  return (
    <div>
      <PASectionHeader t={t}
        title="Missões"
        subtitle={`${MISSION_CATALOG.filter(m => m.active).length} ativas · ${MISSION_CATALOG.length} no catálogo`}
        action={<PAButton t={t} icon="plus">Nova missão</PAButton>}
      />

      {/* filter chips */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
        {[
          { id: 'all',      label: 'Todas' },
          { id: 'daily',    label: 'Diárias' },
          { id: 'weekly',   label: 'Semanais' },
          { id: 'monthly',  label: 'Mensais' },
          { id: 'once',     label: 'Únicas' },
          { id: 'inactive', label: 'Inativas' },
        ].map(f => {
          const active = filter === f.id;
          return (
            <button key={f.id} onClick={() => setFilter(f.id)} style={{
              background: active ? t.ink : t.surface, color: active ? t.bg : t.inkSoft,
              border: 'none', borderRadius: 999, padding: '8px 16px', cursor: 'pointer',
              fontFamily: t.fontBody, fontWeight: 800, fontSize: 12,
              boxShadow: active ? 'none' : t.shadow,
            }}>{f.label}</button>
          );
        })}
      </div>

      {/* table */}
      <PACard t={t} style={{ padding: 0, overflow: 'hidden' }}>
        {/* header row */}
        <div style={{
          display: 'grid', gridTemplateColumns: '2fr 1.3fr 0.8fr 1.5fr 100px 60px',
          gap: 16, padding: '14px 20px', background: t.surfaceAlt,
          fontSize: 11, fontWeight: 800, color: t.inkSoft, letterSpacing: '.1em',
        }}>
          <div>MISSÃO</div>
          <div>RECORRÊNCIA</div>
          <div>ESTRELAS</div>
          <div>ATRIBUÍDA A</div>
          <div>ATIVA</div>
          <div></div>
        </div>
        {visible.map((m, i) => {
          const rt = recurTint[m.recur] || recurTint.daily;
          return (
            <div key={m.id} style={{
              display: 'grid', gridTemplateColumns: '2fr 1.3fr 0.8fr 1.5fr 100px 60px',
              gap: 16, padding: '16px 20px', alignItems: 'center',
              borderTop: i === 0 ? 'none' : `1px solid ${t.hairline}`,
              opacity: m.active ? 1 : 0.55,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 40, height: 40, borderRadius: 12,
                  background: t.surfaceAlt, display: 'grid', placeItems: 'center',
                }}>
                  <TaskIcon kind={m.icon} color={t.lilac} size={22}/>
                </div>
                <div style={{ minWidth: 0 }}>
                  <div style={{
                    fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                    fontWeight: 700, fontSize: 15, color: t.ink, letterSpacing: '-0.01em',
                  }}>{m.title}</div>
                  <div style={{ fontSize: 11, fontWeight: 700, color: t.inkSoft }}>{m.cat}</div>
                </div>
              </div>
              <div>
                <span style={{
                  background: rt.bg, color: rt.fg,
                  padding: '4px 10px', borderRadius: 999,
                  fontSize: 11, fontWeight: 800,
                }}>{recurLabel(m)}</span>
              </div>
              <div><PAStars t={t} value={m.stars} size={14}/></div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {m.assigned.map(kid => {
                  const k = kidById[kid];
                  if (!k) return null;
                  const c = t[k.color];
                  return (
                    <span key={kid} title={k.name} style={{
                      width: 26, height: 26, borderRadius: '50%',
                      background: c.fill, border: `2px solid ${c.ring}`,
                      display: 'inline-grid', placeItems: 'center',
                      fontSize: 10, fontWeight: 900, color: c.ink,
                    }}>{k.name[0]}</span>
                  );
                })}
              </div>
              <div>
                <label style={{ display: 'inline-flex', alignItems: 'center', cursor: 'pointer' }}>
                  <div style={{
                    width: 36, height: 20, borderRadius: 999,
                    background: m.active ? t.lilac : t.hairline,
                    position: 'relative', transition: 'background .15s',
                  }}>
                    <div style={{
                      position: 'absolute', top: 2, left: m.active ? 18 : 2,
                      width: 16, height: 16, borderRadius: '50%',
                      background: '#FFFFFF', transition: 'left .15s',
                      boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                    }}/>
                  </div>
                </label>
              </div>
              <div style={{ display: 'flex', gap: 4, justifyContent: 'flex-end' }}>
                <button style={{
                  background: 'transparent', border: 'none', cursor: 'pointer',
                  padding: 6, borderRadius: 8, color: t.inkSoft,
                }} aria-label="Editar">
                  <LucideIcon name="pencil" size={14} color={t.inkSoft} strokeWidth={2}/>
                </button>
                <button style={{
                  background: 'transparent', border: 'none', cursor: 'pointer',
                  padding: 6, borderRadius: 8, color: t.inkSoft,
                }} aria-label="Remover">
                  <LucideIcon name="trash-2" size={14} color={t.inkSoft} strokeWidth={2}/>
                </button>
              </div>
            </div>
          );
        })}
      </PACard>
    </div>
  );
};
