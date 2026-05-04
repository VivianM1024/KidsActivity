// V5 — Activity detail.
// Where a row taps through to. Hero with category color, key facts grid,
// schedule, location, what to bring, host. Sticky register CTA.

function V5Detail({ activities }) {
  // Pick a representative activity — Saturday soccer at a park district.
  const a = activities.find((x) =>
    x.kind === 'course' && x.category === 'Sports' && x.venueType === 'park_district'
  ) || activities[0];

  const m = window.CATEGORY_META[a.category];
  const venue = (window.VENUE_TYPES.find((v) => v.id === a.venueType) || {}).short || 'Park District';

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%', position: 'relative',
      paddingBottom: 110, fontFamily: '-apple-system, system-ui',
      color: '#26201A',
    }}>
      {/* Status bar fade + nav */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 88,
        background: `linear-gradient(180deg, oklch(0.88 0.07 ${m.hue}) 0%, oklch(0.88 0.07 ${m.hue} / 0) 100%)`,
        pointerEvents: 'none',
      }} />
      <div style={{
        position: 'relative', paddingTop: 56,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '56px 16px 8px',
      }}>
        <CircleBtn>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M9 2L4 7l5 5" stroke="#26201A" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </CircleBtn>
        <div style={{ display: 'flex', gap: 8 }}>
          <CircleBtn>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M7 12s5-3 5-7a3 3 0 00-5-2 3 3 0 00-5 2c0 4 5 7 5 7z"
                stroke="#26201A" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </CircleBtn>
          <CircleBtn>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M3 5l4-3 4 3M7 2v8M3 9v3h8V9" stroke="#26201A" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </CircleBtn>
        </div>
      </div>

      {/* Hero */}
      <div style={{ padding: '4px 20px 18px' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
          color: `oklch(0.32 0.13 ${m.hue})`,
          background: `oklch(0.92 0.07 ${m.hue})`,
          padding: '4px 8px', borderRadius: 6, marginBottom: 10,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: `oklch(0.55 0.15 ${m.hue})` }} />
          {a.category} · {venue}
        </div>
        <div style={{
          fontSize: 26, fontWeight: 700, letterSpacing: -0.6, lineHeight: 1.1,
          marginBottom: 6,
        }}>{a.name}</div>
        <div style={{ fontSize: 13.5, color: '#5B4F3F', lineHeight: 1.4 }}>
          {a.kind === 'course'
            ? `${a.sessions}-week series · ${a.venueShort}`
            : `One-time at ${a.venueShort}`}
        </div>
      </div>

      {/* Key facts — 2×2 grid */}
      <div style={{
        margin: '0 16px 14px', background: '#fff', borderRadius: 14,
        padding: '14px 16px', boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
        display: 'grid', gridTemplateColumns: '1fr 1fr', rowGap: 12, columnGap: 12,
      }}>
        <Fact label="Ages" value={window.ageRangeLabel(a.ageMin, a.ageMax)} />
        <Fact label="Price" value={a.priceRes ? `$${a.priceRes}` : 'Free'}
          sub={a.kind === 'course' ? `${(a.priceRes / a.sessions).toFixed(0)}/session` : null}/>
        <Fact label="When" value={`${window.daysLabel(a.days)} ${a.time}`}
          sub={`Starts ${window.startDateLabel(a.startDate)}`}/>
        <Fact label="Distance" value={`${a.distance.toFixed(1)} mi`} sub="from Logan Square" />
      </div>

      {/* Status banner */}
      <div style={{
        margin: '0 16px 14px', padding: '12px 14px', borderRadius: 12,
        background: a.isOpen
          ? 'oklch(0.95 0.07 145)'
          : a.opensSoon
          ? 'oklch(0.96 0.06 60)'
          : 'rgba(60,40,20,0.06)',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 8, height: 8, borderRadius: 4, flexShrink: 0,
          background: a.isOpen ? 'oklch(0.55 0.15 145)' : 'oklch(0.6 0.15 60)',
          boxShadow: a.isOpen ? '0 0 0 4px oklch(0.55 0.15 145 / 0.2)' : 'none',
        }} />
        <div style={{ flex: 1, fontSize: 13, lineHeight: 1.35 }}>
          <div style={{ fontWeight: 700, color: '#26201A' }}>
            {a.isOpen ? 'Registration is open' : a.opensSoon ? 'Opens soon' : 'Registration closed'}
          </div>
          <div style={{ color: '#5B4F3F' }}>
            {a.isOpen
              ? '8 spots left · most fill within a week'
              : a.opensSoon
              ? 'Tuesday at 9:00 am — set a reminder so you don\'t miss it'
              : 'Try the waitlist or check the next session'}
          </div>
        </div>
      </div>

      {/* Schedule */}
      <Section title="Schedule" trailing={a.kind === 'course' ? `${a.sessions} sessions` : null}>
        {a.kind === 'course' ? (
          <div style={{ padding: '4px 0' }}>
            {[
              { i: 1, d: 'Sat May 10', t: '9:30 am', sub: 'Intro & warm-up games' },
              { i: 2, d: 'Sat May 17', t: '9:30 am', sub: 'Dribbling fundamentals' },
              { i: 3, d: 'Sat May 24', t: '9:30 am', sub: 'Passing & teamwork' },
            ].map((s) => (
              <div key={s.i} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px',
                borderTop: '0.5px solid rgba(60,40,20,0.08)',
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 8,
                  background: `oklch(0.92 0.07 ${m.hue})`,
                  color: `oklch(0.32 0.13 ${m.hue})`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
                }}>{s.i}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13.5, fontWeight: 600 }}>{s.d} · {s.t}</div>
                  <div style={{ fontSize: 12, color: '#7A6D5C' }}>{s.sub}</div>
                </div>
              </div>
            ))}
            <div style={{ padding: '10px 16px', borderTop: '0.5px solid rgba(60,40,20,0.08)',
              fontSize: 12.5, color: '#8B7E6E' }}>
              + {a.sessions - 3} more weeks · same time
            </div>
          </div>
        ) : (
          <div style={{ padding: '10px 16px', fontSize: 13.5, color: '#26201A' }}>
            {window.daysLabel(a.days)} · {a.time}
          </div>
        )}
      </Section>

      {/* Location */}
      <Section title="Location">
        <div style={{ padding: '0 16px 14px' }}>
          <div style={{
            height: 110, borderRadius: 10,
            background: 'linear-gradient(135deg, oklch(0.9 0.04 150) 0%, oklch(0.86 0.05 200) 100%)',
            position: 'relative', overflow: 'hidden',
            boxShadow: '0 0 0 0.5px rgba(60,40,20,0.08)',
          }}>
            {/* fake streets */}
            <div style={{ position: 'absolute', top: '40%', left: 0, right: 0, height: 1, background: 'rgba(255,255,255,0.6)' }} />
            <div style={{ position: 'absolute', top: '70%', left: 0, right: 0, height: 1, background: 'rgba(255,255,255,0.4)' }} />
            <div style={{ position: 'absolute', top: 0, bottom: 0, left: '30%', width: 1, background: 'rgba(255,255,255,0.5)' }} />
            <div style={{ position: 'absolute', top: 0, bottom: 0, left: '65%', width: 1, background: 'rgba(255,255,255,0.5)' }} />
            {/* pin */}
            <div style={{
              position: 'absolute', top: '38%', left: '50%', transform: 'translate(-50%, -100%)',
              width: 22, height: 22, borderRadius: '50% 50% 50% 0',
              background: 'oklch(0.55 0.13 22)', rotate: '-45deg',
              boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
            }}/>
          </div>
          <div style={{ marginTop: 10, fontSize: 14, fontWeight: 600 }}>
            {a.venueShort}
          </div>
          <div style={{ fontSize: 12.5, color: '#7A6D5C', marginTop: 1 }}>
            2715 W Belden Ave · {a.distance.toFixed(1)} mi away · 12 min drive
          </div>
        </div>
      </Section>

      {/* What to bring */}
      <Section title="What to bring">
        <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            'Water bottle (labeled)',
            'Indoor athletic shoes — no cleats',
            'Shin guards optional for ages 5+',
          ].map((t) => (
            <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13.5, color: '#26201A' }}>
              <span style={{ width: 4, height: 4, borderRadius: 2, background: '#26201A', flexShrink: 0 }}/>
              {t}
            </div>
          ))}
        </div>
      </Section>

      {/* Host */}
      <Section title="Hosted by">
        <div style={{
          margin: '0 16px', padding: '12px 14px', background: '#fff', borderRadius: 12,
          boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{
            width: 38, height: 38, borderRadius: 19,
            background: 'oklch(0.85 0.05 60)', color: '#5B4F3F',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 13, fontWeight: 700, letterSpacing: 0.4,
          }}>{(a.venue || 'CPD').split(' ').map(w => w[0]).join('').slice(0,3).toUpperCase()}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13.5, fontWeight: 600 }}>{a.venue || 'Chicago Park District'}</div>
            <div style={{ fontSize: 12, color: '#7A6D5C' }}>1,240 programs · since 1934</div>
          </div>
          <div style={{ fontSize: 12, fontWeight: 600, color: 'oklch(0.55 0.13 22)' }}>View →</div>
        </div>
      </Section>

      {/* Source link — original listing on host's site */}
      <Section title="Original listing">
        <a href={window.activitySourceUrl(a) || '#'} target="_blank" rel="noopener noreferrer"
          style={{ textDecoration: 'none', color: 'inherit' }}>
          <div style={{
            margin: '0 16px', padding: '12px 14px', background: '#fff', borderRadius: 12,
            boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: 9,
              background: 'rgba(60,40,20,0.05)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}>
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <path d="M9 3h4v4M13 3l-6 6M11 8.5V12a1 1 0 01-1 1H4a1 1 0 01-1-1V6a1 1 0 011-1h3.5"
                  stroke="#5B4F3F" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: '#26201A' }}>
                View on {window.sourceHostLabel(a) || 'host site'}
              </div>
              <div style={{
                fontSize: 11.5, color: '#7A6D5C', marginTop: 1,
                whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                fontVariantNumeric: 'tabular-nums', fontFamily: 'ui-monospace, Menlo, monospace',
              }}>
                {window.activitySourceUrl(a) || 'No source link'}
              </div>
            </div>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="none" style={{ flexShrink: 0 }}>
              <path d="M3 2l4 3.5L3 9" stroke="#A89B86" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </a>
        <div style={{
          padding: '6px 20px 0', fontSize: 11, color: '#A89B86', lineHeight: 1.4,
        }}>
          Registration happens on the park district\u2019s ActiveNet site. We pre-fill what we can.
        </div>
      </Section>

      {/* Sticky CTA */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '12px 16px 32px',
        background: 'linear-gradient(180deg, rgba(251,247,241,0) 0%, #FBF7F1 30%)',
        display: 'flex', gap: 10,
      }}>
        <div style={{
          width: 50, height: 50, borderRadius: 14,
          background: '#fff', border: '1px solid rgba(60,40,20,0.12)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <path d="M9 15s6-4 6-9a4 4 0 00-6-3 4 4 0 00-6 3c0 5 6 9 6 9z"
              stroke="#26201A" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <a href={window.activitySourceUrl(a) || '#'} target="_blank" rel="noopener noreferrer"
          style={{
            flex: 1, textDecoration: 'none',
            background: 'oklch(0.55 0.13 22)', color: '#fff',
            padding: '12px 14px', borderRadius: 14,
            boxShadow: '0 4px 16px oklch(0.6 0.15 22 / 0.3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1.15 }}>
            <span style={{ fontSize: 16, fontWeight: 700, letterSpacing: -0.2,
              display: 'flex', alignItems: 'center', gap: 6 }}>
              {a.isOpen ? 'Register' : a.opensSoon ? 'Remind me' : 'Join waitlist'}
              <span style={{ opacity: 0.85, fontWeight: 500, fontSize: 13 }}>
                · ${a.priceRes}
              </span>
              <svg width="11" height="11" viewBox="0 0 11 11" fill="none" style={{ opacity: 0.85 }}>
                <path d="M6 1h4v4M10 1L5 6M8 6.5V9a1 1 0 01-1 1H2a1 1 0 01-1-1V4a1 1 0 011-1h2.5"
                  stroke="#fff" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </span>
            <span style={{ fontSize: 10.5, opacity: 0.75, fontWeight: 500, marginTop: 2,
              fontFamily: 'ui-monospace, Menlo, monospace' }}>
              {window.sourceHostLabel(a) || 'host site'}
            </span>
          </div>
        </a>
      </div>
    </div>
  );
}

function CircleBtn({ children }) {
  return (
    <div style={{
      width: 32, height: 32, borderRadius: 16,
      background: 'rgba(255,253,250,0.92)', backdropFilter: 'blur(10px)',
      boxShadow: '0 0 0 0.5px rgba(60,40,20,0.08)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</div>
  );
}

function Fact({ label, value, sub }) {
  return (
    <div>
      <div style={{
        fontSize: 10.5, fontWeight: 700, letterSpacing: 0.5,
        textTransform: 'uppercase', color: '#A89B86',
      }}>{label}</div>
      <div style={{ fontSize: 16, fontWeight: 700, color: '#26201A', marginTop: 2, letterSpacing: -0.2 }}>
        {value}
      </div>
      {sub && <div style={{ fontSize: 11, color: '#7A6D5C', marginTop: 1 }}>{sub}</div>}
    </div>
  );
}

function Section({ title, trailing, children }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{
        padding: '0 20px 8px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5,
          textTransform: 'uppercase', color: '#A89B86',
        }}>{title}</div>
        {trailing && <div style={{ fontSize: 11, color: '#A89B86', fontVariantNumeric: 'tabular-nums' }}>{trailing}</div>}
      </div>
      {children}
    </div>
  );
}

window.V5Detail = V5Detail;
