// screens/parent-shop-history.jsx — US08 admin da lojinha + US10 extrato

function ParentShopAdmin({ data, setData, go }) {
  const [editItem, setEditItem] = useState(null);
  const toast = useToast();
  const iconOptions = ['iceCream', 'gamepad', 'ferris', 'blocks', 'pizza', 'film', 'moon', 'bookSolid', 'gift', 'heart'];
  const map = window.COLOR_MAP;

  const save = (s) => {
    if (!s.title) { toast.show('Dê um nome', 'error'); return; }
    if (s.__new) {
      setData(d => ({ ...d, shop: [...d.shop, { ...s, id: 's' + Date.now() }] }));
      toast.show('Recompensa criada!');
    } else {
      setData(d => ({ ...d, shop: d.shop.map(x => x.id === s.id ? s : x) }));
      toast.show('Atualizado');
    }
    setEditItem(null);
  };

  const remove = (id) => {
    setData(d => ({ ...d, shop: d.shop.filter(s => s.id !== id) }));
    toast.show('Removido');
    setEditItem(null);
  };

  return (
    <div className="screen screen-enter-right">
      <BgShapes variant="warm"/>
      {toast.el}
      <TopBar
        title="Lojinha"
        subtitle="Catálogo de recompensas da família"
        leftAction={{ onClick: () => go('parent') }}
        rightSlot={
          <button className="btn btn-primary" onClick={() => setEditItem({ title: '', cost: 50, icon: 'gift', category: 'Doce', __new: true })}>
            <Icon name="plus" size={18} color="white"/> Nova
          </button>
        }
      />

      <div className="grid-2" style={{ gap: 12, zIndex: 2 }}>
        {data.shop.map((s, i) => {
          const colorIdx = ['peach', 'rose', 'mint', 'sky', 'lilac', 'coral'][i % 6];
          const c = map[colorIdx];
          return (
            <div key={s.id} className="card pop-on-tap" style={{
              padding: 16,
              cursor: 'pointer',
              border: `2px solid ${c.fg}`,
              boxShadow: `0 4px 0 ${c.fg}`,
              textAlign: 'center',
              animation: `slideInCard 0.35s ease ${i * 0.03}s both`,
            }} onClick={() => setEditItem(s)}>
              <div style={{
                width: 64, height: 64, borderRadius: '50%',
                background: c.fg,
                margin: '0 auto 10px',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={s.icon} size={36} color="white"/>
              </div>
              <div className="h-display" style={{ fontSize: 15 }}>{s.title}</div>
              <div className="chip chip-star" style={{ fontSize: 13, padding: '5px 12px', marginTop: 8 }}>
                <Icon name="star" size={13} color="var(--star-2)"/> {s.cost}
              </div>
            </div>
          );
        })}
      </div>

      <Modal show={!!editItem} onClose={() => setEditItem(null)}>
        {editItem && <ShopForm initial={editItem} iconOptions={iconOptions} onSave={save} onRemove={editItem.__new ? null : () => remove(editItem.id)} onCancel={() => setEditItem(null)}/>}
      </Modal>
    </div>
  );
}

function ShopForm({ initial, iconOptions, onSave, onRemove, onCancel }) {
  const [s, setS] = useState(initial);
  return (
    <div>
      <div className="row mb-4" style={{ justifyContent: 'space-between' }}>
        <h3 className="h-display" style={{ fontSize: 22 }}>{s.__new ? 'Nova recompensa' : 'Editar'}</h3>
        <button className="btn btn-ghost btn-icon" onClick={onCancel}><Icon name="close" size={20}/></button>
      </div>
      <div className="center mb-4">
        <div style={{
          width: 100, height: 100, borderRadius: '50%',
          background: 'var(--primary)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name={s.icon} size={58} color="white"/>
        </div>
      </div>
      <div className="form-field">
        <label className="form-label">Nome</label>
        <input className="form-input" value={s.title} onChange={e => setS({ ...s, title: e.target.value })}/>
      </div>
      <div className="grid-2" style={{ gap: 12 }}>
        <div className="form-field">
          <label className="form-label">Custo (⭐)</label>
          <input type="number" className="form-input" value={s.cost} onChange={e => setS({ ...s, cost: parseInt(e.target.value) || 0 })}/>
        </div>
        <div className="form-field">
          <label className="form-label">Categoria</label>
          <select className="form-select" value={s.category} onChange={e => setS({ ...s, category: e.target.value })}>
            <option>Doce</option><option>Tempo</option><option>Passeio</option><option>Brinquedo</option>
          </select>
        </div>
      </div>
      <div className="form-field">
        <label className="form-label">Ícone</label>
        <div className="row wrap" style={{ gap: 6 }}>
          {iconOptions.map(ic => (
            <button key={ic} type="button" onClick={() => setS({ ...s, icon: ic })} style={{
              width: 44, height: 44, borderRadius: 'var(--r-md)',
              border: s.icon === ic ? '3px solid var(--primary)' : '2px solid rgba(26,42,74,0.1)',
              background: s.icon === ic ? 'var(--primary-soft)' : 'white',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer',
            }}>
              <Icon name={ic} size={24} color="var(--primary)"/>
            </button>
          ))}
        </div>
      </div>
      <div className="row mt-4" style={{ gap: 10, justifyContent: 'space-between' }}>
        {onRemove && <button className="btn btn-danger btn-sm" onClick={onRemove}><Icon name="trash" size={16} color="white"/></button>}
        <div className="row" style={{ gap: 10, marginLeft: 'auto' }}>
          <button className="btn btn-secondary" onClick={onCancel}>Cancelar</button>
          <button className="btn btn-primary" onClick={() => onSave(s)}>
            <Icon name="check" size={18} color="white"/> Salvar
          </button>
        </div>
      </div>
    </div>
  );
}

// ===== Extrato (US10) =====
function HistoryView({ data, user, go, isParent }) {
  const [kidFilter, setKidFilter] = useState('all');
  const map = window.COLOR_MAP;

  const history = isParent
    ? (kidFilter === 'all' ? data.history : data.history.filter(h => h.kidId === kidFilter))
    : data.history.filter(h => h.kidId === user.id);

  const totalEarn = history.filter(h => h.type === 'earn').reduce((s, h) => s + h.amount, 0);
  const totalSpend = history.filter(h => h.type === 'spend').reduce((s, h) => s + h.amount, 0);

  return (
    <div className={`screen screen-enter-right ${isParent ? '' : 'with-nav'}`}>
      <BgShapes variant="cool"/>

      <TopBar
        title="Extrato"
        subtitle={isParent ? 'Histórico completo da família' : 'Suas estrelinhas ganhas e gastas'}
        leftAction={{ onClick: () => go(isParent ? 'parent' : 'kid') }}
      />

      {/* Summary */}
      <div className="grid-2 mb-4" style={{ gap: 12, zIndex: 2 }}>
        <div className="card" style={{ padding: 16, border: '2px solid var(--success)', background: 'var(--c-mint-soft)' }}>
          <div className="row" style={{ gap: 10 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 'var(--r-md)',
              background: 'var(--success)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name="arrowUp" size={22} color="white"/></div>
            <div className="col" style={{ gap: 0 }}>
              <div className="eyebrow" style={{ color: '#1a6a4a' }}>Ganhou</div>
              <div className="h-display" style={{ fontSize: 22, color: '#1a6a4a' }}>+{totalEarn} ⭐</div>
            </div>
          </div>
        </div>
        <div className="card" style={{ padding: 16, border: '2px solid var(--c-rose)', background: 'var(--c-rose-soft)' }}>
          <div className="row" style={{ gap: 10 }}>
            <div style={{
              width: 40, height: 40, borderRadius: 'var(--r-md)',
              background: 'var(--c-rose)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name="arrowDown" size={22} color="white"/></div>
            <div className="col" style={{ gap: 0 }}>
              <div className="eyebrow" style={{ color: '#8a2e4a' }}>Gastou</div>
              <div className="h-display" style={{ fontSize: 22, color: '#8a2e4a' }}>−{totalSpend} ⭐</div>
            </div>
          </div>
        </div>
      </div>

      {isParent && (
        <div className="row wrap mb-4" style={{ gap: 8, zIndex: 2 }}>
          <button className={`tweak-chip ${kidFilter === 'all' ? 'active' : ''}`} onClick={() => setKidFilter('all')}>Todas</button>
          {data.kids.map(k => (
            <button key={k.id} className={`tweak-chip ${kidFilter === k.id ? 'active' : ''}`} onClick={() => setKidFilter(k.id)}
              style={kidFilter === k.id ? { background: map[k.color].fg } : {}}>
              {k.name}
            </button>
          ))}
        </div>
      )}

      <div className="col" style={{ gap: 10, zIndex: 2 }}>
        {history.length === 0 && (
          <EmptyState icon="scroll" title="Nada no extrato ainda" subtitle="Complete missões ou faça resgates pra começar o histórico" color="lilac"/>
        )}
        {history.map((h, i) => {
          const k = data.kids.find(kk => kk.id === h.kidId);
          const earn = h.type === 'earn';
          const kc = k ? map[k.color] : map.primary;
          return (
            <div key={h.id} className="card" style={{
              padding: 14,
              border: '2px solid rgba(26,42,74,0.06)',
              animation: `slideInCard 0.3s ease ${i * 0.02}s both`,
            }}>
              <div className="row" style={{ gap: 14 }}>
                <div style={{
                  width: 48, height: 48, borderRadius: 'var(--r-md)',
                  background: earn ? 'var(--c-mint-soft)' : 'var(--c-rose-soft)',
                  color: earn ? 'var(--success)' : 'var(--c-rose)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name={h.icon} size={26} color="currentColor"/>
                </div>
                <div className="col fg1" style={{ gap: 2 }}>
                  <div className="h-display" style={{ fontSize: 16 }}>{h.label}</div>
                  <div className="row" style={{ gap: 6 }}>
                    {isParent && k && (
                      <div className="chip" style={{ background: kc.bg, color: kc.ink, fontSize: 11, padding: '3px 8px' }}>
                        {k.name}
                      </div>
                    )}
                    <span style={{ fontSize: 12, color: 'var(--text-muted)', fontWeight: 700 }}>{h.ts}</span>
                  </div>
                </div>
                <div className="h-display" style={{
                  fontSize: 18,
                  color: earn ? 'var(--success)' : 'var(--c-rose)',
                }}>
                  {earn ? '+' : '−'}{h.amount} ⭐
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

window.ParentShopAdmin = ParentShopAdmin;
window.HistoryView = HistoryView;
