#!/usr/bin/env python3
"""Generate CK data dictionary PPT with lineage diagrams."""

import re
import json
import subprocess
import sys

# Ensure pptxgenjs is available
try:
    import pptxgenjs_check
except:
    pass

# ========== Parse script.sql ==========
with open('/Users/apple/Aohua/海豚调度/script.sql', 'r') as f:
    sql_content = f.read()

sql_tables = {}
pattern = r'create table (\w+)\s*\((.*?)\)\s*engine'
matches = re.findall(pattern, sql_content, re.DOTALL | re.IGNORECASE)

for table_name, fields_block in matches:
    fields = []
    depth = 0
    current = ''
    for ch in fields_block:
        if ch == '(':
            depth += 1
            current += ch
        elif ch == ')':
            depth -= 1
            current += ch
        elif ch == ',' and depth == 0:
            fields.append(current.strip())
            current = ''
        else:
            current += ch
    if current.strip():
        fields.append(current.strip())

    parsed = []
    for f in fields:
        f = f.strip()
        if not f:
            continue
        comment_match = re.search(r"comment\s+'([^']*)'", f, re.IGNORECASE)
        comment = comment_match.group(1) if comment_match else ''
        f_clean = re.sub(r"comment\s+'[^']*'", '', f, flags=re.IGNORECASE).strip()
        parts = f_clean.split(None, 1)
        if len(parts) >= 2:
            parsed.append((parts[0], parts[1].strip(), comment))
    sql_tables[table_name] = parsed

# ========== Parse views ==========
view_starts = [(m.group(1), m.start()) for m in re.finditer(r'create view\s+[\w.]+\.(\w+)\s*\(', sql_content, re.IGNORECASE)]
for view_name, start_pos in view_starts:
    paren_start = sql_content.find('(', start_pos)
    if paren_start < 0:
        continue
    depth = 0
    end_pos = paren_start
    for i in range(paren_start, min(paren_start + 10000, len(sql_content))):
        if sql_content[i] == '(':
            depth += 1
        elif sql_content[i] == ')':
            depth -= 1
            if depth == 0:
                end_pos = i
                break
    fields_block = sql_content[paren_start+1:end_pos]

    fields = []
    depth = 0
    current = ''
    for ch in fields_block:
        if ch == '(':
            depth += 1
            current += ch
        elif ch == ')':
            depth -= 1
            current += ch
        elif ch == ',' and depth == 0:
            fields.append(current.strip())
            current = ''
        else:
            current += ch
    if current.strip():
        fields.append(current.strip())

    parsed = []
    for f in fields:
        f = f.strip().strip('`')
        if not f:
            continue
        parts = f.split(None, 1)
        if len(parts) >= 2:
            parsed.append((parts[0].strip('`'), parts[1].strip(), ''))
        elif len(parts) == 1:
            parsed.append((parts[0].strip('`'), '', ''))
    sql_tables[view_name] = parsed

# ========== Parse workflow JSON ==========
with open('/Users/apple/Aohua/海豚调度/workflow_1777516820540.json', 'r') as f:
    workflow_data = json.load(f)

lineage = {}
for wf in workflow_data:
    wf_name = wf['processDefinition']['name']
    for t in wf.get('taskDefinitionList', []):
        params = t.get('taskParams', {})
        if not params:
            continue
        target = params.get('targetTable', '').lower()
        sql = params.get('sql', '')
        if not target or not sql:
            continue
        sql_clean = re.sub(r'--[^\n]*', '', sql)
        sql_clean = re.sub(r'/\*.*?\*/', '', sql_clean, flags=re.DOTALL)
        sources = set()
        for m in re.findall(r'(?:from|join)\s+(\w+)', sql_clean, re.IGNORECASE):
            if not m.startswith('$') and len(m) > 3 and m.lower() != 'dual':
                sources.add(m.lower())
        lineage[target] = {'workflow': wf_name, 'sources': sorted(sources)}

def get_layer(tn):
    t = tn.lower()
    if t.startswith('v_'):
        t = t[2:]
    p = t.split('_')[0].lower()
    if p == 'ods': return 'ODS'
    elif p in ('dim', 'uf') or t.startswith('dim_'): return 'DIM'
    elif p == 'dwd': return 'DWD'
    elif p == 'dws': return 'DWS'
    elif p == 'ads': return 'ADS'
    return 'OTHER'

# ========== Generate JS for pptxgenjs ==========
# Build data as JSON for the JS script
data_export = {
    'tables': {},
    'lineage': lineage
}
for tname, fields in sql_tables.items():
    data_export['tables'][tname] = {
        'layer': get_layer(tname),
        'fields': [(f[0], f[1], f[2]) for f in fields]
    }

# Write temp data file
with open('/Users/apple/Aohua/海豚调度/_ppt_data.json', 'w') as f:
    json.dump(data_export, f, ensure_ascii=False)

print('✅ Data prepared, generating PPT via Node.js...')

# ========== Node.js PPT generation ==========
js_code = r'''
const pptxgen = require("pptxgenjs");
const fs = require("fs");

const data = JSON.parse(fs.readFileSync("/Users/apple/Aohua/海豚调度/_ppt_data.json", "utf8"));
const tables = data.tables;
const lineage = data.lineage;

let pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';
pres.author = 'CaiQingsong';
pres.title = 'CK数据仓库数据字典';

const C = {
  primary: '065A82', secondary: '1C7293', accent: '21295C',
  light: 'E8F4F8', white: 'FFFFFF', text: '2D3436', muted: '636E72',
  success: '00B894', warning: 'FDCB6E', danger: 'E17055',
  ods: 'B2BEC3', dim: '6C5CE7', dwd: '065A82', dws: '1C7293', ads: '00B894'
};

// ========== Slide 1: Title ==========
let s1 = pres.addSlide();
s1.background = { color: C.accent };
s1.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.08, fill: { color: C.secondary } });
s1.addShape(pres.shapes.RECTANGLE, { x: 0, y: 5.545, w: 10, h: 0.08, fill: { color: C.secondary } });
s1.addShape(pres.shapes.RECTANGLE, { x: 0.6, y: 1.5, w: 0.08, h: 2.5, fill: { color: C.secondary } });
s1.addText("CK数据仓库数据字典", { x: 1.0, y: 1.5, w: 8, h: 1.2, fontSize: 42, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });
s1.addText("ClickHouse Data Warehouse Dictionary", { x: 1.0, y: 2.6, w: 8, h: 0.6, fontSize: 16, fontFace: 'Arial', color: C.secondary, margin: 0 });

const totalTables = Object.keys(tables).length;
const totalFields = Object.values(tables).reduce((s, t) => s + t.fields.length, 0);
const stats = [
  { n: String(totalTables), l: '数据表' },
  { n: String(totalFields), l: '字段总数' },
  { n: '6', l: '数据层级' },
  { n: '10', l: '调度工作流' }
];
stats.forEach((st, i) => {
  s1.addText([
    { text: st.n, options: { fontSize: 36, bold: true, color: C.secondary, breakLine: true } },
    { text: st.l, options: { fontSize: 12, color: C.muted } }
  ], { x: 1.0 + i * 2.2, y: 3.5, w: 2, h: 1, align: 'center', valign: 'middle' });
});

// ========== Slide 2: Architecture ==========
let s2 = pres.addSlide();
s2.background = { color: C.white };
s2.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.accent } });
s2.addText("数据分层架构", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 28, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

const layers = [
  { name: 'Oracle', sub: 'NC源系统', color: C.ods, x: 0.3 },
  { name: 'ODS', sub: '贴源层', color: C.ods, x: 2.0 },
  { name: 'DIM', sub: '维度层', color: C.dim, x: 3.7 },
  { name: 'DWD', sub: '明细层', color: C.dwd, x: 5.4 },
  { name: 'DWS', sub: '汇总层', color: C.dws, x: 7.1 },
  { name: 'ADS', sub: '应用层', color: C.ads, x: 8.8 }
];
layers.forEach((l, i) => {
  s2.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: l.x, y: 1.3, w: 1.5, h: 1.6, fill: { color: l.color }, rectRadius: 0.08 });
  s2.addText(l.name, { x: l.x, y: 1.5, w: 1.5, h: 0.5, fontSize: 16, fontFace: 'Arial', color: C.white, bold: true, align: 'center', margin: 0 });
  s2.addText(l.sub, { x: l.x, y: 2.0, w: 1.5, h: 0.4, fontSize: 10, fontFace: 'Arial', color: 'FFFFFFCC', align: 'center', margin: 0 });
  if (i < layers.length - 1) {
    s2.addText("→", { x: l.x + 1.55, y: 1.8, w: 0.4, h: 0.4, fontSize: 18, color: C.muted, align: 'center', margin: 0 });
  }
});

// Table count per layer
const layerCounts = {};
Object.values(tables).forEach(t => { layerCounts[t.layer] = (layerCounts[t.layer] || 0) + 1; });
let countY = 3.3;
Object.entries(layerCounts).forEach(([layer, count]) => {
  s2.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.4, y: countY, w: 9.2, h: 0.35, fill: { color: countY % 2 === 0 ? C.light : C.white }, rectRadius: 0.04 });
  s2.addText(layer, { x: 0.5, y: countY, w: 1.5, h: 0.35, fontSize: 11, fontFace: 'Arial', color: C.text, bold: true, margin: 0 });
  s2.addText(count + "张表", { x: 2.0, y: countY, w: 1.5, h: 0.35, fontSize: 11, fontFace: 'Arial', color: C.muted, margin: 0 });
  countY += 0.4;
});

// ========== Slide 3: Lineage Overview ==========
let s3 = pres.addSlide();
s3.background = { color: C.white };
s3.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.accent } });
s3.addText("血缘关系总览", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 28, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

// Show key lineage chains
const keyChains = [
  { name: '财务数据流', chain: 'gl_balance → dwd_gl_balance', color: C.primary },
  { name: '库存数据流', chain: 'ia_detailledger → ods → dwd_ic_flow → dws_ia_material_day_stock', color: C.secondary },
  { name: '销售利润流', chain: 'so_saleorder → dwd_so_saleorder → dwd_so_profit → ads_sales_profit', color: C.success },
  { name: '维度表流', chain: 'NC维表 → dim_material/dim_client/dim_supplier...', color: C.dim },
  { name: '帆软数据流', chain: 'FR填报表 → dwd_fin_* → rpt_forecast', color: C.warning }
];
keyChains.forEach((kc, i) => {
  let y = 1.2 + i * 0.85;
  s3.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.4, y: y, w: 9.2, h: 0.7, fill: { color: C.light }, rectRadius: 0.06 });
  s3.addShape(pres.shapes.RECTANGLE, { x: 0.4, y: y, w: 0.06, h: 0.7, fill: { color: kc.color } });
  s3.addText(kc.name, { x: 0.6, y: y + 0.05, w: 2.0, h: 0.3, fontSize: 12, fontFace: 'Arial', color: kc.color, bold: true, margin: 0 });
  s3.addText(kc.chain, { x: 0.6, y: y + 0.35, w: 8.8, h: 0.3, fontSize: 9, fontFace: 'Courier New', color: C.muted, margin: 0 });
});

// ========== Slide 4-5: Layer Overview ==========
const layerGroups = { 'DIM': [], 'DWD': [], 'DWS': [], 'ADS': [], 'ODS': [] };
Object.entries(tables).forEach(([name, t]) => {
  if (layerGroups[t.layer]) layerGroups[t.layer].push({ name, fieldCount: t.fields.length });
});

// DIM layer
let s4 = pres.addSlide();
s4.background = { color: C.white };
s4.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.dim } });
s4.addText("DIM维度层 — " + layerGroups.DIM.length + "张表", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 24, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

let dimRows = [
  [
    { text: '表名', options: { bold: true, color: C.white, fill: { color: C.dim } } },
    { text: '字段数', options: { bold: true, color: C.white, fill: { color: C.dim } } },
    { text: '说明', options: { bold: true, color: C.white, fill: { color: C.dim } } }
  ]
];
const dimDesc = {
  'dim_material': '物料主数据', 'dim_client': '客户主数据', 'dim_supplier': '供应商',
  'dim_unit': '计量单位', 'dim_stordoc': '仓库', 'dim_bd_defdoc': '基础档案',
  'dim_bd_defdoclist': '档案目录', 'dim_bd_custsale': '客户销售',
  'dim_formula_product_snap': '配方产品快照', 'dim_row_product_snap': '行产品快照',
  'dim_fact_row_price_snap': '行价格快照', 'dim_formula_product_day_snap': '配方产品日快照',
  'dim_material_rd45': 'RD45物料', 'dim_material_uat': 'UAT物料'
};
layerGroups.DIM.sort((a, b) => a.name.localeCompare(b.name));
layerGroups.DIM.forEach(d => {
  dimRows.push([d.name, String(d.fieldCount), dimDesc[d.name] || '']);
});
s4.addTable(dimRows, { x: 0.3, y: 1.1, w: 9.4, fontSize: 9, fontFace: 'Arial', color: C.text, border: { type: 'solid', pt: 0.5, color: 'DFE6E9' }, colW: [4.0, 1.0, 4.4], rowH: 0.28, autoPage: false });

// DWD layer
let s5 = pres.addSlide();
s5.background = { color: C.white };
s5.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.dwd } });
s5.addText("DWD明细层 — " + layerGroups.DWD.length + "张表", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 24, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

let dwdRows = [
  [
    { text: '表名', options: { bold: true, color: C.white, fill: { color: C.dwd } } },
    { text: '字段数', options: { bold: true, color: C.white, fill: { color: C.dwd } } },
    { text: '说明', options: { bold: true, color: C.white, fill: { color: C.dwd } } }
  ]
];
const dwdDesc = {
  'dwd_gl_balance': '总账科目余额', 'dwd_so_saleorder': '销售订单',
  'dwd_so_profit': '销售利润', 'dwd_so_cost': '销售成本',
  'dwd_ia_monthnab': '库存月度结存', 'dwd_ic_flow': '库存流水',
  'dwd_po_order_detail_all': '采购订单明细', 'dwd_cust_rebate_actual_m': '客户返利',
  'dwd_fin_profit_detail': '财务利润明细', 'dwd_fin_budget_detail': '财务预算明细',
  'dwd_fin_gross_profit': '毛利配置'
};
layerGroups.DWD.sort((a, b) => a.name.localeCompare(b.name));
layerGroups.DWD.forEach(d => {
  dwdRows.push([d.name, String(d.fieldCount), dwdDesc[d.name] || '']);
});
s5.addTable(dwdRows, { x: 0.3, y: 1.1, w: 9.4, fontSize: 8, fontFace: 'Arial', color: C.text, border: { type: 'solid', pt: 0.5, color: 'DFE6E9' }, colW: [4.0, 1.0, 4.4], rowH: 0.25, autoPage: false });

// ========== Slide 6: Core Table Detail (ads_sales_profit) ==========
let s6 = pres.addSlide();
s6.background = { color: C.white };
s6.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.ads } });
s6.addText("核心表: ads_sales_profit_contribution_snap", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 20, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

// Show key fields in 2 columns
const adsTable = tables['ads_sales_profit_contribution_snap'];
const adsKeyFields = adsTable.fields.filter(f => f[2]).slice(0, 40);
let leftFields = adsKeyFields.slice(0, 20);
let rightFields = adsKeyFields.slice(20, 40);

function makeFieldList(fields) {
  return fields.map(f => [
    { text: f[0], options: { bold: true, fontSize: 8, breakLine: true } },
    { text: f[2] || '', options: { fontSize: 7, color: C.muted } }
  ]).flat();
}

s6.addText(makeFieldList(leftFields), { x: 0.3, y: 1.1, w: 4.7, h: 4.3, valign: 'top', margin: 0, lineSpacingMultiple: 1.2 });
s6.addText(makeFieldList(rightFields), { x: 5.2, y: 1.1, w: 4.7, h: 4.3, valign: 'top', margin: 0, lineSpacingMultiple: 1.2 });

// ========== Slide 7: Core Table Detail (dwd_so_saleorder) ==========
let s7 = pres.addSlide();
s7.background = { color: C.white };
s7.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.dwd } });
s7.addText("核心表: dwd_so_saleorder (192字段)", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 20, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

const soTable = tables['dwd_so_saleorder'];
const soKeyFields = soTable.fields.filter(f => f[2]).slice(0, 40);
s7.addText(makeFieldList(soKeyFields.slice(0, 20)), { x: 0.3, y: 1.1, w: 4.7, h: 4.3, valign: 'top', margin: 0, lineSpacingMultiple: 1.2 });
s7.addText(makeFieldList(soKeyFields.slice(20, 40)), { x: 5.2, y: 1.1, w: 4.7, h: 4.3, valign: 'top', margin: 0, lineSpacingMultiple: 1.2 });

// ========== Slide 8: DWS Layer ==========
let s8 = pres.addSlide();
s8.background = { color: C.white };
s8.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.dws } });
s8.addText("DWS汇总层 — " + layerGroups.DWS.length + "张表", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 24, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

let dwsRows = [
  [
    { text: '表名', options: { bold: true, color: C.white, fill: { color: C.dws } } },
    { text: '字段数', options: { bold: true, color: C.white, fill: { color: C.dws } } },
    { text: '说明', options: { bold: true, color: C.white, fill: { color: C.dws } } }
  ]
];
const dwsDesc = {
  'dws_ia_material_day_stock': '物料日库存', 'dws_product_subject_cost': '产品科目成本',
  'dws_so_costsharing': '销售成本分摊', 'dws_cust_rebate_actual_m': '客户返利汇总',
  'dws_formula_product_day': '配方产品日汇总', 'dws_oa_cg_wlbj': 'OA采购物料报表',
  'dws_fr_cg_kcgzb': '帆软采购库存报表', 'dws_sal_so_saleorder': '销售订单汇总'
};
layerGroups.DWS.sort((a, b) => a.name.localeCompare(b.name));
layerGroups.DWS.forEach(d => {
  dwsRows.push([d.name, String(d.fieldCount), dwsDesc[d.name] || '']);
});
s8.addTable(dwsRows, { x: 0.3, y: 1.1, w: 9.4, fontSize: 10, fontFace: 'Arial', color: C.text, border: { type: 'solid', pt: 0.5, color: 'DFE6E9' }, colW: [4.0, 1.0, 4.4], rowH: 0.35, autoPage: false });

// ========== Slide 9: Workflow ==========
let s9 = pres.addSlide();
s9.background = { color: C.white };
s9.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.9, fill: { color: C.accent } });
s9.addText("调度工作流与表的关系", { x: 0.6, y: 0.15, w: 8, h: 0.6, fontSize: 24, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

const wfRows = [
  [
    { text: '工作流', options: { bold: true, color: C.white, fill: { color: C.accent } } },
    { text: '描述', options: { bold: true, color: C.white, fill: { color: C.accent } } },
    { text: '产出表', options: { bold: true, color: C.white, fill: { color: C.accent } } }
  ]
];
const wfDesc = {
  '4job-nc_fin': 'nc财务数据', '1job-nc_sal_profit': 'nc销售利润数据流',
  '2-2sub-dws_ia_material_day_stock': '物料日库存', '2-1job-dwd_ia_monthnab_snap': '库存月度结存',
  '1-1job-dwd_so_saleorder': '销量销售额折扣成本', '0dim-table_1h': '核心维度表1h抽取',
  '9.0create_table_ddl': '建表语句', '3job-FRdata': '帆软数据',
  '2job-nc_stock_1h': 'nc伪实时库存1h', '1-2job-dim_formula_product_snap_1w': '配方产品周快照'
};
const wfTables = {};
Object.entries(lineage).forEach(([target, info]) => {
  if (!wfTables[info.workflow]) wfTables[info.workflow] = [];
  wfTables[info.workflow].push(target);
});
Object.entries(wfTables).forEach(([wf, tbls]) => {
  wfRows.push([wf, wfDesc[wf] || '', tbls.slice(0, 5).join(', ') + (tbls.length > 5 ? '...' : '')]);
});
s9.addTable(wfRows, { x: 0.3, y: 1.1, w: 9.4, fontSize: 8, fontFace: 'Arial', color: C.text, border: { type: 'solid', pt: 0.5, color: 'DFE6E9' }, colW: [3.0, 2.5, 3.9], rowH: 0.35, autoPage: false });

// ========== Slide 10: Summary ==========
let s10 = pres.addSlide();
s10.background = { color: C.accent };
s10.addShape(pres.shapes.RECTANGLE, { x: 0, y: 0, w: 10, h: 0.08, fill: { color: C.secondary } });
s10.addShape(pres.shapes.RECTANGLE, { x: 0, y: 5.545, w: 10, h: 0.08, fill: { color: C.secondary } });
s10.addText("统计汇总", { x: 0.6, y: 0.5, w: 8, h: 0.8, fontSize: 36, fontFace: 'Arial', color: C.white, bold: true, margin: 0 });

const summaryData = [
  ['层级', '表数量', '字段总数'],
  ['ODS', String(layerGroups.ODS?.length || 0), String((layerGroups.ODS || []).reduce((s, t) => s + t.fieldCount, 0))],
  ['DIM', String(layerGroups.DIM.length), String(layerGroups.DIM.reduce((s, t) => s + t.fieldCount, 0))],
  ['DWD', String(layerGroups.DWD.length), String(layerGroups.DWD.reduce((s, t) => s + t.fieldCount, 0))],
  ['DWS', String(layerGroups.DWS.length), String(layerGroups.DWS.reduce((s, t) => s + t.fieldCount, 0))],
  ['ADS', String(layerGroups.ADS?.length || 0), String((layerGroups.ADS || []).reduce((s, t) => s + t.fieldCount, 0))],
  ['其他', String(totalTables - Object.values(layerGroups).flat().length), '-'],
  ['总计', String(totalTables), String(totalFields)]
];
s10.addTable(summaryData, { x: 1.5, y: 1.8, w: 7, fontSize: 14, fontFace: 'Arial', color: C.white, border: { type: 'solid', pt: 1, color: C.secondary }, colW: [2.3, 2.3, 2.3], rowH: 0.45, autoPage: false });

// Save
pres.writeFile({ fileName: "/Users/apple/Aohua/海豚调度/CK数据仓库数据字典.pptx" })
  .then(() => console.log("PPT created successfully!"))
  .catch(err => console.error("Error:", err));
''';

with open('/Users/apple/Aohua/海豚调度/_gen_ppt.js', 'w') as f:
    f.write(js_code)

# Run the JS
result = subprocess.run(['node', '/Users/apple/Aohua/海豚调度/_gen_ppt.js'], capture_output=True, text=True, cwd='/Users/apple/Aohua/海豚调度')
print(result.stdout)
if result.stderr:
    print(result.stderr)

# Cleanup temp files
import os
os.remove('/Users/apple/Aohua/海豚调度/_ppt_data.json')
os.remove('/Users/apple/Aohua/海豚调度/_gen_ppt.js')
