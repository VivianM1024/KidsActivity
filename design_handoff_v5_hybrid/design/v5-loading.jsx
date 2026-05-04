// V5 — Loading skeletons for Browse, Saved, Calendar.
// First-launch / cold-start state. Soft pulsing rectangles in the same
// shapes as the real content so the UI doesn't visibly reflow when data
// arrives.

function V5LoadingBrowse() {
  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
    }}>
      {/* Header skeleton */}
      <div style={{ paddingTop: 56, padding: '56px 20px 8px' }}>
        <Bone w={140} h={11} mb={6}/>
        <Bone w={260} h={28} mb={4}/>
      </div>

      {/* Search skeleton */}
      <div style={{ padding: '12px 20px 8px' }}>
        <Bone h={38} radius={12}/>
        <div style={{ display: 'flex', gap: 6, marginTop: 8 }}>
          <Bone w={28} h={11} mr={4}/>
          <Bone w={86} h={26} radius={100}/>
          <Bone w={86} h={26} radius={100}/>
          <Bone w={86} h={26} radius={100}/>
        </div>
      </div>

      {/* Chip rail skeleton */}
      <div style={{ padding: '8px 20px', display: 'flex', gap: 6, overflow: 'hidden' }}>
        {[60, 70, 80, 60, 90].map((w, i) => <Bone key={i} w={w} h={28} radius={100}/>)}
      </div>

      {/* Sort row skeleton */}
      <div style={{ padding: '12px 20px 6px', display: 'flex', justifyContent: 'space-between' }}>
        <Bone w={70} h={12}/>
        <Bone w={150} h={26} radius={8}/>
      </div>

      {/* Row skeletons */}
      <div style={{ padding: '6px 14px' }}>
        {[0,1,2,3,4,5].map((i) => <SkelRow key={i} delay={i*60}/>)}
      </div>

      <V5TabBar tab="Browse" setTab={() => {}}/>
      <PulseStyles/>
    </div>
  );
}

function V5LoadingCalendar() {
  return (
    <div style={{
      background: '#FBF7F1', minHeight: '100%',
      paddingBottom: 100, fontFamily: '-apple-system, system-ui',
    }}>
      <div style={{ paddingTop: 56, padding: '56px 20px 8px',
        display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
        <div>
          <Bone w={100} h={11} mb={6}/>
          <Bone w={170} h={28}/>
        </div>
        <Bone w={70} h={26} radius={8}/>
      </div>
      {/* Month strip skeleton */}
      <div style={{
        margin: '8px 16px 0', padding: '14px',
        background: '#fff', borderRadius: 14,
        boxShadow: '0 0 0 0.5px rgba(60,40,20,0.06)',
      }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4 }}>
          {Array.from({ length: 35 }).map((_, i) => (
            <div key={i} style={{ aspectRatio: '1 / 1' }}>
              <Bone radius={8} h="100%" delay={i*15}/>
            </div>
          ))}
        </div>
      </div>
      {/* Day groups */}
      <div style={{ marginTop: 12, padding: '0 16px' }}>
        {[0,1,2].map((i) => (
          <div key={i} style={{ marginBottom: 18 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 8 }}>
              <Bone w={28} h={22}/>
              <Bone w={70} h={13}/>
            </div>
            <SkelEvent delay={i*100}/>
            {i === 0 && <SkelEvent delay={i*100 + 50}/>}
          </div>
        ))}
      </div>
      <V5TabBar tab="Calendar" setTab={() => {}}/>
      <PulseStyles/>
    </div>
  );
}

// ---------------------------------------------------------------------------

function SkelRow({ delay = 0 }) {
  return (
    <div style={{
      display: 'flex', gap: 10, padding: '10px',
      background: '#fff', borderRadius: 12, marginBottom: 6,
      boxShadow: '0 0 0 0.5px rgba(60,40,20,0.05)',
      alignItems: 'flex-start',
    }}>
      <Bone w={40} h={40} radius={9} delay={delay}/>
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
          <Bone w="60%" h={14} delay={delay+20}/>
          <Bone w={40} h={14} delay={delay+30}/>
        </div>
        <Bone w="80%" h={11} mt={6} delay={delay+40}/>
        <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
          <Bone w={50} h={14} radius={4} delay={delay+50}/>
          <Bone w={40} h={14} radius={4} delay={delay+60}/>
        </div>
      </div>
    </div>
  );
}

function SkelEvent({ delay = 0 }) {
  return (
    <div style={{ display: 'flex', gap: 10, marginBottom: 6 }}>
      <div style={{ width: 56, paddingTop: 10, textAlign: 'right' }}>
        <Bone w={42} h={13} ml="auto" delay={delay}/>
        <Bone w={28} h={9} mt={3} ml="auto" delay={delay+20}/>
      </div>
      <div style={{
        flex: 1, padding: '12px', borderRadius: 12, background: '#fff',
        boxShadow: '0 0 0 0.5px rgba(60,40,20,0.05)',
        borderLeft: '3px solid rgba(60,40,20,0.08)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Bone w={18} h={18} radius={9} delay={delay+30}/>
          <Bone w={50} h={11} radius={4} delay={delay+40}/>
          <Bone w="50%" h={13} delay={delay+50}/>
        </div>
        <Bone w="70%" h={11} mt={6} delay={delay+60}/>
      </div>
    </div>
  );
}

function Bone({ w = '100%', h = 12, radius = 6, mb = 0, mt = 0, mr = 0, ml = 0, delay = 0 }) {
  return (
    <div className="kabone" style={{
      width: w, height: h, borderRadius: radius,
      marginBottom: mb, marginTop: mt, marginRight: mr, marginLeft: ml,
      background: 'rgba(60,40,20,0.08)',
      animationDelay: `${delay}ms`,
    }}/>
  );
}

function PulseStyles() {
  return (
    <style>{`
      @keyframes kabone-pulse {
        0%   { opacity: 0.55; }
        50%  { opacity: 0.85; }
        100% { opacity: 0.55; }
      }
      .kabone {
        animation: kabone-pulse 1.4s ease-in-out infinite;
      }
    `}</style>
  );
}

window.V5LoadingBrowse = V5LoadingBrowse;
window.V5LoadingCalendar = V5LoadingCalendar;
