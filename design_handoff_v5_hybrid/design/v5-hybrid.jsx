// V5 — Hybrid: V1 density × V2 warm aesthetic.
// Two new filter axes:
//   • Venue type (Parks · Library · Museum · Community) — segmented bar
//   • Event kind (All · One-time · Series) — pill toggle next to sort

function V5Hybrid({ activities }) {
  const KIDS = window.KIDS;
  const [tab, setTab] = React.useState('Browse');
  const [selectedKidIds, setSelectedKidIds] = React.useState(['maya']);
  const [venueType, setVenueType] = React.useState('all');
  const [kind, setKind] = React.useState('all');
  const [filter, setFilter] = React.useState('All');
  const [sort, setSort] = React.useState('When');
  const cats = ['All', 'Sports', 'Arts', 'STEM', 'Events', 'Storytime'];

  const selectedKids = KIDS.filter((k) => selectedKidIds.includes(k.id));
  const ageWindow = selectedKids.length ? {
    min: Math.min(...selectedKids.map((k) => k.ageMonths - 6)),
    max: Math.max(...selectedKids.map((k) => k.ageMonths + 12)),
  } : null;

  const toggleKid = (id) => {
    setSelectedKidIds((cur) => {
      if (cur.includes(id)) {
        return cur.length === 1 ? cur : cur.filter((x) => x !== id);
      }
      return [...cur, id];
    });
  };

  const filtered = activities.filter((a) => {
    if (venueType !== 'all' && a.venueType !== venueType) return false;
    if (kind !== 'all' && a.kind !== kind) return false;
    if (filter !== 'All' && a.category !== filter) return false;
    if (ageWindow && (a.ageMax < ageWindow.min || a.ageMin > ageWindow.max)) return false;
    return true;
  });

  const matchKids = (a) => selectedKids.filter((k) =>
    k.ageMonths >= a.ageMin - 3 && k.ageMonths <= a.ageMax + 3
  );

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
    }}>
      {/* Title */}
      <div style={{ paddingTop: 56, padding: '56px 20px 6px' }}>
        <div style={{ fontSize: 11, color: 'oklch(0.55 0.05 60)', fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 4 }}>
          Chicagoland · {activities.length} listings
        </div>
        <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.6, color: '#26201A', lineHeight: 1.05 }}>
          What sounds good?
        </div>
      </div>

      {/* Search + kid picker */}
      <div style={{ padding: '12px 20px 8px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          background: '#fff', borderRadius: 12, padding: '9px 12px',
          boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 1px rgba(60,40,20,0.06)',
        }}>
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
            <circle cx="7" cy="7" r="5" stroke="#8B7E6E" strokeWidth="1.6"/>
            <path d="M11 11l4 4" stroke="#8B7E6E" strokeWidth="1.6" strokeLinecap="round"/>
          </svg>
          <span style={{ flex: 1, fontSize: 14, color: '#8B7E6E' }}>Soccer, art, swim…</span>
        </div>
        <div style={{ display: 'flex', gap: 6, marginTop: 8, alignItems: 'center' }}>
          <span style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color: '#A89B86', marginRight: 2 }}>For</span>
          {KIDS.map((k) => {
            const on = selectedKidIds.includes(k.id);
            return (
              <div key={k.id} onClick={() => toggleKid(k.id)} style={{
                display: 'inline-flex', alignItems: 'center', gap: 6,
                padding: '4px 10px 4px 4px', borderRadius: 100,
                background: on ? `oklch(0.95 0.06 ${k.hue})` : '#fff',
                border: on ? `1.5px solid oklch(0.6 0.14 ${k.hue})` : '1px solid rgba(60,40,20,0.12)',
                cursor: 'pointer', userSelect: 'none',
              }}>
                <span style={{
                  width: 20, height: 20, borderRadius: 10,
                  background: `oklch(0.6 0.14 ${k.hue})`, color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 10, fontWeight: 700,
                }}>{k.initial}</span>
                <span style={{ fontSize: 12, fontWeight: 600, color: on ? `oklch(0.32 0.13 ${k.hue})` : '#5B4F3F' }}>
                  {k.name} · {k.ageYears}y
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Venue type segmented bar */}
      <div style={{ padding: '6px 20px 8px' }}>
        <div style={{
          display: 'flex', gap: 2,
          background: 'rgba(60,40,20,0.06)', borderRadius: 10, padding: 2,
        }}>
          {window.VENUE_TYPES.map((v) => {
            const on = v.id === venueType;
            return (
              <div key={v.id} onClick={() => setVenueType(v.id)} style={{
                flex: 1, fontSize: 11.5, fontWeight: 600,
                padding: '6px 4px', borderRadius: 8, textAlign: 'center',
                background: on ? '#fff' : 'transparent',
                color: on ? '#26201A' : '#8B7E6E',
                boxShadow: on ? '0 1px 2px rgba(60,40,20,0.08)' : 'none',
                cursor: 'pointer', transition: 'all 0.12s',
              }}>{v.short}</div>
            );
          })}
        </div>
      </div>

      {/* Category chips */}
      <div style={{ display: 'flex', gap: 6, padding: '4px 20px 6px', overflowX: 'auto' }}>
        {cats.map((c) => {
          const on = c === filter;
          return (
            <div key={c} onClick={() => setFilter(c)} style={{
              flexShrink: 0, fontSize: 13, fontWeight: 600,
              padding: '5px 11px', borderRadius: 100, cursor: 'pointer',
              background: on ? '#26201A' : 'transparent',
              color: on ? '#fff' : '#5B4F3F',
              border: on ? '1px solid #26201A' : '1px solid rgba(60,40,20,0.15)',
            }}>{c}</div>
          );
        })}
      </div>

      {/* Kind toggle + sort + count */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '8px 20px 8px',
      }}>
        <div style={{
          display: 'inline-flex', background: '#fff', borderRadius: 8,
          boxShadow: '0 0 0 0.5px rgba(60,40,20,0.12)', padding: 2,
        }}>
          {[
            { id: 'all', label: 'All' },
            { id: 'event', label: 'One-time' },
            { id: 'course', label: 'Series' },
          ].map((k) => {
            const on = k.id === kind;
            return (
              <span key={k.id} onClick={() => setKind(k.id)} style={{
                fontSize: 11.5, fontWeight: 600, padding: '4px 10px', borderRadius: 6,
                background: on ? '#26201A' : 'transparent',
                color: on ? '#fff' : '#5B4F3F',
                cursor: 'pointer',
              }}>{k.label}</span>
            );
          })}
        </div>
        <span style={{ flex: 1, fontSize: 12, color: '#7A6D5C', fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>
          {filtered.length} match
        </span>
        <div style={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          {['When', 'Near', 'Price'].map((s) => {
            const on = s === sort;
            return (
              <span key={s} onClick={() => setSort(s)} style={{
                fontSize: 11.5, fontWeight: 600,
                padding: '4px 8px', borderRadius: 6,
                color: on ? '#26201A' : '#8B7E6E',
                background: on ? 'rgba(60,40,20,0.08)' : 'transparent',
                cursor: 'pointer',
              }}>{s}</span>
            );
          })}
        </div>
      </div>

      {/* Compact rows */}
      <div style={{ padding: '0 14px' }}>
        {filtered.length === 0 ? (
          <div style={{ padding: '40px 0', textAlign: 'center', color: '#8B7E6E', fontSize: 13 }}>
            Nothing matches that combination.
          </div>
        ) : filtered.slice(0, 9).map((a) => <V5Row key={a.id} a={a} kids={matchKids(a)} />)}
      </div>

      <V5TabBar tab={tab} setTab={setTab} />
    </div>
  );
}

function V5Row({ a, kids = [] }) {
  const m = window.CATEGORY_META[a.category];
  const venueLetter = (window.VENUE_TYPES.find((v) => v.id === a.venueType) || { letter: 'P' }).letter;
  return (
    <div style={{
      display: 'flex', gap: 10, padding: '10px',
      background: '#fff', borderRadius: 12, marginBottom: 6,
      boxShadow: '0 1px 2px rgba(60,40,20,0.03), 0 0 0 0.5px rgba(60,40,20,0.05)',
      alignItems: 'flex-start',
    }}>
      {/* Category swatch with venue-type corner mark */}
      <div style={{
        width: 40, height: 40, borderRadius: 9, flexShrink: 0,
        background: `oklch(0.88 0.07 ${m.hue})`,
        color: `oklch(0.32 0.13 ${m.hue})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 14, fontWeight: 700, letterSpacing: 0.4,
        position: 'relative',
      }}>
        {m.short.slice(0, 3).toUpperCase()}
        <div style={{
          position: 'absolute', top: -2, right: -2,
          width: 14, height: 14, borderRadius: 7,
          background: '#26201A', color: '#fff',
          fontSize: 8, fontWeight: 700,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: '1.5px solid #fff',
        }}>{venueLetter}</div>
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
          <div style={{
            flex: 1, fontSize: 14, fontWeight: 600, color: '#26201A',
            lineHeight: 1.2, letterSpacing: -0.2,
            display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical', overflow: 'hidden',
          }}>{a.name}</div>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#26201A', flexShrink: 0 }}>
            {window.priceLabel(a.priceRes)}
          </div>
        </div>

        <div style={{
          fontSize: 11, color: '#7A6D5C', marginTop: 2,
          display: 'flex', gap: 5, alignItems: 'center', flexWrap: 'nowrap',
        }}>
          <span style={{ fontWeight: 600, color: '#26201A' }}>
            {window.daysLabel(a.days)} {a.time}
          </span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span>{window.ageRangeLabel(a.ageMin, a.ageMax)}</span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span style={{
            display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical',
            overflow: 'hidden', minWidth: 0,
          }}>{a.venueShort}</span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span style={{ fontVariantNumeric: 'tabular-nums' }}>{a.distance.toFixed(1)} mi</span>
        </div>

        <div style={{ display: 'flex', gap: 4, alignItems: 'center', marginTop: 5, flexWrap: 'wrap' }}>
          {/* Per-kid match dots */}
          {kids.length > 0 && (
            <span style={{ display: 'inline-flex', gap: 2, marginRight: 2 }}>
              {kids.map((k) => (
                <span key={k.id} title={`Good fit for ${k.name}`} style={{
                  width: 14, height: 14, borderRadius: 7,
                  background: `oklch(0.6 0.14 ${k.hue})`, color: '#fff',
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 8, fontWeight: 700, border: '1.5px solid #fff',
                  boxShadow: '0 0 0 0.5px rgba(60,40,20,0.15)',
                }}>{k.initial}</span>
              ))}
            </span>
          )}
          {/* Kind badge */}
          <span style={{
            fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 4,
            background: a.kind === 'course' ? 'oklch(0.95 0.04 280)' : 'oklch(0.95 0.06 200)',
            color: a.kind === 'course' ? 'oklch(0.4 0.13 280)' : 'oklch(0.4 0.13 200)',
            letterSpacing: 0.3,
          }}>{a.kind === 'course' ? `SERIES · ${a.sessions}×` : 'ONE-TIME'}</span>
          {/* Status */}
          {a.isOpen ? (
            <span style={{
              fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 4,
              background: 'oklch(0.94 0.07 145)', color: 'oklch(0.4 0.15 145)', letterSpacing: 0.3,
            }}>{a.status === 'Drop-in' ? 'DROP-IN' : 'OPEN'}</span>
          ) : a.opensSoon ? (
            <span style={{
              fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 4,
              background: 'oklch(0.95 0.06 60)', color: 'oklch(0.45 0.13 60)', letterSpacing: 0.3,
            }}>{a.status.toUpperCase()}</span>
          ) : (
            <span style={{
              fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 4,
              background: 'rgba(60,40,20,0.08)', color: '#7A6D5C', letterSpacing: 0.3,
            }}>{a.status.toUpperCase()}</span>
          )}
          <span style={{
            fontSize: 10, color: '#A89B86', fontVariantNumeric: 'tabular-nums', marginLeft: 'auto',
          }}>{window.startDateLabel(a.startDate)}</span>
        </div>
      </div>
    </div>
  );
}

function V5TabBar({ tab, setTab }) {
  const tabs = [
    { id: 'Browse',   label: 'Browse',   icon: 'browse' },
    { id: 'Saved',    label: 'Saved',    icon: 'saved' },
    { id: 'Calendar', label: 'Calendar', icon: 'cal' },
    { id: 'Me',       label: 'Me',       icon: 'me' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      background: 'rgba(255,253,250,0.92)', backdropFilter: 'blur(20px)',
      borderTop: '0.5px solid rgba(60,40,20,0.12)',
      paddingTop: 8, paddingBottom: 28,
      display: 'flex', justifyContent: 'space-around',
    }}>
      {tabs.map((t) => {
        const on = t.id === tab;
        return (
          <div key={t.id} onClick={() => setTab(t.id)} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: on ? 'oklch(0.55 0.13 22)' : '#8B7E6E',
            fontSize: 10, fontWeight: 600, cursor: 'pointer',
          }}>
            <V5TabIcon kind={t.icon} active={on} />
            {t.label}
          </div>
        );
      })}
    </div>
  );
}

function V5TabIcon({ kind, active }) {
  const stroke = active ? 'oklch(0.55 0.13 22)' : '#8B7E6E';
  const sw = 1.6;
  if (kind === 'browse') return (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
      <circle cx="10" cy="10" r="6" stroke={stroke} strokeWidth={sw}/>
      <path d="M15 15l4 4" stroke={stroke} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
  if (kind === 'saved') return (
    <svg width="22" height="22" viewBox="0 0 22 22" fill={active ? stroke : 'none'}>
      <path d="M6 3h10v16l-5-3-5 3V3z" stroke={stroke} strokeWidth={sw} strokeLinejoin="round"/>
    </svg>
  );
  if (kind === 'cal') return (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
      <rect x="3" y="5" width="16" height="14" rx="2" stroke={stroke} strokeWidth={sw}/>
      <path d="M3 9h16M7 3v4M15 3v4" stroke={stroke} strokeWidth={sw} strokeLinecap="round"/>
      {active && <circle cx="15" cy="14" r="1.5" fill={stroke}/>}
    </svg>
  );
  return (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
      <circle cx="11" cy="8" r="4" stroke={stroke} strokeWidth={sw}/>
      <path d="M3 19c1.5-3.5 4.5-5 8-5s6.5 1.5 8 5" stroke={stroke} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
}

window.V5Hybrid = V5Hybrid;
