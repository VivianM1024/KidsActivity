// V5 — Saved screen.
// Candidate list with a per-row "Registered" toggle. Confirmed items move
// into the Calendar tab.

function V5Saved({ activities }) {
  // Mocked saved set with kid assignments.
  const savedItems = [
    { id: 'cpd-tball-1',     kidId: 'leo'  },
    { id: 'wd-egg-25',       kidId: 'maya' },
    { id: 'np-truck-12',     kidId: 'maya' },
    { id: 'cpl-storytime-1', kidId: 'nora' },
    { id: 'ah-art-1',        kidId: 'maya' },
    { id: 'msi-day-1',       kidId: 'leo'  },
    { id: 'wd-13403',        kidId: 'leo'  },
  ];
  const savedIds = savedItems.map((s) => s.id);
  const kidById = Object.fromEntries(savedItems.map((s) => [s.id, s.kidId]));
  const [confirmed, setConfirmed] = React.useState({
    'wd-egg-25': true,
    'cpd-tball-1': true,
    'cpl-storytime-1': true,
  });

  const saved = savedIds
    .map((id) => activities.find((a) => a.id === id))
    .filter(Boolean);

  const candidates = saved.filter((a) => !confirmed[a.id]);
  const registered = saved.filter((a) => confirmed[a.id]);

  const toggle = (id) => setConfirmed({ ...confirmed, [id]: !confirmed[id] });

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: '#26201A',
    }}>
      {/* Title */}
      <div style={{ paddingTop: 56, padding: '56px 20px 6px' }}>
        <div style={{ fontSize: 11, color: 'oklch(0.55 0.05 60)', fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 4 }}>
          3 kids · {saved.length} saved
        </div>
        <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.6, color: '#26201A', lineHeight: 1.05 }}>
          Saved
        </div>
        <div style={{ fontSize: 13, color: '#7A6D5C', marginTop: 4, lineHeight: 1.4 }}>
          Confirm the ones you actually registered for \u2014 they\u2019ll show up on your Calendar.
        </div>
      </div>

      {/* Summary strip */}
      <div style={{ display: 'flex', gap: 8, padding: '12px 16px 8px' }}>
        <SummaryPill kind="candidates" count={candidates.length} />
        <SummaryPill kind="registered" count={registered.length} />
      </div>

      {/* Section: Considering */}
      {candidates.length > 0 && (
        <SavedSection
          title="Considering"
          subtitle="Tap \u201cI registered\u201d once it\u2019s confirmed on the host site"
        >
          {candidates.map((a) => (
            <SavedRow key={a.id} a={a} kidId={kidById[a.id]} confirmed={false} onToggle={() => toggle(a.id)} />
          ))}
        </SavedSection>
      )}

      {/* Section: Registered */}
      {registered.length > 0 && (
        <SavedSection
          title="Registered"
          subtitle="On your calendar \u00b7 reminders 1 day before"
          accent="oklch(0.55 0.15 145)"
        >
          {registered.map((a) => (
            <SavedRow key={a.id} a={a} kidId={kidById[a.id]} confirmed onToggle={() => toggle(a.id)} />
          ))}
        </SavedSection>
      )}

      <V5TabBar tab="Saved" setTab={() => {}} />
    </div>
  );
}

function SummaryPill({ kind, count }) {
  const isReg = kind === 'registered';
  return (
    <div style={{
      flex: 1, padding: '10px 12px', borderRadius: 12,
      background: isReg ? 'oklch(0.95 0.07 145)' : '#fff',
      boxShadow: isReg ? 'none' : '0 0 0 0.5px rgba(60,40,20,0.06)',
      display: 'flex', alignItems: 'center', gap: 10,
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 14,
        background: isReg ? 'oklch(0.55 0.15 145)' : 'rgba(60,40,20,0.08)',
        color: isReg ? '#fff' : '#5B4F3F',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 13, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
      }}>{count}</div>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600 }}>
          {isReg ? 'Registered' : 'Considering'}
        </div>
        <div style={{ fontSize: 11, color: '#7A6D5C' }}>
          {isReg ? 'on calendar' : 'still deciding'}
        </div>
      </div>
    </div>
  );
}

function SavedSection({ title, subtitle, accent, children }) {
  return (
    <div style={{ marginTop: 14 }}>
      <div style={{ padding: '0 20px 8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {accent && <span style={{ width: 8, height: 8, borderRadius: 4, background: accent }} />}
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: '#A89B86' }}>
            {title}
          </div>
        </div>
        {subtitle && <div style={{ fontSize: 12, color: '#8B7E6E', marginTop: 2 }}>{subtitle}</div>}
      </div>
      <div style={{ padding: '0 14px' }}>{children}</div>
    </div>
  );
}

function SavedRow({ a, kidId, confirmed, onToggle }) {
  const m = window.CATEGORY_META[a.category] || { hue: 60 };
  const venueLetter = (window.VENUE_TYPES.find((v) => v.id === a.venueType) || { letter: 'P' }).letter;
  const kid = (window.KIDS || []).find((k) => k.id === kidId);
  return (
    <div style={{
      display: 'flex', gap: 10, padding: '10px',
      background: '#fff', borderRadius: 12, marginBottom: 6,
      boxShadow: '0 1px 2px rgba(60,40,20,0.03), 0 0 0 0.5px rgba(60,40,20,0.05)',
      alignItems: 'center',
      borderLeft: kid ? `3px solid oklch(0.6 0.14 ${kid.hue})` : '3px solid transparent',
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: 9, flexShrink: 0,
        background: `oklch(0.88 0.07 ${m.hue})`,
        color: `oklch(0.32 0.13 ${m.hue})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 14, fontWeight: 700, letterSpacing: 0.4,
        position: 'relative',
      }}>
        {(window.CATEGORY_META[a.category]?.short || a.category).slice(0, 3).toUpperCase()}
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
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {kid && (
            <span title={kid.name} style={{
              width: 16, height: 16, borderRadius: 8,
              background: `oklch(0.6 0.14 ${kid.hue})`, color: '#fff',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 9, fontWeight: 700, flexShrink: 0,
            }}>{kid.initial}</span>
          )}
          <div style={{
            fontSize: 14, fontWeight: 600, color: '#26201A',
            lineHeight: 1.2, letterSpacing: -0.2, flex: 1, minWidth: 0,
            display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical', overflow: 'hidden',
          }}>{a.name}</div>
        </div>
        <div style={{
          fontSize: 11, color: '#7A6D5C', marginTop: 3,
          display: 'flex', gap: 5, alignItems: 'center', flexWrap: 'nowrap',
        }}>
          <span style={{ fontWeight: 600, color: '#26201A' }}>
            {window.daysLabel(a.days)} {a.time}
          </span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span style={{ fontVariantNumeric: 'tabular-nums' }}>{window.startDateLabel(a.startDate)}</span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span style={{ display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical', overflow: 'hidden', minWidth: 0 }}>
            {a.venueShort}
          </span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span style={{ fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>
            {window.priceLabel(a.priceRes)}
          </span>
        </div>
      </div>

      {/* Toggle */}
      <div onClick={onToggle} style={{
        flexShrink: 0, padding: '6px 8px', borderRadius: 8,
        background: confirmed ? 'oklch(0.95 0.07 145)' : 'rgba(60,40,20,0.05)',
        color: confirmed ? 'oklch(0.4 0.15 145)' : '#7A6D5C',
        fontSize: 11, fontWeight: 700, letterSpacing: 0.3,
        display: 'flex', alignItems: 'center', gap: 4,
        cursor: 'pointer',
      }}>
        {confirmed ? (
          <React.Fragment>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
              <path d="M2 5.5L4.5 8L9 3" stroke="oklch(0.4 0.15 145)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            REGISTERED
          </React.Fragment>
        ) : (
          'I REGISTERED'
        )}
      </div>
    </div>
  );
}

window.V5Saved = V5Saved;
