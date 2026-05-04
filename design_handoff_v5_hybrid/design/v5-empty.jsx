// V5 — Empty states for Browse, Saved, Calendar, and an offline state.
// Each is a full-screen view that gets shown when its owning screen has no
// data to show. Same visual language: soft warm illustration, one sentence
// that names the situation, one action.

function V5EmptyBrowse({ kids }) {
  const list = (window.KIDS || []).slice(0, 2);
  return (
    <Empty
      illustration={<EmptyIllSearch hue={22}/>}
      eyebrow="Nothing to show"
      title={list.length > 0
        ? `No matches for ${list.map(k => k.name).join(' + ')}.`
        : 'No matches yet.'}
      body="Try widening the age range or distance, or clearing a couple filters — venues add new sessions weekly."
      primaryLabel="Adjust filters"
      secondaryLabel="Clear all filters"
      tab="Browse"
    >
      {/* Inline suggestion chips */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, justifyContent: 'center', marginTop: 14 }}>
        {[
          'Increase distance to 10 mi',
          'Include weekdays',
          'Remove price ceiling',
        ].map((s) => (
          <div key={s} style={{
            fontSize: 12, fontWeight: 600,
            padding: '6px 10px', borderRadius: 100,
            background: '#fff', color: '#5B4F3F',
            boxShadow: '0 0 0 0.5px rgba(60,40,20,0.1)',
          }}>{s}</div>
        ))}
      </div>
    </Empty>
  );
}

function V5EmptySaved() {
  return (
    <Empty
      illustration={<EmptyIllBookmark hue={290}/>}
      eyebrow="Saved is empty"
      title="Nothing saved yet."
      body="Tap the heart on anything that looks promising. You can confirm registration here once it's done."
      primaryLabel="Browse activities"
      tab="Saved"
    />
  );
}

function V5EmptyCalendar() {
  return (
    <Empty
      illustration={<EmptyIllCalendar hue={145}/>}
      eyebrow="Nothing scheduled"
      title="Your calendar is clear."
      body="Once you confirm a saved activity, its sessions show up here — with reminders the day before."
      primaryLabel="See saved"
      secondaryLabel="Browse activities"
      tab="Calendar"
    />
  );
}

function V5OfflineState() {
  return (
    <Empty
      illustration={<EmptyIllCloud/>}
      eyebrow="Can’t reach the internet"
      title="You’re offline."
      body="Showing the most recent activity list cached on March 28. Reconnect to refresh."
      primaryLabel="Try again"
      secondaryLabel="Use offline data"
      tab="Browse"
      stale
    />
  );
}

// ---------------------------------------------------------------------------

function Empty({ illustration, eyebrow, title, body, primaryLabel, secondaryLabel, children, tab, stale }) {
  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: '#26201A',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Empty top bar — gives the empty state a header so it doesn't feel like a modal */}
      <div style={{
        paddingTop: 56, padding: '56px 20px 8px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontSize: 22, fontWeight: 700, letterSpacing: -0.5, color: '#26201A',
        }}>{tab}</div>
        {stale && (
          <div style={{
            fontSize: 10.5, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
            color: 'oklch(0.45 0.13 60)',
            background: 'oklch(0.95 0.07 60)',
            padding: '3px 7px', borderRadius: 5,
          }}>Stale data</div>
        )}
      </div>

      <div style={{
        flex: 1,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        padding: '0 36px',
        textAlign: 'center',
      }}>
        <div style={{ marginBottom: 22 }}>{illustration}</div>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase',
          color: '#A89B86', marginBottom: 8,
        }}>{eyebrow}</div>
        <div style={{
          fontSize: 22, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.15,
          color: '#26201A', marginBottom: 8,
        }}>{title}</div>
        <div style={{
          fontSize: 14, color: '#7A6D5C', lineHeight: 1.5, maxWidth: 280,
          textWrap: 'pretty',
        }}>{body}</div>
        {children}

        <div style={{ marginTop: 24, display: 'flex', flexDirection: 'column', gap: 8, width: '100%', maxWidth: 280 }}>
          {primaryLabel && (
            <div style={{
              background: 'oklch(0.55 0.13 22)', color: '#fff',
              padding: '13px 16px', borderRadius: 12,
              fontSize: 14.5, fontWeight: 700, textAlign: 'center',
              boxShadow: '0 4px 12px oklch(0.55 0.13 22 / 0.22)',
            }}>{primaryLabel}</div>
          )}
          {secondaryLabel && (
            <div style={{
              color: '#5B4F3F',
              padding: '12px 16px', borderRadius: 12,
              fontSize: 13.5, fontWeight: 600, textAlign: 'center',
            }}>{secondaryLabel}</div>
          )}
        </div>
      </div>

      {tab && <V5TabBar tab={tab} setTab={() => {}}/>}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Soft, organic illustrations — layered shapes in the warm palette.

function EmptyIllSearch({ hue }) {
  return (
    <svg width="124" height="100" viewBox="0 0 124 100" fill="none">
      <ellipse cx="62" cy="86" rx="52" ry="6" fill="rgba(60,40,20,0.06)"/>
      <circle cx="55" cy="44" r="32" fill={`oklch(0.94 0.05 ${hue})`}/>
      <circle cx="55" cy="44" r="22" stroke={`oklch(0.55 0.14 ${hue})`} strokeWidth="3" fill="none"/>
      <line x1="76" y1="62" x2="92" y2="78" stroke={`oklch(0.55 0.14 ${hue})`} strokeWidth="5" strokeLinecap="round"/>
      {/* lone speck inside, suggesting nothing */}
      <circle cx="55" cy="44" r="2" fill={`oklch(0.55 0.14 ${hue})`}/>
    </svg>
  );
}

function EmptyIllBookmark({ hue }) {
  return (
    <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
      <ellipse cx="60" cy="86" rx="44" ry="5" fill="rgba(60,40,20,0.06)"/>
      <rect x="32" y="14" width="44" height="68" rx="4" fill="#fff" stroke="rgba(60,40,20,0.1)"/>
      <rect x="40" y="22" width="28" height="3" rx="1.5" fill="rgba(60,40,20,0.12)"/>
      <rect x="40" y="30" width="22" height="3" rx="1.5" fill="rgba(60,40,20,0.08)"/>
      <rect x="40" y="38" width="26" height="3" rx="1.5" fill="rgba(60,40,20,0.08)"/>
      {/* dashed bookmark suggesting empty slot */}
      <path d="M82 14v32l8-6 8 6V14a2 2 0 00-2-2H84a2 2 0 00-2 2z"
        stroke={`oklch(0.55 0.14 ${hue})`} strokeWidth="2" strokeDasharray="3 3" fill={`oklch(0.95 0.06 ${hue})`}/>
    </svg>
  );
}

function EmptyIllCalendar({ hue }) {
  return (
    <svg width="120" height="100" viewBox="0 0 120 100" fill="none">
      <ellipse cx="60" cy="88" rx="42" ry="5" fill="rgba(60,40,20,0.06)"/>
      <rect x="28" y="18" width="64" height="62" rx="6" fill="#fff" stroke="rgba(60,40,20,0.1)"/>
      <rect x="28" y="18" width="64" height="14" rx="6" fill={`oklch(0.92 0.07 ${hue})`}/>
      <rect x="38" y="12" width="3" height="12" rx="1.5" fill={`oklch(0.4 0.13 ${hue})`}/>
      <rect x="79" y="12" width="3" height="12" rx="1.5" fill={`oklch(0.4 0.13 ${hue})`}/>
      <line x1="28" y1="44" x2="92" y2="44" stroke="rgba(60,40,20,0.08)"/>
      {/* empty grid */}
      {[0,1,2,3].map(r => (
        <line key={r} x1="28" y1={44 + (r+1)*9} x2="92" y2={44 + (r+1)*9} stroke="rgba(60,40,20,0.06)"/>
      ))}
      {[0,1,2,3,4,5].map(c => (
        <line key={c} x1={28 + (c+1)*64/7} y1="44" x2={28 + (c+1)*64/7} y2="80" stroke="rgba(60,40,20,0.06)"/>
      ))}
    </svg>
  );
}

function EmptyIllCloud() {
  return (
    <svg width="130" height="100" viewBox="0 0 130 100" fill="none">
      <ellipse cx="65" cy="86" rx="46" ry="5" fill="rgba(60,40,20,0.06)"/>
      <path d="M40 60c-8 0-14-6-14-14 0-7 6-13 14-13 1 0 2 0 3 .3C46 24 53 18 62 18c11 0 19 8 19 19l0 .3c1-.2 2-.3 3-.3 7 0 13 6 13 13s-6 13-13 13H40z"
        fill="#fff" stroke="rgba(60,40,20,0.15)" strokeWidth="1.5"/>
      <line x1="44" y1="68" x2="92" y2="68" stroke="rgba(60,40,20,0.18)" strokeWidth="1.5" strokeLinecap="round"
        strokeDasharray="3 4"/>
      <line x1="36" y1="76" x2="100" y2="76" stroke="rgba(60,40,20,0.12)" strokeWidth="1.5" strokeLinecap="round"
        strokeDasharray="3 4"/>
      {/* signal slash */}
      <line x1="34" y1="22" x2="96" y2="78" stroke="oklch(0.55 0.13 22)" strokeWidth="3" strokeLinecap="round"/>
      <line x1="34" y1="22" x2="96" y2="78" stroke="#fff" strokeWidth="1.4" strokeLinecap="round"/>
    </svg>
  );
}

window.V5EmptyBrowse = V5EmptyBrowse;
window.V5EmptySaved = V5EmptySaved;
window.V5EmptyCalendar = V5EmptyCalendar;
window.V5OfflineState = V5OfflineState;
