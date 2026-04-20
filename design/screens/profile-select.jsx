// screens/profile-select.jsx — US01

function ProfileSelect({ data, onPick }) {
  const profiles = [...data.parents, ...data.kids];
  return (
    <div className="screen screen-enter" style={{ justifyContent: 'flex-start', alignItems: 'center', paddingTop: 28 }}>
      <BgShapes variant="blue"/>

      <div style={{ zIndex: 2, width: '100%', maxWidth: 960, textAlign: 'center' }}>
        <div className="mb-4 center col" style={{ gap: 6 }}>
          <Lumi size={72} mood="excited"/>
          <div className="eyebrow mt-2">LittleStars</div>
          <h1 className="h-display display" style={{ fontSize: 36 }}>Quem vai brilhar hoje?</h1>
          <p className="subtitle" style={{ maxWidth: 460, fontSize: 15 }}>Escolha seu perfil para começar a aventura</p>
        </div>

        <div className="grid-auto" style={{ gap: 14, marginTop: 20 }}>
          {profiles.map((p, i) => {
            const isKid = p.role === 'kid';
            const map = window.COLOR_MAP;
            const c = map[p.color] || map.primary;
            return (
              <button
                key={p.id}
                onClick={() => onPick(p)}
                className="card pop-on-tap"
                style={{
                  cursor: 'pointer',
                  background: 'white',
                  border: `3px solid ${c.fg}`,
                  boxShadow: `0 6px 0 ${c.fg}`,
                  padding: '24px 18px',
                  transition: 'transform 0.12s',
                  animation: `slideInCard 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) ${i * 0.05}s both`,
                  textAlign: 'center',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: 12,
                  fontFamily: 'var(--font-body)',
                  fontWeight: 700,
                  color: 'var(--text)',
                }}
                onMouseDown={e => e.currentTarget.style.transform = 'translateY(4px)'}
                onMouseUp={e => e.currentTarget.style.transform = ''}
                onMouseLeave={e => e.currentTarget.style.transform = ''}
              >
                <KidAvatar kid={p} size={96}/>
                <div className="h-display" style={{ fontSize: 20 }}>{p.name}</div>
                {isKid ? (
                  <div className="chip chip-star" style={{ gap: 4 }}>
                    <Icon name="star" size={14} color="var(--star-2)"/>
                    {p.balance}
                  </div>
                ) : (
                  <div className="chip chip-primary">Responsável</div>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

window.ProfileSelect = ProfileSelect;
