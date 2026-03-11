# governance-building

楼宇远程运营平台 — 一个人坐在屏幕前，管几百栋楼。

## 架构

```
┌─────────────────────────────────────────────┐
│  酒店 Container  │  医院 Container  │  商场 Container  │  ...
│  (行业专属逻辑)   │  (行业专属逻辑)   │  (行业专属逻辑)   │
├─────────────────────────────────────────────┤
│              公共基础层（base）               │
│  Point · Alarm · Space · Schedule ·         │
│  WorkOrder · Trend · Equipment · Auth       │
└─────────────────────────────────────────────┘
```

## 目录结构

```
governance-building/
├── docs/                    # 分析文档
├── base/                    # 公共基础层（数据模型 + 引擎）
└── containers/              # 行业 Container
    ├── office-hvac/         # 写字楼/HVAC（第一个）
    ├── hotel/               # 酒店（待启动）
    ├── hospital/            # 医院（待启动）
    └── ...
```

## 开发分支

- `base-schema` — 公共基础层数据模型
- `office-hvac` — 写字楼/HVAC 行业场景
