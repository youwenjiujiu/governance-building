import { useEffect, useState, useRef, useCallback } from 'react';
import {
  fetchBuildings, fetchEquipment, fetchPoints, fetchAlarms,
  connectWebSocket,
  type Building, type Equipment, type Point, type Alarm, type WsMessage,
} from './api';

type Tab = 'overview' | 'equipment' | 'points' | 'alarms';

export default function App() {
  const [tab, setTab] = useState<Tab>('overview');
  const [buildings, setBuildings] = useState<Building[]>([]);
  const [equipment, setEquipment] = useState<Equipment[]>([]);
  const [points, setPoints] = useState<Point[]>([]);
  const [alarms, setAlarms] = useState<Alarm[]>([]);
  const [activeBld, setActiveBld] = useState<string>('');
  const [wsStatus, setWsStatus] = useState<'connecting' | 'connected' | 'disconnected'>('connecting');
  const [liveUpdates, setLiveUpdates] = useState<WsMessage[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  // Initial load
  useEffect(() => {
    fetchBuildings().then((b) => {
      setBuildings(b);
      if (b.length > 0) setActiveBld(b[0].id);
    });
    fetchEquipment().then(setEquipment);
    fetchAlarms().then(setAlarms);
  }, []);

  // Load points when building changes
  useEffect(() => {
    if (activeBld) {
      fetchPoints(activeBld).then(setPoints);
    }
  }, [activeBld]);

  // WebSocket
  const handleWs = useCallback((msg: WsMessage) => {
    setLiveUpdates((prev) => [msg, ...prev].slice(0, 50));
    if (msg.type === 'point_update' && msg.point_id) {
      setPoints((prev) =>
        prev.map((p) =>
          p.id === msg.point_id
            ? { ...p, current_value: msg.value ?? p.current_value, value_timestamp: msg.ts ?? p.value_timestamp }
            : p
        )
      );
    }
    if (msg.type === 'alarm') {
      fetchAlarms().then(setAlarms);
    }
  }, []);

  useEffect(() => {
    const ws = connectWebSocket(handleWs);
    wsRef.current = ws;
    ws.onopen = () => setWsStatus('connected');
    ws.onclose = () => setWsStatus('disconnected');
    return () => ws.close();
  }, [handleWs]);

  const activeAlarms = alarms.filter((a) => a.state.includes('ACTIVE') || a.state.includes('active'));
  const bld = buildings.find((b) => b.id === activeBld);

  return (
    <div style={{ minHeight: '100vh', background: '#0a0e17', color: '#e0e6ed', fontFamily: 'system-ui, -apple-system, sans-serif' }}>
      {/* Header */}
      <header style={{ background: '#111827', borderBottom: '1px solid #1e293b', padding: '12px 24px', display: 'flex', alignItems: 'center', gap: 16 }}>
        <h1 style={{ margin: 0, fontSize: 18, fontWeight: 600, color: '#60a5fa' }}>
          楼宇远程运营平台
        </h1>
        {bld && (
          <select
            value={activeBld}
            onChange={(e) => setActiveBld(e.target.value)}
            style={{ background: '#1e293b', color: '#e0e6ed', border: '1px solid #334155', borderRadius: 6, padding: '4px 8px', fontSize: 13 }}
          >
            {buildings.map((b) => (
              <option key={b.id} value={b.id}>{b.code} {b.name}</option>
            ))}
          </select>
        )}
        <div style={{ flex: 1 }} />
        <StatusDot status={wsStatus} />
      </header>

      {/* Tabs */}
      <nav style={{ background: '#111827', padding: '0 24px', display: 'flex', gap: 0, borderBottom: '1px solid #1e293b' }}>
        {([
          ['overview', '总览'],
          ['equipment', `设备 (${equipment.length})`],
          ['points', `点位 (${points.length})`],
          ['alarms', `告警 (${activeAlarms.length})`],
        ] as [Tab, string][]).map(([t, label]) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            style={{
              background: 'none', border: 'none', borderBottom: tab === t ? '2px solid #60a5fa' : '2px solid transparent',
              color: tab === t ? '#60a5fa' : '#94a3b8', padding: '10px 16px', cursor: 'pointer', fontSize: 13, fontWeight: 500,
            }}
          >{label}</button>
        ))}
      </nav>

      {/* Content */}
      <main style={{ padding: 24 }}>
        {tab === 'overview' && (
          <OverviewTab
            building={bld}
            equipment={equipment}
            points={points}
            activeAlarms={activeAlarms}
            liveUpdates={liveUpdates}
          />
        )}
        {tab === 'equipment' && <EquipmentTab equipment={equipment} />}
        {tab === 'points' && <PointsTab points={points} />}
        {tab === 'alarms' && <AlarmsTab alarms={alarms} />}
      </main>
    </div>
  );
}

// ─── Components ─────────────────────────────────────────────────────────────

function StatusDot({ status }: { status: string }) {
  const color = status === 'connected' ? '#22c55e' : status === 'connecting' ? '#eab308' : '#ef4444';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: '#94a3b8' }}>
      <div style={{ width: 8, height: 8, borderRadius: '50%', background: color }} />
      WebSocket {status}
    </div>
  );
}

function Card({ title, children, style }: { title: string; children: React.ReactNode; style?: React.CSSProperties }) {
  return (
    <div style={{ background: '#111827', border: '1px solid #1e293b', borderRadius: 8, padding: 16, ...style }}>
      <h3 style={{ margin: '0 0 12px', fontSize: 14, fontWeight: 600, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: 0.5 }}>{title}</h3>
      {children}
    </div>
  );
}

function StatBox({ label, value, unit, color }: { label: string; value: string | number; unit?: string; color?: string }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ fontSize: 28, fontWeight: 700, color: color ?? '#e0e6ed', fontVariantNumeric: 'tabular-nums' }}>
        {value}<span style={{ fontSize: 14, fontWeight: 400, color: '#64748b' }}>{unit}</span>
      </div>
      <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>{label}</div>
    </div>
  );
}

function SeverityBadge({ severity }: { severity: string }) {
  const s = severity.toLowerCase();
  const color = s.includes('critical') ? '#ef4444' : s.includes('major') ? '#f59e0b' : s.includes('minor') ? '#3b82f6' : '#64748b';
  return <span style={{ background: color + '22', color, padding: '2px 8px', borderRadius: 4, fontSize: 11, fontWeight: 600 }}>{severity}</span>;
}

function StateBadge({ state }: { state: string }) {
  const s = state.toLowerCase();
  const color = s.includes('active') ? '#ef4444' : s.includes('cleared') ? '#22c55e' : s.includes('closed') ? '#64748b' : '#94a3b8';
  return <span style={{ background: color + '22', color, padding: '2px 8px', borderRadius: 4, fontSize: 11, fontWeight: 600 }}>{state}</span>;
}

// ─── Tabs ───────────────────────────────────────────────────────────────────

function OverviewTab({ building, equipment, points, activeAlarms, liveUpdates }: {
  building?: Building;
  equipment: Equipment[];
  points: Point[];
  activeAlarms: Alarm[];
  liveUpdates: WsMessage[];
}) {
  const alarmPoints = points.filter((p) => p.alarm_enabled);
  const equipByType: Record<string, number> = {};
  equipment.forEach((e) => { equipByType[e.equipment_type] = (equipByType[e.equipment_type] ?? 0) + 1; });

  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: 16 }}>
      {/* Stats */}
      <Card title="系统概况" style={{ gridColumn: 'span 2' }}>
        <div style={{ display: 'flex', justifyContent: 'space-around', flexWrap: 'wrap', gap: 16 }}>
          <StatBox label="设备总数" value={equipment.length} color="#60a5fa" />
          <StatBox label="监控点位" value={points.length} color="#34d399" />
          <StatBox label="告警点位" value={alarmPoints.length} color="#fbbf24" />
          <StatBox label="活跃告警" value={activeAlarms.length} color={activeAlarms.length > 0 ? '#ef4444' : '#22c55e'} />
        </div>
      </Card>

      {/* Building Info */}
      <Card title="楼宇信息">
        {building ? (
          <div style={{ fontSize: 13, lineHeight: 2 }}>
            <div><span style={{ color: '#64748b' }}>编码:</span> {building.code}</div>
            <div><span style={{ color: '#64748b' }}>名称:</span> {building.name}</div>
            {building.total_area && <div><span style={{ color: '#64748b' }}>面积:</span> {building.total_area.toLocaleString()} m²</div>}
            {building.floors_above && <div><span style={{ color: '#64748b' }}>楼层:</span> 地上{building.floors_above}层 {building.floors_below ? `地下${building.floors_below}层` : ''}</div>}
            <div><span style={{ color: '#64748b' }}>状态:</span> <span style={{ color: '#22c55e' }}>{building.status}</span></div>
          </div>
        ) : <div style={{ color: '#64748b' }}>加载中...</div>}
      </Card>

      {/* Equipment breakdown */}
      <Card title="设备分布">
        <div style={{ fontSize: 13, lineHeight: 2 }}>
          {Object.entries(equipByType).sort((a, b) => b[1] - a[1]).map(([type, count]) => (
            <div key={type} style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#94a3b8' }}>{type}</span>
              <span style={{ fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{count}</span>
            </div>
          ))}
        </div>
      </Card>

      {/* Active Alarms */}
      <Card title="活跃告警" style={{ gridColumn: 'span 2' }}>
        {activeAlarms.length === 0 ? (
          <div style={{ color: '#22c55e', fontSize: 13 }}>无活跃告警</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {activeAlarms.slice(0, 5).map((a) => (
              <div key={a.id} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}>
                <SeverityBadge severity={a.severity} />
                <span style={{ flex: 1 }}>{a.title}</span>
                <span style={{ color: '#64748b', fontSize: 11 }}>{new Date(a.triggered_at).toLocaleTimeString()}</span>
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* Live Feed */}
      <Card title="实时数据流" style={{ gridColumn: 'span 2' }}>
        {liveUpdates.length === 0 ? (
          <div style={{ color: '#64748b', fontSize: 13 }}>等待 MQTT 数据...</div>
        ) : (
          <div style={{ fontFamily: 'monospace', fontSize: 12, maxHeight: 200, overflow: 'auto' }}>
            {liveUpdates.slice(0, 15).map((msg, i) => (
              <div key={i} style={{ padding: '2px 0', borderBottom: '1px solid #1e293b', display: 'flex', gap: 8 }}>
                <span style={{ color: msg.type === 'alarm' ? '#ef4444' : '#3b82f6', minWidth: 60 }}>{msg.type}</span>
                {msg.type === 'point_update' && (
                  <>
                    <span style={{ color: '#64748b', minWidth: 80 }}>{msg.point_id?.slice(0, 8)}</span>
                    <span style={{ color: '#34d399', fontWeight: 600 }}>{msg.value}</span>
                    <span style={{ color: '#64748b', marginLeft: 'auto' }}>{msg.ts ? new Date(msg.ts).toLocaleTimeString() : ''}</span>
                  </>
                )}
                {msg.type === 'alarm' && (
                  <>
                    <span style={{ color: '#fbbf24' }}>{msg.alarm_code}</span>
                    <span>{msg.title}</span>
                  </>
                )}
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}

function EquipmentTab({ equipment }: { equipment: Equipment[] }) {
  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
        <thead>
          <tr style={{ borderBottom: '1px solid #1e293b', color: '#64748b', textAlign: 'left' }}>
            <th style={{ padding: '8px 12px' }}>编码</th>
            <th style={{ padding: '8px 12px' }}>名称</th>
            <th style={{ padding: '8px 12px' }}>类型</th>
            <th style={{ padding: '8px 12px' }}>子类型</th>
            <th style={{ padding: '8px 12px' }}>厂商</th>
            <th style={{ padding: '8px 12px' }}>型号</th>
            <th style={{ padding: '8px 12px' }}>额定功率</th>
            <th style={{ padding: '8px 12px' }}>状态</th>
          </tr>
        </thead>
        <tbody>
          {equipment.map((e) => (
            <tr key={e.id} style={{ borderBottom: '1px solid #1e293b' }}>
              <td style={{ padding: '8px 12px', fontFamily: 'monospace', color: '#60a5fa' }}>{e.code}</td>
              <td style={{ padding: '8px 12px' }}>{e.name}</td>
              <td style={{ padding: '8px 12px', color: '#94a3b8' }}>{e.equipment_type}</td>
              <td style={{ padding: '8px 12px', color: '#94a3b8' }}>{e.sub_type ?? '-'}</td>
              <td style={{ padding: '8px 12px', color: '#94a3b8' }}>{e.manufacturer ?? '-'}</td>
              <td style={{ padding: '8px 12px', color: '#94a3b8' }}>{e.model ?? '-'}</td>
              <td style={{ padding: '8px 12px', fontVariantNumeric: 'tabular-nums' }}>{e.rated_power ? `${e.rated_power} kW` : '-'}</td>
              <td style={{ padding: '8px 12px' }}><span style={{ color: '#22c55e' }}>{e.status}</span></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function PointsTab({ points }: { points: Point[] }) {
  const [filter, setFilter] = useState('');
  const [groupBy, setGroupBy] = useState<'display_group' | 'none'>('display_group');

  const filtered = points.filter((p) =>
    !filter || p.code.toLowerCase().includes(filter.toLowerCase()) || p.name.includes(filter) || (p.display_group ?? '').includes(filter)
  );

  const grouped = groupBy === 'display_group'
    ? Object.entries(
        filtered.reduce<Record<string, Point[]>>((acc, p) => {
          const g = p.display_group ?? '(未分组)';
          (acc[g] ??= []).push(p);
          return acc;
        }, {})
      ).sort(([a], [b]) => a.localeCompare(b))
    : [['', filtered] as [string, Point[]]];

  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
        <input
          placeholder="搜索点位..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{ background: '#1e293b', color: '#e0e6ed', border: '1px solid #334155', borderRadius: 6, padding: '6px 12px', fontSize: 13, width: 250 }}
        />
        <select
          value={groupBy}
          onChange={(e) => setGroupBy(e.target.value as typeof groupBy)}
          style={{ background: '#1e293b', color: '#e0e6ed', border: '1px solid #334155', borderRadius: 6, padding: '6px 8px', fontSize: 13 }}
        >
          <option value="display_group">按设备分组</option>
          <option value="none">不分组</option>
        </select>
        <span style={{ color: '#64748b', fontSize: 12, alignSelf: 'center' }}>
          {filtered.length} / {points.length} 点位
        </span>
      </div>

      {grouped.map(([group, pts]) => (
        <div key={group} style={{ marginBottom: 16 }}>
          {group && (
            <h3 style={{ fontSize: 14, fontWeight: 600, color: '#60a5fa', margin: '0 0 8px', padding: '4px 0', borderBottom: '1px solid #1e293b' }}>
              {group} ({pts.length})
            </h3>
          )}
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 12 }}>
            <thead>
              <tr style={{ color: '#64748b', textAlign: 'left' }}>
                <th style={{ padding: '4px 8px' }}>编码</th>
                <th style={{ padding: '4px 8px' }}>名称</th>
                <th style={{ padding: '4px 8px' }}>类型</th>
                <th style={{ padding: '4px 8px' }}>单位</th>
                <th style={{ padding: '4px 8px' }}>当前值</th>
                <th style={{ padding: '4px 8px' }}>告警</th>
                <th style={{ padding: '4px 8px' }}>更新时间</th>
              </tr>
            </thead>
            <tbody>
              {pts.sort((a, b) => (a.display_order ?? 99) - (b.display_order ?? 99)).map((p) => {
                const val = p.current_value;
                const numVal = val ? parseFloat(val) : null;
                const isAlarm = p.alarm_enabled && numVal !== null && (
                  (p.alarm_hi_hi !== null && numVal >= p.alarm_hi_hi) ||
                  (p.alarm_hi !== null && numVal >= p.alarm_hi) ||
                  (p.alarm_lo !== null && numVal <= p.alarm_lo) ||
                  (p.alarm_lo_lo !== null && numVal <= p.alarm_lo_lo)
                );
                return (
                  <tr key={p.id} style={{ borderBottom: '1px solid #1e293b', background: isAlarm ? '#7f1d1d22' : undefined }}>
                    <td style={{ padding: '4px 8px', fontFamily: 'monospace', color: '#94a3b8' }}>{p.code}</td>
                    <td style={{ padding: '4px 8px' }}>{p.name}</td>
                    <td style={{ padding: '4px 8px', color: '#64748b' }}>{p.point_class}</td>
                    <td style={{ padding: '4px 8px', color: '#64748b' }}>{p.unit ?? '-'}</td>
                    <td style={{ padding: '4px 8px', fontFamily: 'monospace', fontWeight: 600, color: isAlarm ? '#ef4444' : val ? '#34d399' : '#64748b' }}>
                      {val ?? '-'}
                    </td>
                    <td style={{ padding: '4px 8px' }}>
                      {p.alarm_enabled ? (
                        <span style={{ fontSize: 10, color: '#fbbf24' }}>
                          {[
                            p.alarm_hi_hi !== null && `HH:${p.alarm_hi_hi}`,
                            p.alarm_hi !== null && `H:${p.alarm_hi}`,
                            p.alarm_lo !== null && `L:${p.alarm_lo}`,
                            p.alarm_lo_lo !== null && `LL:${p.alarm_lo_lo}`,
                          ].filter(Boolean).join(' ')}
                        </span>
                      ) : '-'}
                    </td>
                    <td style={{ padding: '4px 8px', color: '#64748b', fontSize: 11 }}>
                      {p.value_timestamp ? new Date(p.value_timestamp).toLocaleTimeString() : '-'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      ))}
    </div>
  );
}

function AlarmsTab({ alarms }: { alarms: Alarm[] }) {
  return (
    <div>
      {alarms.length === 0 ? (
        <div style={{ color: '#64748b', textAlign: 'center', padding: 40 }}>无告警记录</div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #1e293b', color: '#64748b', textAlign: 'left' }}>
              <th style={{ padding: '8px 12px' }}>告警码</th>
              <th style={{ padding: '8px 12px' }}>严重度</th>
              <th style={{ padding: '8px 12px' }}>状态</th>
              <th style={{ padding: '8px 12px' }}>标题</th>
              <th style={{ padding: '8px 12px' }}>触发值</th>
              <th style={{ padding: '8px 12px' }}>阈值</th>
              <th style={{ padding: '8px 12px' }}>触发时间</th>
              <th style={{ padding: '8px 12px' }}>持续(s)</th>
            </tr>
          </thead>
          <tbody>
            {alarms.map((a) => (
              <tr key={a.id} style={{ borderBottom: '1px solid #1e293b' }}>
                <td style={{ padding: '8px 12px', fontFamily: 'monospace', color: '#60a5fa' }}>{a.alarm_code}</td>
                <td style={{ padding: '8px 12px' }}><SeverityBadge severity={a.severity} /></td>
                <td style={{ padding: '8px 12px' }}><StateBadge state={a.state} /></td>
                <td style={{ padding: '8px 12px' }}>{a.title}</td>
                <td style={{ padding: '8px 12px', fontFamily: 'monospace' }}>{a.trigger_value ?? '-'}</td>
                <td style={{ padding: '8px 12px', fontFamily: 'monospace' }}>{a.threshold_value ?? '-'}</td>
                <td style={{ padding: '8px 12px', fontSize: 12 }}>{new Date(a.triggered_at).toLocaleString()}</td>
                <td style={{ padding: '8px 12px', fontVariantNumeric: 'tabular-nums' }}>{a.duration_s ?? '-'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
