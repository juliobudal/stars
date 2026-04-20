// app.jsx — Shell + Router

const { useState: useStateApp, useEffect: useEffectApp, useMemo: useMemoApp } = React;

function TweaksPanel({ palette, setPalette, cardStyle, setCardStyle }) {
  const [visible, setVisible] = useStateApp(false);

  useEffectApp(() => {
    const onMsg = (e) => {
      if (e.data?.type === '__activate_edit_mode') setVisible(true);
      if (e.data?.type === '__deactivate_edit_mode') setVisible(false);
    };
    window.addEventListener('message', onMsg);
    window.parent.postMessage({ type: '__edit_mode_available' }, '*');
    return () => window.removeEventListener('message', onMsg);
  }, []);

  const persist = (edits) => {
    window.parent.postMessage({ type: '__edit_mode_set_keys', edits }, '*');
  };

  if (!visible) return null;

  const palettes = [
    { id: 'sky',    label: 'Sky',    colors: ['#2e7df6', '#ffc41a', '#3ed49e'] },
    { id: 'aurora', label: 'Sunset', colors: ['#ff6a9d', '#ffb020', '#ff8a5c'] },
    { id: 'galaxy', label: 'Forest', colors: ['#2eca7f', '#ffc41a', '#38b6ff'] },
  ];

  return (
    <div className="tweaks-panel">
      <h4>Tema</h4>
      <div className="tweaks-row">
        {palettes.map(p => (
          <button key={p.id} onClick={() => { setPalette(p.id); persist({ palette: p.id }); }}
            className={`tweak-swatch ${palette === p.id ? 'active' : ''}`}
            title={p.label}
            style={{ background: `linear-gradient(135deg, ${p.colors[0]}, ${p.colors[1]}, ${p.colors[2]})` }}
          />
        ))}
      </div>

      <h4 style={{ marginTop: 18 }}>Card de missão</h4>
      <div className="tweaks-row">
        {['bubble', 'ticket'].map(s => (
          <button key={s} onClick={() => { setCardStyle(s); persist({ cardStyle: s }); window.__tweaks = { ...window.__tweaks, cardStyle: s }; window.dispatchEvent(new Event('tweak-change')); }}
            className={`tweak-chip ${cardStyle === s ? 'active' : ''}`}>
            {s === 'bubble' ? 'Bolha' : 'Ticket'}
          </button>
        ))}
      </div>
    </div>
  );
}

function App() {
  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "palette": "sky",
    "cardStyle": "bubble"
  }/*EDITMODE-END*/;

  const [palette, setPalette] = useStateApp(TWEAK_DEFAULTS.palette);
  const [cardStyle, setCardStyle] = useStateApp(TWEAK_DEFAULTS.cardStyle);
  const [data, setData] = useStateApp(window.INITIAL_DATA);

  const [route, setRoute] = useStateApp(() => {
    try { return JSON.parse(localStorage.getItem('ls-route') || '{"screen":"profile","user":null}'); }
    catch { return { screen: 'profile', user: null }; }
  });
  useEffectApp(() => {
    localStorage.setItem('ls-route', JSON.stringify(route));
  }, [route]);

  const [celebration, setCelebration] = useStateApp(null);
  const triggerCelebration = (origin = { x: 50, y: 50 }) => {
    setCelebration({ origin, key: Date.now() });
    setTimeout(() => setCelebration(null), 2400);
  };

  useEffectApp(() => {
    window.__tweaks = { palette, cardStyle };
    document.documentElement.setAttribute('data-palette', palette);
  }, [palette, cardStyle]);

  const go = (screen) => setRoute(r => ({ ...r, screen }));
  const pickProfile = (profile) => {
    setRoute({ screen: profile.role === 'parent' ? 'parent' : 'kid', user: profile });
  };

  const user = useMemoApp(() => {
    if (!route.user) return null;
    if (route.user.role === 'parent') return data.parents.find(p => p.id === route.user.id);
    return data.kids.find(k => k.id === route.user.id);
  }, [route.user, data]);

  let screen = null;
  const screenKey = route.screen;

  if (screenKey === 'profile' || !user) {
    screen = <ProfileSelect data={data} onPick={pickProfile} />;
  } else if (user.role === 'parent') {
    if (screenKey === 'parent') screen = <ParentDashboard data={data} parent={user} go={go} />;
    else if (screenKey === 'approvals') screen = <ParentApprovals data={data} setData={setData} go={go} />;
    else if (screenKey === 'bank') screen = <ParentBank data={data} setData={setData} go={go} />;
    else if (screenKey === 'kids') screen = <ParentKids data={data} setData={setData} go={go} />;
    else if (screenKey === 'shop-admin') screen = <ParentShopAdmin data={data} setData={setData} go={go} />;
    else if (screenKey === 'history') screen = <HistoryView data={data} user={user} go={go} isParent />;
    else screen = <ParentDashboard data={data} parent={user} go={go} />;
  } else {
    if (screenKey === 'kid') screen = <KidView data={data} kid={user} setData={setData} go={go} />;
    else if (screenKey === 'shop') screen = <KidShop data={data} kid={user} setData={setData} go={go} triggerCelebration={triggerCelebration} />;
    else if (screenKey === 'history') screen = <HistoryView data={data} user={user} go={go} isParent={false} />;
    else screen = <KidView data={data} kid={user} setData={setData} go={go} />;
  }

  const showKidNav = user?.role === 'kid' && ['kid', 'shop', 'history'].includes(screenKey);

  return (
    <div className="app-shell">
      <div className="viewport" key={screenKey}>
        {screen}
      </div>

      {showKidNav && (
        <div className="bottom-nav">
          <button className={`nav-item ${screenKey === 'kid' ? 'active' : ''}`} onClick={() => go('kid')} title="Missões">
            <Icon name="target" size={26} color="currentColor"/>
          </button>
          <button className={`nav-item ${screenKey === 'shop' ? 'active' : ''}`} onClick={() => go('shop')} title="Loja">
            <Icon name="bag" size={26} color="currentColor"/>
          </button>
          <button className={`nav-item ${screenKey === 'history' ? 'active' : ''}`} onClick={() => go('history')} title="Extrato">
            <Icon name="scroll" size={26} color="currentColor"/>
          </button>
          <button className="nav-item" onClick={() => { setRoute({ screen: 'profile', user: null }); }} title="Sair">
            <Icon name="logout" size={26} color="currentColor"/>
          </button>
        </div>
      )}

      {celebration && <Celebration show origin={celebration.origin} key={celebration.key} />}

      <TweaksPanel palette={palette} setPalette={setPalette} cardStyle={cardStyle} setCardStyle={setCardStyle}/>
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
