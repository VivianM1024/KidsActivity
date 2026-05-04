// V5 — Registration handoff bridge sheet.
//
// Shown when the user taps "Register" on a Detail page. The bridge tells
// them what's about to happen (we open the venue's site in Safari), gives
// them the info they'll need to type, and provides a single "I registered"
// button to confirm on return.

function V5RegHandoff({ activities }) {
  const a = activities.find((x) => x.id === 'cpd-tball-1') || activities[0];
  const m = window.CATEGORY_META[a.category];
  const venue = (window.VENUE_TYPES.find((v) => v.id === a.venueType) || {});
  const kid = (window.KIDS || [])[0] || { name: 'Maya', initial: 'M', hue: 22, ageYears: 4 };
  const host = window.sourceHostLabel(a) || 'host site';

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 30, fontFamily: '-apple-system, system-ui',
      color: '#26201A', display: 'flex', flexDirection: 'column',
    }}>
      {/* Top: dismiss handle */}
      <div style={{ paddingTop: 56, padding: '60px 0 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: 'rgba(60,40,20,0.18)' }}/>
      </div>

      {/* Hero */}
      <div style={{ padding: '20px 24px 12px' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
          color: 'oklch(0.45 0.13 22)', marginBottom: 8,
        }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: 'oklch(0.55 0.13 22)' }}/>
          Heads up
        </div>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.1 }}>
          We can’t register you<br/>directly—here’s how it works.
        </div>
        <div style={{ fontSize: 13, color: '#7A6D5C', marginTop: 8, lineHeight: 1.45 }}>
          The venue uses their own system. We’ll open it in Safari so you can
          finish there, then come back to add it to your calendar.
        </div>
      </div>

      {/* Activity summary card */}
      <div style={{
        margin: '0 16px 14px', padding: '12px 14px', background: '#fff', borderRadius: 12,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
        display: 'flex', alignItems: 'center', gap: 10,
      }}>
        <div style={{
          width: 40, height: 40, borderRadius: 9, flexShrink: 0,
          background: `oklch(0.88 0.07 ${m.hue})`,
          color: `oklch(0.32 0.13 ${m.hue})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 13, fontWeight: 700, letterSpacing: 0.3,
        }}>{(m.short || a.category).slice(0,3).toUpperCase()}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 600, lineHeight: 1.2 }}>{a.name}</div>
          <div style={{ fontSize: 11.5, color: '#7A6D5C', marginTop: 2, display: 'flex', gap: 5, alignItems: 'center' }}>
            <span>{window.daysLabel(a.days)} {a.time}</span>
            <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }}/>
            <span style={{ fontWeight: 600, color: '#26201A', fontVariantNumeric: 'tabular-nums' }}>${a.priceRes}</span>
          </div>
        </div>
      </div>

      {/* "Things you'll need" section */}
      <div style={{ padding: '0 20px 4px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
          color: '#A89B86', marginBottom: 8,
        }}>You’ll need</div>
      </div>
      <div style={{
        margin: '0 16px 14px', background: '#fff', borderRadius: 12,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <NeedRow
          icon={<KidIcon kid={kid}/>}
          label={`${kid.name}’s info`}
          value={`Name, age (${kid.ageYears}yr), maybe school`}
          copy={kid.name}
        />
        <NeedRow
          icon={<DotIcon hue={m.hue} letter="$"/>}
          label="Payment"
          value={`$${a.priceRes} resident · credit card or saved on file`}
        />
        <NeedRow
          icon={<DotIcon hue={140} letter="✓"/>}
          label={`${host} account`}
          value="If you don't have one, sign-up takes ~2 min"
          last
        />
      </div>

      {/* Steps */}
      <div style={{ padding: '0 20px 4px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
          color: '#A89B86', marginBottom: 8,
        }}>What happens</div>
      </div>
      <div style={{ padding: '0 20px 16px' }}>
        <Step n={1} title="We open Safari" sub={`Goes to ${host} with this activity pre-selected.`} active/>
        <Step n={2} title="You finish on their site" sub="Account, payment, waivers — the usual stuff."/>
        <Step n={3} title="Come back here" sub={'Tap "I registered" — we’ll add the dates to your Calendar tab.'} last/>
      </div>

      {/* Sticky footer */}
      <div style={{
        position: 'sticky', bottom: 0,
        padding: '14px 20px 30px',
        background: 'linear-gradient(180deg, transparent 0%, #FBF7F1 30%)',
        marginTop: 'auto',
        display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        <a href={window.activitySourceUrl(a) || '#'} target="_blank" rel="noopener noreferrer"
          style={{ textDecoration: 'none' }}>
          <div style={{
            background: 'oklch(0.55 0.13 22)', color: '#fff',
            padding: '14px 18px', borderRadius: 14,
            fontSize: 15, fontWeight: 700, textAlign: 'center',
            boxShadow: '0 4px 12px oklch(0.55 0.13 22 / 0.25)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            Open {host}
            <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
              <path d="M7 1.5h4.5V6M11.5 1.5l-6 6M9 7.5V10a1.5 1.5 0 01-1.5 1.5h-5A1.5 1.5 0 011 10V5a1.5 1.5 0 011.5-1.5H5"
                stroke="#fff" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </a>
        <div style={{
          fontSize: 12, color: '#7A6D5C', textAlign: 'center',
          padding: '6px',
        }}>
          Already done?{' '}
          <span style={{ color: 'oklch(0.45 0.13 22)', fontWeight: 600 }}>I registered →</span>
        </div>
      </div>
    </div>
  );
}

function NeedRow({ icon, label, value, copy, last }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '10px 14px',
      borderBottom: last ? 'none' : '0.5px solid rgba(60,40,20,0.07)',
    }}>
      <div style={{ flexShrink: 0 }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12.5, fontWeight: 600, color: '#26201A', lineHeight: 1.2 }}>{label}</div>
        <div style={{ fontSize: 11.5, color: '#7A6D5C', marginTop: 1 }}>{value}</div>
      </div>
      {copy && (
        <div style={{
          fontSize: 10.5, fontWeight: 700, letterSpacing: 0.4,
          color: '#5B4F3F', background: 'rgba(60,40,20,0.05)',
          padding: '4px 7px', borderRadius: 6, flexShrink: 0,
        }}>COPY</div>
      )}
    </div>
  );
}

function KidIcon({ kid }) {
  return (
    <div style={{
      width: 28, height: 28, borderRadius: 14,
      background: `oklch(0.6 0.14 ${kid.hue})`, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 12, fontWeight: 700,
    }}>{kid.initial}</div>
  );
}

function DotIcon({ hue, letter }) {
  return (
    <div style={{
      width: 28, height: 28, borderRadius: 14,
      background: `oklch(0.92 0.07 ${hue})`,
      color: `oklch(0.32 0.13 ${hue})`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 13, fontWeight: 700,
    }}>{letter}</div>
  );
}

function Step({ n, title, sub, active, last }) {
  return (
    <div style={{ display: 'flex', gap: 12, position: 'relative' }}>
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0,
      }}>
        <div style={{
          width: 26, height: 26, borderRadius: 13,
          background: active ? 'oklch(0.55 0.13 22)' : '#fff',
          color: active ? '#fff' : '#5B4F3F',
          border: active ? 'none' : '1.5px solid rgba(60,40,20,0.15)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
        }}>{n}</div>
        {!last && (
          <div style={{
            width: 1.5, flex: 1, background: 'rgba(60,40,20,0.1)', minHeight: 16,
            margin: '4px 0',
          }}/>
        )}
      </div>
      <div style={{ flex: 1, paddingBottom: last ? 0 : 14 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: '#26201A', lineHeight: 1.25 }}>{title}</div>
        <div style={{ fontSize: 12, color: '#7A6D5C', marginTop: 2, lineHeight: 1.4 }}>{sub}</div>
      </div>
    </div>
  );
}

window.V5RegHandoff = V5RegHandoff;
