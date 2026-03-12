const API = '/api/v1';

export interface Equipment {
  id: string;
  code: string;
  name: string;
  equipment_type: string;
  sub_type: string | null;
  manufacturer: string | null;
  model: string | null;
  rated_power: number | null;
  status: string;
}

export interface Point {
  id: string;
  code: string;
  name: string;
  name_en: string | null;
  equipment_id: string | null;
  point_class: string;
  data_type: string;
  unit: string | null;
  current_value: string | null;
  value_timestamp: string | null;
  alarm_enabled: boolean;
  alarm_hi: number | null;
  alarm_hi_hi: number | null;
  alarm_lo: number | null;
  alarm_lo_lo: number | null;
  display_group: string | null;
  display_order: number | null;
}

export interface Alarm {
  id: string;
  alarm_code: string;
  severity: string;
  state: string;
  title: string;
  description: string | null;
  trigger_value: string | null;
  threshold_value: string | null;
  triggered_at: string;
  cleared_at: string | null;
  acknowledged_at: string | null;
  duration_s: number | null;
}

export interface Building {
  id: string;
  code: string;
  name: string;
  address: string | null;
  total_area: number | null;
  floors_above: number | null;
  floors_below: number | null;
  status: string;
}

export async function fetchBuildings(): Promise<Building[]> {
  const r = await fetch(`${API}/buildings`);
  const j = await r.json();
  return j.data ?? j;
}

export async function fetchEquipment(limit = 100): Promise<Equipment[]> {
  const r = await fetch(`${API}/equipment?per_page=${limit}`);
  const j = await r.json();
  return j.data ?? j;
}

export async function fetchPoints(buildingId: string, limit = 200): Promise<Point[]> {
  const r = await fetch(`${API}/points?building_id=${buildingId}&per_page=${limit}`);
  const j = await r.json();
  return j.data ?? j;
}

export async function fetchAlarms(limit = 50): Promise<Alarm[]> {
  const r = await fetch(`${API}/alarms?per_page=${limit}`);
  const j = await r.json();
  return j.data ?? j;
}

export interface WsMessage {
  type: 'point_update' | 'alarm';
  point_id?: string;
  value?: string;
  value_float?: number | null;
  ts?: string;
  alarm_code?: string;
  severity?: string;
  title?: string;
}

export function connectWebSocket(onMessage: (msg: WsMessage) => void): WebSocket {
  const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const ws = new WebSocket(`${proto}//${location.host}/ws`);
  ws.onmessage = (e) => {
    try {
      onMessage(JSON.parse(e.data));
    } catch { /* ignore parse errors */ }
  };
  ws.onclose = () => {
    setTimeout(() => connectWebSocket(onMessage), 3000);
  };
  return ws;
}
