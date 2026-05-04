// V5 — Co-parent sync via shareable code.
//
// Three screens:
//   - V5ShareCode      — generate side (your code, QR, what syncs)
//   - V5EnterCode      — join side (3 word inputs, preview, confirm)
//   - V5LinkedSettings — settings showing the linked state
//
// Code format is 3 lowercase words from a kid-friendly list + 2-digit
// suffix: e.g. "maple-otter-39". Easier to read aloud than alphanumeric.

const SHARE_PALETTE = {
  bg: '#FBF7F1',
  ink: '#26201A',
  muted: '#7A6D5C',
  faint: '#A89B86',
  hairline: 'rgba(60,40,20,0.08)',
  card: '#fff',
  accent: 'oklch(0.55 0.13 22)',     // warm rust
  accentSoft: 'oklch(0.94 0.05 22)',
  partner: 'oklch(0.55 0.14 250)',   // cool blue for the OTHER parent
  partnerSoft: 'oklch(0.94 0.05 250)',
};

// ---------------------------------------------------------------------------
// 1. SHARE CODE  — the "send this to your co-parent" sheet.

function V5ShareCode() {
  const code = ['maple', 'otter', '39'];
  const kids = (window.KIDS || []).slice(0, 2);

  return (
    <div style={shareScreenStyle()}>
      {/* Top: dismiss handle */}
      <div style={{ paddingTop: 56, padding: '60px 0 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: 'rgba(60,40,20,0.18)' }}/>
      </div>

      <div style={{ padding: '20px 24px 14px' }}>
        <div style={shareEyebrowStyle(SHARE_PALETTE.accent)}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: SHARE_PALETTE.accent }}/>
          Plan together
        </div>
        <div style={shareTitleStyle()}>Share your list with<br/>another parent.</div>
        <div style={shareSubtitleStyle()}>
          They’ll enter this code on their phone and you’ll both see the same Saved
          activities, calendar, and kids — in real time.
        </div>
      </div>

      {/* Code card */}
      <div style={{
        margin: '4px 16px 16px', padding: '22px 18px 18px',
        background: SHARE_PALETTE.card, borderRadius: 18,
        boxShadow: '0 2px 12px rgba(60,40,20,0.06), 0 0 0 0.5px rgba(60,40,20,0.06)',
        textAlign: 'center',
      }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase',
          color: SHARE_PALETTE.faint, marginBottom: 10,
        }}>Your code</div>
        <div style={{
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
          fontSize: 26, fontWeight: 700, letterSpacing: -0.5,
          color: SHARE_PALETTE.ink, marginBottom: 4,
          display: 'flex', justifyContent: 'center', alignItems: 'baseline', gap: 4,
        }}>
          <CodeWord w={code[0]}/>
          <span style={{ color: SHARE_PALETTE.faint }}>–</span>
          <CodeWord w={code[1]}/>
          <span style={{ color: SHARE_PALETTE.faint }}>–</span>
          <CodeWord w={code[2]}/>
        </div>
        <div style={{
          fontSize: 11.5, color: SHARE_PALETTE.muted, marginTop: 6,
        }}>Expires in 24 hours · single use</div>

        {/* Action row — just the two actions parents actually use */}
        <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
          <ActionPill icon="copy" label="Copy code" filled/>
          <ActionPill icon="share" label="Send via…"/>
        </div>
      </div>

      {/* What syncs */}
      <div style={{ padding: '0 20px 6px' }}>
        <div style={shareSectionLabelStyle()}>What you’ll share</div>
      </div>
      <div style={{
        margin: '0 16px 12px', background: SHARE_PALETTE.card, borderRadius: 12,
        boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <SyncRow icon={<KidIconBubble/>}
          label="Kids" value={kids.length ? kids.map(k => `${k.name} (${k.ageYears})`).join(', ') : 'Maya (4), Leo (7)'}/>
        <SyncRow icon={<HeartIcon/>}
          label="Saved activities" value="3 saved · hearts sync both ways"/>
        <SyncRow icon={<CalIcon/>}
          label="Calendar" value="Confirmed registrations show on both devices" last/>
      </div>

      {/* What stays private */}
      <div style={{ padding: '0 20px 6px' }}>
        <div style={shareSectionLabelStyle()}>Stays on your phone</div>
      </div>
      <div style={{
        margin: '0 16px 16px', padding: '12px 14px',
        background: 'rgba(60,40,20,0.03)', borderRadius: 12,
        fontSize: 12.5, color: SHARE_PALETTE.muted, lineHeight: 1.5,
      }}>
        Filters, location, and search history are device-local. We don’t make
        accounts — the code is the only link.
      </div>

      {/* Footer help */}
      <div style={{
        padding: '0 20px 30px', textAlign: 'center',
        fontSize: 12, color: SHARE_PALETTE.muted,
      }}>
        Need to undo this? <span style={{ color: SHARE_PALETTE.accent, fontWeight: 600 }}>Manage in Settings</span>
      </div>
    </div>
  );
}

function CodeWord({ w }) {
  return <span style={{ color: SHARE_PALETTE.ink }}>{w}</span>;
}

function ActionPill({ icon, label, filled }) {
  return (
    <div style={{
      flex: 1, padding: '10px 8px', borderRadius: 10,
      background: filled ? SHARE_PALETTE.accent : 'rgba(60,40,20,0.05)',
      color: filled ? '#fff' : SHARE_PALETTE.ink,
      fontSize: 12.5, fontWeight: 600,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
    }}>
      <PillIcon kind={icon} color={filled ? '#fff' : SHARE_PALETTE.ink}/>
      {label}
    </div>
  );
}

function PillIcon({ kind, color }) {
  if (kind === 'copy') return (
    <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
      <rect x="3.5" y="3.5" width="7" height="8" rx="1.3" stroke={color} strokeWidth="1.4"/>
      <path d="M5.5 3.5V2a1 1 0 011-1h4a1 1 0 011 1v6a1 1 0 01-1 1H10" stroke={color} strokeWidth="1.4"/>
    </svg>
  );
  if (kind === 'share') return (
    <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
      <path d="M6.5 1v8M3.5 4l3-3 3 3M2 8v3a1 1 0 001 1h7a1 1 0 001-1V8" stroke={color} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
  if (kind === 'qr') return (
    <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
      <rect x="1" y="1" width="4" height="4" rx="0.5" stroke={color} strokeWidth="1.2"/>
      <rect x="8" y="1" width="4" height="4" rx="0.5" stroke={color} strokeWidth="1.2"/>
      <rect x="1" y="8" width="4" height="4" rx="0.5" stroke={color} strokeWidth="1.2"/>
      <rect x="9" y="9" width="2" height="2" fill={color}/>
      <rect x="7" y="7" width="1.2" height="1.2" fill={color}/>
      <rect x="11.5" y="7" width="1" height="1" fill={color}/>
    </svg>
  );
  return null;
}

function SyncRow({ icon, label, value, last }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
      borderBottom: last ? 'none' : '0.5px solid rgba(60,40,20,0.07)',
    }}>
      <div style={{ flexShrink: 0 }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: SHARE_PALETTE.ink, lineHeight: 1.2 }}>{label}</div>
        <div style={{ fontSize: 11.5, color: SHARE_PALETTE.muted, marginTop: 1 }}>{value}</div>
      </div>
      <div style={{
        width: 18, height: 18, borderRadius: 9,
        background: SHARE_PALETTE.accent,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
          <path d="M2 5l2 2 4-4" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </div>
  );
}

function KidIconBubble() {
  return (
    <div style={iconBubbleStyle('oklch(0.94 0.05 22)')}>
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <circle cx="5" cy="5" r="2" stroke="oklch(0.5 0.13 22)" strokeWidth="1.4"/>
        <circle cx="10" cy="6" r="1.5" stroke="oklch(0.5 0.13 22)" strokeWidth="1.4"/>
        <path d="M2 12c0-1.7 1.3-3 3-3s3 1.3 3 3M9 12c0-1.4 1-2.5 2-2.5s2 1.1 2 2.5"
          stroke="oklch(0.5 0.13 22)" strokeWidth="1.4" strokeLinecap="round"/>
      </svg>
    </div>
  );
}


function HeartIcon() {
  return (
    <div style={iconBubbleStyle('oklch(0.95 0.06 350)')}>
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <path d="M7 12s-5-3.2-5-7a3 3 0 015-2.2A3 3 0 0112 5c0 3.8-5 7-5 7z"
          fill="oklch(0.55 0.18 350)"/>
      </svg>
    </div>
  );
}

function CalIcon() {
  return (
    <div style={iconBubbleStyle('oklch(0.95 0.06 145)')}>
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <rect x="2" y="3" width="10" height="9" rx="1.5" stroke="oklch(0.45 0.13 145)" strokeWidth="1.4"/>
        <line x1="2" y1="6" x2="12" y2="6" stroke="oklch(0.45 0.13 145)" strokeWidth="1.4"/>
        <line x1="5" y1="2" x2="5" y2="4" stroke="oklch(0.45 0.13 145)" strokeWidth="1.4" strokeLinecap="round"/>
        <line x1="9" y1="2" x2="9" y2="4" stroke="oklch(0.45 0.13 145)" strokeWidth="1.4" strokeLinecap="round"/>
      </svg>
    </div>
  );
}

function iconBubbleStyle(bg) {
  return {
    width: 30, height: 30, borderRadius: 15, background: bg,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  };
}

// ---------------------------------------------------------------------------
// 2. ENTER CODE  — the join side.

function V5EnterCode({ state = 'preview' }) {
  // states: 'empty' (start), 'typing' (one word filled), 'preview' (all 3 filled, showing the link preview),
  // 'success' (animated success). Default to 'preview' since that's the most informative artboard.
  const isPreview = state === 'preview' || state === 'success';
  const words = isPreview ? ['maple', 'otter', '39']
              : state === 'typing' ? ['maple', '', '']
              : ['', '', ''];

  return (
    <div style={shareScreenStyle()}>
      {/* Header */}
      <div style={{
        paddingTop: 56, padding: '56px 20px 4px',
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 15,
          background: 'rgba(60,40,20,0.06)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
            <path d="M8 2L3.5 6.5 8 11" stroke={SHARE_PALETTE.ink} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 14.5, fontWeight: 600, color: SHARE_PALETTE.ink }}>Link a co-parent</div>
      </div>

      <div style={{ padding: '14px 24px 16px' }}>
        <div style={shareEyebrowStyle(SHARE_PALETTE.partner)}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: SHARE_PALETTE.partner }}/>
          Got a code?
        </div>
        <div style={shareTitleStyle()}>Type the code your<br/>partner shared.</div>
        <div style={shareSubtitleStyle()}>
          Three short words and a number. They’ll see your kids and saves the
          moment you confirm.
        </div>
      </div>

      {/* Word inputs */}
      <div style={{ padding: '6px 18px 14px' }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 10 }}>
          <WordInput value={words[0]} placeholder="word" focused={state === 'empty'} flex={1.4}/>
          <span style={{ color: SHARE_PALETTE.faint, fontSize: 18 }}>–</span>
          <WordInput value={words[1]} placeholder="word" focused={state === 'typing'} flex={1.4}/>
          <span style={{ color: SHARE_PALETTE.faint, fontSize: 18 }}>–</span>
          <WordInput value={words[2]} placeholder="##" flex={0.7} numeric/>
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: '0 4px',
        }}>
          <div style={{
            fontSize: 11.5, color: SHARE_PALETTE.muted,
            display: 'flex', alignItems: 'center', gap: 5,
          }}>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
              <rect x="1.5" y="1.5" width="8" height="8" rx="1" stroke={SHARE_PALETTE.muted} strokeWidth="1.2"/>
              <path d="M3.5 1.5V0.5a0.5 0.5 0 01.5-.5h3a0.5 0.5 0 01.5.5v1" stroke={SHARE_PALETTE.muted} strokeWidth="1.2"/>
            </svg>
            Paste full code instead
          </div>
        </div>
      </div>

      {/* Link preview — only show when 3 words are filled */}
      {isPreview && <LinkPreview/>}

      {/* Sticky CTA */}
      <div style={{
        position: 'sticky', bottom: 0, marginTop: 'auto',
        padding: '14px 20px 30px',
        background: 'linear-gradient(180deg, transparent 0%, #FBF7F1 30%)',
      }}>
        <div style={{
          background: isPreview ? SHARE_PALETTE.partner : 'rgba(60,40,20,0.12)',
          color: '#fff',
          padding: '14px 18px', borderRadius: 14,
          fontSize: 15, fontWeight: 700, textAlign: 'center',
          boxShadow: isPreview ? '0 4px 12px oklch(0.55 0.14 250 / 0.25)' : 'none',
        }}>
          {isPreview ? 'Confirm — link with Sam' : 'Enter code'}
        </div>
        <div style={{ textAlign: 'center', marginTop: 10, fontSize: 12, color: SHARE_PALETTE.muted }}>
          Don’t have a code? <span style={{ color: SHARE_PALETTE.partner, fontWeight: 600 }}>Generate one instead</span>
        </div>
      </div>
    </div>
  );
}

function WordInput({ value, placeholder, focused, flex = 1, numeric }) {
  const isEmpty = !value;
  return (
    <div style={{
      flex,
      padding: '14px 10px',
      background: SHARE_PALETTE.card,
      borderRadius: 12,
      border: focused ? `1.5px solid ${SHARE_PALETTE.partner}`
            : value     ? '1.5px solid rgba(60,40,20,0.12)'
            :             '1.5px solid rgba(60,40,20,0.08)',
      textAlign: 'center',
      fontFamily: numeric ? 'ui-monospace, "SF Mono", Menlo, monospace'
                          : '-apple-system, system-ui',
      fontSize: numeric ? 18 : 16,
      fontWeight: 600,
      color: isEmpty ? SHARE_PALETTE.faint : SHARE_PALETTE.ink,
      letterSpacing: numeric ? 1 : -0.2,
      position: 'relative',
      boxShadow: focused ? `0 0 0 4px oklch(0.55 0.14 250 / 0.12)` : 'none',
      transition: 'box-shadow 120ms',
    }}>
      {value || placeholder}
      {focused && (
        <span style={{
          display: 'inline-block', width: 1.5, height: 16,
          background: SHARE_PALETTE.partner,
          marginLeft: 2, verticalAlign: 'middle',
          animation: 'caret-blink 1s step-end infinite',
        }}/>
      )}
      <style>{`
        @keyframes caret-blink {
          50% { opacity: 0; }
        }
      `}</style>
    </div>
  );
}

function LinkPreview() {
  return (
    <div style={{
      margin: '4px 16px 16px',
      padding: '14px 16px',
      background: SHARE_PALETTE.card,
      borderRadius: 14,
      boxShadow: '0 1px 3px rgba(60,40,20,0.05), 0 0 0 0.5px rgba(60,40,20,0.06)',
    }}>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
        color: SHARE_PALETTE.faint, marginBottom: 10,
      }}>You’ll be linking with</div>

      {/* Partner card */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 22,
          background: SHARE_PALETTE.partner, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 17, fontWeight: 700,
        }}>S</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 600, color: SHARE_PALETTE.ink }}>Sam</div>
          <div style={{ fontSize: 12, color: SHARE_PALETTE.muted, marginTop: 1 }}>
            iPhone · Chicago, IL
          </div>
        </div>
      </div>

      {/* What you'll combine */}
      <div style={{
        background: SHARE_PALETTE.partnerSoft, borderRadius: 10,
        padding: '10px 12px', display: 'grid', gap: 6,
      }}>
        <PreviewLine n={2} label="kids combined" detail="(Maya, Leo + Sam’s)"/>
        <PreviewLine n={5} label="saved activities combined" detail="(3 yours + 2 Sam’s)"/>
        <PreviewLine n={1} label="overlap" detail='("CPD T-Ball" — we’ll merge it)'/>
      </div>
    </div>
  );
}

function PreviewLine({ n, label, detail }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, fontSize: 12.5, color: SHARE_PALETTE.ink }}>
      <span style={{
        fontVariantNumeric: 'tabular-nums', fontWeight: 700,
        color: SHARE_PALETTE.partner, minWidth: 14, textAlign: 'right',
      }}>{n}</span>
      <span style={{ flex: 1 }}>
        <span style={{ fontWeight: 500 }}>{label}</span>{' '}
        <span style={{ color: SHARE_PALETTE.muted }}>{detail}</span>
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// 3. LINKED STATE  — the settings row showing "you + Sam are sharing".

function V5LinkedSettings() {
  return (
    <div style={shareScreenStyle()}>
      {/* Top bar */}
      <div style={{
        paddingTop: 56, padding: '56px 20px 4px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 15,
          background: 'rgba(60,40,20,0.06)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
            <path d="M8 2L3.5 6.5 8 11" stroke={SHARE_PALETTE.ink} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 14.5, fontWeight: 600, color: SHARE_PALETTE.ink }}>Settings</div>
        <div style={{ width: 30 }}/>
      </div>

      <div style={{ padding: '14px 24px 4px' }}>
        <div style={{ ...shareTitleStyle(), fontSize: 28 }}>You + Sam</div>
        <div style={shareSubtitleStyle()}>
          You’re planning together. Changes show up on both phones within a few seconds.
        </div>
      </div>

      {/* The big partner card — hero of this screen */}
      <div style={{
        margin: '14px 16px 16px',
        padding: '18px 18px 16px',
        background: SHARE_PALETTE.card,
        borderRadius: 18,
        boxShadow: '0 2px 12px rgba(60,40,20,0.05), 0 0 0 0.5px rgba(60,40,20,0.06)',
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Decorative connector */}
        <PartnerHero/>

        {/* Stats row */}
        <div style={{
          marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 0,
          borderTop: '0.5px solid rgba(60,40,20,0.08)', paddingTop: 12,
        }}>
          <Stat n="2" label="kids"/>
          <Stat n="3" label="saved" divider/>
          <Stat n="2" label="upcoming" divider/>
        </div>
      </div>

      {/* Sync activity log */}
      <div style={{ padding: '0 20px 6px' }}>
        <div style={shareSectionLabelStyle()}>Recent activity</div>
      </div>
      <div style={{
        margin: '0 16px 16px', background: SHARE_PALETTE.card, borderRadius: 12,
        boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <LogRow who="Sam" when="2 min ago" what="saved" target='"Toddler Soccer — Sat 9am"'/>
        <LogRow who="You" when="1 hr ago" what="confirmed" target='"CPD T-Ball" · Maya'/>
        <LogRow who="Sam" when="Yesterday" what="added" target="Henry (3 yr)" last/>
      </div>

      {/* Manage row */}
      <div style={{
        margin: '0 16px 12px', background: SHARE_PALETTE.card, borderRadius: 12,
        boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <ManageRow icon="code" label="Get a new code" detail="If your code expired or got out"/>
        <ManageRow icon="device" label="Sam’s device" detail="iPhone 15 · added Mar 12"/>
        <ManageRow icon="unlink" label="Unlink Sam" detail="Stops sharing on both phones" danger last/>
      </div>

      <div style={{
        padding: '0 24px 30px', textAlign: 'center',
        fontSize: 11.5, color: SHARE_PALETTE.muted, lineHeight: 1.5,
      }}>
        Linked devices share Saved, Calendar, and Kids. Filters and search history stay on each device.
      </div>
    </div>
  );
}

function PartnerHero() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, position: 'relative' }}>
      <div style={{ display: 'flex', alignItems: 'center', flexDirection: 'column', gap: 6 }}>
        <div style={{
          width: 52, height: 52, borderRadius: 26,
          background: SHARE_PALETTE.accent, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 19, fontWeight: 700,
          boxShadow: '0 0 0 3px #fff, 0 0 0 4px rgba(60,40,20,0.06)',
        }}>A</div>
        <div style={{ fontSize: 12, fontWeight: 600, color: SHARE_PALETTE.ink }}>You</div>
      </div>

      {/* Animated link */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, paddingBottom: 18 }}>
        <div style={{
          fontSize: 10.5, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
          color: SHARE_PALETTE.muted,
        }}>linked</div>
        <svg width="80" height="14" viewBox="0 0 80 14" fill="none" style={{ overflow: 'visible' }}>
          <line x1="0" y1="7" x2="80" y2="7" stroke="rgba(60,40,20,0.12)" strokeWidth="1.5" strokeDasharray="3 3"/>
          {/* moving dot */}
          <circle r="3" fill={SHARE_PALETTE.accent}>
            <animate attributeName="cx" from="0" to="80" dur="2.5s" repeatCount="indefinite"/>
          </circle>
        </svg>
        <div style={{
          fontSize: 10.5, fontWeight: 600, color: SHARE_PALETTE.partner,
          fontVariantNumeric: 'tabular-nums',
        }}>last sync · now</div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', flexDirection: 'column', gap: 6 }}>
        <div style={{
          width: 52, height: 52, borderRadius: 26,
          background: SHARE_PALETTE.partner, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 19, fontWeight: 700,
          boxShadow: '0 0 0 3px #fff, 0 0 0 4px rgba(60,40,20,0.06)',
        }}>S</div>
        <div style={{ fontSize: 12, fontWeight: 600, color: SHARE_PALETTE.ink }}>Sam</div>
      </div>
    </div>
  );
}

function Stat({ n, label, divider }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      borderLeft: divider ? '0.5px solid rgba(60,40,20,0.08)' : 'none',
      padding: '4px 0',
    }}>
      <div style={{
        fontSize: 22, fontWeight: 700, letterSpacing: -0.5,
        color: SHARE_PALETTE.ink, fontVariantNumeric: 'tabular-nums',
      }}>{n}</div>
      <div style={{
        fontSize: 11, fontWeight: 600, letterSpacing: 0.3, textTransform: 'uppercase',
        color: SHARE_PALETTE.faint, marginTop: 2,
      }}>{label}</div>
    </div>
  );
}

function LogRow({ who, when, what, target, last }) {
  const youColor = who === 'You' ? SHARE_PALETTE.accent : SHARE_PALETTE.partner;
  const initial = who === 'You' ? 'A' : 'S';
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 10, padding: '10px 14px',
      borderBottom: last ? 'none' : '0.5px solid rgba(60,40,20,0.07)',
    }}>
      <div style={{
        width: 22, height: 22, borderRadius: 11, flexShrink: 0,
        background: youColor, color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 10, fontWeight: 700,
      }}>{initial}</div>
      <div style={{ flex: 1, fontSize: 12.5, color: SHARE_PALETTE.ink, lineHeight: 1.4 }}>
        <span style={{ fontWeight: 600, color: youColor }}>{who}</span>{' '}
        <span style={{ color: SHARE_PALETTE.muted }}>{what}</span>{' '}
        <span style={{ fontWeight: 500 }}>{target}</span>
      </div>
      <div style={{ fontSize: 11, color: SHARE_PALETTE.faint, fontVariantNumeric: 'tabular-nums', flexShrink: 0 }}>
        {when}
      </div>
    </div>
  );
}

function ManageRow({ icon, label, detail, danger, last }) {
  const color = danger ? 'oklch(0.5 0.18 25)' : SHARE_PALETTE.ink;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px',
      borderBottom: last ? 'none' : '0.5px solid rgba(60,40,20,0.07)',
    }}>
      <ManageIcon kind={icon} danger={danger}/>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color }}>{label}</div>
        <div style={{ fontSize: 11.5, color: SHARE_PALETTE.muted, marginTop: 1 }}>{detail}</div>
      </div>
      <svg width="7" height="11" viewBox="0 0 7 11" fill="none">
        <path d="M1 1l4.5 4.5L1 10" stroke={SHARE_PALETTE.faint} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </div>
  );
}

function ManageIcon({ kind, danger }) {
  const bg = danger ? 'oklch(0.95 0.05 25)' : 'rgba(60,40,20,0.05)';
  const stroke = danger ? 'oklch(0.5 0.18 25)' : SHARE_PALETTE.ink;
  return (
    <div style={{
      width: 30, height: 30, borderRadius: 9, background: bg,
      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
    }}>
      {kind === 'code' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <rect x="2" y="3.5" width="10" height="7" rx="1.5" stroke={stroke} strokeWidth="1.4"/>
          <line x1="4" y1="6" x2="4" y2="8" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
          <line x1="7" y1="6" x2="7" y2="8" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
          <line x1="10" y1="6" x2="10" y2="8" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
        </svg>
      )}
      {kind === 'device' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <rect x="3.5" y="1.5" width="7" height="11" rx="1.5" stroke={stroke} strokeWidth="1.4"/>
          <circle cx="7" cy="10.5" r="0.7" fill={stroke}/>
        </svg>
      )}
      {kind === 'unlink' && (
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M5 4H4a3 3 0 100 6h1M9 4h1a3 3 0 010 6H9" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
          <line x1="2" y1="12" x2="12" y2="2" stroke={stroke} strokeWidth="1.4" strokeLinecap="round"/>
        </svg>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// shared style helpers

function shareScreenStyle() {
  return {
    background: SHARE_PALETTE.bg, minHeight: '100%',
    paddingBottom: 30, fontFamily: '-apple-system, system-ui',
    color: SHARE_PALETTE.ink, display: 'flex', flexDirection: 'column',
  };
}
function shareEyebrowStyle(color) {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
    color, marginBottom: 8,
  };
}
function shareTitleStyle() {
  return { fontSize: 24, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.1, color: SHARE_PALETTE.ink };
}
function shareSubtitleStyle() {
  return { fontSize: 13, color: SHARE_PALETTE.muted, marginTop: 8, lineHeight: 1.45, textWrap: 'pretty' };
}
function shareSectionLabelStyle() {
  return {
    fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
    color: SHARE_PALETTE.faint, marginBottom: 8,
  };
}

window.V5ShareCode = V5ShareCode;
window.V5EnterCode = V5EnterCode;
window.V5LinkedSettings = V5LinkedSettings;
