// screens/kid-shop.jsx — US09 lojinha + resgate

function KidShop({ data, kid, setData, go, triggerCelebration }) {
  const [buyItem, setBuyItem] = useState(null);
  const [purchased, setPurchased] = useState(false);
  const [bounce, setBounce] = useState(null);
  const toast = useToast();

  const handleBuy = () => {
    if (kid.balance < buyItem.cost) {
      toast.show('Faltam estrelinhas!', 'error');
      return;
    }
    setPurchased(true);
    triggerCelebration({ x: 50, y: 45 });
    setData(d => ({
      ...d,
      kids: d.kids.map(k => k.id === kid.id ? { ...k, balance: k.balance - buyItem.cost } : k),
      history: [{
        id: 'h' + Date.now(),
        kidId: kid.id,
        type: 'spend',
        amount: buyItem.cost,
        label: buyItem.title,
        icon: buyItem.icon,
        ts: 'Agora',
      }, ...d.history],
    }));
    setTimeout(() => {
      setPurchased(false);
      setBuyItem(null);
    }, 2200);
  };

  const map = window.COLOR_MAP;

  return (
    <div className="screen screen-enter-right with-nav">
      <BgShapes variant="warm"/>
      {toast.el}

      <TopBar
        title="Lojinha"
        subtitle="Troque suas estrelinhas por recompensas"
        leftAction={{ onClick: () => go('kid') }}
        rightSlot={<BalanceChip value={kid.balance}/>}
      />

      <div className="grid-2" style={{ zIndex: 2, gap: 16 }}>
        {data.shop.map((item, i) => {
          const canAfford = kid.balance >= item.cost;
          const colorIdx = ['peach', 'rose', 'mint', 'sky', 'lilac', 'coral'][i % 6];
          const c = map[colorIdx];
          return (
            <button
              key={item.id}
              onClick={() => { setBounce(item.id); setTimeout(() => setBounce(null), 250); setBuyItem(item); }}
              className="card"
              disabled={!canAfford}
              style={{
                cursor: canAfford ? 'pointer' : 'not-allowed',
                border: `3px solid ${c.fg}`,
                boxShadow: `0 5px 0 ${c.fg}`,
                padding: 18,
                textAlign: 'center',
                opacity: canAfford ? 1 : 0.55,
                filter: canAfford ? 'none' : 'grayscale(0.4)',
                transform: bounce === item.id ? 'scale(0.96)' : 'scale(1)',
                transition: 'transform 0.12s',
                animation: `slideInCard 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) ${i * 0.04}s both`,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 12,
                background: 'white',
                fontFamily: 'var(--font-body)',
              }}
            >
              <div style={{
                width: 84, height: 84, borderRadius: '50%',
                background: c.fg,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={item.icon} size={48} color="white"/>
              </div>
              <div className="h-display" style={{ fontSize: 16, color: 'var(--text)' }}>{item.title}</div>
              <div className="chip chip-star" style={{ fontSize: 15, padding: '7px 14px' }}>
                <Icon name="star" size={16} color="var(--star-2)"/>
                {item.cost}
              </div>
              {!canAfford && (
                <div style={{ fontSize: 11, color: 'var(--text-muted)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                  Faltam {item.cost - kid.balance} ⭐
                </div>
              )}
            </button>
          );
        })}
      </div>

      <Modal show={!!buyItem} onClose={() => !purchased && setBuyItem(null)}>
        {buyItem && (
          <div className="center col" style={{ textAlign: 'center', gap: 14 }}>
            {!purchased ? (
              <>
                <Lumi size={76} mood="excited"/>
                <div style={{
                  width: 100, height: 100, borderRadius: '50%',
                  background: 'var(--primary)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  margin: '0 auto',
                }}>
                  <Icon name={buyItem.icon} size={56} color="white"/>
                </div>
                <h3 className="h-display" style={{ fontSize: 26 }}>{buyItem.title}</h3>
                <div className="row" style={{ gap: 10, justifyContent: 'center' }}>
                  <div className="chip chip-star" style={{ fontSize: 16, padding: '8px 14px' }}>
                    <Icon name="star" size={16} color="var(--star-2)"/> {buyItem.cost}
                  </div>
                </div>
                <div className="card" style={{ padding: 14, background: 'var(--bg-mid)', border: 'none', boxShadow: 'none', width: '100%' }}>
                  <div className="row" style={{ justifyContent: 'space-between', fontFamily: 'var(--font-display)', fontWeight: 800 }}>
                    <span>Saldo atual</span>
                    <span>{kid.balance} ⭐</span>
                  </div>
                  <div className="row" style={{ justifyContent: 'space-between', color: 'var(--danger)', fontFamily: 'var(--font-display)', fontWeight: 800, marginTop: 4 }}>
                    <span>−</span>
                    <span>{buyItem.cost} ⭐</span>
                  </div>
                  <div style={{ height: 2, background: 'rgba(26,42,74,0.1)', margin: '8px 0' }}/>
                  <div className="row" style={{ justifyContent: 'space-between', color: 'var(--primary)', fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18 }}>
                    <span>Depois</span>
                    <span>{kid.balance - buyItem.cost} ⭐</span>
                  </div>
                </div>
                <div className="row" style={{ gap: 12, marginTop: 6, width: '100%', justifyContent: 'center' }}>
                  <button className="btn btn-secondary" onClick={() => setBuyItem(null)}>Cancelar</button>
                  <button className="btn btn-primary btn-lg" onClick={handleBuy} disabled={kid.balance < buyItem.cost}>
                    <Icon name="gift" size={20} color="currentColor"/> Resgatar!
                  </button>
                </div>
              </>
            ) : (
              <div className="center col" style={{ gap: 16, padding: 20 }}>
                <Lumi size={100} mood="wow"/>
                <h3 className="h-display" style={{ fontSize: 28, color: 'var(--primary)' }}>Yay! 🎉</h3>
                <p className="subtitle" style={{ fontSize: 16 }}>Sua recompensa está a caminho!</p>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}

window.KidShop = KidShop;
