// Parent Area — Approvals section
// Tabs: Missões (pending-missions queue) | Prêmios (pending-rewards queue).
// Each card has approve / reject actions + optional note.

const DirA = window.DirA || {};
window.DirA = DirA;

DirA.PAApprovals = ({ t }) => {
  const [tab, setTab] = React.useState('missions');
  const missionsCount = PENDING_MISSIONS.length;
  const rewardsCount = PENDING_REWARDS.length;
  const kids = PROFILES.filter(p => p.stars);
  const kidById = Object.fromEntries(kids.map(k => [k.id, k]));

  return (
    <div>
      <PASectionHeader t={t}
        title="Aprovações"
        subtitle={`${missionsCount + rewardsCount} pendências · aprove rápido ou deixe nota para a criança`}
      />

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 24, background: t.surface, padding: 6, borderRadius: 14, boxShadow: t.shadow, width: 'fit-content' }}>
        {[
          { id: 'missions', label: 'Missões', count: missionsCount, icon: 'target' },
          { id: 'rewards',  label: 'Prêmios', count: rewardsCount,  icon: 'gift' },
        ].map(x => {
          const active = tab === x.id;
          return (
            <button key={x.id} onClick={() => setTab(x.id)} style={{
              background: active ? t.ink : 'transparent',
              color: active ? t.bg : t.inkSoft,
              border: 'none', borderRadius: 10,
              padding: '10px 18px', cursor: 'pointer',
              fontFamily: t.fontBody, fontWeight: 800, fontSize: 13,
              display: 'inline-flex', alignItems: 'center', gap: 8,
            }}>
              <LucideIcon name={x.icon} size={14} color={active ? t.bg : t.inkSoft} strokeWidth={2.2}/>
              {x.label}
              <span style={{
                background: active ? 'rgba(255,255,255,0.2)' : t.surfaceAlt,
                color: active ? t.bg : t.inkSoft,
                padding: '2px 8px', borderRadius: 999, fontSize: 11, fontWeight: 900, minWidth: 20, textAlign: 'center',
              }}>{x.count}</span>
            </button>
          );
        })}
      </div>

      {/* Bulk actions */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginBottom: 12 }}>
        <PAButton t={t} variant="soft" icon="check-check" small>Aprovar selecionadas</PAButton>
      </div>

      {/* List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {tab === 'missions' && PENDING_MISSIONS.map(p => {
          const kid = kidById[p.kidId];
          const c = t[kid.color];
          return (
            <PACard key={p.id} t={t} style={{ display: 'flex', alignItems: 'center', gap: 18, padding: 18 }}>
              <input type="checkbox" style={{ width: 18, height: 18, accentColor: t.lilac, cursor: 'pointer' }}/>
              <SmileyAvatar size={48} face={kid.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                  <span style={{
                    fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                    fontWeight: 700, fontSize: 17, color: t.ink, letterSpacing: '-0.01em',
                  }}>{p.title}</span>
                  <span style={{
                    background: c.fill, color: c.ink,
                    padding: '2px 10px', borderRadius: 999,
                    fontSize: 11, fontWeight: 800,
                  }}>{kid.name}</span>
                </div>
                <div style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft, display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span>{p.time}</span>
                  {p.note && (
                    <>
                      <span>·</span>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: t.lilac, fontWeight: 800 }}>
                        <LucideIcon name="paperclip" size={12} color={t.lilac} strokeWidth={2.2}/>
                        {p.note}
                      </span>
                    </>
                  )}
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <PAStars t={t} value={p.stars} size={16} sign="+"/>
                <PAButton t={t} variant="danger" icon="x" small>Rejeitar</PAButton>
                <PAButton t={t} variant="success" icon="check" small>Aprovar</PAButton>
              </div>
            </PACard>
          );
        })}

        {tab === 'rewards' && PENDING_REWARDS.map(p => {
          const kid = kidById[p.kidId];
          const c = t[kid.color];
          return (
            <PACard key={p.id} t={t} style={{ display: 'flex', alignItems: 'center', gap: 18, padding: 18 }}>
              <input type="checkbox" style={{ width: 18, height: 18, accentColor: t.lilac, cursor: 'pointer' }}/>
              <RewardArt kind={p.art} size={56} tint="#EDE9FE"/>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                  <span style={{
                    fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                    fontWeight: 700, fontSize: 17, color: t.ink, letterSpacing: '-0.01em',
                  }}>{p.title}</span>
                  <span style={{
                    background: c.fill, color: c.ink,
                    padding: '2px 10px', borderRadius: 999, fontSize: 11, fontWeight: 800,
                  }}>{kid.name}</span>
                </div>
                <div style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>
                  Pedido {p.time} · Entregar e confirmar no app
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <PAStars t={t} value={p.price} size={16} sign="−"/>
                <PAButton t={t} variant="danger" icon="x" small>Cancelar</PAButton>
                <PAButton t={t} variant="success" icon="check" small>Entregue</PAButton>
              </div>
            </PACard>
          );
        })}

        {/* Empty */}
        {((tab === 'missions' && missionsCount === 0) || (tab === 'rewards' && rewardsCount === 0)) && (
          <PACard t={t} style={{ padding: 40, textAlign: 'center' }}>
            <div style={{ fontSize: 40, marginBottom: 8 }}>🎉</div>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 20, color: t.ink, marginBottom: 4,
            }}>Tudo em dia!</div>
            <div style={{ fontSize: 13, color: t.inkSoft, fontWeight: 600 }}>
              Nenhuma {tab === 'missions' ? 'missão' : 'troca'} aguardando.
            </div>
          </PACard>
        )}
      </div>
    </div>
  );
};
