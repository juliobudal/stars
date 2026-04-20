// screens/parent-kids.jsx — US02 gerenciar crianças

function ParentKids({ data, setData, go }) {
  const [editKid, setEditKid] = useState(null);
  const toast = useToast();

  const iconOptions = ['faceFox', 'faceHero', 'facePrincess', 'faceKid', 'faceParent'];
  const colorOptions = ['peach', 'rose', 'mint', 'sky', 'lilac', 'coral'];
  const map = window.COLOR_MAP;

  const save = (k) => {
    if (!k.name) { toast.show('Dê um nome', 'error'); return; }
    if (editKid.__new) {
      setData(d => ({ ...d, kids: [...d.kids, { ...k, id: 'k' + Date.now(), balance: 0, role: 'kid' }] }));
      toast.show('Criança adicionada!');
    } else {
      setData(d => ({ ...d, kids: d.kids.map(x => x.id === k.id ? k : x) }));
      toast.show('Perfil atualizado');
    }
    setEditKid(null);
  };

  const remove = (id) => {
    setData(d => ({ ...d, kids: d.kids.filter(k => k.id !== id) }));
    toast.show('Removido');
    setEditKid(null);
  };

  return (
    <div className="screen screen-enter-right">
      <BgShapes variant="warm"/>
      {toast.el}
      <TopBar
        title="Crianças"
        subtitle="Gerencie perfis e saldos"
        leftAction={{ onClick: () => go('parent') }}
        rightSlot={
          <button className="btn btn-primary" onClick={() => setEditKid({ name: '', icon: 'faceKid', color: 'peach', __new: true })}>
            <Icon name="plus" size={18} color="white"/> Adicionar
          </button>
        }
      />

      <div className="col" style={{ gap: 12, zIndex: 2 }}>
        {data.kids.map((k, i) => {
          const c = map[k.color];
          const missions = data.todayMissions.filter(t => t.kidId === k.id);
          return (
            <div key={k.id} className="card pop-on-tap" style={{
              padding: 16,
              cursor: 'pointer',
              border: `2px solid ${c.fg}`,
              boxShadow: `0 4px 0 ${c.fg}`,
              animation: `slideInCard 0.35s ease ${i * 0.05}s both`,
            }} onClick={() => setEditKid(k)}>
              <div className="row" style={{ gap: 16 }}>
                <KidAvatar kid={k} size={64}/>
                <div className="col fg1" style={{ gap: 4 }}>
                  <div className="h-display" style={{ fontSize: 20 }}>{k.name}</div>
                  <div className="row" style={{ gap: 8 }}>
                    <div className="chip chip-star" style={{ fontSize: 12, padding: '4px 10px' }}>
                      <Icon name="star" size={12} color="var(--star-2)"/> {k.balance}
                    </div>
                    <div className="chip chip-outline" style={{ fontSize: 12, padding: '4px 10px' }}>
                      {missions.length} missões hoje
                    </div>
                  </div>
                </div>
                <Icon name="edit" size={22} color={c.fg}/>
              </div>
            </div>
          );
        })}
      </div>

      <Modal show={!!editKid} onClose={() => setEditKid(null)}>
        {editKid && (
          <KidForm
            initial={editKid}
            iconOptions={iconOptions}
            colorOptions={colorOptions}
            onSave={save}
            onRemove={editKid.__new ? null : () => remove(editKid.id)}
            onCancel={() => setEditKid(null)}
          />
        )}
      </Modal>
    </div>
  );
}

function KidForm({ initial, iconOptions, colorOptions, onSave, onRemove, onCancel }) {
  const [k, setK] = useState(initial);
  const map = window.COLOR_MAP;
  const c = map[k.color];
  return (
    <div>
      <div className="row mb-4" style={{ justifyContent: 'space-between' }}>
        <h3 className="h-display" style={{ fontSize: 22 }}>{k.__new ? 'Nova criança' : 'Editar perfil'}</h3>
        <button className="btn btn-ghost btn-icon" onClick={onCancel}><Icon name="close" size={20}/></button>
      </div>

      <div className="center mb-4">
        <KidAvatar kid={k} size={100}/>
      </div>

      <div className="form-field">
        <label className="form-label">Nome</label>
        <input className="form-input" value={k.name} onChange={e => setK({ ...k, name: e.target.value })}/>
      </div>

      <div className="form-field">
        <label className="form-label">Avatar</label>
        <div className="row wrap" style={{ gap: 8 }}>
          {iconOptions.map(ic => (
            <button key={ic} type="button" onClick={() => setK({ ...k, icon: ic })} style={{
              width: 56, height: 56, borderRadius: '50%',
              border: k.icon === ic ? `3px solid ${c.fg}` : '2px solid rgba(26,42,74,0.1)',
              background: k.icon === ic ? c.bg : 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer',
              overflow: 'hidden',
            }}>
              <Icon name={ic} size={48} color={c.fg}/>
            </button>
          ))}
        </div>
      </div>

      <div className="form-field">
        <label className="form-label">Cor</label>
        <div className="row" style={{ gap: 10 }}>
          {colorOptions.map(col => (
            <button key={col} type="button" onClick={() => setK({ ...k, color: col })} style={{
              width: 40, height: 40, borderRadius: '50%',
              background: map[col].fg,
              border: k.color === col ? '3px solid var(--text)' : '3px solid transparent',
              cursor: 'pointer',
            }}/>
          ))}
        </div>
      </div>

      <div className="row mt-4" style={{ gap: 10, justifyContent: 'space-between' }}>
        {onRemove && <button className="btn btn-danger btn-sm" onClick={onRemove}><Icon name="trash" size={16} color="white"/></button>}
        <div className="row" style={{ gap: 10, marginLeft: 'auto' }}>
          <button className="btn btn-secondary" onClick={onCancel}>Cancelar</button>
          <button className="btn btn-primary" onClick={() => onSave(k)}>
            <Icon name="check" size={18} color="white"/> Salvar
          </button>
        </div>
      </div>
    </div>
  );
}

window.ParentKids = ParentKids;
