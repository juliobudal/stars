// screens/kid-view.jsx — US04/05/07 vista da criança

function KidView({ data, kid, setData, go }) {
  const [tab, setTab] = useState('todo');
  const [modalMission, setModalMission] = useState(null);
  const [confirmed, setConfirmed] = useState(false);
  const cardStyle = window.__tweaks?.cardStyle || 'bubble';
  const toast = useToast();

  const myMissions = data.todayMissions.filter(t => t.kidId === kid.id);
  const todo = myMissions.filter(t => t.status === 'pending');
  const waiting = myMissions.filter(t => t.status === 'waiting');
  const done = myMissions.filter(t => t.status === 'done');

  const completionPct = myMissions.length === 0 ? 0 : Math.round((done.length + waiting.length * 0.5) / myMissions.length * 100);

  const handleComplete = () => {
    setConfirmed(true);
    setTimeout(() => {
      setData(d => ({
        ...d,
        todayMissions: d.todayMissions.map(t => t.id === modalMission.id ? { ...t, status: 'waiting' } : t)
      }));
      setModalMission(null);
      setConfirmed(false);
      setTab('waiting');
      toast.show('Enviado pra aprovação!', 'primary');
    }, 900);
  };

  const list = tab === 'todo' ? todo : waiting;
  const map = window.COLOR_MAP;
  const kidC = map[kid.color] || map.primary;

  return (
    <div className="screen screen-enter with-nav">
      <BgShapes variant="blue"/>
      {toast.el}

      {/* Header */}
      <div className="row mb-5" style={{ justifyContent: 'space-between', zIndex: 2, flexShrink: 0 }}>
        <div className="row" style={{ gap: 12 }}>
          <KidAvatar kid={kid} size={56}/>
          <div className="col" style={{ gap: 0 }}>
            <div className="eyebrow">Oi,</div>
            <div className="h-display" style={{ fontSize: 24 }}>{kid.name}!</div>
          </div>
        </div>
        <Lumi size={56} mood={todo.length === 0 ? 'excited' : 'happy'}/>
      </div>

      {/* Portal = card primary gigante */}
      <div style={{ zIndex: 2, marginBottom: 28 }}>
        <div className="card card-primary" style={{
          padding: 26,
          overflow: 'hidden',
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute', inset: 0,
            background: 'radial-gradient(circle at 85% 20%, rgba(255,255,255,0.25), transparent 50%)',
            pointerEvents: 'none',
          }}/>
          <div className="row" style={{ gap: 18, position: 'relative' }}>
            <div style={{
              width: 80, height: 80, borderRadius: '50%',
              background: 'rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              border: '3px solid rgba(255,255,255,0.4)',
              animation: 'float 3s ease-in-out infinite',
            }}>
              <Icon name="star" size={48} color="#ffc41a"/>
            </div>
            <div className="col fg1" style={{ gap: 2 }}>
              <div style={{ fontSize: 12, fontWeight: 800, opacity: 0.85, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
                Meu Cofrinho
              </div>
              <div className="h-display" style={{ fontSize: 44, lineHeight: 1 }}>{kid.balance}</div>
              <div style={{ fontSize: 14, opacity: 0.85, fontWeight: 700 }}>estrelinhas guardadas</div>
            </div>
            <button className="btn btn-star" onClick={() => go('shop')}>
              <Icon name="bag" size={18} color="currentColor"/>
              Lojinha
            </button>
          </div>

          {/* Progress do dia */}
          <div style={{ marginTop: 22, position: 'relative' }}>
            <div className="row" style={{ justifyContent: 'space-between', marginBottom: 8 }}>
              <div style={{ fontSize: 13, fontWeight: 800, opacity: 0.9 }}>PROGRESSO DE HOJE</div>
              <div style={{ fontSize: 13, fontWeight: 800 }}>
                {done.length + waiting.length}/{myMissions.length} ✨
              </div>
            </div>
            <div className="progress-track" style={{ background: 'rgba(255,255,255,0.25)' }}>
              <div className="progress-fill" style={{ width: `${completionPct}%`, background: 'white' }}/>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="mb-4" style={{ zIndex: 2 }}>
        <div className="tabs">
          <button className={`tab ${tab === 'todo' ? 'active' : ''}`} onClick={() => setTab('todo')}>
            <Icon name="target" size={16} color="currentColor"/>
            Pra Fazer {todo.length > 0 && <span style={{ background: tab === 'todo' ? 'rgba(255,255,255,0.3)' : 'var(--primary)', color: tab === 'todo' ? 'white' : 'white', padding: '1px 7px', borderRadius: 10, fontSize: 11, marginLeft: 2 }}>{todo.length}</span>}
          </button>
          <button className={`tab ${tab === 'waiting' ? 'active' : ''}`} onClick={() => setTab('waiting')}>
            <Icon name="clock" size={16} color="currentColor"/>
            Aguardando {waiting.length > 0 && <span style={{ background: tab === 'waiting' ? 'rgba(255,255,255,0.3)' : 'var(--c-peach)', color: 'white', padding: '1px 7px', borderRadius: 10, fontSize: 11, marginLeft: 2 }}>{waiting.length}</span>}
          </button>
        </div>
      </div>

      {/* Lista */}
      <div className="col" style={{ gap: 14, zIndex: 2 }}>
        {list.length === 0 && (
          <EmptyState
            icon={tab === 'todo' ? 'check' : 'clock'}
            title={tab === 'todo' ? 'Todas as missões feitas!' : 'Nada aguardando'}
            subtitle={tab === 'todo' ? 'Você está arrasando hoje ✨' : 'Complete missões para elas aparecerem aqui'}
            color={tab === 'todo' ? 'mint' : 'peach'}
          />
        )}
        {list.map((t, i) => {
          const m = data.missionBank.find(mm => mm.id === t.missionId);
          const cat = window.CATEGORIES.find(c => c.id === m.category);
          const catC = map[cat.color];
          return (
            <MissionCard
              key={t.id}
              mission={m}
              cat={cat}
              catC={catC}
              status={t.status}
              style={cardStyle}
              index={i}
              onTap={() => t.status === 'pending' && setModalMission({ ...t, mission: m })}
            />
          );
        })}
      </div>

      {/* Modal confirmar */}
      <Modal show={!!modalMission} onClose={() => !confirmed && setModalMission(null)}>
        {modalMission && (() => {
          const m = modalMission.mission;
          const cat = window.CATEGORIES.find(c => c.id === m.category);
          return (
            <div className="center col" style={{ textAlign: 'center', gap: 16 }}>
              {!confirmed ? (
                <>
                  <Lumi size={76} mood="thinking"/>
                  <IconTile icon={m.icon} color={cat.color} size={88}/>
                  <h3 className="h-display" style={{ fontSize: 26 }}>{m.title}</h3>
                  <div className="row" style={{ gap: 10, justifyContent: 'center' }}>
                    {catChip(m.category)}
                    <div className="chip chip-star">
                      <Icon name="star" size={14} color="var(--star-2)"/>
                      +{m.stars}
                    </div>
                  </div>
                  <p className="subtitle" style={{ marginTop: 4 }}>Terminou essa missão? Um responsável vai confirmar.</p>
                  <div className="row" style={{ gap: 12, marginTop: 8, width: '100%', justifyContent: 'center' }}>
                    <button className="btn btn-secondary" onClick={() => setModalMission(null)}>Ainda não</button>
                    <button className="btn btn-primary btn-lg" onClick={handleComplete}>
                      <Icon name="check" size={20} color="currentColor"/> Terminei!
                    </button>
                  </div>
                </>
              ) : (
                <div className="center col" style={{ gap: 16, padding: 20 }}>
                  <div style={{
                    width: 96, height: 96, borderRadius: '50%',
                    background: 'var(--success)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    animation: 'popIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)',
                    boxShadow: '0 6px 0 #23a365',
                  }}>
                    <Icon name="check" size={56} color="white"/>
                  </div>
                  <h3 className="h-display" style={{ fontSize: 22 }}>Enviado!</h3>
                  <p className="subtitle">Aguardando aprovação ✨</p>
                </div>
              )}
            </div>
          );
        })()}
      </Modal>
    </div>
  );
}

function MissionCard({ mission, cat, catC, status, style, index, onTap }) {
  const [pressed, setPressed] = useState(false);
  const waiting = status === 'waiting';

  if (style === 'ticket') {
    return (
      <div
        className="row pop-on-tap"
        onMouseDown={() => setPressed(true)}
        onMouseUp={() => setPressed(false)}
        onMouseLeave={() => setPressed(false)}
        onClick={onTap}
        style={{
          background: 'white',
          borderRadius: 'var(--r-md)',
          border: '2px solid rgba(26,42,74,0.08)',
          boxShadow: pressed ? '0 1px 0 rgba(26,42,74,0.08)' : '0 4px 0 rgba(26,42,74,0.08)',
          padding: 14,
          transform: pressed ? 'translateY(3px)' : 'translateY(0)',
          cursor: waiting ? 'default' : 'pointer',
          animation: `slideInCard 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) ${index * 0.04}s both`,
          gap: 14,
          opacity: waiting ? 0.7 : 1,
          position: 'relative',
          transition: 'all 0.1s',
        }}
      >
        <IconTile icon={mission.icon} color={cat.color} size={56}/>
        <div className="col fg1" style={{ gap: 4 }}>
          <div className="h-display" style={{ fontSize: 17 }}>{mission.title}</div>
          <div className="row" style={{ gap: 6 }}>
            {catChip(mission.category, 'sm')}
            {waiting && (
              <div className="chip chip-peach" style={{ fontSize: 11, padding: '4px 10px' }}>
                <Icon name="clock" size={12} color="currentColor"/> Aguardando
              </div>
            )}
          </div>
        </div>
        <div className="col center" style={{ gap: 2, padding: '0 6px' }}>
          <Icon name="star" size={22} color="var(--star)"/>
          <div className="h-display" style={{ fontSize: 20, color: 'var(--star-2)' }}>{mission.stars}</div>
        </div>
      </div>
    );
  }

  // bubble
  return (
    <div
      className="pop-on-tap"
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      onClick={onTap}
      style={{
        background: waiting ? catC.bg : 'white',
        borderRadius: 'var(--r-lg)',
        border: `3px solid ${catC.fg}`,
        boxShadow: pressed ? `0 1px 0 ${catC.fg}` : `0 5px 0 ${catC.fg}`,
        padding: '18px 20px',
        transform: pressed ? 'translateY(4px)' : 'translateY(0)',
        cursor: waiting ? 'default' : 'pointer',
        animation: `slideInCard 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) ${index * 0.05}s both`,
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        opacity: waiting ? 0.88 : 1,
        transition: 'all 0.1s',
      }}
    >
      <div style={{
        width: 58, height: 58, borderRadius: '50%',
        background: catC.fg,
        color: 'white',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <Icon name={mission.icon} size={30} color="white"/>
      </div>
      <div className="col fg1" style={{ gap: 4 }}>
        <div className="h-display" style={{ fontSize: 18 }}>{mission.title}</div>
        <div className="row" style={{ gap: 6 }}>
          <div style={{ fontSize: 13, color: 'var(--text-muted)', fontWeight: 700 }}>{mission.category} · {mission.frequency}</div>
        </div>
      </div>
      <div className="col center" style={{ gap: 0 }}>
        {waiting ? (
          <div className="chip chip-peach" style={{ fontSize: 12, padding: '5px 10px' }}>
            <Icon name="clock" size={12} color="currentColor"/>
          </div>
        ) : (
          <div className="row" style={{ gap: 4, alignItems: 'center' }}>
            <Icon name="star" size={20} color="var(--star)"/>
            <div className="h-display" style={{ fontSize: 22, color: 'var(--star-2)' }}>{mission.stars}</div>
          </div>
        )}
      </div>
    </div>
  );
}

window.KidView = KidView;
