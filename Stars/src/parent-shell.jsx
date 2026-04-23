// Parent Area — Shell component that hosts the sidebar nav + active section.
// Sections: Dashboard, Filhos, Missões, Prêmios, Aprovações, Configurações.

const DirA = window.DirA || {};
window.DirA = DirA;

DirA.ParentArea = ({ density = 'comfortable', initialSection = 'dashboard' }) => {
  const t = TOKENS.A;
  const [section, setSection] = React.useState(initialSection);

  const approvalsCount = PENDING_MISSIONS.length + PENDING_REWARDS.length;

  const NAV = [
    { id: 'dashboard',  icon: 'layout-dashboard', label: 'Dashboard' },
    { id: 'kids',       icon: 'users',            label: 'Filhos' },
    { id: 'missions',   icon: 'target',           label: 'Missões' },
    { id: 'rewards',    icon: 'gift',             label: 'Prêmios' },
    { id: 'approvals',  icon: 'check-circle',     label: 'Aprovações', badge: approvalsCount },
    { id: 'settings',   icon: 'settings',         label: 'Configurações' },
  ];

  const SectionComp =
    section === 'dashboard' ? DirA.PADashboard :
    section === 'kids'      ? DirA.PAKids :
    section === 'missions'  ? DirA.PAMissions :
    section === 'rewards'   ? DirA.PARewards :
    section === 'approvals' ? DirA.PAApprovals :
    section === 'settings'  ? DirA.PASettings :
    DirA.PADashboard;

  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '260px 1fr',
      minHeight: '100%', background: t.bg,
      fontFamily: t.fontBody, color: t.ink,
    }}>
      {/* ── Sidebar ── */}
      <aside style={{
        background: t.surface, padding: '24px 16px',
        borderRight: `1px solid ${t.hairline}`,
        display: 'flex', flexDirection: 'column', gap: 24,
        position: 'sticky', top: 0, height: '100vh',
      }}>
        {/* Brand */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '0 8px' }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: t.lilac, display: 'grid', placeItems: 'center',
            boxShadow: '0 3px 0 rgba(76,29,149,0.2)',
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden>
              <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                    fill={t.star} stroke="#FFFFFF" strokeWidth="1.5" strokeLinejoin="round"/>
            </svg>
          </div>
          <div>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 18, color: t.ink, letterSpacing: '-0.01em', lineHeight: 1,
            }}>LittleStars</div>
            <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: '.16em', color: t.inkMuted }}>MODO PAIS</div>
          </div>
        </div>

        {/* Family picker */}
        <button style={{
          background: t.surfaceAlt, border: 'none', borderRadius: 14,
          padding: '12px', display: 'flex', alignItems: 'center', gap: 10,
          cursor: 'pointer', width: '100%', textAlign: 'left',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10, background: t.surface,
            display: 'grid', placeItems: 'center', color: t.lilac, fontWeight: 900, fontSize: 14,
            boxShadow: t.shadow,
          }}>FB</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 800, color: t.ink,
              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            }}>{FAMILY.name}</div>
            <div style={{ fontSize: 11, fontWeight: 700, color: t.inkSoft }}>
              {PROFILES.filter(p => !p.stars).length} pais · {PROFILES.filter(p => p.stars).length} filhos
            </div>
          </div>
          <LucideIcon name="chevrons-up-down" size={14} color={t.inkMuted} strokeWidth={2}/>
        </button>

        {/* Nav */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: 2, flex: 1 }}>
          {NAV.map(n => (
            <PASidebarItem key={n.id} {...n} active={section === n.id}
              onClick={() => setSection(n.id)} t={t}/>
          ))}
        </nav>

        {/* Current parent */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '10px 8px', borderTop: `1px solid ${t.hairline}`, paddingTop: 16,
        }}>
          <SmileyAvatar size={36} face="adult" fill={t.mom.fill} ring={t.mom.ring} ink={t.mom.ink}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 13, fontWeight: 800, color: t.ink }}>{FAMILY.parents[0].name}</div>
            <div style={{ fontSize: 11, fontWeight: 700, color: t.inkSoft }}>{FAMILY.parents[0].role}</div>
          </div>
          <button style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            color: t.inkMuted, padding: 6, borderRadius: 8,
          }} aria-label="Sair">
            <LucideIcon name="log-out" size={16} color={t.inkMuted} strokeWidth={2}/>
          </button>
        </div>
      </aside>

      {/* ── Content area ── */}
      <main style={{ padding: '32px 40px 60px', minWidth: 0 }}>
        <SectionComp t={t} density={density} onGo={setSection}/>
      </main>
    </div>
  );
};
