// V5 — "Why this?" transparency popovers + lightweight cached-data banner.
//
// Two surfaces:
//   V5WhyThis    — modal popover that explains a sort/recommendation. Tapped
//                  from the small (i) button next to "Sorted by best match"
//                  on Browse, or from the "Why this?" link on a recommendation.
//                  Shows the rules that ordered the result, with weights.
//
//   V5BrowseCached — the regular Browse screen with a thin "cached data"
//                    banner inset under the search bar, replacing the
//                    full-screen offline state. Shows when network is down
//                    or stale, with a tap-to-retry pill.

const WHY = {
  bg: '#FBF7F1',
  ink: '#26201A',
  muted: '#7A6D5C',
  faint: '#A89B86',
  card: '#fff',
  hairline: 'rgba(60,40,20,0.07)',
  accent: 'oklch(0.55 0.13 22)',
  accentSoft: 'oklch(0.94 0.05 22)',
  amber: 'oklch(0.62 0.14 70)',
  amberSoft: 'oklch(0.96 0.05 70)',
  amberInk: 'oklch(0.42 0.14 70)',
};

// ---------------------------------------------------------------------------
// 1. WHY THIS?  — sort / recommendation explanation popover

function V5WhyThis() {
  // Each rule shows: the condition, whether it matched, and how much it
  // weighted into the score. Numbers are illustrative — the point is the UI
  // for transparency, not the model itself.
  const rules = [
    {
      label: 'Within your radius',
      detail: 'Welles Park is 1.4 mi away (you set 5 mi).',
      weight: 25, met: true, kind: 'distance',
    },
    {
      label: 'Time fits your free days',
      detail: 'Saturday at 9:30 AM — you marked weekends.',
      weight: 20, met: true, kind: 'days',
    },
    {
      label: 'Age window matches Leo',
      detail: 'Ages 5–7 · Leo is 7.',
      weight: 25, met: true, kind: 'age',
    },
    {
      label: 'Registration still open',
      detail: 'Closes Mar 15 · ~12 spots left.',
      weight: 15, met: true, kind: 'open',
    },
    {
      label: 'Similar to what you’ve saved',
      detail: 'You saved 2 sports activities at Park District venues.',
      weight: 10, met: true, kind: 'similar',
    },
    {
      label: 'Price below your max',
      detail: 'No max set — this rule didn’t apply.',
      weight: 5, met: false, kind: 'price',
    },
  ];
  const total = rules.filter((r) => r.met).reduce((s, r) => s + r.weight, 0);

  return (
    <div style={{
      background: WHY.bg, minHeight: '100%',
      paddingBottom: 30, fontFamily: '-apple-system, system-ui',
      color: WHY.ink, display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ paddingTop: 56, padding: '60px 0 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: 'rgba(60,40,20,0.18)' }}/>
      </div>

      {/* Hero */}
      <div style={{ padding: '20px 24px 12px' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
          color: WHY.accent, marginBottom: 8,
        }}>
          <InfoGlyph color={WHY.accent}/>
          Why this is #1
        </div>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.1 }}>
          CPD T-Ball, Welles Park
        </div>
        <div style={{ fontSize: 13, color: WHY.muted, marginTop: 8, lineHeight: 1.45, textWrap: 'pretty' }}>
          You set what matters in onboarding and the filter sheet. Here’s how
          this activity scored against those rules.
        </div>
      </div>

      {/* Score badge */}
      <div style={{
        margin: '4px 16px 14px', padding: '14px 18px',
        background: WHY.card, borderRadius: 14,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
        display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <ScoreRing score={total}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: WHY.faint, marginBottom: 2 }}>
            Match score
          </div>
          <div style={{ fontSize: 15, fontWeight: 700, color: WHY.ink, letterSpacing: -0.2 }}>
            5 of 6 rules met
          </div>
          <div style={{ fontSize: 11.5, color: WHY.muted, marginTop: 2 }}>
            Higher = more rules you set were satisfied.
          </div>
        </div>
      </div>

      {/* Rules list */}
      <div style={{ padding: '0 20px 6px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
          color: WHY.faint, marginBottom: 8,
        }}>The rules</div>
      </div>
      <div style={{
        margin: '0 16px 14px', background: WHY.card, borderRadius: 12,
        boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
        overflow: 'hidden',
      }}>
        {rules.map((r, i) => <RuleRow key={i} rule={r} last={i === rules.length - 1}/>)}
      </div>

      {/* Footer note */}
      <div style={{
        margin: '0 16px 14px', padding: '12px 14px',
        background: 'rgba(60,40,20,0.03)', borderRadius: 12,
        fontSize: 12.5, color: WHY.muted, lineHeight: 1.5, textWrap: 'pretty',
      }}>
        <strong style={{ color: WHY.ink, fontWeight: 600 }}>No black box.</strong>{' '}
        We never reorder for sponsored placement, and we don’t use what you’ve
        clicked on — only the filters and kids you set yourself.
      </div>

      <div style={{
        marginTop: 'auto', padding: '6px 20px 30px',
        display: 'flex', gap: 8,
      }}>
        <div style={{
          flex: 1, padding: '13px 16px', borderRadius: 12,
          background: 'rgba(60,40,20,0.05)', color: WHY.ink,
          fontSize: 14, fontWeight: 600, textAlign: 'center',
        }}>Adjust filters</div>
        <div style={{
          flex: 1, padding: '13px 16px', borderRadius: 12,
          background: WHY.accent, color: '#fff',
          fontSize: 14, fontWeight: 700, textAlign: 'center',
          boxShadow: '0 2px 8px oklch(0.55 0.13 22 / 0.22)',
        }}>Got it</div>
      </div>
    </div>
  );
}

function ScoreRing({ score }) {
  const r = 22;
  const c = 2 * Math.PI * r;
  const offset = c * (1 - score / 100);
  return (
    <div style={{ position: 'relative', width: 56, height: 56, flexShrink: 0 }}>
      <svg width="56" height="56" viewBox="0 0 56 56" style={{ transform: 'rotate(-90deg)' }}>
        <circle cx="28" cy="28" r={r} stroke="rgba(60,40,20,0.08)" strokeWidth="5" fill="none"/>
        <circle cx="28" cy="28" r={r}
          stroke="oklch(0.55 0.15 145)" strokeWidth="5" fill="none"
          strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={offset}/>
      </svg>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexDirection: 'column',
      }}>
        <div style={{
          fontSize: 16, fontWeight: 700, color: WHY.ink,
          fontVariantNumeric: 'tabular-nums', lineHeight: 1,
        }}>{score}</div>
        <div style={{ fontSize: 8, color: WHY.faint, fontWeight: 600 }}>/100</div>
      </div>
    </div>
  );
}

function RuleRow({ rule, last }) {
  const met = rule.met;
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 12,
      padding: '12px 14px',
      borderBottom: last ? 'none' : `0.5px solid ${WHY.hairline}`,
      opacity: met ? 1 : 0.6,
    }}>
      <RuleIcon kind={rule.kind} met={met}/>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontSize: 13, fontWeight: 600, color: WHY.ink, lineHeight: 1.25,
          textDecoration: met ? 'none' : 'line-through',
          textDecorationColor: WHY.faint,
        }}>{rule.label}</div>
        <div style={{ fontSize: 11.5, color: WHY.muted, marginTop: 2, lineHeight: 1.4 }}>{rule.detail}</div>
      </div>
      <div style={{
        fontSize: 10.5, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
        color: met ? 'oklch(0.4 0.13 145)' : WHY.faint,
        background: met ? 'oklch(0.94 0.05 145)' : 'rgba(60,40,20,0.04)',
        padding: '3px 7px', borderRadius: 4, flexShrink: 0,
        letterSpacing: 0.3,
      }}>{met ? `+${rule.weight}` : `·0`}</div>
    </div>
  );
}

function RuleIcon({ kind, met }) {
  const bg = met ? 'oklch(0.94 0.05 145)' : 'rgba(60,40,20,0.05)';
  const stroke = met ? 'oklch(0.4 0.13 145)' : WHY.faint;
  return (
    <div style={{
      width: 30, height: 30, borderRadius: 9, background: bg, flexShrink: 0,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>
      {kind === 'distance' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M7 1.5a4 4 0 014 4c0 3-4 7-4 7s-4-4-4-7a4 4 0 014-4z" stroke={stroke} strokeWidth="1.4"/>
          <circle cx="7" cy="5.5" r="1.4" fill={stroke}/>
        </svg>
      )}
      {kind === 'days' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <rect x="2" y="3.5" width="10" height="9" rx="1.5" stroke={stroke} strokeWidth="1.4"/>
          <line x1="2" y1="6.5" x2="12" y2="6.5" stroke={stroke} strokeWidth="1.4"/>
          <line x1="4.5" y1="2" x2="4.5" y2="4.5" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
          <line x1="9.5" y1="2" x2="9.5" y2="4.5" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
        </svg>
      )}
      {kind === 'age' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <circle cx="7" cy="5" r="2.3" stroke={stroke} strokeWidth="1.4"/>
          <path d="M2.5 12.5c0-2.2 2-4 4.5-4s4.5 1.8 4.5 4" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
        </svg>
      )}
      {kind === 'open' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <circle cx="7" cy="7" r="5" stroke={stroke} strokeWidth="1.4"/>
          <path d="M7 4v3l2 1.5" stroke={stroke} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
      {kind === 'similar' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M7 12s-4.5-2.8-4.5-6.2A2.8 2.8 0 017 4a2.8 2.8 0 014.5 1.8C11.5 9.2 7 12 7 12z" fill={stroke}/>
        </svg>
      )}
      {kind === 'price' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <circle cx="7" cy="7" r="5" stroke={stroke} strokeWidth="1.4"/>
          <path d="M7 4v6M5.5 5.5h2.5a1.2 1.2 0 010 2.4H6a1.2 1.2 0 000 2.4h3" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
        </svg>
      )}
    </div>
  );
}

function InfoGlyph({ color }) {
  return (
    <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
      <circle cx="5.5" cy="5.5" r="4.5" stroke={color} strokeWidth="1.3"/>
      <rect x="5" y="4.5" width="1" height="3" rx="0.5" fill={color}/>
      <circle cx="5.5" cy="3.2" r="0.7" fill={color}/>
    </svg>
  );
}

// ---------------------------------------------------------------------------
// 2. CACHED BANNER  — a slimmer alternative to the full-screen offline state.
//    Shown inline on the regular Browse screen.

function V5BrowseCached({ activities }) {
  // Pull a few activities to fill the rows below the banner.
  const list = (activities || []).slice(0, 5);
  const M = window.CATEGORY_META || {};

  return (
    <div style={{
      background: WHY.bg, minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: WHY.ink,
    }}>
      {/* Top */}
      <div style={{ paddingTop: 56, padding: '56px 20px 8px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: WHY.amberInk, marginBottom: 4 }}>
          · Offline mode
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -0.5 }}>Browse</div>
      </div>

      {/* Search bar */}
      <div style={{ padding: '6px 16px 10px' }}>
        <div style={{
          background: WHY.card, borderRadius: 12, padding: '11px 14px',
          fontSize: 13.5, color: WHY.faint,
          boxShadow: '0 0 0 0.5px rgba(60,40,20,0.07)',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <circle cx="6" cy="6" r="4" stroke={WHY.faint} strokeWidth="1.4"/>
            <line x1="9.5" y1="9.5" x2="12.5" y2="12.5" stroke={WHY.faint} strokeWidth="1.4" strokeLinecap="round"/>
          </svg>
          Search activities
        </div>
      </div>

      {/* The cached banner — the actual point of this artboard */}
      <div style={{
        margin: '0 16px 12px', padding: '10px 12px',
        background: WHY.amberSoft, borderRadius: 10,
        display: 'flex', alignItems: 'center', gap: 10,
        boxShadow: `0 0 0 0.5px ${WHY.amber}`,
      }}>
        <div style={{
          width: 24, height: 24, borderRadius: 12, flexShrink: 0,
          background: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 0 0 1px ${WHY.amber}`,
        }}>
          <CloudOffGlyph color={WHY.amber}/>
        </div>
        <div style={{ flex: 1, minWidth: 0, fontSize: 12, color: WHY.amberInk, lineHeight: 1.35 }}>
          <strong style={{ fontWeight: 700 }}>Showing cached results</strong>
          <span style={{ color: WHY.muted }}> · last updated 2 hours ago</span>
        </div>
        <div style={{
          fontSize: 11, fontWeight: 700, color: WHY.amberInk,
          background: '#fff', padding: '5px 9px', borderRadius: 100,
          boxShadow: `0 0 0 0.5px ${WHY.amber}`,
          flexShrink: 0,
        }}>Retry</div>
      </div>

      {/* Sort row */}
      <div style={{ padding: '4px 20px 6px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 11.5, color: WHY.muted, fontWeight: 600 }}>
          24 activities cached
        </div>
        <div style={{ fontSize: 12, color: WHY.muted, display: 'flex', alignItems: 'center', gap: 4 }}>
          Sorted by best match
          <InfoGlyph color={WHY.faint}/>
        </div>
      </div>

      {/* Cached rows — dimmed slightly to signal stale */}
      <div style={{ padding: '4px 14px' }}>
        {list.map((a, i) => {
          const m = M[a.category] || { hue: 60 };
          return (
            <div key={a.id || i} style={{
              display: 'flex', gap: 10, padding: 10,
              background: WHY.card, borderRadius: 12, marginBottom: 6,
              boxShadow: '0 0 0 0.5px rgba(60,40,20,0.05)',
              opacity: 0.92,
            }}>
              <div style={{
                width: 40, height: 40, borderRadius: 9, flexShrink: 0,
                background: `oklch(0.92 0.07 ${m.hue})`,
                color: `oklch(0.32 0.13 ${m.hue})`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, fontWeight: 700, letterSpacing: 0.3,
              }}>{(m.short || a.category).slice(0,3).toUpperCase()}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6, alignItems: 'baseline' }}>
                  <div style={{
                    fontSize: 13.5, fontWeight: 600, color: WHY.ink,
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                  }}>{a.name}</div>
                  <div style={{
                    fontSize: 12, fontWeight: 600, color: WHY.muted,
                    fontVariantNumeric: 'tabular-nums', flexShrink: 0,
                  }}>${a.priceRes}</div>
                </div>
                <div style={{ fontSize: 11.5, color: WHY.muted, marginTop: 3 }}>
                  {a.venueShort} · {a.distance ? a.distance.toFixed(1) : '–'} mi
                </div>
                <div style={{
                  fontSize: 10, color: WHY.faint, marginTop: 4,
                  display: 'inline-flex', alignItems: 'center', gap: 4,
                }}>
                  <span style={{ width: 6, height: 6, borderRadius: 3, background: WHY.amber }}/>
                  Availability may have changed
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <V5TabBar tab="Browse" setTab={() => {}}/>
    </div>
  );
}

function CloudOffGlyph({ color }) {
  return (
    <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
      <path d="M3 8.5c-1.4 0-2.5-1.1-2.5-2.5S1.6 3.5 3 3.5h.4C3.7 2 5 1 6.5 1 8.4 1 10 2.6 10 4.5l0 .1c.2-.1.4-.1.7-.1 1.2 0 2.3 1 2.3 2.3S11.9 9 10.7 9H4"
        stroke={color} strokeWidth="1.3" strokeLinecap="round"/>
      <line x1="2" y1="2" x2="11" y2="11" stroke={color} strokeWidth="1.5" strokeLinecap="round"/>
    </svg>
  );
}

window.V5WhyThis = V5WhyThis;
window.V5BrowseCached = V5BrowseCached;
