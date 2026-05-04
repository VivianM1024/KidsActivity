// Sample activities lifted from real KidsActivity scraper output.
// Categories are inferred client-side from the activity name (the scraper
// leaves `category` null for ActiveNet, so this is the same logic the iOS
// app would need anyway).

const ACTIVITIES = [
  {
    id: 'wd-13194',
    name: 'A Royal Affair Princess Tea Party',
    venue: 'Wood Dale Park District',
    venueShort: 'Wood Dale',
    location: 'Rec Cplx',
    distance: 4.2,
    ageMin: 36, ageMax: 120,
    days: ['Sat'], time: '11:30 AM',
    startDate: '2026-05-02', endDate: null, sessions: 1,
    priceRes: 18, priceNonRes: 20,
    isOpen: false, opensAt: null, status: 'Closed',
    category: 'Family',
    desc: 'A magical kingdom of tiaras, gowns, tea, cookies, games, and a special guest princess. Pre-registration required.',
  },
  {
    id: 'wd-13403',
    name: 'Flag Football Camp',
    venue: 'Wood Dale Park District',
    venueShort: 'Wood Dale',
    location: 'Community Park',
    distance: 4.2,
    ageMin: 72, ageMax: 155,
    days: ['Mon','Tue','Wed','Thu','Fri'], time: '9:00 AM',
    startDate: '2026-07-06', endDate: '2026-07-10', sessions: 5,
    priceRes: 165, priceNonRes: 195,
    isOpen: true, opensAt: '2026-04-06', status: 'Open',
    category: 'Sports',
    desc: 'A week of flag football fundamentals — offensive formations, league rules, strategy, and play.',
  },
  {
    id: 'wd-13134',
    name: 'Huntrix K-Pop Dance Party',
    venue: 'Wood Dale Park District',
    venueShort: 'Wood Dale',
    location: 'Rec Cplx',
    distance: 4.2,
    ageMin: 36, ageMax: 107,
    days: ['Fri'], time: '5:00 PM',
    startDate: '2026-05-15', endDate: null, sessions: 1,
    priceRes: 25, priceNonRes: 32,
    isOpen: false, opensAt: null, status: 'Full',
    category: 'Arts',
    desc: 'Hip-hop & jazz movement games, crafts, and choreography to K-Pop Demon Hunter tracks.',
  },
  {
    id: 'np-aa1',
    name: 'Little Explorers Nature Walk',
    venue: 'Naperville Park District',
    venueShort: 'Naperville',
    location: 'Knoch Knolls Nature Center',
    distance: 6.1,
    ageMin: 24, ageMax: 60,
    days: ['Wed'], time: '10:00 AM',
    startDate: '2026-05-13', endDate: '2026-06-17', sessions: 6,
    priceRes: 60, priceNonRes: 75,
    isOpen: true, opensAt: '2026-04-01', status: 'Open',
    category: 'Outdoor',
    desc: 'Toddlers and a grown-up explore the trails, ponds, and prairie with a naturalist guide.',
  },
  {
    id: 'cpd-art-101',
    name: 'Saturday Art Studio',
    venue: 'Chicago Park District',
    venueShort: 'Chicago Parks',
    location: 'Hamlin Park',
    distance: 1.8,
    ageMin: 48, ageMax: 96,
    days: ['Sat'], time: '10:30 AM',
    startDate: '2026-05-09', endDate: '2026-06-13', sessions: 6,
    priceRes: 84, priceNonRes: 105,
    isOpen: true, opensAt: '2026-04-15', status: 'Open',
    category: 'Arts',
    desc: 'Painting, sculpting, and printmaking with rotating mediums each week.',
  },
  {
    id: 'nb-stm-1',
    name: 'Junior Engineers: LEGO Robotics',
    venue: 'Northbrook Park District',
    venueShort: 'Northbrook',
    location: 'Leisure Center',
    distance: 8.4,
    ageMin: 84, ageMax: 144,
    days: ['Tue','Thu'], time: '4:30 PM',
    startDate: '2026-05-12', endDate: '2026-06-04', sessions: 8,
    priceRes: 180, priceNonRes: 215,
    isOpen: true, opensAt: '2026-03-20', status: 'Open',
    category: 'STEM',
    desc: 'Build and program LEGO® robots to complete weekly challenges. No experience needed.',
  },
  {
    id: 'ah-swim-3',
    name: 'Preschool Swim: Sea Otters',
    venue: 'Arlington Heights Park District',
    venueShort: 'Arlington Hts',
    location: 'Arlington Aquatic Center',
    distance: 11.0,
    ageMin: 36, ageMax: 60,
    days: ['Mon','Wed'], time: '5:30 PM',
    startDate: '2026-05-04', endDate: '2026-05-27', sessions: 8,
    priceRes: 96, priceNonRes: 120,
    isOpen: true, opensAt: '2026-04-01', status: 'Open',
    category: 'Aquatics',
    desc: 'Beginner water adjustment, floating, and basic strokes for ages 3–5.',
  },
  {
    id: 'sch-camp-1',
    name: 'Summer Discovery Camp Week 1',
    venue: 'Schaumburg Park District',
    venueShort: 'Schaumburg',
    location: 'Spring Valley Nature Center',
    distance: 13.2,
    ageMin: 60, ageMax: 132,
    days: ['Mon','Tue','Wed','Thu','Fri'], time: '9:00 AM',
    startDate: '2026-06-15', endDate: '2026-06-19', sessions: 5,
    priceRes: 215, priceNonRes: 260,
    isOpen: true, opensAt: '2026-02-01', status: 'Open',
    category: 'Camp',
    desc: 'Outdoor adventure, animal encounters, crafts, and themed Friday celebrations.',
  },
  {
    id: 'el-story-1',
    name: 'Toddler Storytime',
    venue: 'Elmhurst Park District',
    venueShort: 'Elmhurst',
    location: 'Wagner Community Center',
    distance: 9.5,
    ageMin: 18, ageMax: 36,
    days: ['Thu'], time: '10:00 AM',
    startDate: '2026-05-07', endDate: '2026-06-11', sessions: 6,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: '2026-04-10', status: 'Open',
    category: 'Storytime',
    desc: 'Books, songs, fingerplays, and a craft. Caregiver participation required.',
  },
  {
    id: 'wd-13124',
    name: 'Story Time Adventures',
    venue: 'Wood Dale Park District',
    venueShort: 'Wood Dale',
    location: 'Rec Cplx',
    distance: 4.2,
    ageMin: 36, ageMax: 60,
    days: ['Wed'], time: '9:30 AM',
    startDate: '2026-05-06', endDate: '2026-06-10', sessions: 6,
    priceRes: 60, priceNonRes: 70,
    isOpen: false, opensAt: '2025-11-17', status: 'Full',
    category: 'Storytime',
    desc: 'Each week a book is the theme — discussion, crafts, and role-playing. Toilet-trained.',
  },
  {
    id: 'stc-soc-1',
    name: 'Lil\u2019 Kickers Soccer',
    venue: 'St. Charles Park District',
    venueShort: 'St. Charles',
    location: 'Pottawatomie Park',
    distance: 18.4,
    ageMin: 36, ageMax: 60,
    days: ['Sat'], time: '9:00 AM',
    startDate: '2026-05-09', endDate: '2026-06-13', sessions: 6,
    priceRes: 75, priceNonRes: 90,
    isOpen: true, opensAt: '2026-04-01', status: 'Open',
    category: 'Sports',
    desc: 'First touches, passing games, and small-sided scrimmages for the youngest soccer players.',
  },
  {
    id: 'cpd-balletb',
    name: 'Beginning Ballet',
    venue: 'Chicago Park District',
    venueShort: 'Chicago Parks',
    location: 'Lincoln Park Cultural Center',
    distance: 2.6,
    ageMin: 60, ageMax: 96,
    days: ['Mon'], time: '4:00 PM',
    startDate: '2026-05-11', endDate: '2026-06-22', sessions: 7,
    priceRes: 105, priceNonRes: 125,
    isOpen: true, opensAt: '2026-04-15', status: 'Opens 5/7',
    opensSoon: true,
    category: 'Arts',
    desc: 'Foundational positions and barre work in a warm, encouraging classroom.',
  },
  {
    id: 'cpd-tball-1',
    name: 'T-Ball League',
    venue: 'Chicago Park District',
    venueShort: 'Chicago Parks',
    location: 'Welles Park',
    distance: 3.4,
    ageMin: 48, ageMax: 84,
    days: ['Sat'], time: '10:00 AM',
    startDate: '2026-06-06', endDate: '2026-08-01', sessions: 8,
    priceRes: 95, priceNonRes: 115,
    isOpen: false, opensAt: '2026-05-12', status: 'Opens 5/12',
    opensSoon: true,
    category: 'Sports',
    desc: 'Eight-week intro league with weekly games and skill stations.',
  },
  {
    id: 'np-stm-rocket',
    name: 'Rocket Builders',
    venue: 'Naperville Park District',
    venueShort: 'Naperville',
    location: '95th Street Center',
    distance: 6.4,
    ageMin: 96, ageMax: 144,
    days: ['Wed'], time: '6:00 PM',
    startDate: '2026-05-13', endDate: '2026-06-10', sessions: 5,
    priceRes: 88, priceNonRes: 108,
    isOpen: true, opensAt: '2026-04-08', status: 'Open',
    category: 'STEM',
    desc: 'Build, decorate, and launch model rockets. Final-day launch event.',
  },
  {
    id: 'el-yoga-1',
    name: 'Family Yoga',
    venue: 'Elmhurst Park District',
    venueShort: 'Elmhurst',
    venueType: 'park_district',
    location: 'Courts Plus',
    distance: 9.1,
    ageMin: 48, ageMax: 144,
    days: ['Sun'], time: '9:00 AM',
    startDate: '2026-05-03', endDate: '2026-06-07', sessions: 6,
    priceRes: 60, priceNonRes: 75,
    isOpen: true, opensAt: '2026-04-01', status: 'Open',
    category: 'Family',
    desc: 'Bring your kid (and your mat) for poses, breathing games, and quiet time.',
  },
  {
    id: 'ah-art-1',
    name: 'Mini Makers Studio',
    venue: 'Arlington Heights Park District',
    venueShort: 'Arlington Hts',
    venueType: 'park_district',
    location: 'Heritage Park Studio',
    distance: 11.2,
    ageMin: 30, ageMax: 60,
    days: ['Tue'], time: '10:30 AM',
    startDate: '2026-05-05', endDate: '2026-06-09', sessions: 6,
    priceRes: 72, priceNonRes: 90,
    isOpen: true, opensAt: '2026-04-01', status: 'Open',
    category: 'Arts',
    desc: 'Open-ended art exploration for tiny artists — clay, paint, collage.',
  },
  // ── Libraries ──────────────────────────────────────────────
  {
    id: 'cpl-storytime-1',
    name: 'Baby & Me Storytime',
    venue: 'Sulzer Regional Library',
    venueShort: 'Sulzer Library',
    venueType: 'library',
    location: 'Children\u2019s Room',
    distance: 0.8,
    ageMin: 0, ageMax: 24,
    days: ['Tue'], time: '10:30 AM',
    startDate: '2026-05-05', endDate: null, sessions: 1,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: null, status: 'Drop-in',
    category: 'Storytime',
    desc: 'Songs, fingerplays, and short books. Drop-in, no registration.',
  },
  {
    id: 'cpl-stem-1',
    name: 'Lego Engineering Club',
    venue: 'Lincoln Belmont Library',
    venueShort: 'Lincoln Belmont',
    venueType: 'library',
    location: 'Meeting Room A',
    distance: 1.1,
    ageMin: 60, ageMax: 132,
    days: ['Sat'], time: '2:00 PM',
    startDate: '2026-05-09', endDate: '2026-06-13', sessions: 6,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: '2026-04-15', status: 'Open',
    category: 'STEM',
    desc: 'Weekly themed builds and challenges led by our youth librarian.',
  },
  {
    id: 'evpl-music-1',
    name: 'Music with Miss Carole',
    venue: 'Evanston Public Library',
    venueShort: 'Evanston Library',
    venueType: 'library',
    location: 'Community Meeting Rm',
    distance: 5.4,
    ageMin: 12, ageMax: 60,
    days: ['Wed'], time: '10:00 AM',
    startDate: '2026-05-13', endDate: null, sessions: 1,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: null, status: 'Drop-in',
    category: 'Arts',
    desc: 'Sing-along, dance-along music for toddlers and a grown-up.',
  },
  // ── Museums ────────────────────────────────────────────────
  {
    id: 'cmoc-day-1',
    name: 'Tinkering Lab: Bridges',
    venue: 'Chicago Children\u2019s Museum',
    venueShort: 'Children\u2019s Museum',
    venueType: 'museum',
    location: 'Tinkering Lab',
    distance: 2.4,
    ageMin: 48, ageMax: 144,
    days: ['Sat'], time: '11:00 AM',
    startDate: '2026-05-09', endDate: null, sessions: 1,
    priceRes: 18, priceNonRes: 18,
    isOpen: true, opensAt: null, status: 'Open',
    category: 'STEM',
    desc: 'A drop-in design challenge: build a bridge that holds your weight.',
  },
  {
    id: 'msi-day-1',
    name: 'Live Science Show: Static',
    venue: 'Museum of Science & Industry',
    venueShort: 'Sci & Industry',
    venueType: 'museum',
    location: 'Live Science Stage',
    distance: 7.2,
    ageMin: 60, ageMax: 156,
    days: ['Sun'], time: '1:00 PM',
    startDate: '2026-05-10', endDate: null, sessions: 1,
    priceRes: 25, priceNonRes: 25,
    isOpen: true, opensAt: null, status: 'Open',
    category: 'STEM',
    desc: 'See lightning, balloons, and hair stand on end. 30-minute show.',
  },
  {
    id: 'fmnh-day-1',
    name: 'Dozin\u2019 with the Dinos Sleepover',
    venue: 'Field Museum',
    venueShort: 'Field Museum',
    venueType: 'museum',
    location: 'Stanley Field Hall',
    distance: 3.9,
    ageMin: 72, ageMax: 144,
    days: ['Fri'], time: '5:45 PM',
    startDate: '2026-06-12', endDate: null, sessions: 1,
    priceRes: 75, priceNonRes: 75,
    isOpen: false, opensAt: '2026-05-20', status: 'Opens 5/20',
    opensSoon: true,
    category: 'Family',
    desc: 'Overnight at the Field Museum. Flashlight tours, crafts, and breakfast.',
  },
  // ── One-time community events (Easter egg hunt, touch-a-truck, etc.) ──
  {
    id: 'wd-egg-25',
    name: 'Spring Egg Hunt',
    venue: 'Wood Dale Park District',
    venueShort: 'Wood Dale',
    venueType: 'park_district',
    location: 'Community Park',
    distance: 4.2,
    ageMin: 24, ageMax: 120,
    days: ['Sat'], time: '10:00 AM',
    startDate: '2026-04-04', endDate: null, sessions: 1,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: null, status: 'Free · drop-in',
    category: 'Events',
    desc: 'Thousands of candy-filled eggs, photo ops with the Easter Bunny, age-based hunt areas.',
  },
  {
    id: 'np-truck-12',
    name: 'Touch-a-Truck',
    venue: 'Naperville Park District',
    venueShort: 'Naperville',
    venueType: 'park_district',
    location: 'Knoch Park',
    distance: 6.1,
    ageMin: 24, ageMax: 144,
    days: ['Sat'], time: '10:00 AM',
    startDate: '2026-05-17', endDate: null, sessions: 1,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: null, status: 'Free',
    category: 'Events',
    desc: 'Climb on fire trucks, snowplows, excavators, and police cruisers. Quiet hour 10–11 am.',
  },
  {
    id: 'ccm-fest-2',
    name: 'Make-Believe Festival',
    venue: 'Chicago Children’s Museum',
    venueShort: 'Children’s Museum',
    venueType: 'museum',
    location: 'Whole museum',
    distance: 2.4,
    ageMin: 24, ageMax: 96,
    days: ['Sat','Sun'], time: '10:00 AM',
    startDate: '2026-06-13', endDate: '2026-06-14', sessions: 1,
    priceRes: 18, priceNonRes: 18,
    isOpen: true, opensAt: null, status: 'Open',
    category: 'Events',
    desc: 'Costume parade, dress-up stations, storytellers, and pop-up performances all weekend.',
  },
  {
    id: 'cpl-bookday',
    name: 'World Book Day Party',
    venue: 'Chicago Public Library',
    venueShort: 'Sulzer Library',
    venueType: 'library',
    location: 'Children’s Room',
    distance: 0.8,
    ageMin: 24, ageMax: 96,
    days: ['Sat'], time: '11:00 AM',
    startDate: '2026-04-25', endDate: null, sessions: 1,
    priceRes: 0, priceNonRes: 0,
    isOpen: true, opensAt: null, status: 'Free · drop-in',
    category: 'Events',
    desc: 'Costume parade, take-home book, author visit, crafts. No registration needed.',
  },
];

// Backfill venueType on the original entries (added pre-libraries).
for (const a of ACTIVITIES) {
  if (!a.venueType) a.venueType = 'park_district';
  // Event kind: 1 session = one-time event, otherwise a course/series.
  a.kind = (a.sessions && a.sessions > 1) ? 'course' : 'event';
  // Collapse legacy categories into the canonical 5: Sports, Arts, STEM,
  // Events, Storytime. Anything one-time that isn't clearly Sports/Arts/STEM/
  // Storytime is treated as a community Event.
  const c = a.category;
  if (c === 'Aquatics') a.category = 'Sports';
  else if (c === 'Outdoor') a.category = a.kind === 'event' ? 'Events' : 'STEM';
  else if (c === 'Camp')   a.category = 'Sports';
  else if (c === 'Family') a.category = 'Events';
}

const VENUE_TYPES = [
  { id: 'all',           label: 'All venues',    short: 'All',     letter: '·' },
  { id: 'park_district', label: 'Park District', short: 'Parks',   letter: 'P' },
  { id: 'library',       label: 'Library',       short: 'Library', letter: 'L' },
  { id: 'museum',        label: 'Museum',        short: 'Museum',  letter: 'M' },
];

// Category metadata: glyph (1-char fallback), short label, accent color.
// Colors used by variations 2/3/4. Variation 1 is intentionally monochrome.
const CATEGORY_META = {
  Sports:    { hue: 22,  letter: 'S', short: 'Sports'   },
  Arts:      { hue: 320, letter: 'A', short: 'Arts'     },
  STEM:      { hue: 200, letter: 'X', short: 'STEM'     },
  Events:    { hue: 145, letter: 'E', short: 'Events'   },
  Storytime: { hue: 60,  letter: 'T', short: 'Story'    },
};

function ageRangeLabel(minMonths, maxMonths) {
  const lo = Math.floor(minMonths / 12);
  const hi = Math.floor(maxMonths / 12);
  if (lo === hi) return `${lo}y`;
  return `${lo}\u2013${hi}y`;
}

function priceLabel(p) {
  if (!p && p !== 0) return '—';
  if (p === 0) return 'Free';
  return `$${p}`;
}

function daysLabel(days) {
  if (!days || !days.length) return '—';
  if (days.length === 5 && days[0] === 'Mon' && days[4] === 'Fri') return 'M–F';
  if (days.length === 1) return days[0];
  return days.join(' · ');
}

function startDateLabel(iso) {
  if (!iso) return '';
  const d = new Date(iso + 'T00:00:00');
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function categoryColor(cat, lightness = 0.55, chroma = 0.13) {
  const m = CATEGORY_META[cat] || CATEGORY_META.Family;
  return `oklch(${lightness} ${chroma} ${m.hue})`;
}

// ---------------------------------------------------------------------------
// Kids — household profiles. Each kid has an accent hue used on the calendar.
// ---------------------------------------------------------------------------
const KIDS = [
  { id: 'maya',  name: 'Maya',  ageYears: 4, ageMonths: 49, hue: 22,  initial: 'M' }, // warm coral
  { id: 'leo',   name: 'Leo',   ageYears: 7, ageMonths: 86, hue: 220, initial: 'L' }, // blue
  { id: 'nora',  name: 'Nora',  ageYears: 2, ageMonths: 28, hue: 145, initial: 'N' }, // green
];

function kidColor(kid, lightness = 0.55, chroma = 0.14) {
  if (!kid) return `oklch(${lightness} 0 0)`;
  return `oklch(${lightness} ${chroma} ${kid.hue})`;
}

function kidById(id) { return KIDS.find((k) => k.id === id) || null; }

// Map each activity to its host's real registration site. The scraper records
// the source URL per activity; until it's wired into the sample data we infer
// it from venue + id so the detail screen can deep-link.
const VENUE_REGISTRATION_HOSTS = {
  'Wood Dale Park District':   { host: 'wooddaleparks.org',         system: 'ActiveNet' },
  'Naperville Park District':  { host: 'napervilleparks.org',       system: 'ActiveNet' },
  'Chicago Park District':     { host: 'chicagoparkdistrict.com',   system: 'ActiveNet' },
  'Lincolnwood Park District': { host: 'lincolnwoodparks.org',      system: 'ActiveNet' },
  'Skokie Park District':      { host: 'skokieparks.org',           system: 'ActiveNet' },
  'Evanston Public Library':   { host: 'epl.org',                   system: 'LibCal'    },
  'Chicago Public Library':    { host: 'chipublib.org',             system: 'LibCal'    },
  'Chicago Children\u2019s Museum': { host: 'chicagochildrensmuseum.org', system: 'Web' },
  'Museum of Science and Industry': { host: 'msichicago.org',       system: 'Web'      },
  'Field Museum':              { host: 'fieldmuseum.org',           system: 'Web'      },
};

function activitySourceUrl(a) {
  if (a && a.sourceUrl) return a.sourceUrl;
  const h = VENUE_REGISTRATION_HOSTS[a && a.venue];
  if (!h) return null;
  // Mirror the path shape the scraper records.
  if (h.system === 'ActiveNet') {
    return `https://${h.host}/activitynet/activities/details.aspx?id=${a.id}`;
  }
  if (h.system === 'LibCal') {
    return `https://${h.host}/event/${a.id}`;
  }
  return `https://${h.host}/program/${a.id}`;
}

function sourceHostLabel(a) {
  const url = activitySourceUrl(a);
  if (!url) return null;
  try { return new URL(url).host.replace(/^www\./, ''); } catch (e) { return null; }
}

Object.assign(window, {
  ACTIVITIES, CATEGORY_META, VENUE_TYPES, KIDS,
  ageRangeLabel, priceLabel, daysLabel, startDateLabel, categoryColor,
  kidColor, kidById,
  activitySourceUrl, sourceHostLabel,
});
