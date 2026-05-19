#!/usr/bin/env python3
"""Generate comprehensive CK data dictionary markdown from script.sql + workflow JSON."""

import re
import json

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
        elif len(parts) == 1:
            parsed.append((parts[0], '', comment))
    sql_tables[table_name] = parsed

# ========== Parse views ==========
view_starts = [(m.group(1), m.start()) for m in re.finditer(r'create view\s+[\w.]+\.(\w+)\s*\(', sql_content, re.IGNORECASE)]
for view_name, start_pos in view_starts:
    # Find the opening ( after view name
    paren_start = sql_content.find('(', start_pos)
    if paren_start < 0:
        continue
    # Walk to find matching closing )
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

# Build lineage map: target -> {workflow, sources}
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
        from_matches = re.findall(r'(?:from|join)\s+(\w+)', sql_clean, re.IGNORECASE)
        for m in from_matches:
            if not m.startswith('$') and len(m) > 3 and m.lower() != 'dual':
                sources.add(m.lower())

        lineage[target] = {
            'workflow': wf_name,
            'sources': sorted(sources)
        }

# ========== Determine layer ==========
def get_layer(table_name):
    tn = table_name.lower()
    # Handle views: v_dim_xxx -> DIM, v_dwd_xxx -> DWD, etc.
    if tn.startswith('v_'):
        tn = tn[2:]
    prefix = tn.split('_')[0].lower()
    if prefix == 'ods':
        return 'ODS'
    elif prefix == 'dim' or prefix == 'uf' or tn.startswith('dim_'):
        return 'DIM'
    elif prefix == 'dwd':
        return 'DWD'
    elif prefix == 'dws':
        return 'DWS'
    elif prefix == 'ads':
        return 'ADS'
    elif prefix in ('rpt', 'tb', 'crm', 'nc', 'fx'):
        return 'OTHER'
    else:
        return 'OTHER'

layer_names = {
    'ODS': '贴源层', 'DIM': '维度层', 'DWD': '明细层',
    'DWS': '汇总层', 'ADS': '应用层', 'OTHER': '其他'
}

# ========== Generate markdown ==========
output = []
output.append('# ClickHouse 数据仓库数据字典')
output.append('')
output.append('> 自动生成 | 数据来源：script.sql + workflow JSON')
output.append('')
output.append('## 数据分层')
output.append('')
output.append('```')
output.append('Oracle源表 → ODS(贴源层) → DWD(明细层) → DWS(汇总层) → ADS(应用层)')
output.append('                                ↑')
output.append('                          DIM(维度层)')
output.append('```')
output.append('')
output.append('---')
output.append('')

# Group tables by layer
tables_by_layer = {}
for tname in sorted(sql_tables.keys()):
    layer = get_layer(tname)
    if layer not in tables_by_layer:
        tables_by_layer[layer] = []
    tables_by_layer[layer].append(tname)

total_tables = 0
total_fields = 0

for layer in ['ODS', 'DIM', 'DWD', 'DWS', 'ADS', 'OTHER']:
    tables_in_layer = tables_by_layer.get(layer, [])
    if not tables_in_layer:
        continue

    output.append(f'## {layer}层（{layer_names[layer]}）- {len(tables_in_layer)}张表')
    output.append('')

    for tname in tables_in_layer:
        total_tables += 1
        fields = sql_tables[tname]
        total_fields += len(fields)

        lin = lineage.get(tname, {})
        workflow = lin.get('workflow', '-')
        sources = lin.get('sources', [])

        output.append(f'### {tname}')
        output.append(f'**层级**: {layer} | **工作流**: {workflow} | **字段数**: {len(fields)}')

        # Lineage
        if sources:
            # Determine bottom-level Oracle sources
            oracle_sources = [s for s in sources if s in (
                'gl_balance', 'ia_detailledger', 'ic_flow', 'ia_monthnab',
                'so_saleorder', 'so_saleorder_b', 'po_order', 'po_order_b',
                'bd_material', 'bd_customer', 'bd_supplier', 'bd_defdoc',
                'bd_defdoclist', 'bd_custsale', 'bd_stordoc', 'bd_measdoc',
                'bd_marbasclass', 'bd_billtype', 'bd_accasoa', 'bd_account',
                'bd_accperiodmonth', 'bd_channeltype', 'bd_custclass',
                'bd_address', 'bd_areacl', 'bd_bom', 'bd_bom_b',
                'bd_material_v', 'bd_mattaxes', 'bd_psndoc', 'bd_region',
                'bd_supplierclass', 'bd_countryzone', 'bd_prodline',
                'cg_kcgzb', 'cg_wlbj', 'cm_prodcost', 'cm_prodcost_b',
                'formtable_main_147', 'formtable_main_147_dt1',
                'hrmdepartment', 'hrmjobtitles', 'hrmsubcompany', 'HrmResource',
                'org_corp', 'org_costregion', 'org_dept', 'org_dept_v',
                'org_factory', 'org_financeorg', 'org_orgs', 'org_orgs_v',
                'org_salesorg', 'org_stockorg', 'org_purchaseorg',
                'prm_priceform_p', 'prm_tariff', 'resa_factorasoa',
                'sm_user', 'so_arsub', 'so_arsub_b', 'so_buylargess',
                'sr_marcombine', 'sr_marcombine_b', 'sr_plcy', 'sr_plcy_caldet',
                'sr_plcy_calrule', 'sr_plcy_cust', 'sr_plcy_mar',
                'sr_settle', 'sr_settle_b', 'workflow_requestbase', 'yc_xsjh',
                'ia_i5bill', 'ia_i5bill_b', 'ia_iabill', 'ia_iabill_b',
                'material', 'org_dept', 'temp', 'TEMP'
            )]
            ck_sources = [s for s in sources if s.startswith(('dwd_', 'dws_', 'dim_', 'ods_'))]

            output.append(f'**上游表**: {", ".join(sources[:10])}' + (f' 等{len(sources)}张' if len(sources) > 10 else ''))
            if oracle_sources:
                output.append(f'**底层数据源(Oracle)**: {", ".join(oracle_sources[:8])}' + (f' 等{len(oracle_sources)}张' if len(oracle_sources) > 8 else ''))
            if ck_sources:
                output.append(f'**CK内部依赖**: {", ".join(ck_sources)}')
        else:
            output.append('**血缘关系**: 未在workflow中定义（可能是字典表或独立表）')

        output.append('')
        output.append('| 字段名 | 数据类型 | 注释 |')
        output.append('|--------|----------|------|')
        for fname, ftype, comment in fields:
            ftype_clean = ftype.replace('|', '\\|')
            comment_clean = comment.replace('|', '\\|')
            output.append(f'| `{fname}` | {ftype_clean} | {comment_clean} |')
        output.append('')

    output.append('---')
    output.append('')

# Summary
output.append('## 统计')
output.append('')
output.append('| 层级 | 表数量 | 说明 |')
output.append('|------|--------|------|')
for layer in ['ODS', 'DIM', 'DWD', 'DWS', 'ADS', 'OTHER']:
    if tables_by_layer.get(layer):
        output.append(f'| {layer} | {len(tables_by_layer[layer])} | {layer_names[layer]} |')
output.append(f'| **总计** | **{total_tables}** | |')
output.append(f'| **总字段数** | **{total_fields}** | |')

with open('/Users/apple/Aohua/海豚调度/CK数据仓库数据字典.md', 'w') as f:
    f.write('\n'.join(output))

print(f'✅ 已生成 CK数据仓库数据字典.md ({total_tables}张表, {total_fields}个字段)')
