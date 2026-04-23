// App — design canvas with Direction A (Soft Candy).

const { useState, useEffect } = React;

const HASH_FOCUS = {
  'a-picker':     'dirA/a-picker',
  'a-dash':       'dirA/a-dash',
  'a-shop':       'dirA/a-shop',
  'a-history':    'dirA/a-history',
  'pa-dashboard': 'dirA-parent/pa-dashboard',
  'pa-approvals': 'dirA-parent/pa-approvals',
  'pa-kids':      'dirA-parent/pa-kids',
  'pa-missions':  'dirA-parent/pa-missions',
  'pa-rewards':   'dirA-parent/pa-rewards',
  'pa-settings':  'dirA-parent/pa-settings',
};

function App() {
  const [tweaks, setTweaks] = useState(TWEAK_DEFAULTS);
  const [editMode, setEditMode] = useState(false);
  const initialFocus = HASH_FOCUS[window.location.hash.slice(1)] || null;

  useEffect(() => {
    const onMsg = (e) => {
      const d = e.data || {};
      if (d.type === '__activate_edit_mode') setEditMode(true);
      else if (d.type === '__deactivate_edit_mode') setEditMode(false);
    };
    window.addEventListener('message', onMsg);
    try { window.parent.postMessage({ type: '__edit_mode_available' }, '*'); } catch {}
    return () => window.removeEventListener('message', onMsg);
  }, []);

  const tA = applyTweaks(TOKENS.A, tweaks);
  window.TOKENS = { ...TOKENS, A: tA };

  const density = tweaks.density;

  return (
    <>
      <DesignCanvas initialZoom={0.72} initialFocus={initialFocus}>
        <DCSection id="dirA" title="LittleStars · Soft Candy" subtitle="Warm whites, soft shadows, flat tints, serif italic titles">
          <DCArtboard id="a-picker" label="Picker de perfil" width={1280} height={920}>
            <DirA.ProfilePicker density={density}/>
          </DCArtboard>
          <DCArtboard id="a-dash" label="Dashboard · jornada" width={1000} height={1400}>
            <DirA.Dashboard density={density}/>
          </DCArtboard>
          <DCArtboard id="a-shop" label="Lojinha · trocar estrelinhas" width={1000} height={1500}>
            <DirA.Shop density={density}/>
          </DCArtboard>
          <DCArtboard id="a-history" label="Diário · histórico" width={1000} height={1500}>
            <DirA.History density={density}/>
          </DCArtboard>
        </DCSection>

        <DCSection id="dirA-parent" title="Área dos pais · desktop" subtitle="Sidebar + sections: dashboard, filhos, missões, prêmios, aprovações, configurações">
          <DCArtboard id="pa-dashboard" label="Dashboard — aprovações + kids" width={1440} height={1100}>
            <DirA.ParentArea density={density} initialSection="dashboard"/>
          </DCArtboard>
          <DCArtboard id="pa-approvals" label="Aprovações · fila" width={1440} height={1100}>
            <DirA.ParentArea density={density} initialSection="approvals"/>
          </DCArtboard>
          <DCArtboard id="pa-kids" label="Filhos · grid" width={1440} height={1100}>
            <DirA.ParentArea density={density} initialSection="kids"/>
          </DCArtboard>
          <DCArtboard id="pa-missions" label="Missões · catálogo" width={1440} height={1100}>
            <DirA.ParentArea density={density} initialSection="missions"/>
          </DCArtboard>
          <DCArtboard id="pa-rewards" label="Prêmios · lojinha admin" width={1440} height={1100}>
            <DirA.ParentArea density={density} initialSection="rewards"/>
          </DCArtboard>
          <DCArtboard id="pa-settings" label="Configurações · família" width={1440} height={1100}>
            <DirA.ParentArea density={density} initialSection="settings"/>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>
      <TweaksPanel state={tweaks} setState={setTweaks} visible={editMode}/>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
