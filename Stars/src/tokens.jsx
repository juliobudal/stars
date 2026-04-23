// Design tokens for both directions.
// Direction A — "Soft Candy": warm, soft shadows, no borders, calm playful
// Direction B — "Chunky Clean": chunky Duolingo-style bottom shadow edge,
//                               flat fills, bolder display type
const TOKENS = {
  A: {
    name: 'Soft Candy',
    tagline: 'Warm, soft, book-like',
    bg: '#F8F5FF',
    surface: '#FFFFFF',
    surfaceAlt: '#F0EAFF',
    ink: '#2B2A3A',
    inkSoft: '#6A6878',
    inkMuted: '#A09EAE',
    hairline: '#E8E0F5',
    // accents — Berry Pop palette
    star: '#FFC53D',        // sunny yellow (kept)
    starInk: '#2B2A3A',     // charcoal — replaces the amber-brown
    coral: '#EC4899',       // berry pink
    sky: '#38BDF8',         // cyan-sky
    mint: '#34D399',
    lilac: '#A78BFA',       // primary lilac
    peach: '#F472B6',
    // person tints (soft)
    mom:  { fill: '#FCE7F3', ring: '#F9A8D4', ink: '#BE185D' },   // pink
    dad:  { fill: '#DBEAFE', ring: '#93C5FD', ink: '#1D4ED8' },   // blue
    lila: { fill: '#EDE9FE', ring: '#C4B5FD', ink: '#6D28D9' },   // lilac (matches her name)
    theo: { fill: '#CFFAFE', ring: '#67E8F9', ink: '#0E7490' },   // cyan
    zoe:  { fill: '#FCE7F3', ring: '#F472B6', ink: '#BE185D' },   // berry
    // shadow
    shadow: '0 2px 0 rgba(44,42,58,0.04), 0 10px 24px rgba(44,42,58,0.06)',
    shadowRaised: '0 4px 0 rgba(44,42,58,0.05), 0 18px 36px rgba(44,42,58,0.08)',
    radius: 22,
    radiusSm: 14,
    radiusLg: 28,
    fontDisplay: '"Fraunces", "Nunito", serif',
    fontBody: '"Nunito", system-ui, sans-serif',
    fontWeightDisplay: 700,
    titleItalic: true,
  },
  B: {
    name: 'Chunky Clean',
    tagline: 'Game-like, pressable, bright',
    bg: '#F2F5FA',
    surface: '#FFFFFF',
    surfaceAlt: '#E9EEF6',
    ink: '#11233A',
    inkSoft: '#5A6A80',
    inkMuted: '#9AA7BA',
    hairline: '#DDE3EC',
    star: '#FFC21F',
    starInk: '#5C3A00',
    coral: '#FF6F61',
    sky: '#2DB4FF',
    mint: '#2CCB8F',
    lilac: '#8B7CFF',
    peach: '#FF9F4D',
    mom:  { fill: '#FFE1EA', ring: '#FF5E8A', ink: '#B8214B' },
    dad:  { fill: '#D9EDFF', ring: '#3AA8F5', ink: '#0E5F9E' },
    lila: { fill: '#FFE0CE', ring: '#FF924F', ink: '#9E3C0F' },
    theo: { fill: '#D5EAFB', ring: '#3FA9F5', ink: '#0E5F9E' },
    zoe:  { fill: '#FFD6E3', ring: '#FF4D87', ink: '#A11A50' },
    // Duolingo-style bottom-edge shadow for pressable feel
    shadow: '0 4px 0 rgba(17,35,58,0.12)',
    shadowRaised: '0 6px 0 rgba(17,35,58,0.14)',
    radius: 18,
    radiusSm: 12,
    radiusLg: 24,
    fontDisplay: '"Baloo 2", "Nunito", system-ui, sans-serif',
    fontBody: '"Nunito", system-ui, sans-serif',
    fontWeightDisplay: 800,
    titleItalic: false,
  },
};

// Sample data
const PROFILES = [
  { id: 'mom',  name: 'Mamãe', role: 'Responsável', color: 'mom',  face: 'adult' },
  { id: 'dad',  name: 'Papai', role: 'Responsável', color: 'dad',  face: 'adult' },
  { id: 'lila', name: 'Lila',  stars: 340, streak: 7, color: 'lila', face: 'wink' },
  { id: 'theo', name: 'Theo',  stars: 180, streak: 3, color: 'theo', face: 'smile' },
  { id: 'zoe',  name: 'Zoe',   stars: 520, streak: 12, color: 'zoe',  face: 'tongue' },
];

// statuses: 'approved' (confirmed by parent, stars credited) · 'awaiting' (done, waiting parent approval)
// · 'todo' (not done yet) · 'current' (highlighted as next suggestion)
const TASKS = [
  { id: 't1', title: 'Arrumar a cama',     cat: 'Casa',   recur: 'diária', stars: 20, icon: 'home',  status: 'approved' },
  { id: 't2', title: 'Escovar os dentes',  cat: 'Rotina', recur: 'diária', stars: 10, icon: 'sun',   status: 'awaiting' },
  { id: 't3', title: 'Dar comida ao pet',  cat: 'Rotina', recur: 'diária', stars: 15, icon: 'paw',   status: 'current' },
  { id: 't4', title: 'Lição de casa',      cat: 'Escola', recur: 'diária', stars: 25, icon: 'book',  status: 'todo' },
  { id: 't5', title: 'Guardar brinquedos', cat: 'Casa',   recur: 'diária', stars: 15, icon: 'toy',   status: 'todo' },
];

// ── Rewards catalog ────────────────────────────────────────────
// Priced in stars. Category: tela (screen time), doce (treats), passeio (outings),
// brinquedo (toys), experiencia (experiences). `art` key maps to an SVG in shared.jsx.
const REWARD_CATS = [
  { id: 'all',         label: 'Tudo' },
  { id: 'tela',        label: 'Telinha' },
  { id: 'doce',        label: 'Docinhos' },
  { id: 'passeio',     label: 'Passeios' },
  { id: 'brinquedo',   label: 'Brinquedos' },
  { id: 'experiencia', label: 'Experiências' },
];

const REWARDS = [
  { id: 'r1', title: '30min de TV',        cat: 'tela',        price: 50,  art: 'tv',      hot: true  },
  { id: 'r2', title: 'Sorvete especial',   cat: 'doce',        price: 80,  art: 'icecream' },
  { id: 'r3', title: 'Passeio no parque',  cat: 'passeio',     price: 120, art: 'park'     },
  { id: 'r4', title: 'Noite do cinema',    cat: 'experiencia', price: 200, art: 'cinema', hot: true  },
  { id: 'r5', title: 'Brinquedo novo',     cat: 'brinquedo',   price: 400, art: 'toy'      },
  { id: 'r6', title: 'Pijama party',       cat: 'experiencia', price: 300, art: 'sleepover' },
  { id: 'r7', title: 'Chocolate grande',   cat: 'doce',        price: 60,  art: 'choco'    },
  { id: 'r8', title: 'Aluga um joguinho',  cat: 'tela',        price: 150, art: 'game'     },
  { id: 'r9', title: 'Escolhe o jantar',   cat: 'experiencia', price: 90,  art: 'dinner'   },
];

// ── User's redeemed (pending parent delivery) ──
const REDEEMED = [
  { id: 'd1', title: 'Sorvete especial', date: 'Hoje', status: 'ready',   art: 'icecream', price: 80 },
  { id: 'd2', title: '30min de TV',      date: 'Ontem', status: 'enjoyed', art: 'tv',       price: 50 },
];

// ── Transaction history (Diário) ──
// kind:
//   'mission-approved' — +stars when parent approves
//   'mission-awaiting' — 0 stars, awaiting approval
//   'mission-rejected' — 0 stars
//   'purchase'         — −stars when kid redeems
//   'bonus'            — +stars manual bonus from parent
// grouped into day buckets (today | yesterday | older)
const HISTORY = [
  // HOJE
  { id: 'h1',  day: 'today',     time: '14:20', kind: 'purchase',         title: 'Sorvete especial', art: 'icecream', stars: -80,  note: 'Trocado na lojinha' },
  { id: 'h2',  day: 'today',     time: '11:05', kind: 'mission-approved', title: 'Arrumar a cama',   icon: 'home',    stars:  20,  note: 'Mamãe aprovou' },
  { id: 'h3',  day: 'today',     time: '09:30', kind: 'mission-awaiting', title: 'Escovar os dentes',icon: 'sun',     stars:  10,  note: 'Aguardando aprovação' },
  // ONTEM
  { id: 'h4',  day: 'yesterday', time: '19:45', kind: 'bonus',            title: 'Bônus do papai',   icon: 'gift',    stars:  30,  note: 'Por ajudar no jantar' },
  { id: 'h5',  day: 'yesterday', time: '16:10', kind: 'purchase',         title: '30min de TV',      art: 'tv',       stars: -50,  note: 'Trocado na lojinha' },
  { id: 'h6',  day: 'yesterday', time: '10:15', kind: 'mission-approved', title: 'Dar comida ao pet',icon: 'paw',     stars:  15,  note: 'Mamãe aprovou' },
  { id: 'h7',  day: 'yesterday', time: '08:00', kind: 'mission-approved', title: 'Lição de casa',    icon: 'book',    stars:  25,  note: 'Papai aprovou' },
  // ANTES
  { id: 'h8',  day: 'older',     time: 'Seg 15:22', kind: 'mission-approved', title: 'Guardar brinquedos', icon: 'toy', stars: 15,  note: 'Mamãe aprovou' },
  { id: 'h9',  day: 'older',     time: 'Seg 09:12', kind: 'mission-rejected', title: 'Lição de casa',      icon: 'book', stars: 0,  note: 'Feita incompleta' },
  { id: 'h10', day: 'older',     time: 'Dom 17:00', kind: 'purchase',         title: 'Chocolate grande',   art: 'choco', stars: -60, note: 'Trocado na lojinha' },
  { id: 'h11', day: 'older',     time: 'Dom 10:30', kind: 'mission-approved', title: 'Arrumar a cama',     icon: 'home', stars: 20,  note: 'Mamãe aprovou' },
  { id: 'h12', day: 'older',     time: 'Sáb 18:40', kind: 'bonus',            title: 'Bônus da vovó',      icon: 'gift', stars: 50,  note: 'Visita surpresa' },
];

// ── Parent-area data ─────────────────────────────────────────
// Mission catalog (distinct from per-kid instances). Parents create missions in
// a library; each has recurrence + star value + which kids it applies to.
// recur kinds: 'daily' | 'weekly' (with days array) | 'monthly' | 'once'
const MISSION_CATALOG = [
  { id: 'm1', title: 'Arrumar a cama',      cat: 'Casa',     icon: 'home',  stars: 20, recur: 'daily',  assigned: ['lila','theo','zoe'], active: true  },
  { id: 'm2', title: 'Escovar os dentes',   cat: 'Rotina',   icon: 'sun',   stars: 10, recur: 'daily',  assigned: ['lila','theo','zoe'], active: true  },
  { id: 'm3', title: 'Dar comida ao pet',   cat: 'Rotina',   icon: 'paw',   stars: 15, recur: 'daily',  assigned: ['lila','theo'],       active: true  },
  { id: 'm4', title: 'Lição de casa',       cat: 'Escola',   icon: 'book',  stars: 25, recur: 'daily',  assigned: ['lila','theo'],       active: true  },
  { id: 'm5', title: 'Guardar brinquedos',  cat: 'Casa',     icon: 'toy',   stars: 15, recur: 'daily',  assigned: ['theo','zoe'],        active: true  },
  { id: 'm6', title: 'Levar lixo pra fora', cat: 'Casa',     icon: 'home',  stars: 30, recur: 'weekly', days: ['mon','wed','fri'], assigned: ['lila'], active: true },
  { id: 'm7', title: 'Organizar a estante', cat: 'Casa',     icon: 'book',  stars: 40, recur: 'weekly', days: ['sat'],             assigned: ['lila','theo'], active: true },
  { id: 'm8', title: 'Limpar o quarto',     cat: 'Casa',     icon: 'home',  stars: 50, recur: 'monthly', day: 1,                   assigned: ['lila','theo','zoe'], active: true },
  { id: 'm9', title: 'Ajudar na mudança',   cat: 'Especial', icon: 'gift',  stars: 80, recur: 'once',   date: '2024-03-15',        assigned: ['lila','theo'],       active: false },
];

// Pending approvals (kid marked done, awaits parent)
const PENDING_MISSIONS = [
  { id: 'p1', missionId: 'm2', title: 'Escovar os dentes', kidId: 'lila', stars: 10, icon: 'sun',  time: 'há 15min', note: null },
  { id: 'p2', missionId: 'm4', title: 'Lição de casa',     kidId: 'theo', stars: 25, icon: 'book', time: 'há 1h',    note: 'Foto anexada' },
  { id: 'p3', missionId: 'm5', title: 'Guardar brinquedos',kidId: 'zoe',  stars: 15, icon: 'toy',  time: 'há 2h',    note: null },
  { id: 'p4', missionId: 'm1', title: 'Arrumar a cama',    kidId: 'theo', stars: 20, icon: 'home', time: 'há 3h',    note: null },
];

// Pending reward redemptions (kid spent stars, awaits parent to deliver)
const PENDING_REWARDS = [
  { id: 'pr1', rewardId: 'r2', title: 'Sorvete especial', kidId: 'lila', price: 80,  art: 'icecream', time: 'há 30min' },
  { id: 'pr2', rewardId: 'r1', title: '30min de TV',      kidId: 'theo', price: 50,  art: 'tv',       time: 'há 2h' },
  { id: 'pr3', rewardId: 'r3', title: 'Passeio no parque',kidId: 'zoe',  price: 120, art: 'park',     time: 'ontem' },
];

const FAMILY = {
  name: 'Família Budal',
  timezone: 'America/Sao_Paulo',
  language: 'pt-BR',
  weekStart: 'mon',
  parents: [
    { id: 'mom', name: 'Renata',   role: 'Administradora', avatar: 'mom', email: 'renata@familia.com' },
    { id: 'dad', name: 'Julio',    role: 'Administrador',  avatar: 'dad', email: 'julio@familia.com'  },
  ],
  rules: {
    starDecay: false,           // expire stars
    negativeBalance: false,     // allow stars to go negative
    autoApproveUnder: 0,        // star threshold for auto-approve
    requirePhotoProof: false,
  },
};

Object.assign(window, { TOKENS, PROFILES, TASKS, REWARDS, REWARD_CATS, REDEEMED, HISTORY, MISSION_CATALOG, PENDING_MISSIONS, PENDING_REWARDS, FAMILY });
