const pptxgen = require("pptxgenjs");

let pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';
pres.author = 'CaiQingsong';
pres.title = '海豚调度数据结构解析';

// Color Palette - Ocean Gradient
const colors = {
  primary: '065A82',    // deep blue
  secondary: '1C7293',  // teal
  accent: '21295C',     // midnight
  light: 'E8F4F8',      // ice blue
  white: 'FFFFFF',
  text: '2D3436',
  muted: '636E72',
  success: '00B894',
  warning: 'FDCB6E',
  danger: 'E17055'
};

// ========== Slide 1: Title ==========
let slide1 = pres.addSlide();
slide1.background = { color: colors.accent };

// Decorative shapes
slide1.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.08, fill: { color: colors.secondary } });
slide1.addShape(pres.shapes.RECTANGLE, { x: 0, y: 5.545, w: 10, h: 0.08, fill: { color: colors.secondary } });

// Left accent bar
slide1.addShape(pres.shapes.RECTANGLE, { x: 0.6, y: 1.5, w: 0.08, h: 2.5, fill: { color: colors.secondary } });

// Title
slide1.addText("海豚调度数据结构解析", {
  x: 1.0, y: 1.5, w: 8, h: 1.2,
  fontSize: 42, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

// Subtitle
slide1.addText("DolphinScheduler Workflow Data Structure Analysis", {
  x: 1.0, y: 2.6, w: 8, h: 0.6,
  fontSize: 16, fontFace: 'Arial', color: colors.secondary, margin: 0
});

// Stats row
slide1.addText([
  { text: "10", options: { fontSize: 36, bold: true, color: colors.secondary, breakLine: true } },
  { text: "工作流", options: { fontSize: 12, color: colors.muted } }
], { x: 1.0, y: 3.5, w: 2, h: 1, align: 'center', valign: 'middle' });

slide1.addText([
  { text: "182", options: { fontSize: 36, bold: true, color: colors.secondary, breakLine: true } },
  { text: "任务节点", options: { fontSize: 12, color: colors.muted } }
], { x: 3.2, y: 3.5, w: 2, h: 1, align: 'center', valign: 'middle' });

slide1.addText([
  { text: "184", options: { fontSize: 36, bold: true, color: colors.secondary, breakLine: true } },
  { text: "依赖关系", options: { fontSize: 12, color: colors.muted } }
], { x: 5.4, y: 3.5, w: 2, h: 1, align: 'center', valign: 'middle' });

slide1.addText([
  { text: "6", options: { fontSize: 36, bold: true, color: colors.secondary, breakLine: true } },
  { text: "任务类型", options: { fontSize: 12, color: colors.muted } }
], { x: 7.6, y: 3.5, w: 2, h: 1, align: 'center', valign: 'middle' });

// Footer
slide1.addText("NC财务系统数据仓库调度方案", {
  x: 1.0, y: 4.8, w: 8, h: 0.4,
  fontSize: 11, fontFace: 'Arial', color: colors.muted, margin: 0
});


// ========== Slide 2: Core Data Structure ==========
let slide2 = pres.addSlide();
slide2.background = { color: colors.white };

// Header bar
slide2.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: colors.accent } });
slide2.addText("核心数据结构", {
  x: 0.6, y: 0.15, w: 8, h: 0.6,
  fontSize: 28, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

// processDefinition box
slide2.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x: 0.4, y: 1.2, w: 4.4, h: 4.0,
  fill: { color: colors.light }, rectRadius: 0.1,
  line: { color: colors.primary, width: 1.5 }
});
slide2.addText("processDefinition", {
  x: 0.6, y: 1.3, w: 4, h: 0.5,
  fontSize: 18, fontFace: 'Arial', color: colors.primary, bold: true, margin: 0
});

const pdFields = [
  { text: "id", options: { bold: true, fontSize: 10 } },
  { text: " : 工作流唯一标识", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "code", options: { bold: true, fontSize: 10 } },
  { text: " : 业务编码（如 170815861314545）", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "name", options: { bold: true, fontSize: 10 } },
  { text: " : 工作流名称", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "version", options: { bold: true, fontSize: 10 } },
  { text: " : 版本号", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "releaseState", options: { bold: true, fontSize: 10 } },
  { text: " : ONLINE/OFFLINE", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "executionType", options: { bold: true, fontSize: 10 } },
  { text: " : PARALLEL", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "locations", options: { bold: true, fontSize: 10 } },
  { text: " : 任务节点坐标 JSON", options: { fontSize: 10 } }
];
slide2.addText(pdFields, {
  x: 0.6, y: 1.8, w: 4, h: 3.2, valign: 'top', margin: 0, lineSpacingMultiple: 1.3
});

// taskDefinitionList box
slide2.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x: 5.2, y: 1.2, w: 4.4, h: 4.0,
  fill: { color: colors.light }, rectRadius: 0.1,
  line: { color: colors.secondary, width: 1.5 }
});
slide2.addText("taskDefinitionList", {
  x: 5.4, y: 1.3, w: 4, h: 0.5,
  fontSize: 18, fontFace: 'Arial', color: colors.secondary, bold: true, margin: 0
});

const tdFields = [
  { text: "code", options: { bold: true, fontSize: 10 } },
  { text: " : 任务业务编码", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "name", options: { bold: true, fontSize: 10 } },
  { text: " : 任务名称", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "taskType", options: { bold: true, fontSize: 10 } },
  { text: " : SHELL/DATAX/SQL/SWITCH...", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "taskParams", options: { bold: true, fontSize: 10 } },
  { text: " : 任务参数（脚本/SQL）", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "workerGroup", options: { bold: true, fontSize: 10 } },
  { text: " : 执行组", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "failRetryTimes", options: { bold: true, fontSize: 10 } },
  { text: " : 失败重试次数", options: { fontSize: 10 } },
  { text: "\n", options: { breakLine: true } },
  { text: "timeoutFlag", options: { bold: true, fontSize: 10 } },
  { text: " : 超时标记", options: { fontSize: 10 } }
];
slide2.addText(tdFields, {
  x: 5.4, y: 1.8, w: 4, h: 3.2, valign: 'top', margin: 0, lineSpacingMultiple: 1.3
});

// Connection arrow
slide2.addShape(pres.shapes.LINE, {
  x: 4.8, y: 3.2, w: 0.4, h: 0,
  line: { color: colors.danger, width: 2, dashType: 'dash' }
});
slide2.addText("1:N", {
  x: 4.85, y: 2.9, w: 0.3, h: 0.3,
  fontSize: 9, color: colors.danger, bold: true, margin: 0
});


// ========== Slide 3: Task Types ==========
let slide3 = pres.addSlide();
slide3.background = { color: colors.white };

slide3.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: colors.accent } });
slide3.addText("任务类型分布", {
  x: 0.6, y: 0.15, w: 8, h: 0.6,
  fontSize: 28, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

const taskTypes = [
  { name: 'DATAX', desc: '数据抽取\nOracle → ClickHouse', color: colors.primary, count: '主' },
  { name: 'SHELL', desc: 'Shell脚本\n获取时间戳/循环', color: colors.secondary, count: '辅' },
  { name: 'SQL', desc: 'SQL执行\n建表/DDL/判断', color: colors.success, count: '辅' },
  { name: 'DEPENDENT', desc: '依赖检查\n工作流起始节点', color: colors.warning, count: '起' },
  { name: 'SUB_PROCESS', desc: '子流程\n复用调度逻辑', color: colors.danger, count: '嵌' },
  { name: 'SWITCH', desc: '条件分支\n按时间/条件路由', color: '6C5CE7', count: '控' }
];

taskTypes.forEach((t, i) => {
  let x = 0.4 + (i % 3) * 3.1;
  let y = 1.2 + Math.floor(i / 3) * 2.1;

  // Card
  slide3.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: x, y: y, w: 2.9, h: 1.9,
    fill: { color: colors.white }, rectRadius: 0.08,
    shadow: { type: 'outer', blur: 4, offset: 2, color: '000000', opacity: 0.1 }
  });

  // Left accent
  slide3.addShape(pres.shapes.RECTANGLE, {
    x: x, y: y, w: 0.06, h: 1.9,
    fill: { color: t.color }
  });

  // Type name
  slide3.addText(t.name, {
    x: x + 0.2, y: y + 0.15, w: 2.5, h: 0.4,
    fontSize: 16, fontFace: 'Arial', color: t.color, bold: true, margin: 0
  });

  // Description
  slide3.addText(t.desc, {
    x: x + 0.2, y: y + 0.6, w: 2.5, h: 1.1,
    fontSize: 10, fontFace: 'Arial', color: colors.muted, margin: 0, lineSpacingMultiple: 1.4
  });
});


// ========== Slide 4: Data Flow Architecture ==========
let slide4 = pres.addSlide();
slide4.background = { color: colors.white };

slide4.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: colors.accent } });
slide4.addText("数据流向架构", {
  x: 0.6, y: 0.15, w: 8, h: 0.6,
  fontSize: 28, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

const layers = [
  { name: '数据源层', sub: 'Oracle / NC', color: 'B2BEC3', x: 0.4 },
  { name: '抽取层', sub: 'DataX / SHELL', color: colors.primary, x: 2.6 },
  { name: '清洗层', sub: 'DWD / DWS', color: colors.secondary, x: 4.8 },
  { name: '应用层', sub: 'ADS', color: colors.success, x: 7.0 },
  { name: '展示层', sub: '帆软报表', color: '6C5CE7', x: 8.6 }
];

layers.forEach((l, i) => {
  // Box
  slide4.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: l.x, y: 1.3, w: 1.8, h: 1.8,
    fill: { color: l.color }, rectRadius: 0.08
  });
  slide4.addText(l.name, {
    x: l.x, y: 1.5, w: 1.8, h: 0.6,
    fontSize: 14, fontFace: 'Arial', color: colors.white, bold: true, align: 'center', margin: 0
  });
  slide4.addText(l.sub, {
    x: l.x, y: 2.1, w: 1.8, h: 0.6,
    fontSize: 10, fontFace: 'Arial', color: 'FFFFFFCC', align: 'center', margin: 0
  });

  // Arrow
  if (i < layers.length - 1) {
    slide4.addShape(pres.shapes.LINE, {
      x: l.x + 1.85, y: 2.2, w: 0.65, h: 0,
      line: { color: colors.muted, width: 1.5 }
    });
    slide4.addText("→", {
      x: l.x + 1.95, y: 1.95, w: 0.5, h: 0.4,
      fontSize: 16, color: colors.muted, align: 'center', margin: 0
    });
  }
});

// Table names
const tableData = [
  [
    { text: '数据层', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '表名', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '说明', options: { bold: true, color: colors.white, fill: { color: colors.accent } } }
  ],
  [
    { text: 'ODS', options: { color: colors.primary, bold: true } },
    { text: 'ods_ia_detailledger', options: {} },
    { text: '明细账(1张)', options: {} }
  ],
  [
    { text: 'DIM', options: { color: '6C5CE7', bold: true } },
    { text: 'dim_material, dim_client, dim_supplier...', options: {} },
    { text: '维度表(17张)', options: {} }
  ],
  [
    { text: 'DWD', options: { color: colors.primary, bold: true } },
    { text: 'dwd_gl_balance, dwd_so_saleorder...', options: {} },
    { text: '明细层(29张)', options: {} }
  ],
  [
    { text: 'DWS', options: { color: colors.secondary, bold: true } },
    { text: 'dws_ia_material_day_stock...', options: {} },
    { text: '汇总层(7张)', options: {} }
  ],
  [
    { text: 'ADS', options: { color: colors.success, bold: true } },
    { text: 'ads_sales_profit_contribution_snap', options: {} },
    { text: '应用层(1张)', options: {} }
  ]
];

slide4.addTable(tableData, {
  x: 0.4, y: 3.4, w: 9.2,
  fontSize: 9, fontFace: 'Arial', color: colors.text,
  border: { type: 'solid', pt: 0.5, color: 'DFE6E9' },
  colW: [1.2, 4.0, 4.0],
  rowH: 0.3
});


// ========== Slide 5: Workflow Dependency (1job-nc_sal_profit) ==========
let slide5 = pres.addSlide();
slide5.background = { color: colors.white };

slide5.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: colors.accent } });
slide5.addText("依赖关系示例 — 1job-nc_sal_profit", {
  x: 0.6, y: 0.15, w: 8, h: 0.6,
  fontSize: 24, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

// Flow diagram with boxes
const flowNodes = [
  { name: '开始', x: 0.4, y: 1.5, w: 1.2, color: colors.success },
  { name: '1.1采购\n物料报表', x: 0.4, y: 2.8, w: 1.5, color: colors.primary },
  { name: '1.2价格\n维护', x: 0.4, y: 4.2, w: 1.5, color: colors.primary },
  { name: '1.1-2采购\n汇总', x: 2.3, y: 2.8, w: 1.5, color: colors.secondary },
  { name: '1.3行价\n快照', x: 4.2, y: 2.8, w: 1.5, color: colors.secondary },
  { name: '1.4库存\n成本', x: 2.3, y: 4.2, w: 1.5, color: colors.primary },
  { name: '1.5折扣\n明细', x: 4.2, y: 4.2, w: 1.5, color: colors.primary },
  { name: '1.6入库\n快照', x: 6.1, y: 4.2, w: 1.5, color: colors.primary },
  { name: '2-1库存\n月结', x: 6.1, y: 1.5, w: 1.5, color: colors.warning },
  { name: '2-2物料\n日库存', x: 6.1, y: 2.8, w: 1.5, color: colors.warning },
  { name: '依赖节点\n2-1,2-2', x: 7.9, y: 2.0, w: 1.5, color: colors.danger },
  { name: 'ads\n销售利润', x: 7.9, y: 3.5, w: 1.5, color: '6C5CE7' }
];

flowNodes.forEach(n => {
  slide5.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: n.x, y: n.y, w: n.w, h: 0.8,
    fill: { color: n.color }, rectRadius: 0.06
  });
  slide5.addText(n.name, {
    x: n.x, y: n.y, w: n.w, h: 0.8,
    fontSize: 8, fontFace: 'Arial', color: colors.white, bold: true,
    align: 'center', valign: 'middle', margin: 0
  });
});

// Arrows (simplified)
const arrows = [
  [1.0, 2.3, 1.17, 0],   // 开始→1.1
  [1.0, 3.7, 1.17, 0],   // 开始→1.2
  [1.0, 2.3, 0, 1.0],    // 开始→2-1
  [1.9, 3.2, 0.4, 0],    // 1.1→1.1-2
  [3.8, 3.2, 0.4, 0],    // 1.1-2→1.3
  [3.8, 4.6, 0.4, 0],    // 1.4→1.5
  [5.7, 4.6, 0.4, 0],    // 1.5→1.6
  [7.6, 2.0, 0.3, 0],    // 2-1→依赖
  [7.6, 3.15, 0.3, 0],   // 2-2→依赖
  [8.65, 2.8, 0, 0.7],   // 依赖→ads
];
arrows.forEach(a => {
  slide5.addShape(pres.shapes.LINE, {
    x: a[0], y: a[1], w: a[2], h: a[3],
    line: { color: colors.muted, width: 1 }
  });
});

// Legend
slide5.addText([
  { text: "图例：", options: { bold: true, fontSize: 9 } },
  { text: "  ■ 开始  ", options: { color: colors.success, fontSize: 9 } },
  { text: "■ 数据抽取(DataX)  ", options: { color: colors.primary, fontSize: 9 } },
  { text: "■ 数据清洗(DWS)  ", options: { color: colors.secondary, fontSize: 9 } },
  { text: "■ 条件判断  ", options: { color: colors.warning, fontSize: 9 } },
  { text: "■ 子流程  ", options: { color: colors.danger, fontSize: 9 } },
  { text: "■ 最终输出", options: { color: '6C5CE7', fontSize: 9 } }
], { x: 0.4, y: 5.1, w: 9, h: 0.4, margin: 0 });


// ========== Slide 6: Scheduling Strategy ==========
let slide6 = pres.addSlide();
slide6.background = { color: colors.white };

slide6.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: colors.accent } });
slide6.addText("调度策略与频率", {
  x: 0.6, y: 0.15, w: 8, h: 0.6,
  fontSize: 28, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

const schedules = [
  { name: 'dim-table_1h', freq: '1小时', type: '维度表', desc: '高峰期1h抽取一次核心维度表', color: colors.danger },
  { name: '2job-nc_stock_1h', freq: '1小时', type: '库存', desc: 'nc伪实时库存流水/月结/采购', color: colors.danger },
  { name: '1job-nc_sal_profit', freq: '2小时', type: '销售利润', desc: 'bom配方/销售订单/返利/折扣', color: colors.warning },
  { name: '1-1job-dwd_so_saleorder', freq: '按需', type: '销售基础', desc: '销量销售额折扣成本基础表', color: colors.primary },
  { name: '3job-FRdata', freq: '每日', type: '帆软', desc: '填报/预算/预测数据流', color: colors.secondary },
  { name: '1-2job-dim_formula', freq: '每周', type: '配方', desc: '周一0~1点执行配方产品快照', color: colors.success }
];

schedules.forEach((s, i) => {
  let y = 1.2 + i * 0.7;

  // Row background
  slide6.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.4, y: y, w: 9.2, h: 0.6,
    fill: { color: i % 2 === 0 ? colors.light : colors.white }, rectRadius: 0.05
  });

  // Frequency badge
  slide6.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.5, y: y + 0.12, w: 1.2, h: 0.36,
    fill: { color: s.color }, rectRadius: 0.04
  });
  slide6.addText(s.freq, {
    x: 0.5, y: y + 0.12, w: 1.2, h: 0.36,
    fontSize: 10, fontFace: 'Arial', color: colors.white, bold: true,
    align: 'center', valign: 'middle', margin: 0
  });

  // Name
  slide6.addText(s.name, {
    x: 1.9, y: y + 0.1, w: 3.5, h: 0.4,
    fontSize: 11, fontFace: 'Arial', color: colors.text, bold: true, margin: 0
  });

  // Type
  slide6.addText(s.type, {
    x: 5.5, y: y + 0.1, w: 1.0, h: 0.4,
    fontSize: 10, fontFace: 'Arial', color: colors.muted, margin: 0
  });

  // Description
  slide6.addText(s.desc, {
    x: 6.5, y: y + 0.1, w: 3.0, h: 0.4,
    fontSize: 10, fontFace: 'Arial', color: colors.muted, margin: 0
  });
});

// Crontab info
slide6.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x: 0.4, y: 4.9, w: 9.2, h: 0.5,
  fill: { color: colors.light }, rectRadius: 0.05
});
slide6.addText([
  { text: "调度配置：", options: { bold: true, fontSize: 10 } },
  { text: "crontab: 0 15 0,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,23 * * ? *  ", options: { fontSize: 10, fontFace: 'Courier New' } },
  { text: "| 失败策略: CONTINUE | 告警: FAILURE", options: { fontSize: 10 } }
], { x: 0.6, y: 4.9, w: 8.8, h: 0.5, margin: 0 });


// ========== Slide 7: Workflow Overview Table ==========
let slide7 = pres.addSlide();
slide7.background = { color: colors.white };

slide7.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: colors.accent } });
slide7.addText("工作流总览", {
  x: 0.6, y: 0.15, w: 8, h: 0.6,
  fontSize: 28, fontFace: 'Arial', color: colors.white, bold: true, margin: 0
});

const overviewData = [
  [
    { text: '#', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '工作流', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '描述', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '任务数', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '关系数', options: { bold: true, color: colors.white, fill: { color: colors.accent } } },
    { text: '状态', options: { bold: true, color: colors.white, fill: { color: colors.accent } } }
  ],
  ['1', '4job-nc_fin', 'nc财务数据', '3', '3', { text: 'ONLINE', options: { color: colors.success } }],
  ['2', '1job-nc_sal_profit', 'nc销售利润数据流', '14', '18', { text: 'ONLINE', options: { color: colors.success } }],
  ['3', '2-2sub-dws_ia_material_day_stock', '物料日库存', '9', '9', { text: 'ONLINE', options: { color: colors.success } }],
  ['4', '2-1job-dwd_ia_monthnab_snap', '库存月度结存', '7', '8', { text: 'ONLINE', options: { color: colors.success } }],
  ['5', '1-1job-dwd_so_saleorder', '销量销售额折扣成本', '33', '37', { text: 'ONLINE', options: { color: colors.success } }],
  ['6', '0dim-table_1h', '核心维度表1h抽取', '41', '41', { text: 'ONLINE', options: { color: colors.success } }],
  ['7', '9.0create_table_ddl', '建表语句', '27', '27', { text: 'OFFLINE', options: { color: colors.danger } }],
  ['8', '3job-FRdata', '帆软数据', '18', '18', { text: 'ONLINE', options: { color: colors.success } }],
  ['9', '2job-nc_stock_1h', 'nc伪实时库存1h', '17', '21', { text: 'ONLINE', options: { color: colors.success } }],
  ['10', '1-2job-dim_formula_product_snap_1w', '配方产品周快照', '11', '11', { text: 'ONLINE', options: { color: colors.success } }]
];

slide7.addTable(overviewData, {
  x: 0.3, y: 1.1, w: 9.4,
  fontSize: 9, fontFace: 'Arial', color: colors.text,
  border: { type: 'solid', pt: 0.5, color: 'DFE6E9' },
  colW: [0.4, 3.2, 2.4, 0.8, 0.8, 1.0],
  rowH: 0.38,
  autoPage: false
});

// Summary stats
slide7.addShape(pres.shapes.ROUNDED_RECTANGLE, {
  x: 0.4, y: 5.0, w: 9.2, h: 0.45,
  fill: { color: colors.light }, rectRadius: 0.05
});
slide7.addText([
  { text: "总计：", options: { bold: true } },
  { text: "10个工作流 | 182个任务节点 | 184个依赖关系 | 9个ONLINE / 1个OFFLINE", options: {} }
], { x: 0.6, y: 5.0, w: 8.8, h: 0.45, fontSize: 10, margin: 0 });


// ========== Save ==========
pres.writeFile({ fileName: "/Users/apple/Aohua/海豚调度/海豚调度数据结构解析.pptx" })
  .then(() => console.log("PPT created successfully!"))
  .catch(err => console.error("Error:", err));
