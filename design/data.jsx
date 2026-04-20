// data.jsx — dados mock do LittleStars (icons SVG em vez de emojis)

const INITIAL_DATA = {
  parents: [
    { id: 'p1', name: 'Mamãe', icon: 'faceParent', color: 'rose', role: 'parent' },
    { id: 'p2', name: 'Papai', icon: 'faceParent', color: 'sky', role: 'parent' },
  ],
  kids: [
    { id: 'k1', name: 'Lila', icon: 'faceFox', balance: 340, role: 'kid', color: 'peach' },
    { id: 'k2', name: 'Theo', icon: 'faceHero', balance: 180, role: 'kid', color: 'sky' },
    { id: 'k3', name: 'Zoe', icon: 'facePrincess', balance: 520, role: 'kid', color: 'rose' },
  ],
  missionBank: [
    { id: 'm1', title: 'Arrumar a cama', stars: 20, category: 'Casa', icon: 'bed', frequency: 'diária' },
    { id: 'm2', title: 'Escovar os dentes', stars: 10, category: 'Rotina', icon: 'brush', frequency: 'diária' },
    { id: 'm3', title: 'Fazer a lição de casa', stars: 50, category: 'Escola', icon: 'book', frequency: 'diária' },
    { id: 'm4', title: 'Lavar a louça', stars: 40, category: 'Casa', icon: 'dish', frequency: 'diária' },
    { id: 'm5', title: 'Ler um livro', stars: 30, category: 'Escola', icon: 'bookOpen', frequency: 'semanal' },
    { id: 'm6', title: 'Arrumar o quarto', stars: 60, category: 'Casa', icon: 'bear', frequency: 'semanal' },
    { id: 'm7', title: 'Dar comida ao pet', stars: 15, category: 'Rotina', icon: 'paw', frequency: 'diária' },
    { id: 'm8', title: 'Praticar instrumento', stars: 35, category: 'Escola', icon: 'music', frequency: 'diária' },
  ],
  todayMissions: [
    { id: 't1', kidId: 'k1', missionId: 'm1', status: 'pending' },
    { id: 't2', kidId: 'k1', missionId: 'm2', status: 'pending' },
    { id: 't3', kidId: 'k1', missionId: 'm3', status: 'waiting' },
    { id: 't4', kidId: 'k1', missionId: 'm7', status: 'pending' },
    { id: 't5', kidId: 'k2', missionId: 'm1', status: 'waiting' },
    { id: 't6', kidId: 'k2', missionId: 'm4', status: 'pending' },
    { id: 't7', kidId: 'k3', missionId: 'm5', status: 'pending' },
    { id: 't8', kidId: 'k3', missionId: 'm8', status: 'waiting' },
  ],
  shop: [
    { id: 's1', title: 'Sorvete de chocolate', cost: 80, icon: 'iceCream', category: 'Doce' },
    { id: 's2', title: '1h de Video Game', cost: 150, icon: 'gamepad', category: 'Tempo' },
    { id: 's3', title: 'Passeio ao parque', cost: 250, icon: 'ferris', category: 'Passeio' },
    { id: 's4', title: 'LEGO novo', cost: 600, icon: 'blocks', category: 'Brinquedo' },
    { id: 's5', title: 'Pizza de sexta', cost: 200, icon: 'pizza', category: 'Doce' },
    { id: 's6', title: 'Escolher filme', cost: 50, icon: 'film', category: 'Tempo' },
    { id: 's7', title: 'Dormir mais tarde', cost: 120, icon: 'moon', category: 'Tempo' },
    { id: 's8', title: 'Livro novo', cost: 180, icon: 'bookSolid', category: 'Brinquedo' },
  ],
  history: [
    { id: 'h1', kidId: 'k1', type: 'earn', amount: 50, label: 'Lição de casa', icon: 'book', ts: 'Hoje, 16:20' },
    { id: 'h2', kidId: 'k3', type: 'spend', amount: 80, label: 'Sorvete de chocolate', icon: 'iceCream', ts: 'Hoje, 15:45' },
    { id: 'h3', kidId: 'k2', type: 'earn', amount: 20, label: 'Arrumar a cama', icon: 'bed', ts: 'Hoje, 09:12' },
    { id: 'h4', kidId: 'k1', type: 'earn', amount: 10, label: 'Escovar os dentes', icon: 'brush', ts: 'Ontem, 21:00' },
    { id: 'h5', kidId: 'k3', type: 'earn', amount: 60, label: 'Arrumar o quarto', icon: 'bear', ts: 'Ontem, 18:30' },
    { id: 'h6', kidId: 'k2', type: 'spend', amount: 150, label: '1h de Video Game', icon: 'gamepad', ts: 'Ontem, 17:00' },
    { id: 'h7', kidId: 'k1', type: 'earn', amount: 40, label: 'Lavar a louça', icon: 'dish', ts: '2 dias atrás' },
    { id: 'h8', kidId: 'k3', type: 'earn', amount: 30, label: 'Ler um livro', icon: 'bookOpen', ts: '2 dias atrás' },
  ],
};

const CATEGORIES = [
  { id: 'Casa', color: 'mint', icon: 'home' },
  { id: 'Escola', color: 'sky', icon: 'graduationCap' },
  { id: 'Rotina', color: 'peach', icon: 'sun' },
  { id: 'Saúde', color: 'rose', icon: 'muscle' },
];

// Palette map for color tokens
const COLOR_MAP = {
  peach:  { bg: 'var(--c-peach-soft)',  fg: 'var(--c-peach)',  ink: '#8a3a1a' },
  rose:   { bg: 'var(--c-rose-soft)',   fg: 'var(--c-rose)',   ink: '#8a2e4a' },
  mint:   { bg: 'var(--c-mint-soft)',   fg: 'var(--c-mint)',   ink: '#1a6a4a' },
  sky:    { bg: 'var(--c-sky-soft)',    fg: 'var(--c-sky)',    ink: '#1a5a8a' },
  lilac:  { bg: 'var(--c-lilac-soft)',  fg: 'var(--c-lilac)',  ink: '#4a3a8a' },
  coral:  { bg: 'var(--c-coral-soft)',  fg: 'var(--c-coral)',  ink: '#8a2a2a' },
  star:   { bg: 'var(--star-soft)',     fg: 'var(--star-2)',   ink: '#7a5200' },
  primary:{ bg: 'var(--primary-soft)',  fg: 'var(--primary)',  ink: 'var(--primary-2)' },
};

window.INITIAL_DATA = INITIAL_DATA;
window.CATEGORIES = CATEGORIES;
window.COLOR_MAP = COLOR_MAP;
