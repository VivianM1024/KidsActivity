// V5 — Calendar screen.
// Day-by-day agenda of registered activities. Top: month strip with dots
// for days that have something. Below: scrollable day-grouped list with
// time gutter.

function V5Calendar({ activities }) {
  // Mocked registered set — same activities the Saved screen marks confirmed,
  // expanded into actual calendar entries.
  const events = [
    { date: '2026-05-09', time: '9:30 AM',  durMin: 75, activityId: 'cpd-tball-1',     kidId: 'leo',  note: 'Session 1 of 8 \u00b7 bring glove' },
    { date: '2026-05-09', time: '11:00 AM', durMin: 45, activityId: 'cpl-storytime-1', kidId: 'nora' },
    { date: '2026-05-16', time: '9:30 AM',  durMin: 75, activityId: 'cpd-tball-1',     kidId: 'leo',  note: 'Session 2 of 8' },
    { date: '2026-05-17', time: '10:00 AM', durMin: 120, activityId: 'np-truck-12',    kidId: 'maya', note: 'Quiet hour 10\u201311 am' },
    { date: '2026-05-23', time: '9:30 AM',  durMin: 75, activityId: 'cpd-tball-1',     kidId: 'leo',  note: 'Session 3 of 8' },
  ];
  const [exportOpen, setExportOpen] = React.useState(false);
  const today = new Date('2026-05-04T00:00:00');
  const upcoming = events
    .map((e) => ({ ...e, _d: new Date(e.date + 'T00:00:00') }))
    .filter((e) => e._d >= today)
    .sort((a, b) => a._d - b._d || a.time.localeCompare(b.time));

  const days = [];
  for (const e of upcoming) {
    const last = days[days.length - 1];
    if (last && last.date === e.date) last.events.push(e);
    else days.push({ date: e.date, _d: e._d, events: [e] });
  }

  // Month strip — May 2026
  const monthDays = [];
  for (let d = 1; d <= 31; d++) {
    const iso = `2026-05-${String(d).padStart(2, '0')}`;
    const has = upcoming.some((e) => e.date === iso);
    const isToday = iso === '2026-05-04';
    const dt = new Date(iso + 'T00:00:00');
    monthDays.push({ d, dow: dt.getDay(), has, isToday });
  }

  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: '#26201A',
    }}>
      {/* Title */}
      <div style={{
        paddingTop: 56, padding: '56px 20px 8px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontSize: 11, color: 'oklch(0.55 0.05 60)', fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 4 }}>
            {upcoming.length} upcoming
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, letterSpacing: -0.6, lineHeight: 1.05 }}>
            May 2026
          </div>
        </div>
        <div style={{ position: 'relative' }}>
          <div onClick={() => setExportOpen(!exportOpen)} style={{
            fontSize: 12, fontWeight: 600, color: 'oklch(0.55 0.13 22)',
            padding: '6px 10px', background: '#fff', borderRadius: 8,
            boxShadow: '0 0 0 0.5px rgba(60,40,20,0.08)',
            display: 'inline-flex', alignItems: 'center', gap: 5,
            cursor: 'pointer', userSelect: 'none',
          }}>
            <svg width="11" height="11" viewBox="0 0 11 11" fill="none">
              <path d="M5.5 1.5v5.2M3 4.2l2.5 2.5L8 4.2M2 8.5h7" stroke="oklch(0.55 0.13 22)" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            Export
          </div>
          {exportOpen && (
            <V5ExportMenu
              events={events}
              activities={activities}
              onClose={() => setExportOpen(false)}
            />
          )}
        </div>
      </div>

      {/* Month strip */}
      <div style={{
        margin: '8px 16px 0', padding: '12px 12px 10px',
        background: '#fff', borderRadius: 14,
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
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2,
        }}>
          {/* May 1 2026 is a Friday — pad 5 cells. */}
          {Array.from({ length: 5 }).map((_, i) => <div key={`p${i}`} />)}
          {monthDays.map((md) => (
            <div key={md.d} style={{
              aspectRatio: '1 / 1',
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
              gap: 1,
              borderRadius: 8,
              background: md.isToday ? 'oklch(0.55 0.13 22)' : 'transparent',
              color: md.isToday ? '#fff' : md.has ? '#26201A' : '#A89B86',
              fontWeight: md.has || md.isToday ? 700 : 500,
              fontSize: 12, fontVariantNumeric: 'tabular-nums',
            }}>
              {md.d}
              <div style={{
                width: 4, height: 4, borderRadius: 2,
                background: md.isToday ? '#fff' : (md.has ? 'oklch(0.55 0.15 145)' : 'transparent'),
              }}/>
            </div>
          ))}
        </div>
      </div>

      {/* Day groups */}
      <div style={{ marginTop: 12, padding: '0 16px' }}>
        {days.length === 0 ? (
          <div style={{ padding: '60px 20px', textAlign: 'center', color: '#8B7E6E' }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: '#26201A' }}>Nothing scheduled.</div>
            <div style={{ fontSize: 12, marginTop: 4 }}>Confirm a saved activity to see it here.</div>
          </div>
        ) : days.map((day) => <V5DayBlock key={day.date} day={day} activities={activities} />)}

        <div style={{ padding: '20px 0 8px', textAlign: 'center', fontSize: 11, color: '#A89B86' }}>
          Tap "Export" above to add to Apple or Google Calendar
        </div>
      </div>

      <V5TabBar tab="Calendar" setTab={() => {}} />
    </div>
  );
}

function V5DayBlock({ day, activities }) {
  const dt = day._d;
  const dayName = dt.toLocaleDateString('en-US', { weekday: 'long' });
  const dateLabel = dt.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{
        display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 8,
      }}>
        <div style={{
          fontSize: 22, fontWeight: 700, letterSpacing: -0.4, color: '#26201A',
          fontVariantNumeric: 'tabular-nums',
        }}>{dt.getDate()}</div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600, color: '#26201A', lineHeight: 1.1 }}>{dayName}</div>
          <div style={{ fontSize: 11, color: '#A89B86' }}>{dateLabel}</div>
        </div>
        <div style={{ flex: 1, height: 1, background: 'rgba(60,40,20,0.08)', marginBottom: 4 }} />
        <div style={{ fontSize: 11, color: '#A89B86', fontVariantNumeric: 'tabular-nums' }}>
          {day.events.length} {day.events.length === 1 ? 'event' : 'events'}
        </div>
      </div>

      {day.events.map((e, i) => (
        <V5DayEvent key={i} e={e} activities={activities} />
      ))}
    </div>
  );
}

function V5DayEvent({ e, activities }) {
  const a = activities.find((x) => x.id === e.activityId);
  if (!a) return null;
  const m = window.CATEGORY_META[a.category] || { hue: 60 };
  const kid = (window.KIDS || []).find((k) => k.id === e.kidId);
  const accentHue = kid ? kid.hue : m.hue;
  return (
    <div style={{
      display: 'flex', gap: 10, marginBottom: 6,
    }}>
      {/* Time gutter */}
      <div style={{
        width: 56, flexShrink: 0, paddingTop: 10,
        textAlign: 'right',
      }}>
        <div style={{ fontSize: 13, fontWeight: 700, color: '#26201A', fontVariantNumeric: 'tabular-nums' }}>
          {e.time}
        </div>
        <div style={{ fontSize: 10, color: '#A89B86' }}>{e.durMin}m</div>
      </div>

      {/* Card with kid accent */}
      <div style={{
        flex: 1, background: '#fff', borderRadius: 12,
        boxShadow: '0 1px 2px rgba(60,40,20,0.03), 0 0 0 0.5px rgba(60,40,20,0.05)',
        padding: '10px 12px',
        borderLeft: `3px solid oklch(0.6 0.15 ${accentHue})`,
        display: 'flex', flexDirection: 'column', gap: 4,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          {kid && (
            <span title={kid.name} style={{
              width: 18, height: 18, borderRadius: 9,
              background: `oklch(0.6 0.14 ${kid.hue})`, color: '#fff',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 9.5, fontWeight: 700, flexShrink: 0,
            }}>{kid.initial}</span>
          )}
          <span style={{
            fontSize: 9.5, fontWeight: 700, letterSpacing: 0.4,
            color: `oklch(0.32 0.13 ${m.hue})`,
            background: `oklch(0.92 0.07 ${m.hue})`,
            padding: '2px 6px', borderRadius: 4,
            textTransform: 'uppercase',
          }}>{a.category}</span>
          <div style={{
            fontSize: 13.5, fontWeight: 600, color: '#26201A',
            flex: 1, minWidth: 0,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
            letterSpacing: -0.2,
          }}>{a.name}</div>
        </div>
        <div style={{ fontSize: 11.5, color: '#7A6D5C', display: 'flex', gap: 5, alignItems: 'center' }}>
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
            <path d="M5 1a3 3 0 00-3 3c0 2 3 5 3 5s3-3 3-5a3 3 0 00-3-3z" stroke="#7A6D5C" strokeWidth="1.2"/>
            <circle cx="5" cy="4" r="1" fill="#7A6D5C"/>
          </svg>
          <span>{a.venueShort} · {a.location}</span>
          <span style={{ width: 2, height: 2, borderRadius: 1, background: '#C5B9A7' }} />
          <span style={{ fontVariantNumeric: 'tabular-nums' }}>{a.distance.toFixed(1)} mi</span>
        </div>
        {e.note && (
          <div style={{
            fontSize: 11, color: '#5B4F3F',
            background: 'oklch(0.96 0.04 60)', padding: '5px 8px', borderRadius: 6,
            marginTop: 2,
          }}>📌 {e.note}</div>
        )}
        <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
          <a href={window.googleEventUrl(e, [a])} target="_blank" rel="noopener noreferrer" style={{
            fontSize: 10.5, fontWeight: 600, color: '#5B4F3F', textDecoration: 'none',
            background: 'rgba(60,40,20,0.06)', padding: '3px 7px', borderRadius: 5,
            display: 'inline-flex', alignItems: 'center', gap: 4,
          }}>
            <span style={{ color: '#1a73e8', fontWeight: 700 }}>G</span>
            Add to Google
          </a>
          <span onClick={() => window.downloadIcs([e], [a], `${a.id}-${e.date}.ics`)} style={{
            fontSize: 10.5, fontWeight: 600, color: '#5B4F3F',
            background: 'rgba(60,40,20,0.06)', padding: '3px 7px', borderRadius: 5,
            display: 'inline-flex', alignItems: 'center', gap: 4, cursor: 'pointer',
          }}>
            <span style={{ fontWeight: 700 }}></span>
            Add to Apple
          </span>
        </div>
      </div>
    </div>
  );
}

window.V5Calendar = V5Calendar;

// ---------------------------------------------------------------------------
// Calendar export helpers
// ---------------------------------------------------------------------------

// Local-time “floating” ICS datetime: YYYYMMDDTHHMMSS (no Z).
// Imported events render at that wall-clock time in the user’s tz — which is
// what parents want for an after-school 3:30pm class.
function icsLocalDt(date, time, addMinutes = 0) {
  const [h, m, ap] = time.match(/(\d+):(\d+)\s*(AM|PM)/i).slice(1);
  let hr = parseInt(h, 10) % 12;
  if (/PM/i.test(ap)) hr += 12;
  const start = new Date(`${date}T${String(hr).padStart(2, '0')}:${m}:00`);
  start.setMinutes(start.getMinutes() + addMinutes);
  const pad = (n) => String(n).padStart(2, '0');
  return (
    start.getFullYear().toString() +
    pad(start.getMonth() + 1) + pad(start.getDate()) + 'T' +
    pad(start.getHours()) + pad(start.getMinutes()) + '00'
  );
}

function googleUtc(date, time, addMinutes = 0) {
  const [h, m, ap] = time.match(/(\d+):(\d+)\s*(AM|PM)/i).slice(1);
  let hr = parseInt(h, 10) % 12;
  if (/PM/i.test(ap)) hr += 12;
  const start = new Date(`${date}T${String(hr).padStart(2, '0')}:${m}:00`);
  start.setMinutes(start.getMinutes() + addMinutes);
  // Google template URL accepts UTC YYYYMMDDTHHMMSSZ.
  return start.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
}

function icsEscape(s) {
  return String(s || '').replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/,/g, '\\,').replace(/;/g, '\\;');
}

function buildIcs(events, activities) {
  const lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//KidsActivity//EN',
    'CALSCALE:GREGORIAN',
  ];
  for (const e of events) {
    const a = activities.find((x) => x.id === e.activityId);
    if (!a) continue;
    const url = window.activitySourceUrl ? window.activitySourceUrl(a) : '';
    const desc = [
      a.desc || '',
      e.note ? `\n\nNote: ${e.note}` : '',
      url ? `\n\nRegistration: ${url}` : '',
    ].join('');
    lines.push(
      'BEGIN:VEVENT',
      `UID:${a.id}-${e.date}-${e.time.replace(/\s/g, '')}@kidsactivity`,
      `DTSTAMP:${icsLocalDt(e.date, e.time)}`,
      `DTSTART:${icsLocalDt(e.date, e.time)}`,
      `DTEND:${icsLocalDt(e.date, e.time, e.durMin)}`,
      `SUMMARY:${icsEscape(a.name)}`,
      `LOCATION:${icsEscape((a.venue || '') + (a.location ? ' — ' + a.location : ''))}`,
      `DESCRIPTION:${icsEscape(desc)}`,
      url ? `URL:${icsEscape(url)}` : '',
      'END:VEVENT',
    );
  }
  lines.push('END:VCALENDAR');
  return lines.filter(Boolean).join('\r\n');
}

function downloadIcs(events, activities, filename = 'kidsactivity.ics') {
  const ics = buildIcs(events, activities);
  const blob = new Blob([ics], { type: 'text/calendar;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => { document.body.removeChild(a); URL.revokeObjectURL(url); }, 0);
}

function googleEventUrl(e, activities) {
  const a = activities.find((x) => x.id === e.activityId);
  if (!a) return '#';
  const dates = `${googleUtc(e.date, e.time)}/${googleUtc(e.date, e.time, e.durMin)}`;
  const url = window.activitySourceUrl ? window.activitySourceUrl(a) : '';
  const params = new URLSearchParams({
    action: 'TEMPLATE',
    text: a.name,
    dates,
    details: [a.desc || '', e.note ? `Note: ${e.note}` : '', url ? `Registration: ${url}` : ''].filter(Boolean).join('\n\n'),
    location: (a.venue || '') + (a.location ? ' — ' + a.location : ''),
  });
  return `https://calendar.google.com/calendar/render?${params.toString()}`;
}

// ---------------------------------------------------------------------------
// Export menu (popover)
// ---------------------------------------------------------------------------

function V5ExportMenu({ events, activities, onClose }) {
  const stop = (fn) => (ev) => { ev.stopPropagation(); fn(); };
  return (
    <React.Fragment>
      <div onClick={onClose} style={{
        position: 'fixed', inset: 0, zIndex: 10,
      }} />
      <div style={{
        position: 'absolute', top: 'calc(100% + 6px)', right: 0, zIndex: 11,
        width: 240, background: '#fff', borderRadius: 12,
        boxShadow: '0 10px 30px rgba(60,40,20,0.18), 0 0 0 0.5px rgba(60,40,20,0.08)',
        overflow: 'hidden',
      }}>
        <div style={{ padding: '10px 12px 6px', fontSize: 10.5, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: '#A89B86' }}>
          Export {events.length} events
        </div>
        <ExportRow
          icon="apple"
          title="Apple Calendar"
          sub=".ics file · imports all events"
          onClick={stop(() => { downloadIcs(events, activities); onClose(); })}
        />
        <ExportRow
          icon="google"
          title="Google Calendar"
          sub="Subscribe via .ics import"
          onClick={stop(() => { downloadIcs(events, activities, 'kidsactivity-google.ics'); onClose(); })}
        />
        <ExportRow
          icon="link"
          title="Copy subscribe link"
          sub="Auto-syncs new registrations"
          onClick={stop(() => {
            const url = 'https://kidsactivity.app/u/maya-4y/feed.ics';
            if (navigator.clipboard) navigator.clipboard.writeText(url).catch(() => {});
            onClose();
          })}
        />
        <div style={{
          padding: '8px 12px 10px', fontSize: 10.5, color: '#A89B86',
          borderTop: '0.5px solid rgba(60,40,20,0.08)', lineHeight: 1.4,
        }}>
          On iPhone, tap the .ics file in Files → Add All. On desktop Google Calendar, Settings → Import.
        </div>
      </div>
    </React.Fragment>
  );
}

function ExportRow({ icon, title, sub, onClick }) {
  return (
    <div onClick={onClick} style={{
      padding: '10px 12px', display: 'flex', alignItems: 'center', gap: 10,
      cursor: 'pointer', borderTop: '0.5px solid rgba(60,40,20,0.06)',
    }}>
      <ExportIcon kind={icon} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: '#26201A' }}>{title}</div>
        <div style={{ fontSize: 11, color: '#7A6D5C', marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>
      </div>
      <svg width="9" height="9" viewBox="0 0 9 9" fill="none">
        <path d="M2 1.5l3 3-3 3" stroke="#A89B86" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
    </div>
  );
}

function ExportIcon({ kind }) {
  const wrap = { width: 30, height: 30, borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 };
  if (kind === 'apple') return (
    <div style={{ ...wrap, background: '#000' }}>
      <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
        <path d="M10.6 8.1c0-2 1.6-2.9 1.7-3-1-1.4-2.4-1.6-2.9-1.6-1.2-.1-2.4.7-3 .7-.6 0-1.6-.7-2.7-.7C2.4 3.6 1 4.6 1 7c0 1.4.5 2.9 1.2 3.8.5.7 1.1 1.4 1.9 1.4.7 0 1-.5 1.9-.5.9 0 1.2.5 1.9.5.8 0 1.4-.7 1.9-1.4.4-.6.8-1.3 1-2-.6-.3-1.2-.9-1.2-1.7zM8.7 2.5c.4-.5.7-1.2.6-1.9-.6 0-1.3.4-1.7.9-.4.4-.8 1.1-.7 1.8.7.1 1.4-.3 1.8-.8z" fill="#fff"/>
      </svg>
    </div>
  );
  if (kind === 'google') return (
    <div style={{ ...wrap, background: '#fff', boxShadow: '0 0 0 1px rgba(60,40,20,0.1)' }}>
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <rect x="2" y="2" width="12" height="12" rx="2" fill="#fff" stroke="#dadce0" strokeWidth="0.8"/>
        <text x="8" y="11" fontSize="7" fontWeight="700" textAnchor="middle" fill="#1a73e8" fontFamily="-apple-system,system-ui">31</text>
      </svg>
    </div>
  );
  return (
    <div style={{ ...wrap, background: 'rgba(60,40,20,0.07)' }}>
      <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
        <path d="M5.5 9.5l-2 2a2.5 2.5 0 01-3.5-3.5l2-2M9.5 5.5l2-2a2.5 2.5 0 013.5 3.5l-2 2M5 10l5-5" stroke="#5B4F3F" strokeWidth="1.4" strokeLinecap="round"/>
      </svg>
    </div>
  );
}

Object.assign(window, { buildIcs, downloadIcs, googleEventUrl });
