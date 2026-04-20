// icons.jsx — Icon component backed by Phosphor Icons (web font)
// Usage: <Icon name="bed" size={24} color="red" weight="fill" />

// Map logical names (used across the app) to Phosphor glyph names
const PHOSPHOR_MAP = {
  // core / ui
  star: 'star',
  starOutline: 'star',     // rendered with weight="regular"
  check: 'check',
  close: 'x',
  back: 'arrow-left',
  plus: 'plus',
  edit: 'pencil-simple',
  trash: 'trash',
  logout: 'sign-out',
  chevron: 'caret-right',
  sparkle: 'sparkle',
  heart: 'heart',
  gift: 'gift',
  clock: 'clock',
  trending: 'trending-up',
  arrowUp: 'arrow-up',
  arrowDown: 'arrow-down',
  sword: 'sword',

  // nav
  target: 'target',
  bag: 'shopping-bag',
  scroll: 'scroll',
  home: 'house',
  users: 'users-three',

  // missions
  bed: 'bed',
  brush: 'tooth',
  book: 'book',
  dish: 'bowl-food',
  bookOpen: 'book-open',
  bear: 'rabbit',
  paw: 'paw-print',
  music: 'guitar',
  sun: 'sun',
  graduationCap: 'graduation-cap',
  muscle: 'barbell',

  // shop
  iceCream: 'ice-cream',
  gamepad: 'game-controller',
  ferris: 'park',
  blocks: 'blocks',           // fallback used below if missing
  pizza: 'pizza',
  film: 'film-strip',
  moon: 'moon',
  bookSolid: 'book-bookmark',

  // avatars (all face-family for consistency)
  faceKid: 'smiley',
  faceParent: 'user-circle',
  faceFox: 'smiley-wink',
  faceHero: 'smiley-sticker',
  facePrincess: 'smiley-melting',
};

// Phosphor weights: thin | light | regular | bold | fill | duotone
// Default we use "fill" for strong hard-colored feel; "duotone" for 2-tone where nice.
function Icon({ name, size = 24, color = 'currentColor', style = {}, weight = 'fill', className = '' }) {
  const glyph = PHOSPHOR_MAP[name] || name;
  const w = name === 'starOutline' ? 'regular' : weight;
  return (
    <i
      className={`ph-${w} ph-${glyph} ${className}`}
      style={{
        fontSize: size,
        lineHeight: 1,
        color,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: size,
        height: size,
        ...style,
      }}
    />
  );
}

window.Icon = Icon;
