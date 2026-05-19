#!/usr/bin/env python3
"""Generate searchable HTML data dictionary tool with all 5 optimizations."""

import re
import json

# ========== Parse script.sql ==========
with open('/Users/apple/Aohua/海豚调度/script.sql', 'r') as f:
    sql_content = f.read()

# Extract full DDL for each table/view
ddl_map = {}
# Split by CREATE TABLE or CREATE VIEW (with or without schema prefix)
ddl_blocks = re.split(r'(?=create\s+(?:table|view)\s+[\w.]*\.?\w+)', sql_content, flags=re.IGNORECASE)
for block in ddl_blocks:
    block = block.strip()
    if not block:
        continue
    m_table = re.match(r'create\s+table\s+(?:[\w.]+\.)?(\w+)', block, re.IGNORECASE)
    m_view = re.match(r'create\s+view\s+(?:[\w.]+\.)?(\w+)', block, re.IGNORECASE)
    if m_table:
        ddl_map[m_table.group(1).lower()] = block
    elif m_view:
        ddl_map[m_view.group(1).lower()] = block

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
            parsed.append({'name': parts[0], 'type': parts[1].strip(), 'comment': comment})
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
            parsed.append({'name': parts[0].strip('`'), 'type': parts[1].strip(), 'comment': ''})
        elif len(parts) == 1:
            parsed.append({'name': parts[0].strip('`'), 'type': '', 'comment': ''})
    sql_tables[view_name] = parsed

# ========== Parse workflow JSON ==========
with open('/Users/apple/Aohua/海豚调度/workflow_1777516820540.json', 'r') as f:
    workflow_data = json.load(f)

lineage = {}
workflow_tasks = {}  # wf_name -> [{task_name, task_type, target, sql, sources}]
for wf in workflow_data:
    wf_name = wf['processDefinition']['name']
    tasks = []
    for t in wf.get('taskDefinitionList', []):
        task_name = t.get('name', '')
        task_type = t.get('taskType', '')
        params = t.get('taskParams', {})
        target = params.get('targetTable', '').lower() if params else ''
        sql = params.get('sql', '') if params else ''
        sources = []
        if sql:
            sql_clean = re.sub(r'--[^\n]*', '', sql)
            sql_clean = re.sub(r'/\*.*?\*/', '', sql_clean, flags=re.DOTALL)
            src_set = set()
            for m in re.findall(r'(?:from|join)\s+(\w+)', sql_clean, re.IGNORECASE):
                if not m.startswith('$') and len(m) > 3 and m.lower() != 'dual':
                    src_set.add(m.lower())
            sources = sorted(src_set)
        if target:
            lineage[target] = {'workflow': wf_name, 'sources': sources}
        tasks.append({
            'name': task_name,
            'type': task_type,
            'target': target,
            'sql': sql,
            'sources': sources
        })
    workflow_tasks[wf_name] = tasks

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

# ========== Chinese table names ==========
cn_names = {
    # DIM
    'dim_material': '物料主数据', 'dim_client': '客户主数据', 'dim_supplier': '供应商主数据',
    'dim_unit': '计量单位', 'dim_stordoc': '仓库档案', 'dim_bd_defdoc': '基础档案',
    'dim_bd_defdoclist': '档案目录', 'dim_bd_custsale': '客户销售档案',
    'dim_formula_product_snap': '配方产品快照', 'dim_row_product_snap': '行产品快照',
    'dim_fact_row_price_snap': '行价格快照', 'dim_formula_product_day_snap': '配方产品日快照',
    'dim_material_rd45': 'RD45物料', 'dim_material_uat': 'UAT物料',
    'dim_fx_client': '帆软客户', 'dim_fx_organization': '帆软组织',
    'dim_fx_organization_dict': '帆软组织字典', 'dim_fx_organization_dict_parent': '帆软组织上级字典',
    'dim_material_dict': '物料字典', 'dim_client_dict': '客户字典',
    'dim_unit_dict': '单位字典', 'dim_fx_prodline': '帆软产品线',
    'dim_fx_area': '帆软区域',
    # DWD
    'dwd_gl_balance': '总账科目余额', 'dwd_so_saleorder': '销售订单明细',
    'dwd_so_profit': '销售利润', 'dwd_so_cost': '销售成本',
    'dwd_ia_monthnab': '库存月度结存', 'dwd_ic_flow': '库存流水',
    'dwd_po_order_detail_all': '采购订单明细', 'dwd_cust_rebate_actual_m': '客户返利实际月表',
    'dwd_fin_profit_detail': '财务利润明细', 'dwd_fin_budget_detail': '财务预算明细',
    'dwd_fin_gross_profit': '毛利配置', 'dwd_so_priceform': '销售价格表单',
    'dwd_so_saleorder_b': '销售订单明细行', 'dwd_ia_monthnab_snap': '库存月结快照',
    'dwd_fin_cust_forecast': '客户预测明细', 'dwd_fin_cust_budget': '客户预算明细',
    'dwd_fin_dept_forecast': '部门预测明细', 'dwd_fin_dept_budget': '部门预算明细',
    'dwd_fin_profit_budget': '利润预算明细', 'dwd_fin_profit_forecast': '利润预测明细',
    'dwd_fin_rebate_detail': '返利明细', 'dwd_fin_cost_detail': '成本明细',
    'dwd_fin_revenue_detail': '收入明细', 'dwd_fin_expense_detail': '费用明细',
    'dwd_fin_margin_detail': '毛利明细', 'dwd_fin_inventory_detail': '库存财务明细',
    'dwd_fin_cashflow_detail': '现金流明细', 'dwd_fin_asset_detail': '资产明细',
    'dwd_fin_tax_detail': '税务明细', 'dwd_fin_transfer_detail': '转移定价明细',
    'dwd_fin_intercompany_detail': '内部交易明细',
    # DWS
    'dws_ia_material_day_stock': '物料日库存汇总', 'dws_product_subject_cost': '产品科目成本',
    'dws_so_costsharing': '销售成本分摊', 'dws_cust_rebate_actual_m': '客户返利月汇总',
    'dws_formula_product_day': '配方产品日汇总', 'dws_oa_cg_wlbj': 'OA采购物料报价',
    'dws_fr_cg_kcgzb': '帆软采购库存跟踪', 'dws_sal_so_saleorder': '销售订单汇总',
    'dws_fin_profit_m': '月度利润汇总', 'dws_fin_budget_m': '月度预算汇总',
    'dws_fin_forecast_m': '月度预测汇总', 'dws_fin_rebate_m': '月度返利汇总',
    # ADS
    'ads_sales_profit_contribution_snap': '销售利润贡献快照',
    'ads_fin_profit_report': '财务利润报表', 'ads_fin_budget_vs_actual': '预算执行对比',
    'ads_sales_dashboard': '销售看板', 'ads_inventory_dashboard': '库存看板',
    'ads_customer_analysis': '客户分析', 'ads_product_analysis': '产品分析',
    # ODS
    'ods_gl_balance': '总账余额(贴源)', 'ods_so_saleorder': '销售订单(贴源)',
    'ods_ia_detailledger': '库存明细账(贴源)', 'ods_ic_flow': '库存流水(贴源)',
    'ods_po_order': '采购订单(贴源)', 'ods_bd_material': '物料主数据(贴源)',
    'ods_bd_customer': '客户主数据(贴源)', 'ods_bd_supplier': '供应商主数据(贴源)',
    'ods_fx_client_forecast': '帆软客户预测(贴源)',
    # Views
    'v_dim_client': '客户维度视图', 'v_dwd_po_order_detail': '采购订单明细视图',
    'v_dwd_so_saleorder': '销售订单综合视图', 'v_fx_client_forecast': '客户预测视图',
    # Others
    'rpt_forecast': '预测报表', 'tb_fin_profit': '利润台账',
    'crm_customer': 'CRM客户', 'nc_gl_balance': 'NC总账余额',
}

# Build JS data
tables_js = {}
for tname, fields in sql_tables.items():
    tables_js[tname] = {
        'layer': get_layer(tname),
        'fields': fields,
        'lineage': lineage.get(tname, {}),
        'cn_name': cn_names.get(tname, ''),
        'is_view': tname.startswith('v_'),
        'ddl': ddl_map.get(tname.lower(), '')
    }

# Build workflow data for JS
wf_js = {}
for wf_name, tasks in workflow_tasks.items():
    wf_js[wf_name] = [{
        'name': t['name'],
        'type': t['type'],
        'target': t['target'],
        'sql': t['sql'],
        'sources': t['sources']
    } for t in tasks]

# Use ensure_ascii=True to avoid HTML/JS parsing issues with special chars
tables_json = json.dumps(tables_js, ensure_ascii=True)
workflow_json = json.dumps(wf_js, ensure_ascii=True)

print(f'✅ Data prepared: {len(sql_tables)} tables, {len(workflow_tasks)} workflows')
print(f'   DDL extracted for {len(ddl_map)} objects')

# ========== Generate HTML ==========
html = r'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CK数据仓库数据字典</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:#f5f6fa;color:#2d3436}
.header{background:linear-gradient(135deg,#21295C 0%,#065A82 100%);color:#fff;padding:20px 32px;position:sticky;top:0;z-index:100;box-shadow:0 2px 12px rgba(0,0,0,.15)}
.header h1{font-size:22px;margin-bottom:4px}
.header p{font-size:13px;color:rgba(255,255,255,.7)}
.tabs{display:flex;gap:0;margin-top:14px}
.tab-btn{padding:10px 24px;border:none;background:rgba(255,255,255,.15);color:rgba(255,255,255,.8);font-size:14px;cursor:pointer;border-radius:8px 8px 0 0;transition:all .2s}
.tab-btn:hover{background:rgba(255,255,255,.25);color:#fff}
.tab-btn.active{background:#f5f6fa;color:#21295C;font-weight:600}
.controls{display:flex;gap:12px;margin-top:12px;flex-wrap:wrap;align-items:center}
.search-box{flex:1;min-width:200px;padding:10px 16px;border:none;border-radius:8px;font-size:14px;background:rgba(255,255,255,.15);color:#fff;outline:none}
.search-box::placeholder{color:rgba(255,255,255,.5)}
.search-box:focus{background:rgba(255,255,255,.25)}
.layer-btn{padding:8px 16px;border:2px solid #dfe6e9;border-radius:20px;background:#fff;color:#636e72;font-size:13px;cursor:pointer;transition:all .2s}
.layer-btn:hover{border-color:#065A82;color:#065A82}
.layer-btn.active{background:#065A82;color:#fff;border-color:#065A82;font-weight:600}
.stats{display:flex;gap:20px;margin-top:10px}
.stat{font-size:12px;color:rgba(255,255,255,.6)}
.stat strong{color:#fff;font-size:14px}
.container{max-width:1200px;margin:0 auto;padding:20px}
.tab-content{display:none}
.tab-content.active{display:block}
.table-card{background:#fff;border-radius:12px;margin-bottom:12px;box-shadow:0 1px 4px rgba(0,0,0,.06);overflow:hidden;transition:box-shadow .2s}
.table-card:hover{box-shadow:0 4px 16px rgba(0,0,0,.1)}
.table-card.auto-open{box-shadow:0 4px 16px rgba(6,90,130,.15);border:1px solid rgba(6,90,130,.2)}
.table-header{padding:14px 20px;cursor:pointer;display:flex;align-items:center;gap:12px}
.table-header:hover{background:#f8f9fa}
.layer-badge{padding:3px 10px;border-radius:12px;font-size:11px;font-weight:600;color:#fff;flex-shrink:0}
.layer-ODS{background:#b2bec3}.layer-DIM{background:#6c5ce7}.layer-DWD{background:#065A82}.layer-DWS{background:#1C7293}.layer-ADS{background:#00b894}.layer-OTHER{background:#636e72}
.table-name{font-weight:600;font-size:14px;flex:1}
.cn-name{font-size:12px;color:#636e72;margin-left:6px;font-weight:400}
.table-meta{font-size:12px;color:#636e72;flex-shrink:0}
.expand-icon{font-size:18px;color:#b2bec3;transition:transform .2s;flex-shrink:0}
.table-card.open .expand-icon{transform:rotate(90deg)}
.table-detail{display:none;border-top:1px solid #eee}
.table-card.open .table-detail{display:block}
.lineage-section{padding:12px 20px;background:#f8f9fa;border-bottom:1px solid #eee}
.lineage-section h4{font-size:12px;color:#636e72;margin-bottom:6px}
.lineage-tags{display:flex;flex-wrap:wrap;gap:6px}
.lineage-tag{padding:3px 10px;background:#e8f4f8;border-radius:10px;font-size:11px;color:#065A82;cursor:pointer;transition:background .2s}
.lineage-tag:hover{background:#d0ecf4}
.lineage-tag.oracle{background:#fff3e0;color:#e17055}
.sql-actions{padding:12px 20px;display:flex;gap:8px;border-bottom:1px solid #eee}
.sql-btn{padding:6px 14px;border:1px solid #065A82;border-radius:6px;background:#fff;color:#065A82;font-size:12px;cursor:pointer;transition:all .2s}
.sql-btn:hover{background:#065A82;color:#fff}
.fields-table{width:100%;border-collapse:collapse}
.fields-table th{text-align:left;padding:8px 20px;font-size:12px;color:#636e72;font-weight:600;background:#fafafa;position:sticky;top:0}
.fields-table td{padding:7px 20px;font-size:13px;border-top:1px solid #f0f0f0}
.fields-table tr:hover td{background:#f8f9fa}
.fields-table tr.field-highlight td{background:#fff9e6}
.field-name{font-family:"SF Mono",Monaco,monospace;font-weight:500;color:#21295C}
.field-type{color:#636e72;font-size:12px}
.field-comment{color:#2d3436}
.highlight{background:#ffeaa7;padding:1px 2px;border-radius:2px}
.no-results{text-align:center;padding:60px 20px;color:#b2bec3}
.no-results h3{font-size:18px;margin-bottom:8px}

/* SQL Modal */
.modal-overlay{display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.5);z-index:200;justify-content:center;align-items:center}
.modal-overlay.show{display:flex}
.modal{background:#fff;border-radius:12px;width:90%;max-width:900px;max-height:85vh;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 20px 60px rgba(0,0,0,.3)}
.modal-header{padding:16px 24px;background:#21295C;color:#fff;display:flex;justify-content:space-between;align-items:center}
.modal-header h3{font-size:16px}
.modal-close{background:none;border:none;color:#fff;font-size:24px;cursor:pointer;padding:0 4px}
.modal-body{flex:1;overflow:auto;padding:0;background:#1e1e1e}
.modal-body pre{margin:0;padding:20px;font-family:"SF Mono",Monaco,"Fira Code",monospace;font-size:13px;line-height:1.6;color:#d4d4d4;white-space:pre;overflow-x:auto}
/* SQL syntax colors */
.sql-keyword{color:#569cd6;font-weight:600}
.sql-type{color:#4ec9b0}
.sql-string{color:#ce9178}
.sql-comment{color:#6a9955;font-style:italic}
.sql-number{color:#b5cea8}
.sql-func{color:#dcdcaa}
.sql-table{color:#9cdcfe}
.sql-alias{color:#4fc1ff}

/* Workflow tab */
.wf-card{background:#fff;border-radius:12px;margin-bottom:12px;box-shadow:0 1px 4px rgba(0,0,0,.06);overflow:hidden}
.wf-header{padding:16px 20px;cursor:pointer;display:flex;align-items:center;gap:12px}
.wf-header:hover{background:#f8f9fa}
.wf-icon{font-size:20px}
.wf-name{font-weight:600;font-size:14px;flex:1}
.wf-meta{font-size:12px;color:#636e72}
.wf-detail{display:none;border-top:1px solid #eee}
.wf-card.open .wf-detail{display:block}
.wf-expand{font-size:18px;color:#b2bec3;transition:transform .2s;flex-shrink:0}
.wf-card.open .wf-expand{transform:rotate(90deg)}
.wf-visual-btn{padding:6px 14px;border:1px solid #6c5ce7;border-radius:6px;background:#fff;color:#6c5ce7;font-size:12px;cursor:pointer;transition:all .2s;margin:12px 20px}
.wf-visual-btn:hover{background:#6c5ce7;color:#fff}
.task-list{padding:0 20px 16px}
.task-item{display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid #f0f0f0}
.task-type{padding:2px 8px;border-radius:4px;font-size:10px;font-weight:600;color:#fff}
.task-type-SQL{background:#065A82}.task-type-DATAX{background:#6c5ce7}.task-type-SHELL{background:#e17055}.task-type-SWITCH{background:#fdcb6e;color:#2d3436}.task-type-SUB_PROCESS{background:#00b894}
.task-name{font-size:13px;font-weight:500}
.task-target{font-size:12px;color:#636e72;font-family:monospace}
.task-sources{font-size:11px;color:#b2bec3}
.task-sql-btn{padding:3px 8px;border:1px solid #ddd;border-radius:4px;background:#fff;font-size:10px;cursor:pointer;margin-left:auto}

/* Visual graph */
.graph-overlay{display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.5);z-index:200}
.graph-overlay.show{display:block}
.graph-container{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:90%;max-width:1100px;height:80vh;background:#fff;border-radius:12px;overflow:hidden;display:flex;flex-direction:column}
.graph-header{padding:16px 24px;background:#6c5ce7;color:#fff;display:flex;justify-content:space-between;align-items:center}
.graph-header h3{font-size:16px}
.graph-close{background:none;border:none;color:#fff;font-size:24px;cursor:pointer}
.graph-body{flex:1;overflow:auto;position:relative;background:#fafafa}
.graph-body canvas{display:block}
.graph-legend{position:absolute;top:10px;right:10px;background:rgba(255,255,255,.9);border-radius:8px;padding:10px;font-size:11px;box-shadow:0 2px 8px rgba(0,0,0,.1)}
.legend-item{display:flex;align-items:center;gap:6px;margin-bottom:4px}
.legend-dot{width:12px;height:12px;border-radius:3px}

.result-info{padding:8px 0;font-size:13px;color:#636e72}
</style>
</head>
<body>
<div class="header">
  <h1>CK数据仓库数据字典</h1>
  <p>ClickHouse Data Warehouse Dictionary</p>
  <div class="tabs">
    <button class="tab-btn active" onclick="switchTab('tables')">数据表</button>
    <button class="tab-btn" onclick="switchTab('views')">视图 View</button>
    <button class="tab-btn" onclick="switchTab('workflows')">工作流 Workflow</button>
  </div>
</div>

<!-- Tables Tab -->
<div class="tab-content active" id="tab-tables">
  <div class="container">
    <div class="controls">
      <input type="text" class="search-box" id="searchBox" placeholder="搜索表名、字段名、中文名、注释..." autofocus>
      <button class="layer-btn active" data-layer="ALL">全部</button>
      <button class="layer-btn" data-layer="DIM">DIM</button>
      <button class="layer-btn" data-layer="DWD">DWD</button>
      <button class="layer-btn" data-layer="DWS">DWS</button>
      <button class="layer-btn" data-layer="ADS">ADS</button>
      <button class="layer-btn" data-layer="ODS">ODS</button>
    </div>
    <div class="stats">
      <div class="stat"><strong id="totalCount">0</strong> 张表</div>
      <div class="stat"><strong id="fieldCount">0</strong> 个字段</div>
      <div class="stat"><strong id="resultCount">0</strong> 条匹配</div>
    </div>
    <div style="height:12px"></div>
    <div id="tableList"></div>
    <div class="no-results" id="noResults" style="display:none">
      <h3>没有找到匹配的表</h3>
      <p>试试其他关键词</p>
    </div>
  </div>
</div>

<!-- Views Tab -->
<div class="tab-content" id="tab-views">
  <div class="container">
    <div class="stats" style="margin-top:0;margin-bottom:16px;color:#636e72">
      <div class="stat"><strong id="viewCount">0</strong> 个视图</div>
    </div>
    <div id="viewList"></div>
  </div>
</div>

<!-- Workflows Tab -->
<div class="tab-content" id="tab-workflows">
  <div class="container">
    <div class="stats" style="margin-top:0;margin-bottom:16px;color:#636e72">
      <div class="stat"><strong id="wfCount">0</strong> 个工作流</div>
    </div>
    <div id="wfList"></div>
  </div>
</div>

<!-- SQL Modal -->
<div class="modal-overlay" id="sqlModal">
  <div class="modal">
    <div class="modal-header">
      <h3 id="modalTitle">SQL</h3>
      <button class="modal-close" onclick="closeSqlModal()">&times;</button>
    </div>
    <div class="modal-body">
      <pre id="modalCode"></pre>
    </div>
  </div>
</div>

<!-- Graph Overlay -->
<div class="graph-overlay" id="graphOverlay">
  <div class="graph-container">
    <div class="graph-header">
      <h3 id="graphTitle">工作流可视化</h3>
      <button class="graph-close" onclick="closeGraph()">&times;</button>
    </div>
    <div class="graph-body" id="graphBody">
      <div class="graph-legend">
        <div class="legend-item"><div class="legend-dot" style="background:#065A82"></div>DWD明细层</div>
        <div class="legend-item"><div class="legend-dot" style="background:#1C7293"></div>DWS汇总层</div>
        <div class="legend-item"><div class="legend-dot" style="background:#00b894"></div>ADS应用层</div>
        <div class="legend-item"><div class="legend-dot" style="background:#6c5ce7"></div>DIM维度层</div>
        <div class="legend-item"><div class="legend-dot" style="background:#b2bec3"></div>ODS贴源层</div>
        <div class="legend-item"><div class="legend-dot" style="background:#e17055"></div>Oracle源表</div>
      </div>
    </div>
  </div>
</div>

<script>
const DATA = ''' + tables_json + r''';
const WORKFLOWS = ''' + workflow_json + r''';

// ========== Layer colors ==========
const LAYER_COLORS = {ODS:'#b2bec3',DIM:'#6c5ce7',DWD:'#065A82',DWS:'#1C7293',ADS:'#00b894',OTHER:'#636e72'};

// ========== Tab switching ==========
function switchTab(tab) {
  document.querySelectorAll('.tab-btn').forEach((b,i) => {
    b.classList.toggle('active', ['tables','views','workflows'][i] === tab);
  });
  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
}

// ========== SQL syntax highlighting ==========
function highlightSQL(sql) {
  if (!sql) return '';
  let s = escapeHtml(sql);
  // Comments
  s = s.replace(/(--[^\n]*)/g, '<span class="sql-comment">$1</span>');
  s = s.replace(/(\/\*[\s\S]*?\*\/)/g, '<span class="sql-comment">$1</span>');
  // Strings
  s = s.replace(/('(?:[^'\\]|\\.)*')/g, '<span class="sql-string">$1</span>');
  // Keywords
  const kws = 'SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AND|OR|NOT|IN|AS|INSERT|INTO|VALUES|CREATE|TABLE|VIEW|ENGINE|ORDER|BY|GROUP|HAVING|LIMIT|UNION|ALL|WITH|CASE|WHEN|THEN|ELSE|END|DISTINCT|NULL|IS|LIKE|BETWEEN|EXISTS|IF|MULTIIF|OVER|PARTITION|ROW|RANGE|PRECEDING|FOLLOWING|CURRENT|UNBOUNDED|DESC|ASC|SET|UPDATE|DELETE|DROP|ALTER|ADD|PRIMARY|KEY|DEFAULT|COMMENT|IF|REPLACE|MATERIALIZED|DICTIONARY|TEMPORARY|IF NOT EXISTS|FINAL|SETTINGS|FORMAT|ARRAY|JOIN|GLOBAL|ANY|ASOF|USING'.split('|');
  kws.sort((a,b) => b.length - a.length);
  const kwRegex = new RegExp('\\b(' + kws.join('|') + ')\\b', 'gi');
  s = s.replace(kwRegex, '<span class="sql-keyword">$1</span>');
  // Types
  s = s.replace(/\b(String|Int\w*|UInt\w*|Float\w*|Decimal\w*|Date\w*|DateTime\w*|FixedString\w*|Nullable\w*|Array\w*|Map\w*|Enum\w*|UUID|IPv4|IPv6|Boolean|Tuple)\b/g, '<span class="sql-type">$1</span>');
  // Numbers
  s = s.replace(/\b(\d+(?:\.\d+)?)\b/g, '<span class="sql-number">$1</span>');
  // Functions
  s = s.replace(/\b(sum|count|avg|min|max|coalesce|concat|substring|length|replace|trim|upper|lower|cast|toDate|toDateTime|toString|toDecimal\w*|toYYYYMM|toYear|today|now|addMonths|formatDateTime|dictGet|multiIf|if|round|floor|ceil|abs|split|arrayJoin|groupArray|any|argMax|argMin|row_number|rank|dense_rank|lag|lead|first_value|last_value|nth_value|quantile\w*|uniq\w*)\b/gi, '<span class="sql-func">$1</span>');
  return s;
}

// ========== SQL Modal ==========
function openSqlModal(title, sql) {
  document.getElementById('modalTitle').textContent = title;
  document.getElementById('modalCode').innerHTML = highlightSQL(sql);
  document.getElementById('sqlModal').classList.add('show');
}
function showTaskSql(wfName, taskIdx) {
  const wf = WORKFLOWS[wfName];
  if (wf && wf[taskIdx]) {
    openSqlModal(wf[taskIdx].name, wf[taskIdx].sql);
  }
}
function closeSqlModal() {
  document.getElementById('sqlModal').classList.remove('show');
}
document.getElementById('sqlModal').addEventListener('click', function(e) {
  if (e.target === this) closeSqlModal();
});

// ========== Tables ==========
const tables = Object.entries(DATA).filter(([,t]) => !t.is_view).map(([name, t]) => ({
  name, ...t,
  totalFields: t.fields.length,
  fieldText: t.fields.map(f => f.name + ' ' + f.type + ' ' + f.comment).join(' '),
  sourceText: (t.lineage.sources || []).join(' ')
}));
const views = Object.entries(DATA).filter(([,t]) => t.is_view).map(([name, t]) => ({
  name, ...t,
  totalFields: t.fields.length,
  fieldText: t.fields.map(f => f.name + ' ' + f.type).join(' ')
}));

let currentLayer = 'ALL';
let currentSearch = '';

function escapeHtml(s) { return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }

function highlightText(text, query) {
  if (!query) return escapeHtml(text);
  const escaped = escapeHtml(text);
  const q = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return escaped.replace(new RegExp('(' + q + ')', 'gi'), '<span class="highlight">$1</span>');
}

function getSourceTag(source) {
  const isOracle = !source.startsWith('dwd_') && !source.startsWith('dws_') && !source.startsWith('dim_') && !source.startsWith('ods_') && !source.startsWith('ads_') && !source.startsWith('v_');
  return '<span class="lineage-tag' + (isOracle ? ' oracle' : '') + '" onclick="event.stopPropagation();showTableFromTag(\'' + source + '\')">' + escapeHtml(source) + '</span>';
}

function showTableFromTag(name) {
  switchTab('tables');
  document.getElementById('searchBox').value = name;
  currentSearch = name;
  renderTables();
  // Auto-open the matching card
  setTimeout(() => {
    const cards = document.querySelectorAll('#tableList .table-card');
    cards.forEach(c => {
      if (c.dataset.name === name) c.classList.add('open');
    });
  }, 100);
}

function getWorkflowSqlForTable(tableName) {
  const t = DATA[tableName];
  if (!t || !t.lineage.workflow) return '';
  const wf = WORKFLOWS[t.lineage.workflow];
  if (!wf) return '';
  for (const task of wf) {
    if (task.target === tableName && task.sql) return task.sql;
  }
  return '';
}

function renderTables() {
  const query = currentSearch.toLowerCase();
  let filtered = tables;

  if (currentLayer !== 'ALL') {
    filtered = filtered.filter(t => t.layer === currentLayer);
  }

  // Check if query matches field names (for auto-expand)
  const fieldMatchTables = new Set();
  if (query) {
    filtered.forEach(t => {
      const hasFieldMatch = t.fields.some(f =>
        f.name.toLowerCase().includes(query) || f.comment.toLowerCase().includes(query)
      );
      if (hasFieldMatch) fieldMatchTables.add(t.name);
    });
    filtered = filtered.filter(t =>
      t.name.toLowerCase().includes(query) ||
      (t.cn_name && t.cn_name.toLowerCase().includes(query)) ||
      t.fieldText.toLowerCase().includes(query) ||
      t.sourceText.toLowerCase().includes(query) ||
      (t.lineage.workflow || '').toLowerCase().includes(query)
    );
  }

  filtered.sort((a, b) => a.name.localeCompare(b.name));

  document.getElementById('resultCount').textContent = filtered.length;
  const el = document.getElementById('tableList');
  const noResults = document.getElementById('noResults');

  if (filtered.length === 0) {
    el.innerHTML = '';
    noResults.style.display = 'block';
    return;
  }
  noResults.style.display = 'none';

  el.innerHTML = filtered.map(t => {
    const sources = t.lineage.sources || [];
    const workflow = t.lineage.workflow || '';
    const hasFieldMatch = fieldMatchTables.has(t.name);
    const isOpen = hasFieldMatch ? ' open auto-open' : '';

    // Lineage section
    let lineageHtml = '';
    if (sources.length > 0 || workflow) {
      lineageHtml = '<div class="lineage-section">';
      if (workflow) {
        lineageHtml += '<h4>调度工作流</h4><div class="lineage-tags"><span class="lineage-tag" onclick="event.stopPropagation();switchTab(\'workflows\')">' + escapeHtml(workflow) + '</span></div>';
      }
      if (sources.length > 0) {
        lineageHtml += '<h4>上游依赖 (' + sources.length + '张表)</h4><div class="lineage-tags">' + sources.map(s => getSourceTag(s)).join('') + '</div>';
      }
      lineageHtml += '</div>';
    }

    // SQL action buttons
    const ddl = t.ddl || '';
    const wfSql = getWorkflowSqlForTable(t.name);
    let actionsHtml = '<div class="sql-actions">';
    if (ddl) {
      actionsHtml += '<button class="sql-btn" onclick="event.stopPropagation();openSqlModal(\'建表语句: ' + t.name + '\', DATA[\'' + t.name + '\'].ddl)">建表语句 DDL</button>';
    }
    if (wfSql) {
      actionsHtml += '<button class="sql-btn" onclick="event.stopPropagation();openSqlModal(\'取数SQL: ' + t.name + '\', getWorkflowSqlForTable(\'' + t.name + '\'))">取数 SQL</button>';
    }
    actionsHtml += '</div>';

    // Fields table - highlight matching fields
    const fieldsHtml = t.fields.map(f => {
      const isFieldMatch = query && (f.name.toLowerCase().includes(query) || f.comment.toLowerCase().includes(query));
      const trClass = isFieldMatch ? ' class="field-highlight"' : '';
      return '<tr' + trClass + '>' +
        '<td class="field-name">' + highlightText(f.name, currentSearch) + '</td>' +
        '<td class="field-type">' + escapeHtml(f.type) + '</td>' +
        '<td class="field-comment">' + highlightText(f.comment, currentSearch) + '</td>' +
      '</tr>';
    }).join('');

    const cnDisplay = t.cn_name ? '<span class="cn-name">' + escapeHtml(t.cn_name) + '</span>' : '';

    return '<div class="table-card' + isOpen + '" data-name="' + t.name + '" onclick="this.classList.toggle(\'open\')">' +
      '<div class="table-header">' +
        '<span class="layer-badge layer-' + t.layer + '">' + t.layer + '</span>' +
        '<span class="table-name">' + highlightText(t.name, currentSearch) + cnDisplay + '</span>' +
        '<span class="table-meta">' + t.totalFields + '个字段' + (sources.length ? ' · ' + sources.length + '个上游' : '') + '</span>' +
        '<span class="expand-icon">▶</span>' +
      '</div>' +
      '<div class="table-detail">' +
        lineageHtml + actionsHtml +
        '<table class="fields-table"><thead><tr><th>字段名</th><th>数据类型</th><th>注释</th></tr></thead>' +
        '<tbody>' + fieldsHtml + '</tbody></table>' +
      '</div>' +
    '</div>';
  }).join('');
}

// ========== Views ==========
function renderViews() {
  const el = document.getElementById('viewList');
  document.getElementById('viewCount').textContent = views.length;
  views.sort((a,b) => a.name.localeCompare(b.name));
  el.innerHTML = views.map(t => {
    const sources = t.lineage.sources || [];
    const workflow = t.lineage.workflow || '';
    const ddl = t.ddl || '';

    let lineageHtml = '';
    if (sources.length > 0 || workflow) {
      lineageHtml = '<div class="lineage-section">';
      if (workflow) lineageHtml += '<h4>调度工作流</h4><div class="lineage-tags"><span class="lineage-tag">' + escapeHtml(workflow) + '</span></div>';
      if (sources.length > 0) lineageHtml += '<h4>上游依赖</h4><div class="lineage-tags">' + sources.map(s => getSourceTag(s)).join('') + '</div>';
      lineageHtml += '</div>';
    }

    let actionsHtml = '<div class="sql-actions">';
    if (ddl) actionsHtml += '<button class="sql-btn" onclick="event.stopPropagation();openSqlModal(\'视图定义: ' + t.name + '\', DATA[\'' + t.name + '\'].ddl)">视图定义 DDL</button>';
    actionsHtml += '</div>';

    const fieldsHtml = t.fields.map(f =>
      '<tr><td class="field-name">' + escapeHtml(f.name) + '</td><td class="field-type">' + escapeHtml(f.type) + '</td><td class="field-comment">' + escapeHtml(f.comment) + '</td></tr>'
    ).join('');

    const cnDisplay = t.cn_name ? '<span class="cn-name">' + escapeHtml(t.cn_name) + '</span>' : '';

    return '<div class="table-card" onclick="this.classList.toggle(\'open\')">' +
      '<div class="table-header">' +
        '<span class="layer-badge layer-' + t.layer + '">' + t.layer + ' VIEW</span>' +
        '<span class="table-name">' + escapeHtml(t.name) + cnDisplay + '</span>' +
        '<span class="table-meta">' + t.totalFields + '个字段</span>' +
        '<span class="expand-icon">▶</span>' +
      '</div>' +
      '<div class="table-detail">' + lineageHtml + actionsHtml +
        '<table class="fields-table"><thead><tr><th>字段名</th><th>数据类型</th><th>注释</th></tr></thead>' +
        '<tbody>' + fieldsHtml + '</tbody></table>' +
      '</div>' +
    '</div>';
  }).join('');
}

// ========== Workflows ==========
function renderWorkflows() {
  const el = document.getElementById('wfList');
  const wfNames = Object.keys(WORKFLOWS).sort();
  document.getElementById('wfCount').textContent = wfNames.length;

  el.innerHTML = wfNames.map(wfName => {
    const tasks = WORKFLOWS[wfName];
    const targets = tasks.filter(t => t.target).map(t => t.target);

    const taskHtml = tasks.map((t, idx) => {
      const typeClass = t.type || 'SQL';
      const wfKey = wfName.replace(/'/g, "\\'");
      const taskName = escapeHtml(t.name).replace(/'/g, "\\'");
      return '<div class="task-item">' +
        '<span class="task-type task-type-' + typeClass + '">' + typeClass + '</span>' +
        '<span class="task-name">' + escapeHtml(t.name) + '</span>' +
        (t.target ? '<span class="task-target">→ ' + escapeHtml(t.target) + '</span>' : '') +
        (t.sources.length ? '<span class="task-sources">← ' + t.sources.join(', ') + '</span>' : '') +
        (t.sql ? '<button class="task-sql-btn" onclick="event.stopPropagation();showTaskSql(\'' + wfKey + '\',' + idx + ')">SQL</button>' : '') +
      '</div>';
    }).join('');

    return '<div class="wf-card" onclick="this.classList.toggle(\'open\')">' +
      '<div class="wf-header">' +
        '<span class="wf-icon">⚙️</span>' +
        '<span class="wf-name">' + escapeHtml(wfName) + '</span>' +
        '<span class="wf-meta">' + tasks.length + '个任务 · ' + targets.length + '张产出表</span>' +
        '<span class="wf-expand">▶</span>' +
      '</div>' +
      '<div class="wf-detail">' +
        '<button class="wf-visual-btn" onclick="event.stopPropagation();showGraph(\'' + escapeHtml(wfName) + '\')">📊 可视化血缘图</button>' +
        '<div class="task-list">' + taskHtml + '</div>' +
      '</div>' +
    '</div>';
  }).join('');
}

// ========== Graph visualization ==========
function showGraph(wfName) {
  const overlay = document.getElementById('graphOverlay');
  overlay.classList.add('show');
  document.getElementById('graphTitle').textContent = '工作流可视化: ' + wfName;

  const body = document.getElementById('graphBody');
  // Remove existing canvas
  const oldCanvas = body.querySelector('canvas');
  if (oldCanvas) oldCanvas.remove();

  const tasks = WORKFLOWS[wfName];
  // Collect all nodes and edges
  const nodes = new Map(); // name -> {type, layer, x, y}
  const edges = []; // {from, to}

  tasks.forEach(t => {
    if (t.target) {
      const layer = DATA[t.target] ? DATA[t.target].layer : 'OTHER';
      nodes.set(t.target, {type: 'table', layer, taskType: t.type});
    }
    t.sources.forEach(s => {
      if (!nodes.has(s)) {
        const layer = DATA[s] ? DATA[s].layer : null;
        nodes.set(s, {type: layer ? 'table' : 'oracle', layer: layer || 'ORACLE'});
      }
      if (t.target) {
        edges.push({from: s, to: t.target});
      }
    });
  });

  // Layout: arrange by layer
  const layerOrder = ['ORACLE', 'ODS', 'DIM', 'DWD', 'DWS', 'ADS', 'OTHER'];
  const layerGroups = {};
  nodes.forEach((info, name) => {
    const l = info.layer || 'OTHER';
    if (!layerGroups[l]) layerGroups[l] = [];
    layerGroups[l].push(name);
  });

  const canvas = document.createElement('canvas');
  const nodeW = 160, nodeH = 36, padX = 40, padY = 20;
  let maxX = 0, maxY = 0;
  const positions = {};
  let colX = 30;
  layerOrder.forEach(layer => {
    if (!layerGroups[layer]) return;
    const names = layerGroups[layer].sort();
    let rowY = 30;
    names.forEach(name => {
      positions[name] = {x: colX, y: rowY};
      rowY += nodeH + padY;
      maxY = Math.max(maxY, rowY);
    });
    colX += nodeW + padX;
    maxX = Math.max(maxX, colX);
  });
  // Add any remaining layers
  Object.keys(layerGroups).forEach(l => {
    if (!layerOrder.includes(l)) {
      const names = layerGroups[l].sort();
      let rowY = 30;
      names.forEach(name => {
        positions[name] = {x: colX, y: rowY};
        rowY += nodeH + padY;
        maxY = Math.max(maxY, rowY);
      });
      colX += nodeW + padX;
      maxX = Math.max(maxX, colX);
    }
  });

  canvas.width = Math.max(maxX + 30, body.clientWidth);
  canvas.height = Math.max(maxY + 30, body.clientHeight);
  body.appendChild(canvas);

  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#fafafa';
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // Draw edges
  ctx.strokeStyle = '#ccc';
  ctx.lineWidth = 1.5;
  edges.forEach(e => {
    const from = positions[e.from];
    const to = positions[e.to];
    if (!from || !to) return;
    ctx.beginPath();
    ctx.moveTo(from.x + nodeW, from.y + nodeH/2);
    // Bezier curve
    const cpx = (from.x + nodeW + to.x) / 2;
    ctx.bezierCurveTo(cpx, from.y + nodeH/2, cpx, to.y + nodeH/2, to.x, to.y + nodeH/2);
    ctx.stroke();
    // Arrow
    const angle = Math.atan2(to.y + nodeH/2 - (to.y + nodeH/2), to.x - cpx);
    ctx.fillStyle = '#ccc';
    ctx.beginPath();
    ctx.moveTo(to.x, to.y + nodeH/2);
    ctx.lineTo(to.x - 8, to.y + nodeH/2 - 4);
    ctx.lineTo(to.x - 8, to.y + nodeH/2 + 4);
    ctx.closePath();
    ctx.fill();
  });

  // Draw nodes
  nodes.forEach((info, name) => {
    const pos = positions[name];
    if (!pos) return;
    const color = LAYER_COLORS[info.layer] || '#636e72';

    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.08)';
    ctx.beginPath();
    ctx.roundRect(pos.x + 2, pos.y + 2, nodeW, nodeH, 6);
    ctx.fill();

    // Node
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.roundRect(pos.x, pos.y, nodeW, nodeH, 6);
    ctx.fill();

    // Text
    ctx.fillStyle = '#fff';
    ctx.font = '11px -apple-system, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const displayName = name.length > 20 ? name.substring(0, 18) + '..' : name;
    ctx.fillText(displayName, pos.x + nodeW/2, pos.y + nodeH/2);
  });

  // Click handler for nodes
  canvas.onclick = function(e) {
    const rect = canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    nodes.forEach((info, name) => {
      const pos = positions[name];
      if (pos && mx >= pos.x && mx <= pos.x + nodeW && my >= pos.y && my <= pos.y + nodeH) {
        closeGraph();
        showTableFromTag(name);
      }
    });
  };
  canvas.style.cursor = 'pointer';
}

function closeGraph() {
  document.getElementById('graphOverlay').classList.remove('show');
}
document.getElementById('graphOverlay').addEventListener('click', function(e) {
  if (e.target === this) closeGraph();
});

// ========== Init ==========
document.getElementById('totalCount').textContent = tables.length;
document.getElementById('fieldCount').textContent = tables.reduce((s, t) => s + t.totalFields, 0);

// Search
let debounce;
document.getElementById('searchBox').addEventListener('input', function(e) {
  clearTimeout(debounce);
  debounce = setTimeout(() => {
    currentSearch = e.target.value.trim();
    renderTables();
  }, 200);
});

// Layer filter
document.querySelectorAll('.layer-btn').forEach(btn => {
  btn.addEventListener('click', function() {
    document.querySelectorAll('.layer-btn').forEach(b => b.classList.remove('active'));
    this.classList.add('active');
    currentLayer = this.dataset.layer;
    renderTables();
  });
});

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    closeSqlModal();
    closeGraph();
  }
});

// Initial render
renderTables();
renderViews();
renderWorkflows();
</script>
</body>
</html>'''

with open('/Users/apple/Aohua/海豚调度/数据字典查询.html', 'w') as f:
    f.write(html)

print(f'✅ 已生成 数据字典查询.html')
print(f'   表: {sum(1 for t in sql_tables if not t.startswith("v_"))}张')
print(f'   视图: {sum(1 for t in sql_tables if t.startswith("v_"))}个')
print(f'   工作流: {len(workflow_tasks)}个')
