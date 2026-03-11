# 数据中心行业场景定义

> **Container**: `data-center`
> **定位**: 楼宇远程运营平台的数据中心行业 Container，专注于 IDC/企业数据中心的制冷、供配电、环境安全及容量管理。
> **适用场景**: Tier I~IV 数据中心的远程运维，涵盖精密空调、液冷、自然冷却、供配电、消防安全、容量管理全链路。

---

## 目录

1. [数据中心系统全景](#1-数据中心系统全景)
2. [标准告警规则](#2-标准告警规则)
3. [标准排程模板](#3-标准排程模板)
4. [运营场景剧本](#4-运营场景剧本playbook)
5. [核心 KPI](#5-核心-kpi)
6. [Tier 等级对比](#6-tier-等级对比)
7. [与 base 层对接说明](#7-与-base-层的对接说明)

---

## 1. 数据中心系统全景

### 1.1 设备树

```
数据中心设备树
├── 制冷系统 (Cooling)
│   ├── 精密空调 (CRAC) × N 台
│   │   ├── 压缩机
│   │   ├── 送风机（含 VFD/EC 风机）
│   │   ├── 加湿器（电极/红外）
│   │   ├── 电加热器
│   │   ├── 空气过滤器
│   │   └── 温湿度传感器组
│   │
│   ├── 冷冻水精密空调 (CRAH) × N 台
│   │   ├── 冷冻水盘管 + 电动阀
│   │   ├── EC 风机
│   │   ├── 加湿器
│   │   └── 温湿度传感器组
│   │
│   ├── 列间空调 (In-Row) × N 台
│   │   ├── 冷冻水盘管/直膨盘管
│   │   ├── EC 风机
│   │   └── 温湿度传感器组
│   │
│   ├── 后门换热器 (RDHX) × N 台
│   │   ├── 冷冻水盘管
│   │   ├── 风扇组
│   │   └── 进出水温度传感器
│   │
│   ├── 冷冻水系统 (Chilled Water Plant)
│   │   ├── 冷水机组 (Chiller) × N 台
│   │   ├── 冷冻水泵 (CHWP) × N 台
│   │   ├── 冷却水泵 (CWP) × N 台
│   │   ├── 冷却塔 (CT) × N 台
│   │   ├── 板式换热器 (PHE，自然冷却用)
│   │   └── 分集水器 + 定压补水
│   │
│   ├── 液冷系统 (Liquid Cooling)
│   │   ├── CDU (Coolant Distribution Unit) × N 台
│   │   ├── 一次侧/二次侧循环泵
│   │   ├── 冷却液管路（机柜级）
│   │   ├── 冷板/浸没式模块
│   │   └── 泄漏检测传感器
│   │
│   └── 自然冷却 (Free Cooling)
│       ├── 水侧经济器（板换 + 旁通阀）
│       ├── 风侧经济器（风阀 + 过滤）
│       └── 间接蒸发冷却机组（如有）
│
├── 供配电系统 (Electrical)
│   ├── 高压配电 (HV)
│   │   ├── 10kV 进线柜 × 2 路
│   │   ├── 高压开关柜
│   │   └── 变压器 × N 台
│   │
│   ├── ATS/STS（自动/静态转换开关）
│   │   ├── ATS × N 台
│   │   └── STS × N 台
│   │
│   ├── UPS（不间断电源）× N 台
│   │   ├── 整流器
│   │   ├── 逆变器
│   │   ├── 静态旁路
│   │   └── 电池组 (铅酸/锂电)
│   │
│   ├── 柴油发电机 × N 台
│   │   ├── 发动机 + 发电机
│   │   ├── 燃油系统（日用油箱 + 储油罐）
│   │   ├── 冷却系统
│   │   └── ATS 联动
│   │
│   └── PDU（配电单元）
│       ├── 列头柜 PDU × N 台
│       │   ├── 主路/支路断路器
│       │   ├── 每路电流/功率监测
│       │   └── SPD（浪涌保护）
│       └── 机架 PDU × N 条
│           ├── 每路/每插位功率监测
│           └── 远程开关（智能 PDU）
│
├── 环境安全系统 (Environmental & Safety)
│   ├── VESDA（极早期烟雾探测）
│   ├── 气体灭火系统（七氟丙烷/IG541）
│   │   ├── 灭火剂瓶组 + 压力监测
│   │   ├── 喷头 + 管网
│   │   └── 联动控制（断电/关风阀/延时释放）
│   ├── 漏水检测系统
│   │   ├── 漏水检测绳（精密空调下/管道沿线）
│   │   └── 定位型漏水检测（可定位泄漏点）
│   ├── 温湿度传感器（高密度部署）
│   │   ├── 冷通道入口传感器
│   │   ├── 热通道出口传感器
│   │   └── 机柜中部传感器
│   ├── CCTV 监控
│   └── 门禁系统
│
└── 容量管理 (Capacity)
    ├── 机柜 U 位管理
    ├── 电力容量管理（kW/机柜）
    ├── 冷量容量管理（kW）
    └── 网络端口管理
```

### 1.2 核心点位清单

#### 1.2.1 精密空调 CRAC（直膨式）

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行状态 | CRAC_Status | DI | - | R | ON/OFF/FAULT | 机组状态 |
| 启停命令 | CRAC_CMD | DO | - | W | ON/OFF | 远程启停 |
| 送风温度 | CRAC_SA_Temp | AI | °C | R | 15.0~25.0 | 送风温度 |
| 回风温度 | CRAC_RA_Temp | AI | °C | R | 20.0~35.0 | 回风温度 |
| 回风湿度 | CRAC_RA_RH | AI | %RH | R | 20~80 | 回风相对湿度 |
| 温度设定 | CRAC_Temp_SP | AO | °C | R/W | 18.0~27.0 | 温度设定值 |
| 湿度设定 | CRAC_RH_SP | AO | %RH | R/W | 40~60 | 湿度设定值 |
| 风机转速 | CRAC_Fan_RPM | AI | RPM | R | 0~3000 | EC风机转速 |
| 风量 | CRAC_Airflow | AI | m³/h | R | 0~额定 | 实际风量 |
| 压缩机状态 | CRAC_Comp_Status | DI | - | R | ON/OFF/FAULT | 压缩机运行 |
| 压缩机电流 | CRAC_Comp_Amps | AI | A | R | 0~额定 | 压缩机电流 |
| 高压压力 | CRAC_HP | AI | kPa | R | 800~2500 | 高压侧 |
| 低压压力 | CRAC_LP | AI | kPa | R | 200~600 | 低压侧 |
| 加湿器状态 | CRAC_Humid_Status | DI | - | R | ON/OFF | 加湿运行 |
| 除湿模式 | CRAC_Dehumid | DI | - | R | ON/OFF | 除湿运行 |
| 滤网压差 | CRAC_Filter_DP | AI | Pa | R | 20~300 | 滤网堵塞程度 |
| 总功率 | CRAC_kW | AI | kW | R | 0~额定 | 机组总功率 |
| 运行时间 | CRAC_RunHrs | AI | h | R | 0~99999 | 累计运行 |
| 故障代码 | CRAC_FaultCode | AI | - | R | 厂商定义 | 故障诊断 |

#### 1.2.2 冷冻水精密空调 CRAH

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行状态 | CRAH_Status | DI | - | R | ON/OFF/FAULT | 机组状态 |
| 启停命令 | CRAH_CMD | DO | - | W | ON/OFF | 远程启停 |
| 送风温度 | CRAH_SA_Temp | AI | °C | R | 15.0~25.0 | 送风温度 |
| 回风温度 | CRAH_RA_Temp | AI | °C | R | 25.0~40.0 | 回风温度 |
| 回风湿度 | CRAH_RA_RH | AI | %RH | R | 20~80 | 回风湿度 |
| 温度设定 | CRAH_Temp_SP | AO | °C | R/W | 18.0~27.0 | 温度设定 |
| EC风机转速 | CRAH_Fan_RPM | AI | RPM | R | 0~3000 | 风机转速 |
| 冷水阀开度 | CRAH_CHW_Valve | AO | % | R/W | 0~100 | 冷冻水阀位 |
| 滤网压差 | CRAH_Filter_DP | AI | Pa | R | 20~300 | 滤网堵塞 |
| 总功率 | CRAH_kW | AI | kW | R | 0~额定 | 风机功率 |

#### 1.2.3 列间空调 (In-Row Cooling)

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行状态 | IRC_Status | DI | - | R | ON/OFF/FAULT | 机组状态 |
| 送风温度 | IRC_SA_Temp | AI | °C | R | 15.0~25.0 | 冷通道送风温度 |
| 回风温度 | IRC_RA_Temp | AI | °C | R | 30.0~45.0 | 热通道回风温度 |
| 风机转速 | IRC_Fan_RPM | AI | RPM | R | 0~3000 | EC风机 |
| 冷水阀开度 | IRC_CHW_Valve | AO | % | R/W | 0~100 | 冷冻水阀位 |
| 总功率 | IRC_kW | AI | kW | R | 0~额定 | 风机功率 |

#### 1.2.4 后门换热器 (RDHX)

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行状态 | RDHX_Status | DI | - | R | ON/OFF | 运行状态 |
| 进水温度 | RDHX_In_Temp | AI | °C | R | 10.0~20.0 | 冷冻水进水 |
| 出水温度 | RDHX_Out_Temp | AI | °C | R | 18.0~35.0 | 冷冻水出水 |
| 风扇转速 | RDHX_Fan_RPM | AI | RPM | R | 0~3000 | 风扇组转速 |
| 散热量 | RDHX_kW_cool | AI | kW | R | 0~额定 | 散热功率 |

#### 1.2.5 液冷系统 CDU

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行状态 | CDU_Status | DI | - | R | ON/OFF/FAULT | CDU 状态 |
| 一次侧供水温度 | CDU_Pri_Supply_T | AI | °C | R | 6.0~18.0 | 冷冻水进 CDU |
| 一次侧回水温度 | CDU_Pri_Return_T | AI | °C | R | 12.0~30.0 | 冷冻水出 CDU |
| 二次侧供液温度 | CDU_Sec_Supply_T | AI | °C | R | 25.0~45.0 | 冷却液供 IT |
| 二次侧回液温度 | CDU_Sec_Return_T | AI | °C | R | 35.0~60.0 | 冷却液回 CDU |
| 二次侧流量 | CDU_Sec_Flow | AI | L/min | R | 0~额定 | 冷却液流量 |
| 二次侧压力 | CDU_Sec_Press | AI | kPa | R | 50~400 | 冷却液压力 |
| 泵状态 | CDU_Pump_Status | DI | - | R | ON/OFF/FAULT | 循环泵 |
| 泄漏检测 | CDU_Leak | DI | - | R | NORMAL/ALARM | 泄漏报警 |
| 总功率 | CDU_kW | AI | kW | R | 0~额定 | CDU 功率 |
| 冷却液液位 | CDU_Level | AI | % | R | 0~100 | 冷却液箱液位 |

#### 1.2.6 自然冷却 (Free Cooling)

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 模式 | FC_Mode | DI | - | R | OFF/PARTIAL/FULL | 自然冷却模式 |
| 水侧经济器阀位 | FC_WS_Valve | AO | % | R/W | 0~100 | 板换旁通阀 |
| 风侧经济器风阀 | FC_AS_Damper | AO | % | R/W | 0~100 | 新风阀开度 |
| 室外温度 | OAT | AI | °C | R | -20~50 | 室外干球温度 |
| 室外湿球温度 | OA_WB | AI | °C | R | -25~35 | 湿球温度 |
| 切换条件满足 | FC_Ready | DI | - | R | YES/NO | 满足切换条件 |
| 节省功率 | FC_Savings_kW | AI | kW | R | 0~N | 节省的压缩机功率 |

> **水侧切换条件**: 室外湿球温度 < 冷冻水回水设定 - 3°C，持续 15min
> **风侧切换条件**: 室外干球温度 < 18°C 且 室外湿度 < 80%RH

#### 1.2.7 市电进线 / 高压配电

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| A路市电状态 | Mains_A_Status | DI | - | R | NORMAL/FAIL | 第一路市电 |
| B路市电状态 | Mains_B_Status | DI | - | R | NORMAL/FAIL | 第二路市电 |
| A路电压(三相) | Mains_A_V_abc | AI | V | R | 9500~10500 | 10kV 线电压 |
| B路电压(三相) | Mains_B_V_abc | AI | V | R | 9500~10500 | 10kV 线电压 |
| A路功率 | Mains_A_kW | AI | kW | R | 0~额定 | A路总有功 |
| B路功率 | Mains_B_kW | AI | kW | R | 0~额定 | B路总有功 |
| 变压器温度 | XFMR_Temp | AI | °C | R | 20~120 | 绕组温度 |

#### 1.2.8 ATS / STS

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 当前供电源 | ATS_Source | DI | - | R | MAINS_A/MAINS_B/GEN | 当前供电路径 |
| 切换次数 | ATS_SwitchCnt | AI | 次 | R | 0~N | 累计切换次数 |
| 切换时间 | ATS_SwitchTime | AI | ms | R | 0~500 | 上次切换耗时 |
| STS 输出电压 | STS_Out_V | AI | V | R | 380~420 | 输出线电压 |
| STS 输出电流 | STS_Out_A | AI | A | R | 0~额定 | 输出电流 |
| STS 负载率 | STS_Load | AI | % | R | 0~100 | 负载率 |

#### 1.2.9 UPS

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行模式 | UPS_Mode | DI | - | R | NORMAL/BATTERY/BYPASS/ECO | 运行模式 |
| 输入电压 | UPS_In_V | AI | V | R | 340~440 | 输入线电压 |
| 输入电流 | UPS_In_A | AI | A | R | 0~额定 | 输入电流 |
| 输出电压 | UPS_Out_V | AI | V | R | 380~420 | 输出线电压 |
| 输出电流 | UPS_Out_A | AI | A | R | 0~额定 | 输出电流 |
| 输出功率 | UPS_Out_kW | AI | kW | R | 0~额定 | 输出有功功率 |
| 输出视在功率 | UPS_Out_kVA | AI | kVA | R | 0~额定 | 输出视在功率 |
| 负载率 | UPS_Load | AI | % | R | 0~100 | 负载百分比 |
| 电池电压 | BAT_V | AI | V | R | 因组数而异 | 电池组电压 |
| 电池电流 | BAT_A | AI | A | R | 充正放负 | 电池充放电电流 |
| 电池 SOC | BAT_SOC | AI | % | R | 0~100 | 剩余电量 |
| 电池温度 | BAT_Temp | AI | °C | R | 15~40 | 电池组温度 |
| 预估后备时间 | BAT_Remain_min | AI | min | R | 0~N | 剩余放电时间 |
| UPS 故障 | UPS_Fault | DI | - | R | NORMAL/FAULT | 故障状态 |
| UPS 告警 | UPS_Alarm | DI | - | R | NORMAL/WARN | 告警状态 |

#### 1.2.10 柴油发电机

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 运行状态 | GEN_Status | DI | - | R | STANDBY/RUNNING/FAULT | 发电机状态 |
| 启动命令 | GEN_CMD | DO | - | W | START/STOP | 远程启停 |
| 输出电压 | GEN_Out_V | AI | V | R | 380~420 | 输出线电压 |
| 输出电流 | GEN_Out_A | AI | A | R | 0~额定 | 输出电流 |
| 输出功率 | GEN_Out_kW | AI | kW | R | 0~额定 | 输出功率 |
| 输出频率 | GEN_Freq | AI | Hz | R | 49.5~50.5 | 输出频率 |
| 负载率 | GEN_Load | AI | % | R | 0~100 | 负载百分比 |
| 发动机转速 | GEN_RPM | AI | RPM | R | 0~1500 | 发动机转速 |
| 冷却水温度 | GEN_CoolTemp | AI | °C | R | 20~95 | 发动机水温 |
| 机油压力 | GEN_OilPress | AI | kPa | R | 100~600 | 机油压力 |
| 日用油箱液位 | Fuel_DayTank | AI | % | R | 0~100 | 日用油箱 |
| 储油罐液位 | Fuel_MainTank | AI | % | R | 0~100 | 主储油罐 |
| 电池电压 | GEN_BAT_V | AI | V | R | 22~28 | 启动电池 |
| 运行时间 | GEN_RunHrs | AI | h | R | 0~99999 | 累计运行 |

#### 1.2.11 PDU（列头柜/机架）

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| 总输入电压 | PDU_In_V | AI | V | R | 380~420 | 输入线电压 |
| 总输入电流 | PDU_In_A | AI | A | R | 0~额定 | 总输入电流 |
| 总有功功率 | PDU_Total_kW | AI | kW | R | 0~额定 | 总功率 |
| 总电能 | PDU_Total_kWh | AI | kWh | R | 0~累计 | 累计电能 |
| 支路N电流 | PDU_Br_N_A | AI | A | R | 0~额定 | 每支路电流 |
| 支路N功率 | PDU_Br_N_kW | AI | kW | R | 0~额定 | 每支路功率 |
| 负载率 | PDU_Load | AI | % | R | 0~100 | 总负载率 |

#### 1.2.12 环境安全

| 点位名称 | 英文标识 | 类型 | 单位 | 读/写 | 典型范围 | 说明 |
|---------|---------|------|------|-------|---------|------|
| VESDA 烟雾浓度 | VESDA_Level | AI | %obs/m | R | 0~20 | 烟雾浓度 |
| VESDA 报警级别 | VESDA_Alarm | DI | - | R | NORMAL/ALERT/ACTION/FIRE | 四级报警 |
| 气体灭火瓶组压力 | FE_Bottle_Press | AI | MPa | R | 2.5~5.0 | 灭火剂压力 |
| 气体灭火系统状态 | FE_Status | DI | - | R | ARMED/DISCHARGED/FAULT | 灭火系统 |
| 漏水检测 | WLD_Status | DI | - | R | NORMAL/ALARM | 漏水报警 |
| 漏水定位 | WLD_Location | AI | m | R | 0~N | 泄漏点距检测绳起点 |
| 机柜进风温度 | Cab_Inlet_Temp | AI | °C | R | 15.0~32.0 | 冷通道/机柜前 |
| 机柜排风温度 | Cab_Outlet_Temp | AI | °C | R | 25.0~50.0 | 热通道/机柜后 |
| 区域湿度 | Zone_RH | AI | %RH | R | 8~80 | 区域湿度 |
| 区域露点 | Zone_DewPt | AI | °C | R | -12~24 | 露点温度 |

#### 1.2.13 容量管理

| 点位/指标 | 英文标识 | 类型 | 单位 | 说明 |
|----------|---------|------|------|------|
| 机柜总U位 | Cab_Total_U | Config | U | 机柜可用U位总数 |
| 已用U位 | Cab_Used_U | AI/Manual | U | 已安装设备占用U位 |
| 机柜额定功率 | Cab_Rated_kW | Config | kW | 单柜设计功率上限 |
| 机柜实际功率 | Cab_Actual_kW | AI | kW | 单柜实时功率(PDU读取) |
| 总IT负载 | IT_Total_kW | AI | kW | 全机房IT负载功率 |
| 总冷量 | Cool_Total_kW | Config | kW | 制冷系统设计总冷量 |
| 实际制冷负荷 | Cool_Actual_kW | AI | kW | 实时散热功率 |
| 网络端口总数 | Net_Total_Ports | Config | 个 | 交换机可用端口 |
| 已用端口 | Net_Used_Ports | Manual | 个 | 已使用端口 |

---

## 2. 标准告警规则

### 2.1 制冷系统告警

| 告警名称 | 条件 | 严重度 | 处理建议 |
|---------|------|--------|---------|
| 机柜进风温度偏高 | Cab_Inlet_Temp > 27°C 持续 5min | 警告 | 检查空调运行状态、气流组织、盲板是否缺失 |
| 机柜进风温度过高 | Cab_Inlet_Temp > 32°C 持续 3min | 紧急 | 立即排查热点原因，必要时迁移负载或降低IT功率 |
| 机柜排风温度过高 | Cab_Outlet_Temp > 45°C | 严重 | 检查机柜负载是否超限，空调风量是否充足 |
| 精密空调故障 | CRAC/CRAH_Status = FAULT | 严重 | 启动备用空调，派人检修故障机组 |
| 空调滤网堵塞 | Filter_DP > 200Pa | 警告 | 安排更换滤网，避免风量衰减 |
| 空调滤网严重堵塞 | Filter_DP > 300Pa | 严重 | 立即更换滤网 |
| 冷冻水供水温度偏高 | CHWS_Temp > SP + 2°C 持续 10min | 警告 | 检查冷机负载及冷却水系统 |
| 液冷泄漏 | CDU_Leak = ALARM | 紧急 | 立即关闭对应CDU，隔离泄漏段，现场确认 |
| CDU 二次侧温度偏高 | CDU_Sec_Supply_T > 45°C 持续 5min | 严重 | 检查一次侧冷冻水供应，确认CDU换热正常 |
| CDU 流量不足 | CDU_Sec_Flow < 设计值×60% | 警告 | 检查循环泵运行、管路是否堵塞/气堵 |
| 湿度过低 | Zone_RH < 20% 持续 15min | 警告 | 检查加湿器运行，防止静电放电风险 |
| 湿度过高 | Zone_RH > 80% 或 Zone_DewPt > Cab_Inlet_Temp-3 | 警告 | 检查除湿运行，防止结露 |

### 2.2 供配电系统告警

| 告警名称 | 条件 | 严重度 | 处理建议 |
|---------|------|--------|---------|
| 市电A路中断 | Mains_A_Status = FAIL | 紧急 | 确认ATS/STS已切换至B路，启动发电机备用 |
| 市电B路中断 | Mains_B_Status = FAIL | 紧急 | 确认ATS/STS已切换至A路，启动发电机备用 |
| 双路市电中断 | Mains_A + Mains_B 均 FAIL | 紧急 | 确认发电机启动、UPS 电池接管、通知应急团队 |
| UPS 切换至电池 | UPS_Mode = BATTERY | 严重 | 确认市电/发电机恢复时间，评估后备时长 |
| UPS 电池 SOC 低 | BAT_SOC < 50% 且 UPS_Mode = BATTERY | 紧急 | 准备非关键负载卸载方案 |
| UPS 电池 SOC 极低 | BAT_SOC < 20% 且 UPS_Mode = BATTERY | 紧急 | 执行非关键负载卸载，启动应急关机流程 |
| UPS 故障 | UPS_Fault = FAULT | 紧急 | 确认旁路供电正常，立即派人检修 |
| UPS 负载率过高 | UPS_Load > 85% | 警告 | 评估负载分布，禁止新增负载 |
| 发电机启动失败 | GEN_CMD=START 后 30s GEN_Status≠RUNNING | 紧急 | 手动启动发电机，检查启动电池/燃油/机油 |
| 燃油液位低 | Fuel_DayTank < 30% | 警告 | 从主油罐补油，联系燃油供应商 |
| 燃油液位极低 | Fuel_MainTank < 20% | 严重 | 紧急联系供应商补油，评估可运行时间 |
| 电池温度过高 | BAT_Temp > 35°C | 警告 | 检查电池室空调，高温加速电池老化 |
| PDU 支路过载 | PDU_Br_N_A > 额定×80% | 警告 | 重新分配负载或增加PDU支路 |
| PDU 总负载过高 | PDU_Load > 80% | 警告 | 评估容量，禁止新增负载至该PDU |
| STS 切换异常 | ATS_SwitchTime > 10ms (STS) | 警告 | 检查STS同步状态，安排维保 |
| 变压器温度过高 | XFMR_Temp > 100°C | 严重 | 检查变压器散热、负载率，降载运行 |

### 2.3 环境安全告警

| 告警名称 | 条件 | 严重度 | 处理建议 |
|---------|------|--------|---------|
| VESDA 预警 | VESDA_Alarm = ALERT | 警告 | 现场巡检确认，排查灰尘/施工扬尘干扰 |
| VESDA 行动 | VESDA_Alarm = ACTION | 严重 | 启动消防应急预案，现场确认火情，准备灭火 |
| VESDA 火警 | VESDA_Alarm = FIRE | 紧急 | 执行灭火流程：人员疏散→断电→释放灭火剂 |
| 灭火剂瓶组压力低 | FE_Bottle_Press < 额定×90% | 警告 | 安排检查灭火剂是否泄漏，必要时补充 |
| 漏水报警 | WLD_Status = ALARM | 严重 | 定位泄漏点，关闭相关水阀，清理积水 |
| 机房门禁异常 | 非授权时段有开门 | 警告 | 调阅CCTV确认，通知安保 |

### 2.4 容量告警

| 告警名称 | 条件 | 严重度 | 处理建议 |
|---------|------|--------|---------|
| 机柜功率超限 | Cab_Actual_kW > Cab_Rated_kW × 90% | 警告 | 禁止新增设备，评估是否需迁移负载 |
| 总IT负载接近上限 | IT_Total_kW > 设计容量 × 85% | 警告 | 启动容量扩展规划 |
| 制冷容量不足 | Cool_Actual_kW > Cool_Total_kW × 85% | 警告 | 评估冷量余量，规划扩容 |
| 网络端口不足 | Net_Used_Ports > Net_Total_Ports × 90% | 警告 | 规划网络扩容 |

---

## 3. 标准排程模板

### 3.1 UPS 电池测试排程

| 项目 | 说明 |
|------|------|
| **周期** | 月度（放电测试）/ 季度（深度测试）/ 年度（满负荷测试） |
| **月度测试** | 自动切换电池模式 10min，记录电压曲线和 SOC 下降率 |
| **季度测试** | 电池放电至 SOC=80%，记录各节电池内阻和电压 |
| **年度测试** | 电池放电至 SOC=30%（带负载），评估实际后备时长 |
| **时间窗口** | 周二/三 02:00~06:00（低负载时段） |
| **前置条件** | 双路市电正常、发电机可用、无其他维护窗口 |
| **回退方案** | 测试异常立即切回市电 |

### 3.2 柴油发电机测试排程

| 项目 | 说明 |
|------|------|
| **周期** | 周测（空载）/ 月测（带载30%）/ 季测（带载80%+）/ 年测（满载+黑启动） |
| **周测** | 自动启动发电机运行 15min，确认启动时间 < 10s |
| **月测** | 手动切换负载至发电机运行 30min，验证 ATS 切换 |
| **季测** | 带载 80% 运行 2h，检查水温/油压/排烟正常 |
| **年测** | 满载 4h + 模拟双路失电黑启动 |
| **时间窗口** | 周三 02:00~06:00 |
| **燃油检查** | 每次测试前确认日用油箱 > 80%，主油罐 > 50% |

### 3.3 自然冷却切换排程

| 切换方向 | 触发条件 | 操作步骤 |
|---------|---------|---------|
| 机械制冷→部分自然冷却 | 室外湿球 < 冷冻水回水设定 - 3°C 持续 30min | 1.打开板换旁通阀至50% 2.观察冷冻水温度稳定 3.降低冷机负载 |
| 部分自然冷却→全自然冷却 | 室外湿球 < 冷冻水供水设定 + 2°C 持续 30min | 1.板换旁通阀全开 2.停止冷机(保留1台备用) 3.监控温度 |
| 全自然冷却→部分 | 室外湿球 > 冷冻水供水设定 + 1°C 持续 15min | 1.启动冷机补充冷量 2.调整板换阀位 |
| 自然冷却→机械制冷 | 室外湿球 > 冷冻水回水设定 - 1°C 持续 15min | 1.启动冷机全负荷 2.关闭板换旁通阀 |

### 3.4 维护窗口排程

| 维护类型 | 周期 | 时间窗口 | 影响评估 |
|---------|------|---------|---------|
| 精密空调维保 | 季度 | 周二/三 02:00~06:00 | 单台维护，N+1 冗余保障 |
| UPS 维保 | 半年 | 周日 00:00~06:00 | 旁路运行期间无冗余 |
| 冷水机组维保 | 季度 | 根据自然冷却季节安排 | 需冷量冗余评估 |
| PDU 维保 | 年度 | 需停电窗口 | 提前迁移负载至冗余路径 |
| 消防系统年检 | 年度 | 协调消防部门 | VESDA/灭火系统联动测试 |
| 漏水检测校准 | 半年 | 随空调维保同步 | 喷水模拟测试 |
| 电池内阻测试 | 季度 | 随 UPS 测试同步 | 识别劣化电池单体 |

---

## 4. 运营场景剧本（Playbook）

### 场景1：市电中断全流程

**触发条件**: 任一路或双路市电中断

**操作步骤**:

```
单路中断（A路为例）:
1. T+0s    ATS/STS 自动切换至 B路（STS < 10ms / ATS < 500ms）
2. T+0s    系统生成紧急告警，通知值班工程师+运维主管
3. T+5s    确认 B路供电正常，IT 负载无中断
4. T+30s   发电机自动预启动至热备状态
5. T+5min  联系供电局确认故障原因和预计恢复时间
6. T+持续  每 30min 报告一次供电状态

双路中断:
1. T+0s    UPS 电池接管全部 IT 负载
2. T+0s    系统生成最高级别告警，电话通知所有应急人员
3. T+10s   发电机自动启动（启动时间要求 < 10s）
4. T+15s   确认发电机输出电压/频率正常
5. T+20s   ATS 切换至发电机供电
6. T+30s   确认 UPS 从电池模式切回正常模式
7. T+5min  评估燃油储量，计算可支撑时长
8. T+30min 启动燃油补给流程（如预计停电 > 4h）
9. 市电恢复后: 观察 15min 稳定→ATS 切回市电→发电机冷却运行 15min→停机
```

---

### 场景2：机柜热点处理

**触发条件**: Cab_Inlet_Temp > 27°C 持续 5min

**操作步骤**:

```
1. 定位热点: 确认告警机柜位置、当前温度、相邻机柜温度
2. 初步排查:
   ├── 检查该列空调运行状态（是否故障/降速）
   ├── 检查机柜盲板是否缺失（冷热通道短路）
   ├── 检查地板风口/导风板是否正确
   └── 检查机柜实际功率是否超限
3. 快速缓解:
   ├── 临时增大邻近空调风量
   ├── 降低冷冻水供水温度设定 1~2°C
   └── 高功率设备临时降频/迁移（如可行）
4. 根因处理:
   ├── 补装盲板/封堵气流短路
   ├── 调整地板风口/增加定向导风
   ├── 维修故障空调
   └── 重新评估机柜负载分布
5. 验证: 温度恢复至 ASHRAE 推荐范围（18~27°C）
```

---

### 场景3：自然冷却切换

**触发条件**: 室外湿球温度满足切换条件

**操作步骤**:

```
切入自然冷却:
1. 确认室外湿球温度连续 30min 低于阈值
2. 缓慢开启板式换热器旁通阀（每 5min 增加 20%）
3. 监控冷冻水供水温度，确保波动 < 1°C
4. 逐步降低冷机负载直至停机（保留 1 台热备）
5. 确认全自然冷却模式稳定运行
6. 记录切换时间及节能数据

退出自然冷却:
1. 室外湿球温度上升触发退出条件
2. 提前 15min 启动备用冷机预冷
3. 逐步关闭板换旁通阀
4. 确认冷机接管全部冷量
5. 记录切换时间
```

---

### 场景4：漏水处理

**触发条件**: WLD_Status = ALARM

**操作步骤**:

```
1. T+0s    系统告警，定位泄漏点（WLD_Location）
2. T+1min  值班人员携带工具前往现场
3. T+3min  现场确认泄漏源:
           ├── 空调冷凝水 → 疏通排水管
           ├── 冷冻水管接头 → 关闭对应阀门
           ├── CDU 液冷泄漏 → 关闭 CDU + 隔离管段
           └── 外部渗水 → 通知物业处理
4. 清理积水: 使用吸水器清理，防止扩散至机柜/线缆桥架下方
5. 检查设备: 确认机柜/PDU/线缆无进水损坏
6. 恢复: 修复泄漏点→恢复供水→确认无二次泄漏
7. 报告: 编写事件报告，更新维护计划
```

---

### 场景5：UPS 电池测试

**触发条件**: 月度/季度/年度排程

**操作步骤**:

```
测试前:
1. 确认双路市电正常、发电机可用
2. 确认当前 UPS 负载率 < 80%
3. 通知相关人员进入维护窗口
4. 准备回退方案

月度测试（10min 放电）:
1. 手动将 UPS 切换至电池模式
2. 记录: 初始 SOC、电池电压、放电电流
3. 每 2min 记录一次 SOC 下降曲线
4. 10min 后切回市电模式
5. 计算 SOC 下降率，与历史数据对比

季度测试（放电至 80%）:
1~4. 同月度测试
5. 延长放电至 SOC=80%
6. 使用内阻测试仪测量各节电池
7. 标记内阻异常（偏差>20%）的电池单体
8. 切回市电，确认充电正常

异常处理:
├── SOC 下降过快 → 电池组可能老化，安排深度检测
├── 单节电压偏低 → 标记并安排更换
└── 充电异常 → 检查充电器/电池连接
```

---

### 场景6：新机柜上架

**触发条件**: 客户/业务部门提交上架需求

**操作步骤**:

```
1. 容量审核:
   ├── 电力: 确认 PDU 支路有余量（总负载 < 80%）
   ├── 冷量: 确认机柜位置冷量充足（进风温度达标）
   ├── U位: 确认物理空间可用
   └── 网络: 确认端口和带宽可用

2. 工程准备:
   ├── 分配 PDU 支路（A路+B路双路由）
   ├── 安装设备导轨/托盘
   ├── 布放电源线缆和网线
   └── 安装环境传感器（如该柜新启用）

3. 设备安装:
   ├── 按规划安装设备（从下至上、重设备在下）
   ├── 接入双路 PDU 电源
   ├── 接入网络
   └── 安装盲板封堵空余 U 位

4. 验证:
   ├── PDU 每路电流读数正常
   ├── 设备加电自检通过
   ├── 机柜进风温度在范围内
   └── 更新 DCIM 容量数据

5. 交付: 更新资产台账，交付客户
```

---

### 场景7：VESDA 预警处理

**触发条件**: VESDA_Alarm = ALERT

**操作步骤**:

```
1. ALERT 级别（预警）:
   ├── 系统告警通知值班人员
   ├── 5min 内到达报警区域现场巡检
   ├── 排查常见误报源: 施工扬尘/清洁剂雾气/设备异味
   ├── 如确认无火情 → 记录并消除告警源
   └── 如无法确认 → 保持警戒，持续监控

2. ACTION 级别（行动）:
   ├── 启动消防应急预案
   ├── 现场确认是否有明火/烟雾
   ├── 准备人员疏散（非必要人员撤离机房）
   ├── 准备气体灭火系统（手动模式待命）
   └── 通知消防部门待命

3. FIRE 级别（火警）:
   ├── 人员全部撤离
   ├── 确认所有人员撤出后，关闭机房门
   ├── 手动或自动释放灭火剂（延时 30s 后释放）
   ├── 联动断电: 关闭火灾区域空调（防止助燃）
   ├── 拨打 119
   └── 灭火后: 通风排气→检查设备损坏→编写事故报告
```

---

### 场景8：PUE 优化

**触发条件**: 月度 PUE > 目标值 或 季度性优化评审

**操作步骤**:

```
1. 数据采集与分析:
   ├── 采集 30 天 PUE 趋势（每 15min 粒度）
   ├── 分解: 总能耗 = IT负载 + 制冷 + 配电损耗 + 照明其他
   ├── 制冷能耗占比分析（通常 30~40%）
   └── 识别主要优化方向

2. 制冷优化:
   ├── 提高冷冻水供水温度（每提高 1°C 约省电 2~3%）
   ├── 扩大自然冷却运行时间窗口
   ├── 优化气流组织（封堵冷热通道泄漏）
   ├── 调整空调风机转速与送风温度匹配
   └── 液冷系统: 提高二次侧供液温度

3. 配电优化:
   ├── UPS ECO 模式评估（可降低损耗 2~4%）
   ├── 变压器负载均衡
   └── 淘汰低效设备

4. IT负载优化（与业务协调）:
   ├── 识别低利用率服务器（"僵尸服务器"）
   ├── 推动虚拟化整合
   └── 动态电源管理

5. 验证: 对比优化前后 PUE，量化节能效果
```

---

### 场景9：液冷泄漏处理

**触发条件**: CDU_Leak = ALARM 或现场发现液冷管路渗漏

**操作步骤**:

```
1. T+0s    系统告警定位泄漏 CDU 编号
2. T+30s   远程关闭对应 CDU 二次侧循环泵
3. T+1min  值班人员到场确认泄漏位置和严重程度
4. T+3min  操作:
           ├── 轻微渗漏: 关闭对应机柜液冷阀门，放置接液盘
           ├── 严重泄漏: 关闭 CDU 一次侧+二次侧阀门
           └── 同时: 确认受影响服务器温度，必要时迁移负载
5. 清理: 使用专用吸收材料清理冷却液，防止接触电气设备
6. 修复: 更换泄漏管件/接头/密封件
7. 恢复:
   ├── 管路打压测试（1.5倍工作压力，保持 30min）
   ├── 排气→充液→启动循环泵
   ├── 观察 2h 无泄漏后恢复正常运行
   └── 编写事件报告
```

---

### 场景10：单路供电维护

**触发条件**: PDU/UPS/ATS 计划性单路维护

**操作步骤**:

```
维护前（T-7天~T-1天）:
1. 发布维护通知（受影响区域、时间窗口、风险说明）
2. 确认所有 IT 设备双路供电正常（排查单路供电设备）
3. 确认另一路供电容量可承载全部负载
4. 准备回退方案

维护执行:
1. T+0    确认维护窗口开始，值班人员就位
2. T+5min 手动将待维护路径断电
           ├── 确认 IT 设备全部自动切换至另一路
           ├── 检查有无设备因单路供电而掉电
           └── 确认 PDU 另一路负载率 < 90%
3. T+10min 开始维护操作（更换断路器/UPS模块/线缆等）
4. 维护完成: 合闸送电→确认电压正常→等待 10min 稳定
5. T+end  确认双路供电全部恢复，通知维护结束

异常处理:
├── 发现单路设备掉电 → 立即恢复供电，推迟维护
├── 另一路负载过高 → 临时卸载非关键负载
└── 维护期间另一路故障 → 立即恢复待维护路径（即使未完成）
```

---

## 5. 核心 KPI

### 5.1 KPI 定义与对标

| KPI 名称 | 计算公式 | 优秀 | 良好 | 一般 | 差 | 单位 |
|---------|---------|------|------|------|---|------|
| PUE (电力利用效率) | 总设施功率 / IT 设备功率 | <1.3 | 1.3~1.5 | 1.5~1.8 | >1.8 | - |
| pPUE (部分PUE) | (IT功率+制冷功率) / IT功率 | <1.15 | 1.15~1.3 | 1.3~1.5 | >1.5 | - |
| WUE (水利用效率) | 年用水量(L) / IT设备年能耗(kWh) | <0.5 | 0.5~1.0 | 1.0~1.8 | >1.8 | L/kWh |
| CUE (碳利用效率) | CO2排放(kgCO2) / IT设备能耗(kWh) | <0.3 | 0.3~0.5 | 0.5~0.8 | >0.8 | kgCO2/kWh |
| 温度合规率 | 进风温度在18~27°C时间 / 总运行时间 | >99.5% | 98~99.5% | 95~98% | <95% | % |
| 湿度合规率 | 湿度在ASHRAE范围内时间 / 总运行时间 | >99% | 97~99% | 95~97% | <95% | % |
| IT可用性 | (总时间-IT停机时间) / 总时间 | >99.999% | 99.99~99.999% | 99.9~99.99% | <99.9% | % |
| 电力可用性 | (总时间-供电中断时间) / 总时间 | >99.999% | 99.99% | 99.9% | <99.9% | % |
| 电力容量利用率 | 实际IT负载 / 设计IT容量 | 60~80% | 40~60% | <40% | >85% | % |
| 冷量容量利用率 | 实际散热负荷 / 设计制冷容量 | 60~80% | 40~60% | <40% | >85% | % |
| U位利用率 | 已用U位 / 总可用U位 | 70~85% | 50~70% | <50% | >90% | % |
| 网络端口利用率 | 已用端口 / 总端口 | 60~80% | 40~60% | <40% | >85% | % |
| MTBF | 总运行时间 / 故障次数 | >8760h | 4380~8760h | 2000~4380h | <2000h | h |
| MTTR | 总修复时间 / 修复次数 | <1h | 1~4h | 4~8h | >8h | h |

### 5.2 PUE 计算详解

```
PUE = P_total / P_IT

其中:
  P_total = P_IT + P_cooling + P_elec_loss + P_lighting + P_other

  P_IT          = UPS 输出功率之和（所有 UPS_Out_kW）
  P_cooling     = 冷机 + 冷冻水泵 + 冷却水泵 + 冷却塔风机 + 精密空调风机 + CDU
  P_elec_loss   = 变压器损耗 + UPS 损耗 + PDU 损耗 + 线缆损耗
  P_lighting    = 照明 + 安防 + 消防 + 办公区
  P_other       = 其他辅助设施

PUE 分解:
  PUE = 1 + (P_cooling/P_IT) + (P_elec_loss/P_IT) + (P_other/P_IT)
      = 1 + CLF + ELF + OLF

  CLF (Cooling Load Factor)  = P_cooling / P_IT   # 制冷因子，通常 0.15~0.5
  ELF (Electrical Loss Factor) = P_elec_loss / P_IT  # 配电损耗因子，通常 0.08~0.15
  OLF (Other Load Factor)    = P_other / P_IT      # 其他因子，通常 0.01~0.05
```

### 5.3 WUE 计算详解

```
WUE = W_annual / E_IT_annual  (L/kWh)

其中:
  W_annual    = 冷却塔年补水量(L) + 加湿器年用水量(L) + 其他用水
  E_IT_annual = IT 设备年总能耗 (kWh)

注: 全空冷/全液冷无冷却塔系统 WUE 可接近 0
```

---

## 6. Tier 等级对比

> 参照 Uptime Institute Tier Standard

| 对比维度 | Tier I (基本) | Tier II (冗余组件) | Tier III (可并行维护) | Tier IV (容错) |
|---------|-------------|-------------------|---------------------|---------------|
| **可用性目标** | 99.671% | 99.749% | 99.982% | 99.995% |
| **年停机时间** | ≤28.8h | ≤22.0h | ≤1.6h | ≤0.4h |
| **供电路径** | 单路径 | 单路径 | 双路径(一活一备) | 双路径(同时活动) |
| **配电冗余** | N | N+1 | N+1 | 2N 或 2(N+1) |
| **UPS 冗余** | N | N+1 | N+1 | 2N |
| **发电机** | 可选 | N+1 | N+1 | 2N |
| **制冷冗余** | N | N+1 | N+1 | 2N |
| **不停机维护** | 不支持 | 不支持 | 支持 | 支持 |
| **单点故障容忍** | 有 | 有 | 有（计划维护时） | 无 |
| **市电引入** | 单路 | 单路 | 双路(一主一备) | 双路(同时供电) |
| **典型 PUE** | 2.0~2.5 | 1.6~2.0 | 1.3~1.6 | 1.2~1.4 |
| **建设成本(参考)** | 低 | 中低 | 中高 | 高 |
| **适用场景** | 小型企业/开发测试 | 中小企业 | 大型企业/商业IDC | 金融/电信/核心业务 |

---

## 7. 与 base 层的对接说明

### 7.1 复用的 base 层实体

| base 实体 | 用途 | 引用方式 |
|-----------|------|---------|
| **Organization** | 数据中心运营商/租户组织 | 直接使用 |
| **Site** | 数据中心园区 | 直接使用 |
| **Building** | 数据中心楼栋 | 直接使用，`building_type = DATA_CENTER` |
| **Floor** | 楼层 | 直接使用 |
| **Zone** | 机房/模块/列/机柜行 | 直接使用，扩展 `space_type` 枚举 |
| **System** | 制冷/供配电/消防等子系统 | 直接使用，扩展 `system_type` 枚举 |
| **Equipment** | 空调/UPS/发电机/PDU 等 | 直接使用，扩展设备类型和专属字段 |
| **Component** | 压缩机/电池组/风机等 | 直接使用 |
| **Point** | 所有传感器和控制点位 | 直接使用，扩展行业标签 |
| **Alarm / AlarmRule** | 告警模型和规则 | 直接使用，扩展行业告警规则 |
| **Schedule** | 排程（维护窗口/测试计划） | 直接使用 |
| **WorkOrder** | 维护工单 | 直接使用 |
| **Trend** | 时序数据存储 | 直接使用 |
| **EnergyMeter** | 电力/水计量 | 直接使用 |
| **AuditLog** | 操作审计 | 直接使用 |
| **User / Role / Permission** | RBAC | 直接使用 |

### 7.2 扩展的行业专属字段

#### Equipment 扩展

```
base.Equipment (通用字段)
├── id, name, type, location, status, install_date, ...
│
└── data-center 扩展字段 (metadata):
    ├── cooling_type: enum [CRAC_DX, CRAH_CW, IN_ROW, RDHX, CDU_LIQUID]
    ├── rated_cooling_kw: number          # 额定制冷量
    ├── ups_topology: enum [ONLINE_DOUBLE, LINE_INTERACTIVE, OFFLINE]
    ├── ups_rated_kva: number             # UPS 额定容量
    ├── battery_type: enum [LEAD_ACID, LITHIUM, NICKEL]
    ├── battery_string_count: number      # 电池串数
    ├── battery_design_backup_min: number # 设计后备时间(min)
    ├── generator_rated_kw: number        # 发电机额定功率
    ├── generator_fuel_type: enum [DIESEL, GAS, DUAL_FUEL]
    ├── pdu_rated_amps: number            # PDU 额定电流
    ├── pdu_branch_count: number          # PDU 支路数
    ├── pdu_monitoring_level: enum [TOTAL, BRANCH, OUTLET]  # 监测粒度
    └── tier_level: enum [I, II, III, IV] # 该设备所属冗余等级
```

#### Zone (Space) 扩展

```
base.Zone (通用字段)
├── id, name, type, floor_id, area, ...
│
└── data-center 扩展字段 (metadata):
    ├── dc_zone_type: enum [WHITE_SPACE, GRAY_SPACE, ELECTRICAL_ROOM,
    │                       BATTERY_ROOM, GENERATOR_YARD, COOLING_PLANT,
    │                       LOADING_DOCK, NOC, OFFICE]
    ├── containment_type: enum [COLD_AISLE, HOT_AISLE, NONE]
    ├── raised_floor_height_mm: number    # 架空地板高度
    ├── floor_load_kg_sqm: number         # 地板承重
    ├── design_power_density_kw_rack: number  # 设计功率密度
    ├── rack_count: number                # 机柜数量
    ├── fire_suppression_type: enum [FM200, IG541, NOVEC1230, WATER_MIST]
    └── security_level: enum [L1, L2, L3, L4]  # 安全等级
```

#### Alarm 扩展

```
base.Alarm (通用字段)
├── id, point_id, equipment_id, type, severity, timestamp, ...
│
└── data-center 扩展字段 (metadata):
    ├── dc_category: enum [COOLING, POWER, FIRE_SAFETY, WATER_LEAK,
    │                      SECURITY, CAPACITY, ENVIRONMENTAL]
    ├── impact_scope: enum [SINGLE_RACK, ROW, ROOM, HALL, BUILDING]
    ├── it_impact: enum [NONE, DEGRADED, AT_RISK, SERVICE_DOWN]
    ├── sla_affected: boolean             # 是否影响 SLA
    ├── affected_customer_ids: string[]   # 受影响客户
    ├── auto_response_action: string      # 自动联动动作
    └── tier_compliance_impact: boolean   # 是否影响 Tier 合规
```

### 7.3 新增的行业专属实体

#### CabinetAsset（机柜资产）

```
CabinetAsset
├── id: UUID
├── zone_id: UUID (FK)                  # 所属区域
├── code: string                        # 机柜编码 (如 "A01-R03-C05")
├── row: string                         # 行号
├── position: number                    # 列位
├── total_u: number                     # 总 U 位 (通常 42/47)
├── used_u: number                      # 已用 U 位
├── rated_power_kw: number              # 额定功率
├── pdu_a_id: UUID (FK)                 # A路 PDU
├── pdu_b_id: UUID (FK)                 # B路 PDU
├── network_panel_ids: UUID[]           # 网络配线架
├── weight_capacity_kg: number          # 承重上限
├── current_weight_kg: number           # 当前重量
├── containment_side: enum [COLD, HOT]  # 通道归属
├── customer_id: UUID                   # 客户/租户
├── status: enum [AVAILABLE, IN_USE, RESERVED, MAINTENANCE]
├── metadata: JSON
└── created_at / updated_at: TIMESTAMP
```

#### PowerChainSnapshot（供电链路快照）

```
PowerChainSnapshot
├── id: UUID
├── timestamp: datetime
├── snapshot_interval_min: number       # 快照间隔
├── mains_status: {a: string, b: string}
├── generator_status: [{id, status, kw, load_pct, fuel_level}]
├── ats_sts_status: [{id, source, switch_count}]
├── ups_status: [{id, mode, in_kw, out_kw, load_pct, bat_soc, bat_temp}]
├── pdu_summary: [{id, total_kw, load_pct, branch_max_pct}]
├── total_facility_kw: number
├── total_it_kw: number
├── pue_instant: number                 # 瞬时 PUE
├── cooling_kw: number
└── created_at: datetime
```

#### DcKpiSnapshot（数据中心 KPI 快照）

```
DcKpiSnapshot
├── id: UUID
├── snapshot_type: enum [HOURLY, DAILY, WEEKLY, MONTHLY]
├── period_start / period_end: datetime
│
├── energy_kpis:
│   ├── pue: number
│   ├── ppue: number
│   ├── wue: number
│   ├── cue: number
│   ├── total_energy_kwh: number
│   ├── it_energy_kwh: number
│   ├── cooling_energy_kwh: number
│   └── free_cooling_hours: number
│
├── environment_kpis:
│   ├── temp_compliance_rate: number
│   ├── humidity_compliance_rate: number
│   ├── hotspot_count: number
│   └── avg_delta_t: number             # 平均冷热通道温差
│
├── availability_kpis:
│   ├── it_availability: number
│   ├── power_availability: number
│   ├── cooling_availability: number
│   ├── mtbf_hours: number
│   └── mttr_hours: number
│
├── capacity_kpis:
│   ├── power_utilization: number
│   ├── cooling_utilization: number
│   ├── rack_u_utilization: number
│   └── network_port_utilization: number
│
└── created_at: datetime
```

### 7.4 缺口分析

| 领域 | base 层现状 | data-center 需求 | 建议 |
|------|-----------|-----------------|------|
| **供电链路建模** | Equipment 为扁平结构 | 需要表达"市电→变压器→ATS→UPS→PDU→机柜"链路 | 扩展 Equipment 添加 `power_chain_order` 和 `upstream_equipment_id` |
| **冗余关系** | 无冗余/主备关系 | 需要 A/B 路、主备关系、N+1 组 | 新增 `RedundancyGroup` 实体或在 Equipment.metadata 中增加冗余配置 |
| **容量管理** | 无专门容量实体 | 需要 U 位/电力/冷量/网络四维容量 | 新增 `CabinetAsset` + `CapacityPool` 实体 |
| **SLA 管理** | ComplianceRule 偏通用 | 需要可用性 SLA、响应时间 SLA | 扩展 ComplianceRule 添加 `sla_target` 和 `measurement_method` |
| **变更管理** | WorkOrder 偏维修 | 数据中心需严格变更审批流程 (CAB) | 扩展 WorkOrder 添加 `change_type`、`risk_level`、`cab_approval` |
| **客户/租赁** | Organization 偏运营 | 需要 Colo 客户与机柜/功率的租赁关系 | 新增 `CustomerLease` 实体关联 Organization 和 CabinetAsset |

---

## 附录：术语表

| 缩写 | 英文全称 | 中文 |
|------|---------|------|
| ATS | Automatic Transfer Switch | 自动转换开关 |
| CAB | Change Advisory Board | 变更咨询委员会 |
| CDU | Coolant Distribution Unit | 冷却液分配单元 |
| CRAC | Computer Room Air Conditioner | 机房精密空调（直膨式） |
| CRAH | Computer Room Air Handler | 机房精密空气处理机（冷冻水式） |
| CUE | Carbon Usage Effectiveness | 碳利用效率 |
| DCIM | Data Center Infrastructure Management | 数据中心基础设施管理 |
| PDU | Power Distribution Unit | 配电单元 |
| PHE | Plate Heat Exchanger | 板式换热器 |
| PUE | Power Usage Effectiveness | 电力利用效率 |
| RDHX | Rear Door Heat Exchanger | 后门换热器 |
| SOC | State of Charge | 电池荷电状态 |
| STS | Static Transfer Switch | 静态转换开关 |
| UPS | Uninterruptible Power Supply | 不间断电源 |
| VESDA | Very Early Smoke Detection Apparatus | 极早期烟雾探测系统 |
| WUE | Water Usage Effectiveness | 水利用效率 |
