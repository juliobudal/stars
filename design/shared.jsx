// shared.jsx — componentes compartilhados (flat + rounded + SVG)

const { useState, useEffect, useRef, useMemo } = React;

// ===== Mascote Lumi (Phosphor smiley em dourado, animado) =====
function Lumi({ size = 80, mood = 'happy', style = {} }) {
  // moods: happy | excited | thinking | sad | wow
  const moodToIcon = {
    happy:    'smiley',
    excited:  'smiley-wink',
    thinking: 'smiley-meh',
    sad:      'smiley-sad',
    wow:      'smiley-sticker',
  };
  const iconName = moodToIcon[mood] || 'smiley';
  return (
    <div
      className={`lumi-wrap ${mood === 'excited' ? 'excited' : ''}`}
      style={{
        width: size,
        height: size,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        ...style,
      }}
    >
      {/* star halo behind */}
      <i
        className="ph-fill ph-star-four"
        style={{
          position: 'absolute',
          inset: 0,
          fontSize: size,
          color: '#ffc41a',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          filter: 'drop-shadow(0 4px 0 rgba(255,160,30,0.35))',
        }}
      />
      {/* face on top */}
      <i
        className={`ph-fill ph-${iconName}`}
        style={{
          position: 'relative',
          fontSize: size * 0.5,
          color: '#7a4f00',
          zIndex: 1,
        }}
      />
    </div>
  );
}

// ===== Organic background shapes =====
function BgShapes({ variant = 'blue' }) {
  const palettes = {
    blue:  ['#c7ddff', '#ffd6e6', '#c2f0dd'],
    warm:  ['#ffe0b3', '#ffcad4', '#e0ccff'],
    cool:  ['#c2e7ff', '#dccfff', '#c2f0dd'],
  };
  const colors = palettes[variant] || palettes.blue;
  return (
    <>
      <div className="bg-shape" style={{ top: '-8%', right: '-10%', width: '45%', height: '45%', background: colors[0] }} />
      <div className="bg-shape" style={{ bottom: '-12%', left: '-8%', width: '50%', height: '50%', background: colors[1] }} />
      <div className="bg-shape" style={{ top: '30%', left: '50%', width: '30%', height: '30%', background: colors[2], opacity: 0.35 }} />
    </>
  );
}

// ===== Star badge (reusable) =====
function StarBadge({ size = 20, filled = true }) {
  return (
    <span style={{ display: 'inline-flex', width: size, height: size }}>
      <Icon name={filled ? 'star' : 'starOutline'} size={size} color="var(--star)" />
    </span>
  );
}

// ===== Balance Chip =====
function BalanceChip({ value, size = 'md' }) {
  const [displayed, setDisplayed] = useState(value);
  useEffect(() => {
    if (value === displayed) return;
    const diff = value - displayed;
    const steps = 18;
    let i = 0;
    const interval = setInterval(() => {
      i++;
      setDisplayed(Math.round(displayed + (diff * i / steps)));
      if (i >= steps) { setDisplayed(value); clearInterval(interval); }
    }, 25);
    return () => clearInterval(interval);
  }, [value]);
  const big = size === 'lg';
  return (
    <div className="balance-chip" style={big ? { fontSize: 28, padding: '10px 20px 10px 12px' } : {}}>
      <div className="star-badge" style={big ? { width: 36, height: 36 } : {}}>
        <Icon name="star" size={big ? 22 : 16} color="#8a5a00" />
      </div>
      <span>{displayed}</span>
    </div>
  );
}

// ===== Icon Tile (substitui emojis) =====
function IconTile({ icon, color = 'primary', size = 56, accent }) {
  const map = window.COLOR_MAP;
  const c = map[color] || map.primary;
  return (
    <div className="icon-tile" style={{
      width: size, height: size,
      background: c.bg,
      color: c.fg,
    }}>
      <Icon name={icon} size={size * 0.56} color={c.fg} accent={accent} />
    </div>
  );
}

// ===== Kid avatar (face icon dentro de um círculo colorido) =====
function KidAvatar({ kid, size = 64 }) {
  const map = window.COLOR_MAP;
  const c = map[kid.color] || map.primary;
  return (
    <div style={{
      width: size, height: size,
      borderRadius: '50%',
      background: c.bg,
      border: `3px solid ${c.fg}`,
      overflow: 'hidden',
      flexShrink: 0,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}>
      <Icon name={kid.icon} size={size - 4} color={c.fg} />
    </div>
  );
}

// ===== Confetti / Celebração =====
function Celebration({ show, origin = { x: 50, y: 50 } }) {
  if (!show) return null;
  const colors = ['#ffc41a', '#ff8a5c', '#ff5a8a', '#3ed49e', '#38b6ff', '#9b7aff'];
  const shapes = ['50%', '20%', '4px'];
  const confetti = Array.from({ length: 70 }).map((_, i) => ({
    id: i,
    left: Math.random() * 100,
    color: colors[i % colors.length],
    shape: shapes[i % shapes.length],
    delay: Math.random() * 0.3,
    rotation: Math.random() * 360,
    size: 8 + Math.random() * 10,
  }));
  const stars = Array.from({ length: 18 }).map((_, i) => ({
    id: i,
    angle: (i / 18) * 360,
    distance: 100 + Math.random() * 140,
    delay: Math.random() * 0.25,
    size: 18 + Math.random() * 16,
  }));
  return (
    <div className="confetti-layer">
      <div className="glow-burst" style={{ left: `${origin.x}%`, top: `${origin.y}%` }} />
      {confetti.map(c => (
        <div key={c.id} className="confetti" style={{
          left: `${c.left}%`, top: '-20px',
          background: c.color,
          borderRadius: c.shape,
          width: c.size, height: c.size,
          animationDelay: `${c.delay}s`,
          transform: `rotate(${c.rotation}deg)`,
        }} />
      ))}
      {stars.map(s => (
        <div key={`s${s.id}`} style={{
          position: 'absolute',
          left: `${origin.x}%`, top: `${origin.y}%`,
          animation: `starBurst 1.1s cubic-bezier(0.34, 1.56, 0.64, 1) ${s.delay}s forwards`,
          '--angle': `${s.angle}deg`,
          '--dist': `${s.distance}px`,
          opacity: 0,
          color: '#ffc41a',
        }}>
          <Icon name="star" size={s.size} color="#ffc41a" />
        </div>
      ))}
      <style>{`
        @keyframes starBurst {
          0% {
            opacity: 1;
            transform: translate(-50%, -50%) rotate(0deg) translateX(0) scale(0.3);
          }
          100% {
            opacity: 0;
            transform: translate(-50%, -50%) rotate(var(--angle)) translateX(var(--dist)) scale(1.3);
          }
        }
      `}</style>
    </div>
  );
}

// ===== Modal =====
function Modal({ show, onClose, children, width }) {
  if (!show) return null;
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={width ? { maxWidth: width } : {}} onClick={e => e.stopPropagation()}>
        {children}
      </div>
    </div>
  );
}

// ===== Top Bar =====
function TopBar({ title, subtitle, leftAction, rightSlot }) {
  return (
    <div className="row mb-5" style={{ justifyContent: 'space-between', flexShrink: 0, alignItems: 'flex-start' }}>
      <div className="row" style={{ gap: 14, alignItems: 'center' }}>
        {leftAction && (
          <button className="btn btn-secondary btn-icon" onClick={leftAction.onClick}>
            <Icon name="back" size={22} />
          </button>
        )}
        <div>
          <h2 className="h-display display" style={{ fontSize: 30 }}>{title}</h2>
          {subtitle && <div className="subtitle" style={{ marginTop: 2 }}>{subtitle}</div>}
        </div>
      </div>
      <div>{rightSlot}</div>
    </div>
  );
}

// ===== Category Chip helper =====
function catChip(categoryId, size = 'md') {
  const cat = window.CATEGORIES.find(c => c.id === categoryId);
  if (!cat) return null;
  return (
    <div className={`chip chip-${cat.color}`} style={size === 'sm' ? { fontSize: 11, padding: '4px 10px' } : {}}>
      <Icon name={cat.icon} size={13} color="currentColor"/> {cat.id}
    </div>
  );
}

// ===== Empty State =====
function EmptyState({ icon = 'sparkle', title, subtitle, color = 'primary' }) {
  return (
    <div className="center col" style={{ padding: 40, textAlign: 'center', gap: 14 }}>
      <IconTile icon={icon} color={color} size={80}/>
      <h3 className="h-display" style={{ fontSize: 22, marginTop: 8 }}>{title}</h3>
      <p className="subtitle" style={{ maxWidth: 320 }}>{subtitle}</p>
    </div>
  );
}

// ===== Toast (micro feedback) =====
function useToast() {
  const [msg, setMsg] = useState(null);
  const show = (text, kind = 'success') => {
    setMsg({ text, kind, key: Date.now() });
    setTimeout(() => setMsg(null), 2200);
  };
  const el = msg ? (
    <div style={{
      position: 'absolute',
      top: 24, left: '50%',
      transform: 'translateX(-50%)',
      zIndex: 500,
      background: msg.kind === 'success' ? 'var(--success)' : msg.kind === 'error' ? 'var(--danger)' : 'var(--primary)',
      color: 'white',
      padding: '12px 20px',
      borderRadius: 'var(--r-full)',
      fontFamily: 'var(--font-display)',
      fontWeight: 800,
      fontSize: 15,
      boxShadow: '0 4px 0 rgba(26,42,74,0.15), 0 10px 24px rgba(26,42,74,0.2)',
      animation: 'popIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1) both',
      display: 'flex', alignItems: 'center', gap: 8,
    }}>
      <Icon name={msg.kind === 'success' ? 'check' : msg.kind === 'error' ? 'close' : 'sparkle'} size={18} color="white"/>
      {msg.text}
    </div>
  ) : null;
  return { show, el };
}

Object.assign(window, { Lumi, BgShapes, StarBadge, BalanceChip, IconTile, KidAvatar, Celebration, Modal, TopBar, catChip, EmptyState, useToast });
