// Shop / Lojinha — spend stars on rewards.
// Matches Direction A · Soft Candy aesthetic.

DirA.Shop = ({ density = 'comfortable' }) => {
  const t = TOKENS.A;
  const profile = PROFILES.find(p => p.id === 'lila');
  const c = t[profile.color];
  const [activeCat, setActiveCat] = React.useState('all');

  const SPACE = { xs: 8, sm: 12, md: 18, lg: 28, xl: 44, xxl: 64 };
  const maxW = 900;

  // tints per category — Berry Pop friendly pastels
  const catTint = {
    tela:        '#DBEAFE', // sky
    doce:        '#FCE7F3', // pink
    passeio:     '#D1FAE5', // mint
    brinquedo:   '#FEF3C7', // butter
    experiencia: '#EDE9FE', // lilac
  };

  const visible = REWARDS.filter(r => activeCat === 'all' || r.cat === activeCat);
  const featured = REWARDS.find(r => r.hot && r.cat === 'experiencia') || REWARDS[3];

  return (
    <div style={{
      background: t.bg, minHeight: '100%',
      fontFamily: t.fontBody, color: t.ink,
      padding: `${SPACE.lg}px ${SPACE.xl}px 140px`, position: 'relative', overflow: 'hidden',
    }}>
      {/* top bar */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        maxWidth: maxW, margin: `0 auto ${SPACE.lg}px`,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.md }}>
          <button style={{
            background: t.surface, border: 'none', borderRadius: 999,
            width: 44, height: 44, display: 'grid', placeItems: 'center',
            boxShadow: t.shadow, cursor: 'pointer', color: t.ink,
          }} aria-label="Voltar">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M15 18 L9 12 L15 6"/>
            </svg>
          </button>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.22em', color: t.inkMuted }}>LOJINHA DA</div>
            <div style={{
              fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
              fontWeight: 700, fontSize: 28, color: t.ink, letterSpacing: '-0.01em', lineHeight: 1.1,
            }}>{profile.name}</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.sm }}>
          {/* wallet pill */}
          <div style={{
            background: '#FFF4CC', color: t.starInk,
            borderRadius: 999, padding: '10px 16px',
            display: 'flex', alignItems: 'center', gap: 8,
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 18,
            boxShadow: t.shadow,
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden>
              <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                    fill={t.star} stroke={t.starInk} strokeWidth="1.2" strokeLinejoin="round"/>
            </svg>
            {profile.stars}
          </div>
          <SmileyAvatar size={44} face={profile.face} fill={c.fill} ring={c.ring} ink={c.ink}/>
        </div>
      </div>

      {/* featured banner */}
      <div style={{
        maxWidth: maxW, margin: `0 auto ${SPACE.lg}px`,
        background: t.surface, borderRadius: t.radiusLg,
        padding: SPACE.lg, boxShadow: t.shadow,
        display: 'grid', gridTemplateColumns: '1fr auto', gap: SPACE.lg, alignItems: 'center',
        position: 'relative', overflow: 'hidden',
      }}>
        <div>
          <span style={{
            display: 'inline-flex', alignItems: 'center', gap: 4,
            background: '#EDE9FE', color: '#6D28D9',
            padding: '4px 10px', borderRadius: 999,
            fontSize: 11, fontWeight: 800, letterSpacing: '.1em', marginBottom: SPACE.sm,
          }}>✨ EM DESTAQUE</span>
          <h3 style={{
            fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
            fontWeight: 700, fontSize: 26, margin: '0 0 6px', color: t.ink, letterSpacing: '-0.01em',
          }}>{featured.title}</h3>
          <p style={{ margin: `0 0 ${SPACE.md}px`, fontSize: 14, color: t.inkSoft, fontWeight: 500, lineHeight: 1.4 }}>
            Uma noite especial com pipoca, cobertor e seu filme favorito.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: SPACE.sm }}>
            <button style={{
              background: t.lilac, border: 'none', borderRadius: t.radiusSm,
              padding: '12px 20px', fontFamily: t.fontBody, fontWeight: 900,
              color: '#FFFFFF', fontSize: 14, cursor: 'pointer',
              display: 'flex', alignItems: 'center', gap: 8,
              boxShadow: '0 3px 0 rgba(76,29,149,0.25)',
            }}>
              Trocar por
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                <svg width="14" height="14" viewBox="0 0 24 24" aria-hidden>
                  <path d="M12 2l3 6.5 7 .9-5.1 4.6 1.4 7L12 17.5 5.7 21l1.4-7L2 9.4l7-.9z"
                        fill={t.star} stroke="#FFFFFF" strokeWidth="1.4" strokeLinejoin="round"/>
                </svg>
                {featured.price}
              </span>
            </button>
            {profile.stars >= featured.price ? (
              <span style={{ fontSize: 12, fontWeight: 700, color: '#047857' }}>✓ Você pode pegar essa!</span>
            ) : (
              <span style={{ fontSize: 12, fontWeight: 700, color: t.inkMuted }}>
                Faltam {featured.price - profile.stars} estrelinhas
              </span>
            )}
          </div>
        </div>
        <RewardArt kind={featured.art} size={140} tint={catTint[featured.cat]}/>
      </div>

      {/* category tabs */}
      <div style={{
        maxWidth: maxW, margin: `${SPACE.xl}px auto ${SPACE.md}px`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        gap: SPACE.sm, flexWrap: 'wrap',
      }}>
        <h2 style={{
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 26, margin: 0, color: t.ink, letterSpacing: '-0.015em',
        }}>O que você quer hoje?</h2>
        <span style={{ fontSize: 13, fontWeight: 700, color: t.inkSoft }}>
          {visible.length} prêmios
        </span>
      </div>
      <div style={{
        maxWidth: maxW, margin: `0 auto ${SPACE.lg}px`,
        display: 'flex', gap: 8, flexWrap: 'wrap',
      }}>
        {REWARD_CATS.map(cat => {
          const active = activeCat === cat.id;
          return (
            <button key={cat.id} onClick={() => setActiveCat(cat.id)} style={{
              background: active ? t.ink : t.surface,
              color: active ? t.bg : t.inkSoft,
              border: 'none', borderRadius: 999,
              padding: '10px 18px', cursor: 'pointer',
              fontFamily: t.fontBody, fontWeight: 800, fontSize: 13,
              boxShadow: active ? 'none' : t.shadow,
              transition: 'all .15s',
            }}>{cat.label}</button>
          );
        })}
      </div>

      {/* grid of rewards */}
      <div style={{
        maxWidth: maxW, margin: '0 auto',
        display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: SPACE.md,
      }}>
        {visible.map(r => {
          const canAfford = profile.stars >= r.price;
          const tint = catTint[r.cat];
          return (
            <button key={r.id} style={{
              background: t.surface, border: 'none',
              borderRadius: t.radius, padding: SPACE.md,
              boxShadow: t.shadow, cursor: 'pointer',
              fontFamily: t.fontBody, color: t.ink, textAlign: 'left',
              transition: 'transform .15s, box-shadow .15s',
              display: 'flex', flexDirection: 'column', gap: SPACE.sm,
              position: 'relative',
              opacity: canAfford ? 1 : 0.8,
            }}
            onMouseOver={e => { if (canAfford) { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = t.shadowRaised; } }}
            onMouseOut={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = t.shadow; }}>
              {r.hot && (
                <span style={{
                  position: 'absolute', top: 14, right: 14, zIndex: 2,
                  background: '#FCE7F3', color: '#BE185D',
                  padding: '3px 9px', borderRadius: 999,
                  fontSize: 10, fontWeight: 900, letterSpacing: '.08em',
                }}>POPULAR</span>
              )}
              <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0' }}>
                <RewardArt kind={r.art} size={120} tint={tint}/>
              </div>
              <div style={{
                fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                fontWeight: 700, fontSize: 17, color: t.ink, letterSpacing: '-0.01em',
                lineHeight: 1.2, marginTop: 2,
              }}>{r.title}</div>
              <div style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                marginTop: 'auto', paddingTop: 4,
              }}>
                <StarBadge value={r.price} size="sm" t={t}/>
                {canAfford ? (
                  <span style={{
                    background: t.lilac, color: '#FFFFFF',
                    padding: '6px 12px', borderRadius: 999,
                    fontSize: 12, fontWeight: 900, letterSpacing: '.04em',
                    boxShadow: '0 2px 0 rgba(76,29,149,0.25)',
                  }}>TROCAR</span>
                ) : (
                  <span style={{
                    fontSize: 11, fontWeight: 800, color: t.inkMuted,
                    display: 'inline-flex', alignItems: 'center', gap: 4,
                  }}>
                    <NavIcon kind="lock" size={11} color={t.inkMuted}/>
                    faltam {r.price - profile.stars}
                  </span>
                )}
              </div>
            </button>
          );
        })}
      </div>

      {/* redeemed section */}
      <div style={{
        maxWidth: maxW, margin: `${SPACE.xl}px auto ${SPACE.md}px`,
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
      }}>
        <h2 style={{
          fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
          fontWeight: 700, fontSize: 22, margin: 0, color: t.ink, letterSpacing: '-0.015em',
        }}>Meus prêmios</h2>
        <span style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>últimos 7 dias</span>
      </div>
      <div style={{
        maxWidth: maxW, margin: '0 auto',
        display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: SPACE.md,
      }}>
        {REDEEMED.map(d => (
          <div key={d.id} style={{
            background: t.surface, borderRadius: t.radius,
            padding: SPACE.md, boxShadow: t.shadow,
            display: 'flex', alignItems: 'center', gap: SPACE.md,
          }}>
            <RewardArt kind={d.art} size={64} tint={catTint[REWARDS.find(r=>r.art===d.art)?.cat] || '#EDE9FE'}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{
                fontFamily: t.fontDisplay, fontStyle: t.titleItalic ? 'italic' : 'normal',
                fontWeight: 700, fontSize: 16, color: t.ink, letterSpacing: '-0.01em',
                lineHeight: 1.2, marginBottom: 4,
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              }}>{d.title}</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: t.inkSoft }}>
                {d.date} · −{d.price} ✨
              </div>
            </div>
            {d.status === 'ready' ? (
              <span style={{
                background: '#FCE7F3', color: '#BE185D',
                padding: '5px 10px', borderRadius: 999,
                fontSize: 11, fontWeight: 800, whiteSpace: 'nowrap',
              }}>Disponível</span>
            ) : (
              <span style={{
                background: '#D1FAE5', color: '#047857',
                padding: '5px 10px', borderRadius: 999,
                fontSize: 11, fontWeight: 800, whiteSpace: 'nowrap',
              }}>Aproveitado</span>
            )}
          </div>
        ))}
      </div>

      {/* bottom nav */}
      <div style={{
        position: 'absolute', bottom: 32, left: '50%', transform: 'translateX(-50%)',
        background: t.surface, borderRadius: 999, padding: '10px 14px',
        display: 'flex', gap: 4, boxShadow: t.shadowRaised,
      }}>
        {[
          { k: 'target', label: 'Jornada' },
          { k: 'bag',    active: true, label: 'Lojinha' },
          { k: 'book',   label: 'Diário' },
          { k: 'exit',   label: 'Sair' },
        ].map((it, i) => (
          <button key={i} style={{
            background: it.active ? t.star : 'transparent',
            border: 'none', borderRadius: 999, padding: '10px 16px',
            display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
            color: it.active ? t.starInk : t.inkSoft,
            fontFamily: t.fontBody, fontWeight: 800, fontSize: 13,
          }}>
            <NavIcon kind={it.k} size={18}/>
            {it.active && <span>{it.label}</span>}
          </button>
        ))}
      </div>
    </div>
  );
};
