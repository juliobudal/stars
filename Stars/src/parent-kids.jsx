// Parent Area — Filhos (Kids) section
// Grid of kid cards with inline edit affordance for color, face, name, age.

const DirA = window.DirA || {};
window.DirA = DirA;

const FACE_OPTIONS = ['smile', 'wink', 'tongue', 'calm', 'happy'];
const COLOR_OPTIONS = ['lila', 'theo', 'zoe', 'mom', 'dad'];

DirA.PAKids = ({ t }) => {
  const kids = PROFILES.filter(p => p.stars);
  const [editing, setEditing] = React.useState(null);

  return (
    <div>
      <PASectionHeader t={t}
        title="Filhos"
        subtitle="Gerencie as crianças da família. Adicione novas, mude cor, nome ou expressão."
        action={<PAButton t={t} icon="user-plus">Adicionar filho</PAButton>}
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
        {kids.map(k => {
          const c = t[k.color];
          const missions = MISSION_CATALOG.filter(m => m.assigned.includes(k.id) && m.active).length;
          return (
            <PACard key={k.id} t={t} style={{ padding: 0, overflow: 'hidden' }}>
              {/* avatar band */}
              <div style={{
                background: c.fill, padding: '28px 20px 20px',
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10,
                position: 'relative',
              }}>
                <button style={{
                  position: 'absolute', top: 12, right: 12,
                  background: 'rgba(255,255,255,0.7)', border: 'none',
                  width: 32, height: 32, borderRadius: 10, cursor: 'pointer',
                  display: 'grid', placeItems: 'center', color: c.ink,
                }} onClick={() => setEditing(editing === k.id ? null : k.id)} aria-label="Editar">
                  <LucideIcon name={editing === k.id ? 'check' : 'pencil'} size={14} color={c.ink} strokeWidth={2.2}/>
                </button>
                <SmileyAvatar size={92} face={k.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
                <div style={{
                  fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                  fontWeight: 700, fontSize: 24, color: c.ink, letterSpacing: '-0.01em', lineHeight: 1,
                }}>{k.name}</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: c.ink, opacity: 0.7, letterSpacing: '.08em' }}>
                  8 ANOS · NÍVEL 4
                </div>
              </div>

              {/* stats + edit */}
              <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div style={{ background: t.surfaceAlt, borderRadius: 12, padding: 10, textAlign: 'center' }}>
                    <div style={{ fontSize: 11, fontWeight: 800, color: t.inkSoft, letterSpacing: '.08em' }}>SALDO</div>
                    <div style={{ marginTop: 4, display: 'inline-flex', justifyContent: 'center' }}>
                      <PAStars t={t} value={k.stars} size={16}/>
                    </div>
                  </div>
                  <div style={{ background: t.surfaceAlt, borderRadius: 12, padding: 10, textAlign: 'center' }}>
                    <div style={{ fontSize: 11, fontWeight: 800, color: t.inkSoft, letterSpacing: '.08em' }}>MISSÕES</div>
                    <div style={{
                      marginTop: 4, fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                      fontWeight: 700, fontSize: 18, color: t.ink,
                    }}>{missions}</div>
                  </div>
                </div>

                {editing === k.id && (
                  <div style={{ borderTop: `1px dashed ${t.hairline}`, paddingTop: 14, display: 'flex', flexDirection: 'column', gap: 12 }}>
                    <div>
                      <div style={{ fontSize: 11, fontWeight: 800, color: t.inkSoft, letterSpacing: '.08em', marginBottom: 6 }}>EXPRESSÃO</div>
                      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                        {FACE_OPTIONS.map(f => (
                          <button key={f} style={{
                            background: k.face === f ? c.ring : t.surface,
                            border: `2px solid ${k.face === f ? c.ink : t.hairline}`,
                            borderRadius: 10, padding: 4, cursor: 'pointer',
                          }}>
                            <SmileyAvatar size={28} face={f} fill={c.fill} ring={c.ring} ink={c.ink}/>
                          </button>
                        ))}
                      </div>
                    </div>
                    <div>
                      <div style={{ fontSize: 11, fontWeight: 800, color: t.inkSoft, letterSpacing: '.08em', marginBottom: 6 }}>COR</div>
                      <div style={{ display: 'flex', gap: 6 }}>
                        {COLOR_OPTIONS.map(co => {
                          const cc = t[co];
                          return (
                            <button key={co} style={{
                              width: 30, height: 30, borderRadius: '50%',
                              background: cc.fill,
                              border: `3px solid ${k.color === co ? cc.ink : 'transparent'}`,
                              cursor: 'pointer', padding: 0,
                            }}>
                              <div style={{ width: '100%', height: '100%', borderRadius: '50%', background: cc.ring }}/>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                )}

                <div style={{ display: 'flex', gap: 8 }}>
                  <PAButton t={t} variant="soft" icon="eye" small>Ver jornada</PAButton>
                  <PAButton t={t} variant="ghost" icon="trash-2" small>Remover</PAButton>
                </div>
              </div>
            </PACard>
          );
        })}

        {/* Add new kid */}
        <button style={{
          background: 'transparent', border: `2px dashed ${t.hairline}`,
          borderRadius: t.radius, padding: 40,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12,
          cursor: 'pointer', color: t.inkSoft, fontFamily: t.fontBody, fontWeight: 800, fontSize: 14,
          minHeight: 300,
        }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: t.surfaceAlt, display: 'grid', placeItems: 'center',
          }}>
            <LucideIcon name="plus" size={24} color={t.lilac} strokeWidth={2.5}/>
          </div>
          Adicionar filho
        </button>
      </div>
    </div>
  );
};
