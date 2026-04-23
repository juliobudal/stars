// Tweaks panel — toggles per-tweak and posts to host for persistence
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "direction": "A",
  "density": "comfortable",
  "bordersStyle": "soft",
  "accentHue": null,
  "fontMode": "default",
  "avatarStyle": "smiley"
}/*EDITMODE-END*/;

const TweaksPanel = ({ state, setState, visible }) => {
  if (!visible) return null;
  const post = (patch) => {
    setState(s => ({ ...s, ...patch }));
    try { window.parent.postMessage({ type: '__edit_mode_set_keys', edits: patch }, '*'); } catch {}
  };
  const row = { display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: '1px solid #eee' };
  const label = { fontSize: 12, fontWeight: 800, color: '#555', letterSpacing: '.06em', textTransform: 'uppercase' };
  const pill = (on) => ({
    padding: '6px 12px', borderRadius: 999, border: 'none', cursor: 'pointer',
    background: on ? '#111' : '#f2f2f2', color: on ? 'white' : '#666',
    fontFamily: 'Nunito, sans-serif', fontWeight: 800, fontSize: 12,
  });
  return (
    <div style={{
      position: 'fixed', right: 20, bottom: 20, zIndex: 99,
      background: 'white', borderRadius: 16, padding: 16,
      boxShadow: '0 20px 48px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.04)',
      width: 300, fontFamily: 'Nunito, sans-serif',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
        <div style={{ fontWeight: 900, fontSize: 15 }}>Tweaks</div>
        <div style={{ fontSize: 11, color: '#999', fontWeight: 700 }}>LittleStars</div>
      </div>
      <div style={row}>
        <div style={label}>Direção</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {['A','B'].map(d => <button key={d} style={pill(state.direction===d)} onClick={()=>post({direction:d})}>{d==='A'?'Soft':'Chunky'}</button>)}
        </div>
      </div>
      <div style={row}>
        <div style={label}>Densidade</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {['compact','comfortable'].map(d => <button key={d} style={pill(state.density===d)} onClick={()=>post({density:d})}>{d==='compact'?'Compacta':'Confort.'}</button>)}
        </div>
      </div>
      <div style={row}>
        <div style={label}>Bordas</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {['soft','bordered','flat'].map(d => <button key={d} style={pill(state.bordersStyle===d)} onClick={()=>post({bordersStyle:d})}>{d}</button>)}
        </div>
      </div>
      <div style={row}>
        <div style={label}>Fonte</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {['default','round','serif'].map(d => <button key={d} style={pill(state.fontMode===d)} onClick={()=>post({fontMode:d})}>{d}</button>)}
        </div>
      </div>
      <div style={row}>
        <div style={label}>Avatar</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {['smiley','mascot'].map(d => <button key={d} style={pill(state.avatarStyle===d)} onClick={()=>post({avatarStyle:d})}>{d}</button>)}
        </div>
      </div>
      <div style={{ ...row, borderBottom: 'none' }}>
        <div style={label}>Matiz acento</div>
        <input type="range" min="0" max="360" value={state.accentHue ?? 45}
               onChange={e => post({ accentHue: +e.target.value })}
               style={{ width: 140 }}/>
      </div>
    </div>
  );
};

// Apply tweaks to tokens: return a modified tokens object
function applyTweaks(tokens, tweaks) {
  const out = { ...tokens };
  // Borders
  if (tweaks.bordersStyle === 'flat') {
    out.shadow = 'none';
    out.shadowRaised = 'none';
  } else if (tweaks.bordersStyle === 'bordered') {
    out.shadow = `0 0 0 2px ${out.hairline}`;
    out.shadowRaised = `0 0 0 2px ${out.hairline}`;
  }
  // Font
  if (tweaks.fontMode === 'round') {
    out.fontDisplay = '"Baloo 2", system-ui, sans-serif';
    out.fontBody = '"Nunito", system-ui, sans-serif';
    out.titleItalic = false;
  } else if (tweaks.fontMode === 'serif') {
    out.fontDisplay = '"Fraunces", serif';
    out.titleItalic = true;
  }
  // Hue shift — only when user has actually touched the slider.
  // Keep palette-defined star/starInk otherwise (so Berry Pop's charcoal ink survives).
  if (typeof tweaks.accentHue === 'number') {
    const h = tweaks.accentHue;
    out.star = `hsl(${h} 95% 55%)`;
    out.starInk = `hsl(${h} 30% 20%)`; // lower sat so it reads as ink, not brown
  }
  return out;
}

Object.assign(window, { TWEAK_DEFAULTS, TweaksPanel, applyTweaks });
