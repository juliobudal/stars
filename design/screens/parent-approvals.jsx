// screens/parent-approvals.jsx — US06

function ParentApprovals({ data, setData, go }) {
  const [flashId, setFlashId] = useState(null); // {id, kind}
  const toast = useToast();

  const waiting = data.todayMissions.filter(t => t.status === 'waiting');
  const grouped = data.kids.map(k => ({
    kid: k,
    items: waiting.filter(t => t.kidId === k.id).map(t => ({
      ...t,
      mission: data.missionBank.find(m => m.id === t.missionId),
    })),
  })).filter(g => g.items.length > 0);

  const approve = (t, mission, kid) => {
    setFlashId({ id: t.id, kind: 'ok' });
    setTimeout(() => {
      setData(d => ({
        ...d,
        todayMissions: d.todayMissions.map(x => x.id === t.id ? { ...x, status: 'done' } : x),
        kids: d.kids.map(k => k.id === kid.id ? { ...k, balance: k.balance + mission.stars } : k),
        history: [{
          id: 'h' + Date.now(),
          kidId: kid.id,
          type: 'earn',
          amount: mission.stars,
          label: mission.title,
          icon: mission.icon,
          ts: 'Agora',
        }, ...d.history],
      }));
      toast.show(`+${mission.stars} ⭐ para ${kid.name}!`);
      setFlashId(null);
    }, 450);
  };

  const reject = (t) => {
    setFlashId({ id: t.id, kind: 'no' });
    setTimeout(() => {
      setData(d => ({
        ...d,
        todayMissions: d.todayMissions.map(x => x.id === t.id ? { ...x, status: 'pending' } : x),
      }));
      toast.show('Devolvido pra refazer', 'error');
      setFlashId(null);
    }, 450);
  };

  const map = window.COLOR_MAP;

  return (
    <div className="screen screen-enter-right">
      <BgShapes variant="cool"/>
      {toast.el}

      <TopBar
        title="Aprovações"
        subtitle="Confira e libere as estrelinhas"
        leftAction={{ onClick: () => go('parent') }}
        rightSlot={
          <div className="chip chip-peach" style={{ fontSize: 14, padding: '8px 14px' }}>
            <Icon name="clock" size={15} color="currentColor"/> {waiting.length}
          </div>
        }
      />

      {grouped.length === 0 && (
        <EmptyState
          icon="check"
          title="Tudo em dia!"
          subtitle="Nenhuma missão aguardando aprovação agora."
          color="mint"
        />
      )}

      {grouped.map((g, gi) => {
        const kc = map[g.kid.color];
        return (
          <div key={g.kid.id} className="mb-5" style={{ zIndex: 2, animation: `slideInCard 0.4s ease ${gi * 0.06}s both` }}>
            <div className="row mb-3" style={{ gap: 12 }}>
              <KidAvatar kid={g.kid} size={44}/>
              <div className="h-display" style={{ fontSize: 20 }}>{g.kid.name}</div>
              <div className="chip chip-outline">{g.items.length} pedido{g.items.length > 1 ? 's' : ''}</div>
            </div>
            <div className="col" style={{ gap: 10 }}>
              {g.items.map(it => {
                const m = it.mission;
                const cat = window.CATEGORIES.find(c => c.id === m.category);
                const flash = flashId?.id === it.id;
                const kind = flashId?.kind;
                return (
                  <div key={it.id} className="card" style={{
                    padding: 14,
                    border: flash ? `3px solid ${kind === 'ok' ? 'var(--success)' : 'var(--danger)'}` : '2px solid rgba(26,42,74,0.08)',
                    background: flash ? (kind === 'ok' ? 'var(--c-mint-soft)' : 'var(--c-coral-soft)') : 'white',
                    animation: flash && kind === 'no' ? 'shake 0.4s' : 'none',
                    transition: 'all 0.2s',
                  }}>
                    <div className="row" style={{ gap: 14 }}>
                      <IconTile icon={m.icon} color={cat.color} size={52}/>
                      <div className="col fg1" style={{ gap: 4 }}>
                        <div className="h-display" style={{ fontSize: 17 }}>{m.title}</div>
                        <div className="row" style={{ gap: 6 }}>
                          {catChip(m.category, 'sm')}
                          <div className="chip chip-star" style={{ fontSize: 12, padding: '4px 10px' }}>
                            <Icon name="star" size={12} color="var(--star-2)"/>+{m.stars}
                          </div>
                        </div>
                      </div>
                      <div className="row" style={{ gap: 8 }}>
                        <button className="btn btn-danger btn-icon" onClick={() => reject(it)}>
                          <Icon name="close" size={20} color="white"/>
                        </button>
                        <button className="btn btn-success btn-icon" onClick={() => approve(it, m, g.kid)}>
                          <Icon name="check" size={22} color="white"/>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        );
      })}
    </div>
  );
}

window.ParentApprovals = ParentApprovals;
