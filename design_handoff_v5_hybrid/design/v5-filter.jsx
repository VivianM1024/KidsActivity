// V5 — Filter sheet.
// Full-screen filter for everything that doesn't fit on the home chip bar:
// age slider, distance, date range, price, registration status, and
// multi-select venue type + category.

function V5FilterSheet() {
  const KIDS = window.KIDS;
  const [selectedKidIds, setSelectedKidIds] = React.useState(['maya', 'nora']);
  const [ages, setAges] = React.useState([2, 6]);
  const [ageMode, setAgeMode] = React.useState('kids'); // 'kids' | 'manual'
  const [distance, setDistance] = React.useState(5);
  const [registration, setRegistration] = React.useState('open');
  const [price, setPrice] = React.useState('any');
  const [days, setDays] = React.useState({ Mon:false, Tue:false, Wed:false, Thu:false, Fri:false, Sat:true, Sun:true });
  const [venues, setVenues] = React.useState({ park_district:true, library:true, museum:true });
  const [cats, setCats] = React.useState({ Sports:true, Arts:true, STEM:true, Events:true, Storytime:false });

  const toggleKid = (id) => {
    setSelectedKidIds((cur) => cur.includes(id) ? cur.filter((x) => x !== id) : [...cur, id]);
  };
  const selectedKids = KIDS.filter((k) => selectedKidIds.includes(k.id));

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: '#26201A',
    }}>
      {/* Sheet header */}
      <div style={{
        paddingTop: 56, padding: '56px 20px 8px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontSize: 14, fontWeight: 600, color: 'oklch(0.55 0.13 22)',
          padding: '4px 6px',
        }}>Reset</div>
        <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: -0.3 }}>Filters</div>
        <div style={{
          width: 28, height: 28, borderRadius: 14,
          background: 'rgba(60,40,20,0.08)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
            <path d="M2 2l7 7M9 2l-7 7" stroke="#5B4F3F" strokeWidth="1.8" strokeLinecap="round"/>
          </svg>
        </div>
      </div>

      {/* Active summary */}
      <div style={{
        margin: '12px 16px 18px',
        background: '#fff', borderRadius: 12, padding: '12px 14px',
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color: '#A89B86', marginBottom: 6 }}>
          Active filters
        </div>
        <div style={{ fontSize: 13, color: '#26201A', lineHeight: 1.5 }}>
          {selectedKids.length > 0 ? (
            <React.Fragment>
              {selectedKids.map((k, i) => (
                <span key={k.id}>
                  {i > 0 && ' + '}
                  <strong style={{ color: `oklch(0.4 0.14 ${k.hue})` }}>{k.name}</strong>
                </span>
              ))} · within <strong>5 mi</strong> · weekends · registration open
            </React.Fragment>
          ) : (
            <React.Fragment>No kids selected · manual ages 2–6</React.Fragment>
          )}
        </div>
      </div>

      <V5Section label="Kids" subtitle="Filter ages from your kids' profiles">
        <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 4 }}>
          {KIDS.map((k) => {
            const on = selectedKidIds.includes(k.id);
            return (
              <div key={k.id} onClick={() => toggleKid(k.id)} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '10px 12px', background: '#fff', borderRadius: 10,
                cursor: 'pointer',
                boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
                borderLeft: on ? `3px solid oklch(0.6 0.14 ${k.hue})` : '3px solid transparent',
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 16,
                  background: `oklch(0.6 0.14 ${k.hue})`, color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 13, fontWeight: 700,
                  flexShrink: 0,
                }}>{k.initial}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: '#26201A' }}>{k.name}</div>
                  <div style={{ fontSize: 11.5, color: '#7A6D5C' }}>
                    {k.ageYears} yrs old · ages {Math.max(0, k.ageYears - 1)}–{k.ageYears + 1} programs
                  </div>
                </div>
                <div style={{
                  width: 20, height: 20, borderRadius: 6,
                  background: on ? `oklch(0.6 0.14 ${k.hue})` : '#fff',
                  border: on ? 'none' : '1.5px solid rgba(60,40,20,0.25)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  {on && (
                    <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
                      <path d="M2 5.5L4.5 8L9 3" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </V5Section>

      <V5Section label="Ages" subtitle={ageMode === 'kids' ? 'Auto-fit from selected kids' : 'Manual override'}>
        <div style={{ padding: '0 16px 8px', display: 'flex', gap: 4 }}>
          {[
            { id: 'kids', label: 'Use kids’ ages' },
            { id: 'manual', label: 'Manual range' },
          ].map((opt) => {
            const on = opt.id === ageMode;
            return (
              <div key={opt.id} onClick={() => setAgeMode(opt.id)} style={{
                flex: 1, fontSize: 12, fontWeight: 600, padding: '7px 8px', borderRadius: 8,
                background: on ? '#fff' : 'transparent',
                color: on ? '#26201A' : '#8B7E6E',
                border: on ? '1.5px solid #26201A' : '1px solid rgba(60,40,20,0.12)',
                textAlign: 'center', cursor: 'pointer',
              }}>{opt.label}</div>
            );
          })}
        </div>
        {ageMode === 'kids' ? (
          <div style={{ padding: '4px 24px 0' }}>
            {selectedKids.length === 0 ? (
              <div style={{ fontSize: 12, color: '#A89B86' }}>Pick a kid above first.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {selectedKids.map((k) => (
                  <div key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span style={{
                      width: 22, height: 22, borderRadius: 11,
                      background: `oklch(0.6 0.14 ${k.hue})`, color: '#fff',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 10, fontWeight: 700, flexShrink: 0,
                    }}>{k.initial}</span>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12.5, color: '#26201A' }}>{k.name}’s window</div>
                      <div style={{
                        height: 4, background: 'rgba(60,40,20,0.1)', borderRadius: 2,
                        position: 'relative', marginTop: 4,
                      }}>
                        <div style={{
                          position: 'absolute', height: 4, borderRadius: 2,
                          left: `${Math.max(0, (k.ageYears - 1) / 18 * 100)}%`,
                          width: `${(2 / 18) * 100}%`,
                          background: `oklch(0.6 0.14 ${k.hue})`,
                        }}/>
                      </div>
                    </div>
                    <span style={{ fontSize: 12, fontWeight: 600, color: '#5B4F3F', fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
                      {Math.max(0, k.ageYears - 1)}–{k.ageYears + 1}y
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : (
          <RangeRow lo={ages[0]} hi={ages[1]} max={18} onChange={setAges} unit="yrs" />
        )}
      </V5Section>

      <V5Section label="Distance">
        <SingleRow value={distance} max={25} onChange={setDistance} unit="mi"
          ticks={['1', '5', '10', '25+']}/>
      </V5Section>

      <V5Section label="Date range">
        <div style={{ padding: '0 16px', display: 'flex', gap: 8 }}>
          <DateField label="From" value="May 4" />
          <DateField label="Until" value="Jun 30" />
        </div>
      </V5Section>

      <V5Section label="Days">
        <div style={{ padding: '0 16px', display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) => {
            const on = days[d];
            return (
              <div key={d} onClick={() => setDays({ ...days, [d]: !on })} style={{
                width: 38, height: 38, borderRadius: 10,
                background: on ? '#26201A' : '#fff',
                color: on ? '#fff' : '#5B4F3F',
                border: on ? 'none' : '1px solid rgba(60,40,20,0.12)',
                fontSize: 12, fontWeight: 600,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                cursor: 'pointer',
              }}>{d.slice(0,1)}</div>
            );
          })}
        </div>
      </V5Section>

      <V5Section label="Price">
        <div style={{ padding: '0 16px', display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {[
            { id: 'any', label: 'Any' },
            { id: 'free', label: 'Free' },
            { id: 'under25', label: 'Under $25' },
            { id: 'under75', label: 'Under $75' },
            { id: 'under200', label: 'Under $200' },
          ].map((p) => {
            const on = p.id === price;
            return (
              <div key={p.id} onClick={() => setPrice(p.id)} style={{
                fontSize: 12.5, fontWeight: 600, padding: '7px 12px', borderRadius: 100,
                background: on ? '#26201A' : '#fff', color: on ? '#fff' : '#5B4F3F',
                border: on ? 'none' : '1px solid rgba(60,40,20,0.12)',
                cursor: 'pointer',
              }}>{p.label}</div>
            );
          })}
        </div>
      </V5Section>

      <V5Section label="Registration">
        <div style={{ padding: '0 16px', display: 'flex', gap: 6 }}>
          {[
            { id: 'open', label: 'Open now', sub: '\u25CF' },
            { id: 'opening', label: 'Opening soon' },
            { id: 'any', label: 'Any' },
          ].map((r) => {
            const on = r.id === registration;
            return (
              <div key={r.id} onClick={() => setRegistration(r.id)} style={{
                flex: 1, fontSize: 12.5, fontWeight: 600, padding: '8px 10px', borderRadius: 10,
                background: on ? '#fff' : 'transparent',
                color: on ? '#26201A' : '#8B7E6E',
                border: on ? '1.5px solid #26201A' : '1px solid rgba(60,40,20,0.12)',
                textAlign: 'center', cursor: 'pointer',
              }}>{r.label}</div>
            );
          })}
        </div>
      </V5Section>

      <V5Section label="Venue type" subtitle="Where the activity happens">
        <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 4 }}>
          {[
            { id: 'park_district', label: 'Park District', count: 302 },
            { id: 'library',       label: 'Library', count: 48 },
            { id: 'museum',        label: 'Museum', count: 21 },
          ].map((v) => (
            <CheckRow key={v.id} label={v.label} count={v.count}
              checked={venues[v.id]} onChange={() => setVenues({ ...venues, [v.id]: !venues[v.id] })} />
          ))}
        </div>
      </V5Section>

      <V5Section label="Category">
        <div style={{ padding: '0 16px', display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {Object.keys(cats).map((c) => {
            const m = window.CATEGORY_META[c];
            const on = cats[c];
            return (
              <div key={c} onClick={() => setCats({ ...cats, [c]: !on })} style={{
                fontSize: 12.5, fontWeight: 600, padding: '7px 11px', borderRadius: 100,
                background: on ? `oklch(0.92 0.07 ${m.hue})` : '#fff',
                color: on ? `oklch(0.32 0.13 ${m.hue})` : '#5B4F3F',
                border: on ? `1.5px solid oklch(0.6 0.13 ${m.hue})` : '1px solid rgba(60,40,20,0.12)',
                display: 'inline-flex', alignItems: 'center', gap: 5, cursor: 'pointer',
              }}>
                <span style={{
                  width: 8, height: 8, borderRadius: 4,
                  background: `oklch(0.6 0.15 ${m.hue})`, opacity: on ? 1 : 0.5,
                }} />
                {c}
              </div>
            );
          })}
        </div>
      </V5Section>

      <div style={{ height: 24 }} />

      {/* Apply CTA — sticky-ish over tab area */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        padding: '12px 16px 32px',
        background: 'linear-gradient(180deg, rgba(251,247,241,0) 0%, #FBF7F1 22%)',
      }}>
        <div style={{
          background: 'oklch(0.55 0.13 22)', color: '#fff',
          padding: '14px', borderRadius: 14, textAlign: 'center',
          fontSize: 16, fontWeight: 700, letterSpacing: -0.2,
          boxShadow: '0 4px 16px oklch(0.6 0.15 22 / 0.3)',
        }}>Show 41 results</div>
      </div>
    </div>
  );
}

function V5Section({ label, subtitle, children }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{ padding: '0 20px 8px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5,
          textTransform: 'uppercase', color: '#A89B86',
        }}>{label}</div>
        {subtitle && <div style={{ fontSize: 12, color: '#8B7E6E', marginTop: 1 }}>{subtitle}</div>}
      </div>
      {children}
    </div>
  );
}

function RangeRow({ lo, hi, max, onChange, unit }) {
  // Visual-only — bar with two thumbs at percent positions.
  const a = (lo / max) * 100, b = (hi / max) * 100;
  return (
    <div style={{ padding: '4px 24px 0' }}>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
        marginBottom: 12, fontSize: 14, fontWeight: 600, color: '#26201A',
      }}>
        <span style={{ fontVariantNumeric: 'tabular-nums' }}>{lo} {unit}</span>
        <span style={{ fontSize: 11, color: '#A89B86', fontWeight: 500 }}>to</span>
        <span style={{ fontVariantNumeric: 'tabular-nums' }}>{hi}+ {unit}</span>
      </div>
      <div style={{ height: 4, background: 'rgba(60,40,20,0.1)', borderRadius: 2, position: 'relative' }}>
        <div style={{
          position: 'absolute', left: `${a}%`, right: `${100-b}%`,
          top: 0, height: 4, background: 'oklch(0.55 0.13 22)', borderRadius: 2,
        }} />
        <Thumb percent={a} />
        <Thumb percent={b} />
      </div>
    </div>
  );
}

function SingleRow({ value, max, onChange, unit, ticks = [] }) {
  const v = (value / max) * 100;
  return (
    <div style={{ padding: '4px 24px 0' }}>
      <div style={{
        marginBottom: 12, fontSize: 14, fontWeight: 600, color: '#26201A',
      }}>Within <span style={{ fontVariantNumeric: 'tabular-nums' }}>{value}</span> {unit}</div>
      <div style={{ height: 4, background: 'rgba(60,40,20,0.1)', borderRadius: 2, position: 'relative', marginBottom: 8 }}>
        <div style={{
          position: 'absolute', left: 0, width: `${v}%`,
          top: 0, height: 4, background: 'oklch(0.55 0.13 22)', borderRadius: 2,
        }} />
        <Thumb percent={v} />
      </div>
      <div style={{
        display: 'flex', justifyContent: 'space-between',
        fontSize: 10, color: '#A89B86', fontVariantNumeric: 'tabular-nums',
      }}>
        {ticks.map((t) => <span key={t}>{t}</span>)}
      </div>
    </div>
  );
}

function Thumb({ percent }) {
  return (
    <div style={{
      position: 'absolute', left: `${percent}%`, top: -8,
      transform: 'translateX(-50%)',
      width: 20, height: 20, borderRadius: 10, background: '#fff',
      boxShadow: '0 1px 3px rgba(60,40,20,0.2), 0 0 0 1.5px oklch(0.55 0.13 22)',
    }} />
  );
}

function DateField({ label, value }) {
  return (
    <div style={{
      flex: 1, background: '#fff', borderRadius: 10,
      padding: '8px 12px', boxShadow: '0 0 0 1px rgba(60,40,20,0.1)',
    }}>
      <div style={{ fontSize: 10, color: '#A89B86', fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.4 }}>{label}</div>
      <div style={{ fontSize: 15, fontWeight: 600, color: '#26201A', marginTop: 2 }}>{value}</div>
    </div>
  );
}

function CheckRow({ label, count, checked, onChange }) {
  return (
    <div onClick={onChange} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '10px 12px', background: '#fff', borderRadius: 10,
      cursor: 'pointer',
      boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
    }}>
      <div style={{
        width: 20, height: 20, borderRadius: 6,
        background: checked ? 'oklch(0.55 0.13 22)' : '#fff',
        border: checked ? 'none' : '1.5px solid rgba(60,40,20,0.25)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        {checked && (
          <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
            <path d="M2 5.5L4.5 8L9 3" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
      <div style={{ flex: 1, fontSize: 14.5, fontWeight: 500, color: '#26201A' }}>{label}</div>
      <div style={{ fontSize: 12, color: '#A89B86', fontVariantNumeric: 'tabular-nums' }}>{count}</div>
    </div>
  );
}

window.V5FilterSheet = V5FilterSheet;
