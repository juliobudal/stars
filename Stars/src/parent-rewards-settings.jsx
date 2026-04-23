// Parent Area — Prêmios (rewards catalog) section

const DirA = window.DirA || {};
window.DirA = DirA;

DirA.PARewards = ({ t }) => {
  const [cat, setCat] = React.useState('all');

  const catTint = {
    tela:        '#DBEAFE',
    doce:        '#FCE7F3',
    passeio:     '#D1FAE5',
    brinquedo:   '#FEF3C7',
    experiencia: '#EDE9FE',
  };
  const catLabel = Object.fromEntries(REWARD_CATS.map(c => [c.id, c.label]));

  const visible = REWARDS.filter(r => cat === 'all' || r.cat === cat);

  return (
    <div>
      <PASectionHeader t={t}
        title="Prêmios da lojinha"
        subtitle={`${REWARDS.length} prêmios · precificados em estrelas`}
        action={<PAButton t={t} icon="plus">Novo prêmio</PAButton>}
      />

      <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
        {REWARD_CATS.map(c => {
          const active = cat === c.id;
          return (
            <button key={c.id} onClick={() => setCat(c.id)} style={{
              background: active ? t.ink : t.surface, color: active ? t.bg : t.inkSoft,
              border: 'none', borderRadius: 999, padding: '8px 16px', cursor: 'pointer',
              fontFamily: t.fontBody, fontWeight: 800, fontSize: 12,
              boxShadow: active ? 'none' : t.shadow,
            }}>{c.label}</button>
          );
        })}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
        {visible.map(r => (
          <PACard key={r.id} t={t} style={{ display: 'flex', gap: 14, alignItems: 'center', padding: 16 }}>
            <RewardArt kind={r.art} size={72} tint={catTint[r.cat]}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{
                fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                fontWeight: 700, fontSize: 16, color: t.ink, letterSpacing: '-0.01em',
                marginBottom: 4,
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              }}>{r.title}</div>
              <div style={{ fontSize: 11, fontWeight: 700, color: t.inkSoft, marginBottom: 8 }}>{catLabel[r.cat]}</div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <PAStars t={t} value={r.price} size={14}/>
                <div style={{ display: 'flex', gap: 2 }}>
                  <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 4, color: t.inkSoft }}>
                    <LucideIcon name="pencil" size={14} color={t.inkSoft} strokeWidth={2}/>
                  </button>
                  <button style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: 4, color: t.inkSoft }}>
                    <LucideIcon name="trash-2" size={14} color={t.inkSoft} strokeWidth={2}/>
                  </button>
                </div>
              </div>
            </div>
          </PACard>
        ))}

        <button style={{
          background: 'transparent', border: `2px dashed ${t.hairline}`,
          borderRadius: t.radius, padding: 24,
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10,
          cursor: 'pointer', color: t.inkSoft, fontFamily: t.fontBody, fontWeight: 800, fontSize: 13,
          minHeight: 104,
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: 12,
            background: t.surfaceAlt, display: 'grid', placeItems: 'center',
          }}>
            <LucideIcon name="plus" size={18} color={t.lilac} strokeWidth={2.5}/>
          </div>
          Novo prêmio
        </button>
      </div>
    </div>
  );
};

DirA.PASettings = ({ t }) => {
  const [lang, setLang] = React.useState(FAMILY.language);
  const [tz, setTz] = React.useState(FAMILY.timezone);

  const Toggle = ({ on }) => (
    <div style={{
      width: 36, height: 20, borderRadius: 999,
      background: on ? t.lilac : t.hairline, position: 'relative',
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 18 : 2,
        width: 16, height: 16, borderRadius: '50%',
        background: '#FFFFFF', boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
      }}/>
    </div>
  );

  const Row = ({ label, children, hint }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 16,
      padding: '16px 0', borderBottom: `1px solid ${t.hairline}`,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, fontWeight: 800, color: t.ink }}>{label}</div>
        {hint && <div style={{ fontSize: 12, fontWeight: 600, color: t.inkSoft, marginTop: 2 }}>{hint}</div>}
      </div>
      {children}
    </div>
  );

  return (
    <div>
      <PASectionHeader t={t}
        title="Configurações"
        subtitle="Família, responsáveis e regras do sistema."
      />

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
        <PACard t={t}>
          <h3 style={{
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 18, margin: '0 0 8px', color: t.ink, letterSpacing: '-0.01em',
          }}>Família</h3>
          <Row label="Nome da família" hint="Aparece no app das crianças">
            <span style={{ fontSize: 13, fontWeight: 700, color: t.ink }}>{FAMILY.name}</span>
          </Row>
          <Row label="Idioma">
            <select value={lang} onChange={e => setLang(e.target.value)} style={{
              background: t.surfaceAlt, border: 'none', borderRadius: 10,
              padding: '8px 12px', fontFamily: t.fontBody, fontWeight: 700, fontSize: 13, color: t.ink, cursor: 'pointer',
            }}>
              <option value="pt-BR">Português (BR)</option>
              <option value="en-US">English (US)</option>
              <option value="es">Español</option>
            </select>
          </Row>
          <Row label="Fuso horário">
            <select value={tz} onChange={e => setTz(e.target.value)} style={{
              background: t.surfaceAlt, border: 'none', borderRadius: 10,
              padding: '8px 12px', fontFamily: t.fontBody, fontWeight: 700, fontSize: 13, color: t.ink, cursor: 'pointer',
            }}>
              <option value="America/Sao_Paulo">São Paulo (GMT−3)</option>
              <option value="America/New_York">New York (GMT−5)</option>
              <option value="Europe/Lisbon">Lisboa (GMT+0)</option>
            </select>
          </Row>
          <Row label="Início da semana">
            <div style={{ display: 'flex', gap: 4 }}>
              {['dom', 'seg'].map(d => (
                <button key={d} style={{
                  background: d === 'seg' ? t.ink : t.surfaceAlt, color: d === 'seg' ? t.bg : t.inkSoft,
                  border: 'none', borderRadius: 8, padding: '6px 14px', cursor: 'pointer',
                  fontFamily: t.fontBody, fontWeight: 800, fontSize: 12,
                }}>{d}</button>
              ))}
            </div>
          </Row>
        </PACard>

        <PACard t={t}>
          <h3 style={{
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 18, margin: '0 0 8px', color: t.ink, letterSpacing: '-0.01em',
          }}>Responsáveis</h3>
          {FAMILY.parents.map(p => {
            const c = p.avatar === 'mom' ? t.mom : t.dad;
            return (
              <div key={p.id} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '14px 0', borderBottom: `1px solid ${t.hairline}`,
              }}>
                <SmileyAvatar size={40} face="adult" fill={c.fill} ring={c.ring} ink={c.ink}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 800, color: t.ink }}>{p.name}</div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>{p.email} · {p.role}</div>
                </div>
                <button style={{ background: 'transparent', border: 'none', padding: 6, cursor: 'pointer', color: t.inkSoft }}>
                  <LucideIcon name="pencil" size={14} color={t.inkSoft} strokeWidth={2}/>
                </button>
              </div>
            );
          })}
          <div style={{ paddingTop: 14 }}>
            <PAButton t={t} variant="soft" icon="user-plus" small>Convidar responsável</PAButton>
          </div>
        </PACard>

        <PACard t={t} style={{ gridColumn: '1 / -1' }}>
          <h3 style={{
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 18, margin: '0 0 8px', color: t.ink, letterSpacing: '-0.01em',
          }}>Regras do sistema</h3>
          <Row label="Exigir foto na conclusão" hint="Criança precisa anexar uma foto para marcar missão como feita">
            <Toggle on={FAMILY.rules.requirePhotoProof}/>
          </Row>
          <Row label="Estrelas expiram" hint="Estrelas não usadas expiram após 30 dias">
            <Toggle on={FAMILY.rules.starDecay}/>
          </Row>
          <Row label="Permitir saldo negativo" hint="Crianças podem ficar 'devendo' estrelas por rejeições">
            <Toggle on={FAMILY.rules.negativeBalance}/>
          </Row>
          <Row label="Auto-aprovar missões até" hint="Missões de valor baixo são aprovadas automaticamente">
            <select style={{
              background: t.surfaceAlt, border: 'none', borderRadius: 10,
              padding: '8px 12px', fontFamily: t.fontBody, fontWeight: 700, fontSize: 13, color: t.ink, cursor: 'pointer',
            }}>
              <option>Desativado</option>
              <option>10 estrelas</option>
              <option>20 estrelas</option>
            </select>
          </Row>
        </PACard>
      </div>
    </div>
  );
};
