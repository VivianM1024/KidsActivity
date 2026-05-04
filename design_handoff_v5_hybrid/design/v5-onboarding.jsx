// V5 — Onboarding screen (first launch only).
//
// Three quick steps:
//   1. Kid names (one or more).
//   2. Home location (for distance ranking).
//   3. Days of the week the parent has bandwidth on (weekends most common).
//
// Everything else lives in the FilterSheet — onboarding stays scannable.

function V5Onboarding({ onDone, initialStep = 0, initialNames }) {
  const [step, setStep] = React.useState(initialStep); // 0=kids, 1=location, 2=days
  const [names, setNames] = React.useState(initialNames || ['']);
  const [zip, setZip] = React.useState('');
  const [neighborhood, setNeighborhood] = React.useState('');
  const [days, setDays] = React.useState({
    Mon: false, Tue: false, Wed: false, Thu: false, Fri: false, Sat: true, Sun: true,
  });

  const HUES = [22, 250, 320, 145, 200, 60, 290];
  const setNameAt = (i, v) => setNames((cur) => cur.map((n, j) => (j === i ? v : n)));
  const addName = () => setNames((cur) => [...cur, '']);
  const removeName = (i) => setNames((cur) => cur.filter((_, j) => j !== i));
  const toggleDay = (d) => setDays((cur) => ({ ...cur, [d]: !cur[d] }));

  const filledNames = names.map((n) => n.trim()).filter(Boolean);
  const stepCanContinue = (
    step === 0 ? filledNames.length > 0 :
    step === 1 ? true :  // location is optional but recommended
    /* step === 2 */ Object.values(days).some(Boolean)
  );

  const isLast = step === 2;

  const next = () => {
    if (!stepCanContinue) return;
    if (isLast) submit();
    else setStep(step + 1);
  };
  const back = () => setStep(Math.max(0, step - 1));

  const submit = () => {
    const kids = filledNames.map((name, i) => ({
      id: `kid-${i + 1}`,
      name,
      initial: name.slice(0, 1).toUpperCase(),
      hue: HUES[i % HUES.length],
      ageYears: 5, // refined later in Filters → Manual range
    }));
    const prefs = {
      home: { zip: zip.trim(), neighborhood: neighborhood.trim() },
      days,
      distanceMiles: 5,
    };
    onDone && onDone({ kids, prefs });
  };

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 30, fontFamily: '-apple-system, system-ui',
      color: '#26201A', display: 'flex', flexDirection: 'column',
    }}>
      <Header step={step} total={3} onBack={step > 0 ? back : null} />

      {step === 0 && (
        <KidsStep
          names={names}
          setNameAt={setNameAt}
          addName={addName}
          removeName={removeName}
          hues={HUES}
        />
      )}

      {step === 1 && (
        <LocationStep
          zip={zip}
          setZip={setZip}
          neighborhood={neighborhood}
          setNeighborhood={setNeighborhood}
        />
      )}

      {step === 2 && (
        <DaysStep
          days={days}
          toggleDay={toggleDay}
          kids={filledNames}
        />
      )}

      <Footer
        canContinue={stepCanContinue}
        isLast={isLast}
        step={step}
        onNext={next}
        ctaLabel={
          step === 0
            ? (filledNames.length > 1 ? `Continue with ${filledNames.length} kids` : 'Continue')
            : step === 1
              ? (zip.trim() || neighborhood.trim() ? 'Continue' : 'Skip for now')
              : `Find activities`
        }
      />
    </div>
  );
}

function Header({ step, total, onBack }) {
  return (
    <div style={{
      paddingTop: 56,
      padding: '60px 20px 0',
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{ width: 32 }}>
        {onBack && (
          <div onClick={onBack} style={{
            width: 32, height: 32, borderRadius: 16,
            background: 'rgba(60,40,20,0.05)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
              <path d="M7.5 2L3.5 6L7.5 10" stroke="#26201A" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        )}
      </div>
      <div style={{ flex: 1, display: 'flex', gap: 4 }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 3, borderRadius: 2,
            background: i <= step ? 'oklch(0.55 0.13 22)' : 'rgba(60,40,20,0.1)',
            transition: 'background 240ms',
          }}/>
        ))}
      </div>
      <div style={{
        width: 32, fontSize: 11, fontWeight: 700, letterSpacing: 0.4,
        textTransform: 'uppercase', color: '#A89B86',
        textAlign: 'right', fontVariantNumeric: 'tabular-nums',
      }}>
        {step + 1}/{total}
      </div>
    </div>
  );
}

function StepHero({ eyebrow, title, subtitle }) {
  return (
    <div style={{ padding: '24px 24px 16px' }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 0.6,
        textTransform: 'uppercase', color: 'oklch(0.45 0.13 22)', marginBottom: 8,
      }}>
        {eyebrow}
      </div>
      <div style={{
        fontSize: 28, fontWeight: 700, letterSpacing: -0.7,
        color: '#26201A', lineHeight: 1.05,
      }}>
        {title}
      </div>
      {subtitle && (
        <div style={{
          fontSize: 14, color: '#7A6D5C', marginTop: 8, lineHeight: 1.45,
          maxWidth: 320,
        }}>{subtitle}</div>
      )}
    </div>
  );
}

// --------------- Step 1: kids ---------------

function KidsStep({ names, setNameAt, addName, removeName, hues }) {
  return (
    <React.Fragment>
      <StepHero
        eyebrow="Welcome"
        title={<React.Fragment>Who are we<br/>planning for?</React.Fragment>}
        subtitle="Add a name for each kid. You can fine-tune ages, distance, and the rest in Filters anytime."
      />
      <div style={{ padding: '0 20px', flex: 1 }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5,
          textTransform: 'uppercase', color: '#A89B86', marginBottom: 8,
        }}>Kids</div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {names.map((n, i) => {
            const hue = hues[i % hues.length];
            const initial = (n.trim().slice(0, 1) || '').toUpperCase();
            return (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                background: '#fff', borderRadius: 12, padding: '10px 12px',
                boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
              }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 18, flexShrink: 0,
                  background: initial ? `oklch(0.6 0.14 ${hue})` : 'rgba(60,40,20,0.06)',
                  color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 15, fontWeight: 700,
                  transition: 'background 180ms',
                }}>
                  {initial || (
                    <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                      <circle cx="7" cy="5" r="2.5" stroke="#A89B86" strokeWidth="1.4"/>
                      <path d="M2.5 12c.5-2 2.4-3.2 4.5-3.2s4 1.2 4.5 3.2" stroke="#A89B86" strokeWidth="1.4" strokeLinecap="round"/>
                    </svg>
                  )}
                </div>
                <input
                  value={n}
                  onChange={(e) => setNameAt(i, e.target.value)}
                  placeholder={i === 0 ? 'Kid’s name' : 'Another kid’s name'}
                  autoFocus={i === 0}
                  style={{
                    flex: 1, border: 'none', outline: 'none',
                    background: 'transparent',
                    fontSize: 16, fontWeight: 500, color: '#26201A',
                    fontFamily: 'inherit', minWidth: 0,
                  }}
                />
                {names.length > 1 && (
                  <div onClick={() => removeName(i)} style={{
                    width: 24, height: 24, borderRadius: 12, flexShrink: 0,
                    background: 'rgba(60,40,20,0.05)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    cursor: 'pointer',
                  }}>
                    <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                      <path d="M2.5 2.5l5 5M7.5 2.5l-5 5" stroke="#7A6D5C" strokeWidth="1.6" strokeLinecap="round"/>
                    </svg>
                  </div>
                )}
              </div>
            );
          })}

          <div onClick={addName} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            padding: '10px 12px', borderRadius: 12,
            border: '1.5px dashed rgba(60,40,20,0.18)',
            cursor: 'pointer', color: '#7A6D5C',
            fontSize: 13.5, fontWeight: 600,
          }}>
            <div style={{
              width: 22, height: 22, borderRadius: 11,
              background: 'rgba(60,40,20,0.06)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                <path d="M5 1.5v7M1.5 5h7" stroke="#5B4F3F" strokeWidth="1.6" strokeLinecap="round"/>
              </svg>
            </div>
            Add another kid
          </div>
        </div>

        <div style={{
          marginTop: 16, padding: '12px 14px',
          background: 'oklch(0.97 0.025 60)', borderRadius: 10,
          fontSize: 12, color: '#7A6D5C', lineHeight: 1.45,
          display: 'flex', gap: 8, alignItems: 'flex-start',
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" style={{ flexShrink: 0, marginTop: 1 }}>
            <circle cx="7" cy="7" r="5.5" stroke="#A89B86" strokeWidth="1.3"/>
            <path d="M7 6v3.5M7 4.4v.2" stroke="#5B4F3F" strokeWidth="1.4" strokeLinecap="round"/>
          </svg>
          <div>
            Stays on this device. We don’t make accounts or share names with venues.
          </div>
        </div>
      </div>
    </React.Fragment>
  );
}

// --------------- Step 2: location ---------------

function LocationStep({ zip, setZip, neighborhood, setNeighborhood }) {
  return (
    <React.Fragment>
      <StepHero
        eyebrow="Step 2"
        title="Where’s home?"
        subtitle="We’ll sort activities by distance. Just a ZIP works — we don’t need an exact address."
      />
      <div style={{ padding: '0 20px', flex: 1 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Field
            label="ZIP code"
            placeholder="60614"
            value={zip}
            onChange={setZip}
            inputMode="numeric"
            maxLength={5}
          />
          <Field
            label="Neighborhood"
            sublabel="optional"
            placeholder="Lincoln Park"
            value={neighborhood}
            onChange={setNeighborhood}
          />
        </div>

        <div onClick={() => { /* placeholder for native location prompt */ }} style={{
          marginTop: 12, padding: '12px 14px',
          background: '#fff', borderRadius: 12,
          boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
          display: 'flex', alignItems: 'center', gap: 10,
          cursor: 'pointer',
        }}>
          <div style={{
            width: 32, height: 32, borderRadius: 16, flexShrink: 0,
            background: 'oklch(0.94 0.06 22)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <circle cx="7" cy="7" r="5.5" stroke="oklch(0.45 0.13 22)" strokeWidth="1.4"/>
              <circle cx="7" cy="7" r="1.5" fill="oklch(0.45 0.13 22)"/>
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13.5, fontWeight: 600, color: '#26201A' }}>Use my current location</div>
            <div style={{ fontSize: 11.5, color: '#7A6D5C', marginTop: 1 }}>
              Asks iOS for permission · doesn’t leave the device
            </div>
          </div>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M3 1.5l4 3.5l-4 3.5" stroke="#A89B86" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>
    </React.Fragment>
  );
}

function Field({ label, sublabel, value, onChange, placeholder, inputMode, maxLength }) {
  return (
    <div style={{
      background: '#fff', borderRadius: 12, padding: '8px 14px',
      boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
        <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: '#A89B86' }}>{label}</div>
        {sublabel && <div style={{ fontSize: 10.5, color: '#A89B86' }}>· {sublabel}</div>}
      </div>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        inputMode={inputMode}
        maxLength={maxLength}
        style={{
          width: '100%', border: 'none', outline: 'none',
          background: 'transparent',
          fontSize: 16, fontWeight: 500, color: '#26201A',
          fontFamily: 'inherit', padding: '4px 0 6px',
        }}
      />
    </div>
  );
}

// --------------- Step 3: days ---------------

function DaysStep({ days, toggleDay, kids }) {
  const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const selected = order.filter((d) => days[d]);
  const summary =
    selected.length === 0 ? 'Pick at least one day' :
    selected.length === 7 ? 'Any day of the week' :
    selected.length === 2 && days.Sat && days.Sun ? 'Weekends' :
    selected.length === 5 && !days.Sat && !days.Sun ? 'Weekdays' :
    selected.join(', ');

  return (
    <React.Fragment>
      <StepHero
        eyebrow="Step 3"
        title="When are you free?"
        subtitle={kids.length > 0
          ? `Days you’d realistically take ${kids.length === 1 ? kids[0] : 'the kids'} to something.`
          : 'Days you’d realistically take the kids to something.'}
      />
      <div style={{ padding: '0 20px', flex: 1 }}>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6,
        }}>
          {order.map((d) => {
            const on = days[d];
            return (
              <div key={d} onClick={() => toggleDay(d)} style={{
                aspectRatio: '1 / 1.1',
                background: on ? 'oklch(0.55 0.13 22)' : '#fff',
                color: on ? '#fff' : '#26201A',
                border: on ? 'none' : '0.5px solid rgba(60,40,20,0.1)',
                borderRadius: 10,
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                gap: 1,
                fontWeight: 600,
                cursor: 'pointer',
                boxShadow: on ? '0 4px 10px oklch(0.55 0.13 22 / 0.18)' : '0 1px 2px rgba(60,40,20,0.04)',
                transition: 'background 160ms, color 160ms, box-shadow 160ms',
                userSelect: 'none',
              }}>
                <div style={{ fontSize: 10, letterSpacing: 0.4, opacity: on ? 0.85 : 0.6, textTransform: 'uppercase' }}>{d.slice(0, 1)}</div>
                <div style={{ fontSize: 13, letterSpacing: -0.1 }}>{d.slice(0, 3)}</div>
              </div>
            );
          })}
        </div>

        <div style={{ display: 'flex', gap: 6, marginTop: 12 }}>
          <Preset label="Weekends" onClick={() => {
            ['Mon','Tue','Wed','Thu','Fri'].forEach((d) => { if (days[d]) toggleDay(d); });
            ['Sat','Sun'].forEach((d) => { if (!days[d]) toggleDay(d); });
          }}/>
          <Preset label="Weekdays" onClick={() => {
            ['Mon','Tue','Wed','Thu','Fri'].forEach((d) => { if (!days[d]) toggleDay(d); });
            ['Sat','Sun'].forEach((d) => { if (days[d]) toggleDay(d); });
          }}/>
          <Preset label="Any day" onClick={() => {
            order.forEach((d) => { if (!days[d]) toggleDay(d); });
          }}/>
        </div>

        <div style={{
          marginTop: 16, padding: '12px 14px',
          background: '#fff', borderRadius: 12,
          boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 14, flexShrink: 0,
            background: 'oklch(0.94 0.06 22)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
              <rect x="2" y="3" width="9" height="8" rx="1.4" stroke="oklch(0.45 0.13 22)" strokeWidth="1.4"/>
              <path d="M2 5.5h9M5 1.5v3M8 1.5v3" stroke="oklch(0.45 0.13 22)" strokeWidth="1.4" strokeLinecap="round"/>
            </svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color: '#A89B86' }}>You’ll see</div>
            <div style={{ fontSize: 13.5, fontWeight: 600, color: '#26201A', marginTop: 1 }}>{summary}</div>
          </div>
        </div>
      </div>
    </React.Fragment>
  );
}

function Preset({ label, onClick }) {
  return (
    <div onClick={onClick} style={{
      flex: 1, padding: '8px 10px', borderRadius: 8,
      background: '#fff',
      border: '0.5px solid rgba(60,40,20,0.1)',
      fontSize: 12, fontWeight: 600, color: '#5B4F3F',
      textAlign: 'center', cursor: 'pointer',
    }}>{label}</div>
  );
}

// --------------- Footer (sticky CTA) ---------------

function Footer({ canContinue, isLast, ctaLabel, onNext }) {
  return (
    <div style={{
      position: 'sticky', bottom: 0,
      padding: '14px 20px 30px',
      background: 'linear-gradient(180deg, transparent 0%, #FBF7F1 30%)',
      marginTop: 'auto',
    }}>
      <div onClick={onNext} style={{
        background: canContinue ? 'oklch(0.55 0.13 22)' : 'rgba(60,40,20,0.12)',
        color: canContinue ? '#fff' : '#A89B86',
        padding: '14px 18px', borderRadius: 14,
        fontSize: 15, fontWeight: 700, textAlign: 'center',
        boxShadow: canContinue ? '0 4px 12px oklch(0.55 0.13 22 / 0.25)' : 'none',
        cursor: canContinue ? 'pointer' : 'default',
        letterSpacing: -0.1,
        transition: 'background 180ms, box-shadow 180ms, color 180ms',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        {ctaLabel}
        {isLast && canContinue && (
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M2 7h10M8 3l4 4l-4 4" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
    </div>
  );
}

window.V5Onboarding = V5Onboarding;
