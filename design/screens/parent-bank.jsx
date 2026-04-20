// screens/parent-bank.jsx — US03 banco de missões

function ParentBank({ data, setData, go }) {
  const [editItem, setEditItem] = useState(null); // null | 'new' | mission
  const toast = useToast();

  const iconOptions = ['bed', 'brush', 'book', 'dish', 'bookOpen', 'bear', 'paw', 'music', 'sun', 'home', 'graduationCap', 'muscle'];
  const map = window.COLOR_MAP;

  const save = (m) => {
    if (!m.title) { toast.show('Dê um nome à missão', 'error'); return; }
    if (editItem === 'new') {
      setData(d => ({ ...d, missionBank: [...d.missionBank, { ...m, id: 'm' + Date.now() }] }));
      toast.show('Missão criada!');
    } else {
      setData(d => ({ ...d, missionBank: d.missionBank.map(x => x.id === m.id ? m : x) }));
      toast.show('Missão atualizada');
    }
    setEditItem(null);
  };

  const remove = (id) => {
    setData(d => ({ ...d, missionBank: d.missionBank.filter(m => m.id !== id) }));
    toast.show('Missão removida');
    setEditItem(null);
  };

  return (
    <div className="screen screen-enter-right">
      <BgShapes variant="blue"/>
      {toast.el}

      <TopBar
        title="Banco de Missões"
        subtitle="Crie tarefas que as crianças podem cumprir"
        leftAction={{ onClick: () => go('parent') }}
        rightSlot={
          <button className="btn btn-primary" onClick={() => setEditItem({ id: null, title: '', stars: 20, category: 'Casa', icon: 'home', frequency: 'diária', __new: true })}>
            <Icon name="plus" size={18} color="white"/> Nova
          </button>
        }
      />

      <div className="col" style={{ gap: 10, zIndex: 2 }}>
        {data.missionBank.map((m, i) => {
          const cat = window.CATEGORIES.find(c => c.id === m.category);
          return (
            <div key={m.id} className="card pop-on-tap" style={{
              padding: 14,
              cursor: 'pointer',
              animation: `slideInCard 0.35s ease ${i * 0.03}s both`,
              border: '2px solid rgba(26,42,74,0.08)',
            }} onClick={() => setEditItem(m)}>
              <div className="row" style={{ gap: 14 }}>
                <IconTile icon={m.icon} color={cat.color} size={52}/>
                <div className="col fg1" style={{ gap: 4 }}>
                  <div className="h-display" style={{ fontSize: 17 }}>{m.title}</div>
                  <div className="row" style={{ gap: 6 }}>
                    {catChip(m.category, 'sm')}
                    <div className="chip chip-outline" style={{ fontSize: 11, padding: '4px 10px' }}>{m.frequency}</div>
                  </div>
                </div>
                <div className="row" style={{ gap: 4, alignItems: 'center' }}>
                  <Icon name="star" size={20} color="var(--star)"/>
                  <div className="h-display" style={{ fontSize: 20, color: 'var(--star-2)' }}>{m.stars}</div>
                </div>
                <Icon name="chevron" size={18} color="var(--text-soft)"/>
              </div>
            </div>
          );
        })}
      </div>

      <Modal show={!!editItem} onClose={() => setEditItem(null)}>
        {editItem && (
          <MissionForm
            initial={editItem.__new ? editItem : editItem}
            isNew={!!editItem.__new}
            iconOptions={iconOptions}
            onSave={save}
            onRemove={editItem.__new ? null : () => remove(editItem.id)}
            onCancel={() => setEditItem(null)}
          />
        )}
      </Modal>
    </div>
  );
}

function MissionForm({ initial, isNew, iconOptions, onSave, onRemove, onCancel }) {
  const [m, setM] = useState(initial);
  const map = window.COLOR_MAP;
  const cat = window.CATEGORIES.find(c => c.id === m.category) || window.CATEGORIES[0];
  return (
    <div>
      <div className="row mb-4" style={{ justifyContent: 'space-between' }}>
        <h3 className="h-display" style={{ fontSize: 22 }}>{isNew ? 'Nova missão' : 'Editar missão'}</h3>
        <button className="btn btn-ghost btn-icon" onClick={onCancel}><Icon name="close" size={20}/></button>
      </div>

      <div className="center mb-4">
        <IconTile icon={m.icon} color={cat.color} size={80}/>
      </div>

      <div className="form-field">
        <label className="form-label">Título</label>
        <input className="form-input" value={m.title} onChange={e => setM({ ...m, title: e.target.value })} placeholder="Ex: Arrumar a cama"/>
      </div>

      <div className="grid-2" style={{ gap: 12 }}>
        <div className="form-field">
          <label className="form-label">Estrelinhas</label>
          <input type="number" className="form-input" value={m.stars} onChange={e => setM({ ...m, stars: parseInt(e.target.value) || 0 })}/>
        </div>
        <div className="form-field">
          <label className="form-label">Frequência</label>
          <select className="form-select" value={m.frequency} onChange={e => setM({ ...m, frequency: e.target.value })}>
            <option value="diária">Diária</option>
            <option value="semanal">Semanal</option>
            <option value="única">Única</option>
          </select>
        </div>
      </div>

      <div className="form-field">
        <label className="form-label">Categoria</label>
        <div className="row wrap" style={{ gap: 8 }}>
          {window.CATEGORIES.map(c => (
            <button key={c.id} type="button"
              className={`chip chip-${c.color}`}
              onClick={() => setM({ ...m, category: c.id })}
              style={{
                cursor: 'pointer', border: 'none',
                fontSize: 13, padding: '8px 14px',
                outline: m.category === c.id ? `3px solid ${map[c.color].fg}` : 'none',
                outlineOffset: 2,
              }}>
              <Icon name={c.icon} size={14} color="currentColor"/> {c.id}
            </button>
          ))}
        </div>
      </div>

      <div className="form-field">
        <label className="form-label">Ícone</label>
        <div className="row wrap" style={{ gap: 6 }}>
          {iconOptions.map(ic => (
            <button key={ic} type="button" onClick={() => setM({ ...m, icon: ic })} style={{
              width: 40, height: 40, borderRadius: 'var(--r-md)',
              border: m.icon === ic ? `3px solid ${map[cat.color].fg}` : '2px solid rgba(26,42,74,0.1)',
              background: m.icon === ic ? map[cat.color].bg : 'white',
              color: map[cat.color].fg,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer',
            }}>
              <Icon name={ic} size={22} color="currentColor"/>
            </button>
          ))}
        </div>
      </div>

      <div className="row mt-4" style={{ gap: 10, justifyContent: 'space-between' }}>
        {onRemove && <button className="btn btn-danger btn-sm" onClick={onRemove}><Icon name="trash" size={16} color="white"/></button>}
        <div className="row" style={{ gap: 10, marginLeft: 'auto' }}>
          <button className="btn btn-secondary" onClick={onCancel}>Cancelar</button>
          <button className="btn btn-primary" onClick={() => onSave(m)}>
            <Icon name="check" size={18} color="white"/> Salvar
          </button>
        </div>
      </div>
    </div>
  );
}

window.ParentBank = ParentBank;
