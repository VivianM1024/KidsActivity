// V5 \u2014 Co-parent assignment surfaces.
//
// Centralizes the parent-avatar visual language and the screens that
// expose it. Pairs with the new PARENTS data layer in activities.jsx.
//
// Surfaces in this file:
//   - ParentChip          shared mini-avatar (Mom / Dad / Both / Split)
//   - V5DetailWhosGoing   activity detail with new "Who's going" picker
//   - V5CalendarByParent  Calendar with All / Mine / Theirs filter
//   - V5LinkedLoad        the existing Linked-state settings + load summary

const COP = {
  bg: '#FBF7F1', ink: '#26201A', muted: '#7A6D5C', faint: '#A89B86',
  card: '#fff', hairline: 'rgba(60,40,20,0.07)',
};

// ---------------------------------------------------------------------------
// ParentChip \u2014 small visual that goes on rows and inline in detail copy.
//
//   <ParentChip kind="both"/>                    two stacked avatars
//   <ParentChip kind="solo" parentId="p_you"/>   single colored avatar
//   <ParentChip kind="split" split={{...}}/>     two avatars + tiny / between
//   <ParentChip kind="unassigned"/>              dashed circle with ?

function ParentChip({ kind = 'both', parentId, split, size = 22, withLabel = false }) {
  const PARENTS = window.PARENTS || [];
  const you     = PARENTS.find((p) => p.role === 'you');
  const partner = PARENTS.find((p) => p.role === 'partner');

  const baseAvatarStyle = (p) => ({
    width: size, height: size, borderRadius: size / 2,
    background: `oklch(0.6 0.14 ${p.hue})`, color: '#fff',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: Math.round(size * 0.46), fontWeight: 700,
    boxShadow: '0 0 0 1.5px #fff',
    flexShrink: 0,
  });

  let visual;
  let label;
  if (kind === 'both') {
    visual = (
      <div style={{ display: 'flex' }}>
        <div style={baseAvatarStyle(you)}>{you.initial}</div>
        <div style={{ ...baseAvatarStyle(partner), marginLeft: -size * 0.35 }}>{partner.initial}</div>
      </div>
    );
    label = 'Both';
  } else if (kind === 'solo') {
    const p = PARENTS.find((x) => x.id === parentId) || you;
    visual = <div style={baseAvatarStyle(p)}>{p.initial}</div>;
    label = p.short;
  } else if (kind === 'split') {
    visual = (
      <div style={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        <div style={baseAvatarStyle(you)}>{you.initial}</div>
        <span style={{
          fontSize: Math.round(size * 0.5), color: COP.faint, fontWeight: 600,
          marginTop: -1,
        }}>/</span>
        <div style={baseAvatarStyle(partner)}>{partner.initial}</div>
      </div>
    );
    label = 'Split';
  } else {
    visual = (
      <div style={{
        width: size, height: size, borderRadius: size / 2,
        border: `1.5px dashed ${COP.faint}`, color: COP.faint,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: Math.round(size * 0.55), fontWeight: 600, flexShrink: 0,
      }}>?</div>
    );
    label = 'Claim';
  }

  if (!withLabel) return visual;
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      {visual}
      <span style={{ fontSize: 12, color: COP.muted, fontWeight: 600 }}>{label}</span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// "Who's going" section \u2014 lifted into a standalone artboard so the picker
// design is visible. In production this slots into ActivityDetail above the
// "Hosted by" section.

function V5DetailWhosGoing() {
  const PARENTS = window.PARENTS || [];
  const KIDS = window.KIDS || [];
  // Default state is COLLAPSED \u2014 user hasn't assigned anything yet.
  // Co-parent is opt-in per activity. Single parents never see the picker.
  const [expanded, setExpanded] = React.useState(false);
  const [mode, setMode] = React.useState('split'); // both | solo | split

  return (
    <div style={{
      background: COP.bg, minHeight: '100%',
      paddingBottom: 30, fontFamily: '-apple-system, system-ui',
      color: COP.ink,
    }}>
      <div style={{ paddingTop: 60, padding: '60px 20px 14px' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 6,
          fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase',
          color: 'oklch(0.55 0.13 22)', marginBottom: 6,
        }}>
          Activity detail \u00b7 section
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -0.5 }}>
          Who\u2019s going?
        </div>
        <div style={{ fontSize: 13, color: COP.muted, marginTop: 8, lineHeight: 1.45, textWrap: 'pretty' }}>
          By default it\u2019s on your calendar only. Add Sam if you want to coordinate
          drop-off, swap, or split the kids.
        </div>
      </div>

      {/* Collapsed state \u2014 single ghost row, opt-in */}
      {!expanded && (
        <div style={{ padding: '0 16px 14px' }}>
          <div onClick={() => setExpanded(true)} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '14px 14px',
            background: COP.card, borderRadius: 14,
            border: `1px dashed ${COP.faint}`,
            cursor: 'pointer',
          }}>
            <ParentChip kind="unassigned" size={28}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: COP.ink }}>
                Add Sam to this activity
              </div>
              <div style={{ fontSize: 11.5, color: COP.muted, marginTop: 2, lineHeight: 1.4 }}>
                Optional. Only show on Sam\u2019s calendar if you assign them.
              </div>
            </div>
            <div style={{
              fontSize: 22, color: COP.faint, fontWeight: 300,
              lineHeight: 1, marginRight: 2,
            }}>+</div>
          </div>
          <div style={{
            marginTop: 10, padding: '0 4px',
            fontSize: 11, color: COP.faint, lineHeight: 1.4,
          }}>
            Tip: most parents only assign for activities where coordination matters \u2014
            same-time conflicts, long drives, or trades.
          </div>
        </div>
      )}

      {/* Expanded state \u2014 segmented control + picker body */}
      {expanded && (
        <React.Fragment>
          <div style={{ padding: '0 16px 10px' }}>
            <div style={{
              background: 'rgba(60,40,20,0.05)', borderRadius: 10, padding: 3,
              display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 2,
            }}>
              {[
                { id: 'both',  label: 'Both go' },
                { id: 'solo',  label: 'Just Sam' },
                { id: 'split', label: 'Split kids' },
              ].map((o) => {
                const on = mode === o.id;
                return (
                  <div key={o.id} onClick={() => setMode(o.id)} style={{
                    padding: '8px 6px', borderRadius: 8, textAlign: 'center',
                    fontSize: 13, fontWeight: 600, cursor: 'pointer',
                    background: on ? '#fff' : 'transparent',
                    color: on ? COP.ink : COP.muted,
                    boxShadow: on ? '0 1px 2px rgba(60,40,20,0.06)' : 'none',
                  }}>{o.label}</div>
                );
              })}
            </div>
          </div>

          <div style={{
            margin: '0 16px 14px', background: COP.card, borderRadius: 14,
            boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
            padding: '14px 16px',
          }}>
            {mode === 'both' && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <ParentChip kind="both" size={36}/>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: COP.ink }}>You and Sam, both kids</div>
                  <div style={{ fontSize: 12, color: COP.muted, marginTop: 2, lineHeight: 1.4 }}>
                    Adds the event to Sam\u2019s calendar too.
                  </div>
                </div>
              </div>
            )}

            {mode === 'solo' && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color: COP.faint, marginBottom: 2 }}>
                  Who\u2019s taking the kids?
                </div>
                {PARENTS.map((p, i) => {
                  const on = i === 1;
                  return (
                    <div key={p.id} style={{
                      display: 'flex', alignItems: 'center', gap: 12,
                      padding: '10px 12px', borderRadius: 10,
                      background: on ? `oklch(0.96 0.04 ${p.hue})` : 'transparent',
                      border: on ? `1.5px solid oklch(0.6 0.14 ${p.hue})` : '1px solid rgba(60,40,20,0.08)',
                      cursor: 'pointer',
                    }}>
                      <ParentChip kind="solo" parentId={p.id} size={28}/>
                      <div style={{ flex: 1, fontSize: 14, fontWeight: 600, color: COP.ink }}>{p.name}</div>
                      {on && <CheckGlyph color={`oklch(0.6 0.14 ${p.hue})`}/>}
                    </div>
                  );
                })}
              </div>
            )}

            {mode === 'split' && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color: COP.faint, marginBottom: 2 }}>
                  Assign per kid
                </div>
                {KIDS.slice(0, 2).map((k, i) => {
                  const assignedTo = PARENTS[i % 2];
                  return (
                    <div key={k.id} style={{
                      display: 'flex', alignItems: 'center', gap: 10,
                      padding: '10px 12px', borderRadius: 10,
                      background: '#FBF7F1',
                      border: `0.5px solid ${COP.hairline}`,
                    }}>
                      <div style={{
                        width: 28, height: 28, borderRadius: 14,
                        background: `oklch(0.6 0.14 ${k.hue})`, color: '#fff',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 12, fontWeight: 700,
                      }}>{k.initial}</div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 13.5, fontWeight: 600, color: COP.ink }}>{k.name}</div>
                        <div style={{ fontSize: 11.5, color: COP.muted }}>{k.ageYears} yrs</div>
                      </div>
                      <ArrowGlyph/>
                      <div style={{
                        display: 'inline-flex', alignItems: 'center', gap: 6,
                        padding: '6px 10px', borderRadius: 100,
                        background: `oklch(0.94 0.05 ${assignedTo.hue})`,
                        color: `oklch(0.32 0.13 ${assignedTo.hue})`,
                        fontSize: 12, fontWeight: 700,
                        border: `0.5px solid oklch(0.6 0.14 ${assignedTo.hue})`,
                      }}>
                        <ParentChip kind="solo" parentId={assignedTo.id} size={16}/>
                        {assignedTo.short}
                      </div>
                    </div>
                  );
                })}
                <div style={{ fontSize: 11.5, color: COP.muted, padding: '4px 4px 0', lineHeight: 1.4 }}>
                  Tap any chip to swap.
                </div>
              </div>
            )}
          </div>

          {/* Cancel + Save */}
          <div style={{ padding: '0 16px 14px', display: 'flex', gap: 8 }}>
            <div onClick={() => setExpanded(false)} style={{
              padding: '13px 14px', borderRadius: 12,
              background: 'rgba(60,40,20,0.05)', color: COP.ink,
              fontSize: 14, fontWeight: 600, textAlign: 'center', cursor: 'pointer',
            }}>Cancel</div>
            <div style={{
              flex: 1, padding: '13px 14px', borderRadius: 12,
              background: 'oklch(0.55 0.13 22)', color: '#fff',
              fontSize: 14, fontWeight: 700, textAlign: 'center',
              boxShadow: '0 2px 10px oklch(0.55 0.13 22 / 0.22)',
            }}>Add to Sam\u2019s calendar</div>
          </div>
        </React.Fragment>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// V5CalendarByParent \u2014 calendar with All / Mine / Theirs / Both filter
// at the top. Reuses calendar visual language; rows show the parent chip
// in the right gutter.

function V5CalendarByParent({ activities }) {
  const PARENTS = window.PARENTS || [];
  const KIDS = window.KIDS || [];
  const [filter, setFilter] = React.useState('all'); // all | mine | theirs | both
  const M = window.CATEGORY_META || {};

  // Mock the day's events. Note: most are unassigned (single-parent default);
  // only 2 of 4 have been explicitly assigned. The filter strip + right-side
  // chips appear because the user has linked Sam AND assigned at least one event.
  const events = [
    { time: '9:30 AM',  durMin: 75, activityId: 'cpd-tball-1',   kidId: 'leo',  assign: { kind: 'solo', parentId: 'p_you' } },
    { time: '10:00 AM', durMin: 30, activityId: 'cpl-storytime-1', kidId: 'maya', assign: null },
    { time: '2:00 PM',  durMin: 90, activityId: 'msi-saturday',  kidId: 'maya', assign: null },
    { time: '3:30 PM',  durMin: 60, activityId: 'pd-art-1',      kidId: 'leo',  assign: { kind: 'solo', parentId: 'p_partner' } },
  ];
  const acts = activities || window.ACTIVITIES || [];
  const eventsHydrated = events.map((e) => ({
    ...e,
    a: acts.find((x) => x.id === e.activityId) || acts[0],
    kid: KIDS.find((k) => k.id === e.kidId),
  }));

  const hasAnyAssignment = eventsHydrated.some((e) => e.assign);

  const filtered = eventsHydrated.filter((e) => {
    if (filter === 'all') return true;
    if (filter === 'mine')   return e.assign?.kind === 'solo' && e.assign.parentId === 'p_you';
    if (filter === 'theirs') return e.assign?.kind === 'solo' && e.assign.parentId === 'p_partner';
    if (filter === 'both')   return e.assign?.kind === 'both';
    return true;
  });

  const counts = {
    all: eventsHydrated.length,
    mine: eventsHydrated.filter((e) => e.assign?.kind === 'solo' && e.assign.parentId === 'p_you').length,
    theirs: eventsHydrated.filter((e) => e.assign?.kind === 'solo' && e.assign.parentId === 'p_partner').length,
    both: eventsHydrated.filter((e) => e.assign?.kind === 'both').length,
  };

  return (
    <div style={{
      background: COP.bg, minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
      color: COP.ink,
    }}>
      <div style={{ paddingTop: 56, padding: '56px 20px 6px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: COP.faint, marginBottom: 4 }}>
          Saturday \u00b7 May 9
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -0.5 }}>Calendar</div>
      </div>

      {/* Parent filter \u2014 only when at least one event has been assigned */}
      {hasAnyAssignment && (
        <div style={{ padding: '6px 16px 6px', overflow: 'hidden' }}>
          <div style={{ display: 'flex', gap: 6, overflowX: 'auto' }}>
            {[
              { id: 'all',    label: 'All',    chip: null },
              { id: 'mine',   label: 'Mine',   chip: <ParentChip kind="solo" parentId="p_you" size={16}/> },
              { id: 'theirs', label: 'Sam\u2019s', chip: <ParentChip kind="solo" parentId="p_partner" size={16}/> },
              { id: 'both',   label: 'Both',   chip: <ParentChip kind="both" size={16}/> },
            ].map((opt) => {
              const on = filter === opt.id;
              return (
                <div key={opt.id} onClick={() => setFilter(opt.id)} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  fontSize: 12.5, fontWeight: 600, padding: '7px 12px', borderRadius: 100,
                  background: on ? COP.ink : '#fff',
                  color: on ? '#fff' : COP.ink,
                  boxShadow: '0 0 0 0.5px rgba(60,40,20,0.08)',
                  cursor: 'pointer', flexShrink: 0,
                }}>
                  {opt.chip}
                  {opt.label}
                  <span style={{
                    fontSize: 10.5, fontWeight: 700,
                    color: on ? 'rgba(255,255,255,0.7)' : COP.faint,
                    fontVariantNumeric: 'tabular-nums',
                  }}>{counts[opt.id]}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Day header */}
      <div style={{ padding: '14px 20px 6px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: -0.3 }}>Today</div>
        <div style={{ fontSize: 11, color: COP.muted, fontWeight: 600 }}>{filtered.length} events</div>
      </div>

      {/* Events */}
      <div style={{ padding: '0 14px' }}>
        {filtered.length === 0 ? (
          <div style={{
            margin: '20px 6px', padding: '28px 18px', textAlign: 'center',
            background: COP.card, borderRadius: 14,
            color: COP.muted, fontSize: 13, lineHeight: 1.5,
          }}>
            Nothing on your plate this filter.
          </div>
        ) : filtered.map((e, i) => <DayEventRow key={i} e={e}/>)}
      </div>

      <V5TabBar tab="Calendar" setTab={() => {}}/>
    </div>
  );
}

function DayEventRow({ e }) {
  const M = window.CATEGORY_META || {};
  const m = M[e.a.category] || { hue: 60, short: e.a.category };
  const accentHue = e.kid ? e.kid.hue : m.hue;
  return (
    <div style={{
      display: 'flex', alignItems: 'stretch', gap: 0, padding: '10px 0',
      background: '#fff', borderRadius: 14, marginBottom: 6,
      boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
      borderLeft: `4px solid oklch(0.6 0.14 ${accentHue})`,
      paddingLeft: 8,
    }}>
      <div style={{ width: 56, padding: '0 6px 0 4px', textAlign: 'right', flexShrink: 0 }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: COP.ink, fontVariantNumeric: 'tabular-nums' }}>{e.time}</div>
        <div style={{ fontSize: 10, color: COP.faint, marginTop: 2 }}>{e.durMin}min</div>
      </div>
      <div style={{ flex: 1, minWidth: 0, paddingRight: 12, paddingLeft: 4 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: COP.ink, lineHeight: 1.25 }}>
          {e.a.name}
        </div>
        <div style={{ fontSize: 11.5, color: COP.muted, marginTop: 3, display: 'flex', alignItems: 'center', gap: 5 }}>
          <span style={{
            display: 'inline-block', width: 7, height: 7, borderRadius: 4,
            background: `oklch(0.6 0.14 ${e.kid.hue})`,
          }}/>
          {e.kid.name} \u00b7 {e.a.venueShort}
        </div>
      </div>
      {/* Parent chip only renders when an assignment exists \u2014 unassigned events
          look like normal calendar rows. */}
      {e.assign && (
        <div style={{ display: 'flex', alignItems: 'center', paddingRight: 10 }}>
          <ParentChip kind={e.assign.kind} parentId={e.assign.parentId} size={22}/>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// V5LinkedLoad \u2014 settings with on-demand load summary line.

function V5LinkedLoad() {
  return (
    <div style={{
      background: COP.bg, minHeight: '100%',
      paddingBottom: 30, fontFamily: '-apple-system, system-ui', color: COP.ink,
    }}>
      <div style={{ paddingTop: 60, padding: '60px 20px 8px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: COP.faint, marginBottom: 4 }}>
          Settings
        </div>
        <div style={{ fontSize: 26, fontWeight: 700, letterSpacing: -0.5 }}>Linked with Sam</div>
      </div>

      {/* Linked status */}
      <div style={{
        margin: '12px 16px 14px', padding: '14px 16px',
        background: COP.card, borderRadius: 14,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
        display: 'flex', alignItems: 'center', gap: 12,
      }}>
        <ParentChip kind="both" size={34}/>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: COP.ink }}>You & Sam are linked</div>
          <div style={{ fontSize: 11.5, color: COP.muted, marginTop: 2 }}>
            Code <code style={{ fontFamily: 'ui-monospace, monospace', color: COP.muted }}>maple-otter-39</code> \u00b7 since Mar 12
          </div>
        </div>
        <CheckCircleGlyph/>
      </div>

      {/* Load summary */}
      <div style={{ padding: '4px 20px 8px' }}>
        <div style={{
          fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase',
          color: COP.faint,
        }}>This week\u2019s load</div>
        <div style={{ fontSize: 11, color: COP.muted, marginTop: 2 }}>
          On-demand only \u2014 we don\u2019t notify you about it.
        </div>
      </div>

      <div style={{
        margin: '0 16px 14px', padding: '14px 16px',
        background: COP.card, borderRadius: 14,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <LoadBar/>
        <div style={{
          marginTop: 12, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
        }}>
          <LoadCell who="You"  count={4} hue={250} parentId="p_you"/>
          <LoadCell who="Both" count={1} both/>
          <LoadCell who="Sam"  count={3} hue={30} parentId="p_partner"/>
        </div>
        <div style={{
          marginTop: 12, padding: '10px 12px', background: COP.bg,
          borderRadius: 10, fontSize: 11.5, color: COP.muted, lineHeight: 1.45,
        }}>
          You\u2019ve got an extra event this week. <span style={{ color: 'oklch(0.5 0.13 30)', fontWeight: 600 }}>
          Tap an event in Calendar</span> to swap.
        </div>
      </div>

      {/* Sync settings */}
      <div style={{ padding: '4px 20px 8px' }}>
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', color: COP.faint }}>
          Notify Sam when
        </div>
      </div>
      <div style={{
        margin: '0 16px 14px', background: COP.card, borderRadius: 14,
        boxShadow: '0 1px 2px rgba(60,40,20,0.04), 0 0 0 0.5px rgba(60,40,20,0.06)',
        overflow: 'hidden',
      }}>
        <SettingRow label="An activity is reassigned to them" sub="Same-day reassignments only" on/>
        <SettingRow label="Weekly digest" sub="Sunday 6 PM \u00b7 your week ahead" on/>
        <SettingRow label="A new activity is added" sub="Saved or registered, either parent" on={false} last/>
      </div>

      {/* Disconnect */}
      <div style={{ margin: '8px 16px', padding: '12px 14px',
        textAlign: 'center', fontSize: 13, fontWeight: 600,
        color: 'oklch(0.5 0.16 25)',
      }}>
        Unlink from Sam
      </div>
    </div>
  );
}

function LoadBar() {
  // Visual: 4 you / 1 both / 3 sam = 8 events, you 50%, both 12.5%, sam 37.5%
  return (
    <div style={{
      display: 'flex', height: 10, borderRadius: 5, overflow: 'hidden',
      background: 'rgba(60,40,20,0.06)',
    }}>
      <div style={{ flex: 4, background: 'oklch(0.6 0.14 250)' }}/>
      <div style={{ flex: 1, background: 'oklch(0.7 0.05 60)' }}/>
      <div style={{ flex: 3, background: 'oklch(0.6 0.14 30)' }}/>
    </div>
  );
}

function LoadCell({ who, count, hue, parentId, both }) {
  const bg = both ? 'rgba(60,40,20,0.04)' : `oklch(0.96 0.04 ${hue})`;
  const ink = both ? COP.ink : `oklch(0.32 0.13 ${hue})`;
  return (
    <div style={{
      padding: '10px 8px', borderRadius: 10, background: bg, textAlign: 'center',
    }}>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 4 }}>
        {both ? <ParentChip kind="both" size={20}/> : <ParentChip kind="solo" parentId={parentId} size={20}/>}
      </div>
      <div style={{ fontSize: 18, fontWeight: 700, color: ink, fontVariantNumeric: 'tabular-nums' }}>{count}</div>
      <div style={{ fontSize: 10.5, fontWeight: 600, color: ink, marginTop: 1, opacity: 0.8 }}>{who}</div>
    </div>
  );
}

function SettingRow({ label, sub, on, last }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px',
      borderBottom: last ? 'none' : `0.5px solid ${COP.hairline}`,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: COP.ink }}>{label}</div>
        <div style={{ fontSize: 11.5, color: COP.muted, marginTop: 1 }}>{sub}</div>
      </div>
      <Toggle on={on}/>
    </div>
  );
}

function Toggle({ on }) {
  return (
    <div style={{
      width: 38, height: 22, borderRadius: 11,
      background: on ? 'oklch(0.55 0.15 145)' : 'rgba(60,40,20,0.18)',
      position: 'relative', flexShrink: 0,
    }}>
      <div style={{
        position: 'absolute', top: 2, left: on ? 18 : 2,
        width: 18, height: 18, borderRadius: 9, background: '#fff',
        boxShadow: '0 1px 3px rgba(0,0,0,0.18)',
        transition: 'left 0.18s',
      }}/>
    </div>
  );
}

function CheckGlyph({ color = COP.ink }) {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
      <path d="M3 8.5L6.5 12L13 4.5" stroke={color} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}
function CheckCircleGlyph() {
  return (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
      <circle cx="11" cy="11" r="10" fill="oklch(0.55 0.15 145)"/>
      <path d="M6.5 11.5l3 3 6-6" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}
function ArrowGlyph() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
      <path d="M3 7h8M8 4l3 3-3 3" stroke={COP.faint} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

window.ParentChip = ParentChip;
window.V5DetailWhosGoing = V5DetailWhosGoing;
window.V5CalendarByParent = V5CalendarByParent;
window.V5LinkedLoad = V5LinkedLoad;
