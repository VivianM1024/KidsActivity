// V5 — Calendar with conflict detection + dedicated conflict-resolution sheet.
//
// Two artboards:
//   V5CalendarConflicts  — same calendar layout as V5Calendar, but two events
//                            on Saturday May 9 overlap (Leo's T-Ball 9:30–10:45
//                            and Maya's Storytime 11:00 was bumped to 10:00,
//                            creating a 15-min overlap + travel time issue).
//                            The day cell on the month strip gets a yellow
//                            ring; the day group header shows a "1 conflict"
//                            chip; the two cards visually share a stitched
//                            container with a warning rail.
//
//   V5ConflictSheet      — the resolution sheet you get when tapping the
//                            conflict chip. Shows both events side-by-side
//                            with a travel-time row in the middle, then
//                            three resolution options (skip one, move,
//                            keep both). Warm tone; explains the math.

const CFLT = {
  bg: '#FBF7F1',
  ink: '#26201A',
  muted: '#7A6D5C',
  faint: '#A89B86',
  card: '#fff',
  warn: 'oklch(0.62 0.14 70)',     // amber
  warnSoft: 'oklch(0.96 0.06 70)',
  warnInk: 'oklch(0.42 0.14 70)',
};

// ---------------------------------------------------------------------------

function V5CalendarConflicts({ activities }) {
  const events = [
    { id: 'e1', date: '2026-05-09', start: '09:30', end: '10:45', activityId: 'cpd-tball-1',     kidId: 'leo',  loc: 'Welles Park' },
    { id: 'e2', date: '2026-05-09', start: '10:00', end: '10:45', activityId: 'cpl-storytime-1', kidId: 'nora', loc: 'Sulzer Library' },
    { id: 'e3', date: '2026-05-16', start: '09:30', end: '10:45', activityId: 'cpd-tball-1',     kidId: 'leo',  loc: 'Welles Park' },
    { id: 'e4', date: '2026-05-17', start: '10:00', end: '12:00', activityId: 'np-truck-12',     kidId: 'maya', loc: 'Notebaert' },
  ];
  // Compute conflicts per day. Two events conflict if their windows overlap.
  const byDay = {};
  for (const e of events) (byDay[e.date] ||= []).push(e);
  const conflictDays = new Set();
  for (const [d, list] of Object.entries(byDay)) {
    for (let i = 0; i < list.length; i++) for (let j = i+1; j < list.length; j++) {
      if (overlap(list[i], list[j])) conflictDays.add(d);
    }
  }

  const today = '2026-05-04';
  const sortedDates = Object.keys(byDay).sort();

  return (
    <div style={{
      background: CFLT.bg, minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: CFLT.ink,
    }}>
      {/* Header */}
      <div style={{
        paddingTop: 56, padding: '56px 20px 8px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontSize: 11, color: 'oklch(0.55 0.05 60)', fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 4 }}>
            4 upcoming · <span style={{ color: CFLT.warnInk }}>1 conflict</span>
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.6, lineHeight: 1.05 }}>
            May 2026
          </div>
        </div>
      </div>

      {/* Month strip with conflict ring on Sat 9 */}
      <div style={{
        margin: '8px 16px 0', padding: '12px 12px 10px',
        background: CFLT.card, borderRadius: 14,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2,
          fontSize: 9, fontWeight: 700, color: '#A89B86',
          textTransform: 'uppercase', letterSpacing: 0.4,
          textAlign: 'center', marginBottom: 6,
        }}>
          {['S','M','T','W','T','F','S'].map((d, i) => <div key={i}>{d}</div>)}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2 }}>
          {Array.from({ length: 5 }).map((_, i) => <div key={`p${i}`} />)}
          {Array.from({ length: 31 }).map((_, idx) => {
            const d = idx + 1;
            const iso = `2026-05-${String(d).padStart(2, '0')}`;
            const hasEvent = !!byDay[iso];
            const isConflict = conflictDays.has(iso);
            const isToday = iso === today;
            return (
              <div key={d} style={{
                aspectRatio: '1 / 1', position: 'relative',
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                gap: 1,
                borderRadius: 8,
                background: isToday ? 'oklch(0.55 0.13 22)'
                          : isConflict ? CFLT.warnSoft
                          : 'transparent',
                color: isToday ? '#fff' : hasEvent ? CFLT.ink : CFLT.faint,
                fontWeight: hasEvent || isToday ? 700 : 500,
                fontSize: 12, fontVariantNumeric: 'tabular-nums',
                boxShadow: isConflict && !isToday ? `inset 0 0 0 1.5px ${CFLT.warn}` : 'none',
              }}>
                {d}
                <div style={{
                  width: 4, height: 4, borderRadius: 2,
                  background: isToday ? '#fff'
                            : isConflict ? CFLT.warn
                            : hasEvent ? 'oklch(0.6 0.15 145)'
                            : 'transparent',
                }}/>
              </div>
            );
          })}
        </div>
        {/* Mini legend */}
        <div style={{
          marginTop: 8, paddingTop: 8, borderTop: '0.5px solid rgba(60,40,20,0.07)',
          display: 'flex', gap: 12, fontSize: 10, color: CFLT.muted,
          alignItems: 'center', justifyContent: 'center',
        }}>
          <Legend dot="oklch(0.6 0.15 145)" label="Scheduled"/>
          <Legend dot={CFLT.warn} ring label="Conflict"/>
          <Legend dot="#fff" filled="oklch(0.55 0.13 22)" label="Today"/>
        </div>
      </div>

      {/* Day groups */}
      <div style={{ marginTop: 12, padding: '0 16px' }}>
        {sortedDates.map((iso) => (
          <DayBlock
            key={iso}
            iso={iso}
            events={byDay[iso]}
            activities={activities}
            isConflict={conflictDays.has(iso)}
          />
        ))}
      </div>

      <V5TabBar tab="Calendar" setTab={() => {}}/>
    </div>
  );
}

function Legend({ dot, ring, filled, label }) {
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
      <span style={{
        width: 8, height: 8, borderRadius: 4,
        background: filled || dot,
        boxShadow: ring ? `inset 0 0 0 1.5px ${dot}` : 'none',
        border: filled ? `1.5px solid ${filled}` : 'none',
      }}/>
      {label}
    </span>
  );
}

function DayBlock({ iso, events, activities, isConflict }) {
  const dt = new Date(iso + 'T00:00:00');
  const dayName = dt.toLocaleDateString('en-US', { weekday: 'long' });
  const dateLabel = dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{
        display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 8,
      }}>
        <div style={{
          fontSize: 22, fontWeight: 700, letterSpacing: -0.4, color: CFLT.ink,
          fontVariantNumeric: 'tabular-nums',
        }}>{dt.getDate()}</div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, color: CFLT.ink, lineHeight: 1.1 }}>{dayName}</div>
          <div style={{ fontSize: 11, color: CFLT.faint }}>{dateLabel}</div>
        </div>
        <div style={{ flex: 1, height: 1, background: 'rgba(60,40,20,0.08)', marginBottom: 4 }}/>
        {isConflict ? (
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 5,
            fontSize: 10.5, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase',
            color: CFLT.warnInk, background: CFLT.warnSoft,
            padding: '3px 8px', borderRadius: 100,
          }}>
            <WarnGlyph color={CFLT.warn} size={10}/>
            1 conflict
          </div>
        ) : (
          <div style={{ fontSize: 11, color: CFLT.faint, fontVariantNumeric: 'tabular-nums' }}>
            {events.length} event{events.length === 1 ? '' : 's'}
          </div>
        )}
      </div>

      {isConflict ? (
        <ConflictGroup events={events} activities={activities}/>
      ) : (
        events.map((e) => <SingleEvent key={e.id} e={e} activities={activities}/>)
      )}
    </div>
  );
}

function ConflictGroup({ events, activities }) {
  return (
    <div style={{ position: 'relative', paddingLeft: 10 }}>
      {/* Warning rail — connects both events */}
      <div style={{
        position: 'absolute', left: 0, top: 14, bottom: 14, width: 3,
        borderRadius: 2, background: CFLT.warn,
      }}/>
      <div style={{
        background: CFLT.warnSoft, borderRadius: 14, padding: '8px 8px 6px',
        boxShadow: `0 0 0 0.5px ${CFLT.warn}`,
      }}>
        {/* Banner */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px 8px',
        }}>
          <WarnGlyph color={CFLT.warn} size={14}/>
          <div style={{ flex: 1, fontSize: 12, color: CFLT.warnInk, lineHeight: 1.35 }}>
            <strong style={{ fontWeight: 700 }}>15-min overlap</strong>{' — '}
            and Welles Park → Sulzer is{' '}
            <strong style={{ fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>~12 min</strong>
            {' '}drive.
          </div>
          <div style={{
            fontSize: 11, fontWeight: 700, color: CFLT.warnInk,
            background: '#fff', padding: '4px 8px', borderRadius: 100,
            boxShadow: `0 0 0 0.5px ${CFLT.warn}`,
          }}>Resolve</div>
        </div>
        {events.map((e, i) => (
          <SingleEvent key={e.id} e={e} activities={activities} stitched={i === 0 ? 'top' : 'bottom'}/>
        ))}
      </div>
    </div>
  );
}

function SingleEvent({ e, activities, stitched }) {
  const a = activities.find((x) => x.id === e.activityId) || activities[0];
  const m = window.CATEGORY_META[a.category] || { hue: 60 };
  const kid = (window.KIDS || []).find((k) => k.id === e.kidId);
  const accentHue = kid ? kid.hue : m.hue;
  const time12 = (t) => {
    const [hh, mm] = t.split(':').map(Number);
    const h12 = ((hh + 11) % 12) + 1;
    return `${h12}:${String(mm).padStart(2,'0')} ${hh < 12 ? 'AM' : 'PM'}`;
  };
  return (
    <div style={{ display: 'flex', gap: 10, marginBottom: stitched === 'top' ? 4 : 6 }}>
      <div style={{ width: 56, flexShrink: 0, paddingTop: 10, textAlign: 'right' }}>
        <div style={{ fontSize: 12.5, fontWeight: 700, color: CFLT.ink, fontVariantNumeric: 'tabular-nums' }}>
          {time12(e.start)}
        </div>
        <div style={{ fontSize: 10, color: CFLT.faint }}>{minutesBetween(e.start, e.end)}m</div>
      </div>
      <div style={{
        flex: 1, background: '#fff', borderRadius: 12,
        boxShadow: '0 1px 2px rgba(60,40,20,0.03), 0 0 0 0.5px rgba(60,40,20,0.05)',
        padding: '10px 12px',
        borderLeft: `3px solid oklch(0.6 0.15 ${accentHue})`,
        display: 'flex', flexDirection: 'column', gap: 4,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {kid && (
            <span style={{
              width: 18, height: 18, borderRadius: 9,
              background: `oklch(0.6 0.14 ${kid.hue})`, color: '#fff',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 9.5, fontWeight: 700, flexShrink: 0,
            }}>{kid.initial}</span>
          )}
          <span style={{
            fontSize: 9.5, fontWeight: 700, letterSpacing: 0.4,
            color: `oklch(0.32 0.13 ${m.hue})`, background: `oklch(0.92 0.07 ${m.hue})`,
            padding: '2px 6px', borderRadius: 4, textTransform: 'uppercase',
          }}>{a.category}</span>
          <div style={{
            fontSize: 13, fontWeight: 600, color: CFLT.ink,
            flex: 1, minWidth: 0,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            letterSpacing: -0.2,
          }}>{a.name}</div>
        </div>
        <div style={{ fontSize: 11.5, color: CFLT.muted }}>
          {e.loc}
        </div>
      </div>
    </div>
  );
}

function WarnGlyph({ color, size = 12 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 12 12" fill="none">
      <path d="M6 1l5 9.5H1L6 1z" fill={color}/>
      <rect x="5.4" y="4.5" width="1.2" height="3" fill="#fff" rx="0.6"/>
      <circle cx="6" cy="9" r="0.7" fill="#fff"/>
    </svg>
  );
}

// ---------------------------------------------------------------------------
// CONFLICT RESOLUTION SHEET

function V5ConflictSheet({ activities }) {
  const aLeo = activities.find((x) => x.id === 'cpd-tball-1') || activities[0];
  const aNora = activities.find((x) => x.id === 'cpl-storytime-1') || activities[1];
  return (
    <div style={{
      background: CFLT.bg, minHeight: '100%',
      paddingBottom: 30, fontFamily: '-apple-system, system-ui',
      color: CFLT.ink, display: 'flex', flexDirection: 'column',
    }}>
      {/* Handle */}
      <div style={{ paddingTop: 56, padding: '60px 0 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: 'rgba(60,40,20,0.18)' }}/>
      </div>

      <div style={{ padding: '20px 24px 12px' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
          color: CFLT.warnInk, marginBottom: 8,
        }}>
          <WarnGlyph color={CFLT.warn} size={12}/>
          Saturday, May 9
        </div>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.1 }}>
          You can’t make both<br/>without rushing.
        </div>
        <div style={{ fontSize: 13, color: CFLT.muted, marginTop: 8, lineHeight: 1.45 }}>
          Two events overlap by 15 minutes — and the venues are 12 min apart by car.
          Here’s how parents usually handle this.
        </div>
      </div>

      {/* Stacked event timeline */}
      <div style={{
        margin: '4px 16px 14px', padding: '14px',
        background: CFLT.card, borderRadius: 14,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <Timeline aLeo={aLeo} aNora={aNora}/>
      </div>

      {/* Resolution options */}
      <div style={{ padding: '0 20px 6px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
          color: CFLT.faint, marginBottom: 8,
        }}>Pick one</div>
      </div>
      <div style={{
        margin: '0 16px 18px', display: 'flex', flexDirection: 'column', gap: 8,
      }}>
        <ResolveOption
          letter="A"
          title="Skip Storytime this week"
          detail="Library runs Storytime every Sat — Maya can do next weekend instead."
          tag="Easiest"
          tagColor="oklch(0.55 0.15 145)"
          recommended
        />
        <ResolveOption
          letter="B"
          title="Move Storytime to 11:30 AM session"
          detail="Library has a second session at 11:30. You'd arrive 5 min early."
          tag="Best for both"
          tagColor="oklch(0.55 0.15 250)"
        />
        <ResolveOption
          letter="C"
          title="Keep both, split with Sam"
          detail="Sam takes Maya to Storytime, you stay with Leo at T-Ball."
          tag="If linked"
          tagColor="oklch(0.55 0.13 290)"
        />
        <ResolveOption
          letter="D"
          title="Cancel one"
          detail="Free up Saturday entirely — unregisters from the venue."
          danger
        />
      </div>

      {/* Footer */}
      <div style={{
        marginTop: 'auto', padding: '0 20px 30px', textAlign: 'center',
        fontSize: 12, color: CFLT.muted,
      }}>
        Or <span style={{ color: 'oklch(0.55 0.13 22)', fontWeight: 600 }}>dismiss</span> — we’ll keep flagging it on the calendar.
      </div>
    </div>
  );
}

function Timeline({ aLeo, aNora }) {
  // 9:00 — 11:30 window. Each minute = 1.5px.
  const startMin = 9 * 60;
  const minToX = (m) => (m - startMin) * 1.5;
  const tballStart = minToX(9 * 60 + 30);
  const tballEnd = minToX(10 * 60 + 45);
  const storyStart = minToX(10 * 60);
  const storyEnd = minToX(10 * 60 + 45);
  const overlapStart = minToX(10 * 60);
  const overlapEnd = minToX(10 * 60 + 45);
  return (
    <div>
      {/* Hour markers */}
      <div style={{
        display: 'flex', justifyContent: 'space-between',
        fontSize: 10, fontWeight: 600, color: CFLT.faint,
        fontVariantNumeric: 'tabular-nums', marginBottom: 6,
        padding: '0 2px',
      }}>
        <span>9:00</span><span>9:30</span><span>10:00</span><span>10:30</span><span>11:00</span><span>11:30</span>
      </div>

      {/* Track 1: Leo */}
      <TrackRow
        kidName="Leo"
        kidHue={145}
        title={aLeo.name}
        venue="Welles Park"
        startX={tballStart}
        endX={tballEnd}
        timeLabel="9:30 – 10:45"
      />

      {/* Overlap stripe behind both */}
      <div style={{ position: 'relative', height: 12, margin: '6px 0' }}>
        <div style={{
          position: 'absolute', left: overlapStart, width: overlapEnd - overlapStart,
          top: 0, bottom: 0, background: CFLT.warnSoft,
          borderRadius: 4, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{
            fontSize: 9.5, fontWeight: 700, color: CFLT.warnInk, letterSpacing: 0.3,
            textTransform: 'uppercase',
          }}>Overlap 45m</span>
        </div>
      </div>

      {/* Track 2: Nora */}
      <TrackRow
        kidName="Nora"
        kidHue={350}
        title={aNora.name}
        venue="Sulzer Library"
        startX={storyStart}
        endX={storyEnd}
        timeLabel="10:00 – 10:45"
      />

      {/* Travel time row */}
      <div style={{
        marginTop: 12, paddingTop: 10, borderTop: '0.5px solid rgba(60,40,20,0.07)',
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 11.5, color: CFLT.muted,
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M3 9L7 1.5L11 9M5 7h4M2 12h10" stroke={CFLT.muted} strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
        <span>Welles Park → Sulzer Library</span>
        <span style={{ flex: 1, height: 1, background: 'rgba(60,40,20,0.08)' }}/>
        <span style={{
          fontWeight: 700, color: CFLT.warnInk, fontVariantNumeric: 'tabular-nums',
        }}>~12 min drive</span>
      </div>
    </div>
  );
}

function TrackRow({ kidName, kidHue, title, venue, startX, endX, timeLabel }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <div style={{
        width: 22, height: 22, borderRadius: 11,
        background: `oklch(0.6 0.14 ${kidHue})`, color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 10.5, fontWeight: 700, flexShrink: 0,
      }}>{kidName[0]}</div>
      <div style={{ flex: 1, position: 'relative', height: 28 }}>
        {/* Track baseline */}
        <div style={{
          position: 'absolute', left: 0, right: 0, top: 13, height: 2,
          background: 'rgba(60,40,20,0.06)', borderRadius: 1,
        }}/>
        {/* Bar */}
        <div style={{
          position: 'absolute', left: startX, width: endX - startX,
          top: 4, height: 20, borderRadius: 5,
          background: `oklch(0.6 0.14 ${kidHue})`,
          boxShadow: `0 1px 2px oklch(0.6 0.14 ${kidHue} / 0.3)`,
          display: 'flex', alignItems: 'center', justifyContent: 'flex-start',
          paddingLeft: 6, gap: 4, overflow: 'hidden',
          color: '#fff', fontSize: 10, fontWeight: 700,
          whiteSpace: 'nowrap',
        }}>
          {title.split(' ').slice(0, 2).join(' ')}
        </div>
      </div>
      <div style={{
        fontSize: 10.5, color: CFLT.muted, fontVariantNumeric: 'tabular-nums',
        whiteSpace: 'nowrap', flexShrink: 0,
      }}>{timeLabel}</div>
    </div>
  );
}

function ResolveOption({ letter, title, detail, tag, tagColor, recommended, danger }) {
  return (
    <div style={{
      background: recommended ? '#fff' : danger ? 'transparent' : '#fff',
      borderRadius: 12,
      padding: '12px 14px',
      boxShadow: recommended
        ? `0 0 0 1.5px oklch(0.55 0.15 145), 0 2px 8px oklch(0.55 0.15 145 / 0.12)`
        : `0 0 0 0.5px rgba(60,40,20,0.08)`,
      display: 'flex', gap: 12, alignItems: 'flex-start',
      opacity: danger ? 0.85 : 1,
    }}>
      <div style={{
        width: 26, height: 26, borderRadius: 13, flexShrink: 0,
        background: recommended ? 'oklch(0.55 0.15 145)'
                  : danger ? 'rgba(60,40,20,0.05)'
                  : 'rgba(60,40,20,0.05)',
        color: recommended ? '#fff' : CFLT.ink,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 12, fontWeight: 700,
      }}>{letter}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
          <div style={{
            fontSize: 13.5, fontWeight: 700, color: danger ? CFLT.muted : CFLT.ink,
            letterSpacing: -0.2,
          }}>{title}</div>
          {tag && (
            <div style={{
              fontSize: 9.5, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase',
              color: tagColor, padding: '2px 6px', borderRadius: 4,
              background: 'transparent',
              boxShadow: `inset 0 0 0 1px ${tagColor}`,
            }}>{tag}</div>
          )}
        </div>
        <div style={{ fontSize: 12, color: CFLT.muted, lineHeight: 1.4 }}>{detail}</div>
      </div>
      <svg width="7" height="11" viewBox="0 0 7 11" fill="none" style={{ marginTop: 8, flexShrink: 0 }}>
        <path d="M1 1l4.5 4.5L1 10" stroke={CFLT.faint} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </div>
  );
}

// ---------------------------------------------------------------------------
// helpers

function overlap(a, b) {
  const aStart = toMin(a.start), aEnd = toMin(a.end);
  const bStart = toMin(b.start), bEnd = toMin(b.end);
  return aStart < bEnd && bStart < aEnd;
}
function toMin(t) { const [h,m] = t.split(':').map(Number); return h*60 + m; }
function minutesBetween(a, b) { return toMin(b) - toMin(a); }

window.V5CalendarConflicts = V5CalendarConflicts;
window.V5ConflictSheet = V5ConflictSheet;
