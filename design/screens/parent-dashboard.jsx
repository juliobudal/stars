// screens/parent-dashboard.jsx — hub do responsável

function ParentDashboard({ data, parent, go }) {
  const totalStars = data.kids.reduce((s, k) => s + k.balance, 0);
  const totalPending = data.todayMissions.filter(t => t.status === 'waiting').length;
  const totalDoneToday = data.todayMissions.filter(t => t.status === 'done').length;

  const tiles = [
    { id: 'approvals', label: 'Aprovações', icon: 'check', color: 'mint', badge: totalPending },
    { id: 'bank',      label: 'Banco de Missões', icon: 'target', color: 'primary' },
    { id: 'kids',      label: 'Crianças', icon: 'users', color: 'peach' },
    { id: 'shop-admin',label: 'Lojinha', icon: 'bag', color: 'rose' },
    { id: 'history',   label: 'Extrato', icon: 'scroll', color: 'lilac' },
  ];
  const map = window.COLOR_MAP;

  return (
    <div className="screen screen-enter">
      <BgShapes variant="blue"/>

      {/* Header */}
      <div className="row mb-5" style={{ justifyContent: 'space-between', zIndex: 2 }}>
        <div className="row" style={{ gap: 12 }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: 'var(--primary-soft)',
            border: '3px solid var(--primary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name={parent.icon} size={52} color="var(--primary)"/>
          </div>
          <div className="col" style={{ gap: 0 }}>
            <div className="eyebrow">Olá,</div>
            <div className="h-display" style={{ fontSize: 24 }}>{parent.name}</div>
          </div>
        </div>
        <button className="btn btn-secondary btn-icon" onClick={() => localStorage.removeItem('ls-route') || window.location.reload()}>
          <Icon name="logout" size={20}/>
        </button>
      </div>

      {/* KPIs */}
      <div className="grid-3 mb-5" style={{ gap: 12, zIndex: 2 }}>
        <div className="card" style={{ padding: 18, textAlign: 'center' }}>
          <div className="row center" style={{ gap: 6 }}>
            <Icon name="star" size={22} color="var(--star)"/>
            <div className="h-display" style={{ fontSize: 28, color: 'var(--star-2)' }}>{totalStars}</div>
          </div>
          <div className="eyebrow" style={{ marginTop: 4 }}>Estrelinhas</div>
        </div>
        <div className="card" style={{ padding: 18, textAlign: 'center' }}>
          <div className="row center" style={{ gap: 6 }}>
            <Icon name="clock" size={22} color="var(--c-peach)"/>
            <div className="h-display" style={{ fontSize: 28, color: 'var(--c-peach)' }}>{totalPending}</div>
          </div>
          <div className="eyebrow" style={{ marginTop: 4 }}>Aguardando</div>
        </div>
        <div className="card" style={{ padding: 18, textAlign: 'center' }}>
          <div className="row center" style={{ gap: 6 }}>
            <Icon name="users" size={22} color="var(--primary)"/>
            <div className="h-display" style={{ fontSize: 28, color: 'var(--primary)' }}>{data.kids.length}</div>
          </div>
          <div className="eyebrow" style={{ marginTop: 4 }}>Crianças</div>
        </div>
      </div>

      {/* Crianças */}
      <div className="mb-5" style={{ zIndex: 2 }}>
        <h3 className="h-display mb-3" style={{ fontSize: 20 }}>Visão Geral</h3>
        <div className="col" style={{ gap: 10 }}>
          {data.kids.map((k, i) => {
            const kidMissions = data.todayMissions.filter(t => t.kidId === k.id);
            const doneCount = kidMissions.filter(t => t.status === 'done' || t.status === 'waiting').length;
            const pct = kidMissions.length === 0 ? 0 : doneCount / kidMissions.length * 100;
            const c = map[k.color];
            return (
              <button
                key={k.id}
                className="card pop-on-tap"
                onClick={() => go('approvals')}
                style={{
                  padding: 16,
                  cursor: 'pointer',
                  textAlign: 'left',
                  fontFamily: 'var(--font-body)',
                  animation: `slideInCard 0.4s ease ${i * 0.05}s both`,
                  border: `2px solid rgba(26,42,74,0.08)`,
                }}
              >
                <div className="row" style={{ gap: 14 }}>
                  <KidAvatar kid={k} size={54}/>
                  <div className="col fg1" style={{ gap: 6 }}>
                    <div className="row" style={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
                      <div className="h-display" style={{ fontSize: 18 }}>{k.name}</div>
                      <div className="row" style={{ gap: 4, alignItems: 'center' }}>
                        <Icon name="star" size={14} color="var(--star)"/>
                        <span className="h-display" style={{ color: 'var(--star-2)', fontSize: 15 }}>{k.balance}</span>
                      </div>
                    </div>
                    <div className="progress-track" style={{ height: 10 }}>
                      <div className="progress-fill" style={{ width: `${pct}%`, background: c.fg }}/>
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 700 }}>
                      {doneCount}/{kidMissions.length} missões hoje
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Tiles */}
      <div style={{ zIndex: 2 }}>
        <h3 className="h-display mb-3" style={{ fontSize: 20 }}>Gerenciar</h3>
        <div className="grid-auto" style={{ gap: 12 }}>
          {tiles.map((t, i) => {
            const c = map[t.color];
            return (
              <button
                key={t.id}
                onClick={() => go(t.id)}
                className="card pop-on-tap"
                style={{
                  padding: 18,
                  cursor: 'pointer',
                  textAlign: 'left',
                  position: 'relative',
                  border: `2px solid ${c.fg}`,
                  boxShadow: `0 4px 0 ${c.fg}`,
                  animation: `slideInCard 0.4s ease ${0.2 + i * 0.04}s both`,
                  fontFamily: 'var(--font-body)',
                }}
              >
                {t.badge > 0 && (
                  <div style={{
                    position: 'absolute', top: -6, right: -6,
                    width: 28, height: 28,
                    borderRadius: '50%',
                    background: 'var(--danger)',
                    color: 'white',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 13, fontWeight: 800,
                    border: '3px solid white',
                    boxShadow: '0 2px 0 rgba(26,42,74,0.15)',
                  }}>{t.badge}</div>
                )}
                <div style={{
                  width: 46, height: 46, borderRadius: 'var(--r-md)',
                  background: c.bg,
                  color: c.fg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  marginBottom: 10,
                }}>
                  <Icon name={t.icon} size={26} color={c.fg}/>
                </div>
                <div className="h-display" style={{ fontSize: 15 }}>{t.label}</div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

window.ParentDashboard = ParentDashboard;
