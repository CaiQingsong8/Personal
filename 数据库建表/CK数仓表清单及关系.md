# ClickHouse 数仓表清单及关系

> 导出时间：2026-04-30
> 数据源：海豚调度 workflow_1777516820540.json
> 总计：55 张 CK 表

---

## 一、表清单（按层级）

### DIM 维度层（15 张）

| 表名 | 说明 | 工作流 | 写入策略 |
|---|---|---|---|
| dim_unit | 公司/组织维表 | 0dim-table_1h | TRUNCATE 全量 |
| dim_material | 物料维表 | 0dim-table_1h | TRUNCATE 全量 |
| dim_material_uat | 物料维表(UAT) | 0dim-table_1h | TRUNCATE 全量 |
| dim_material_rd45 | 物料维表(RD45) | 2job-nc_stock_1h | TRUNCATE 全量 |
| dim_client | 客户维表 | 0dim-table_1h | TRUNCATE 全量 |
| dim_supplier | 供应商维表 | 0dim-table_1h | TRUNCATE 全量 |
| dim_stordoc | 仓库维表 | 0dim-table_1h | TRUNCATE 全量 |
| dim_bd_defdoc | 自定义档案 | 0dim-table_1h | TRUNCATE 全量 |
| dim_bd_defdoc_uat | 自定义档案(UAT) | 0dim-table_1h | TRUNCATE 全量 |
| dim_bd_defdoclist | 档案明细 | 0dim-table_1h | TRUNCATE 全量 |
| dim_bd_custsale | 客户销售档案 | 0dim-table_1h | TRUNCATE 全量 |
| dim_fx_organization | OA组织架构 | 0dim-table_1h | TRUNCATE 全量 |
| dim_formula_product_snap | 配方产品快照 | 1-2job-dim_formula_product_snap_1w | 按月分区 |
| dim_row_product_snap | 原料产品快照 | 1-2job-dim_formula_product_snap_1w | 按月分区 |
| dim_formula_product_day_snap | 配方产品日快照 | 1-1job-dwd_so_saleorder | 按日分区 |
| dim_fact_row_price_snap | 原料报价快照 | 1job-nc_sal_profit | 按月分区 |

### ODS 贴源层（1 张）

| 表名 | 说明 | 工作流 | 写入策略 |
|---|---|---|---|
| ods_ia_detailledger | 存货明细账 | 2job-nc_stock_1h | 增量 ts |

### DWD 明细层（25 张）

| 表名 | 说明 | 工作流 | 写入策略 |
|---|---|---|---|
| **销售利润链** | | | |
| dwd_so_saleorder | 销售订单（核心基础表） | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_so_priceform | 价格维护 | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_so_cost | 销售成本（完工成本） | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_so_profit | 销售利润明细（最终表） | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_so_profit_old | 销售利润(旧) | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_cust_rebate_actual_m | 客户返利实际兑付 | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_product_subject_cost | 科目成本 | 1-1job-dwd_so_saleorder | 按月分区 |
| dwd_plcy_discount_detail_ysnap | 折扣政策明细 | 1job-nc_sal_profit | 按年分区 |
| dwd_prm_promoteprice_detail_ysnap | 促销价格明细 | 1job-nc_sal_profit | 按年分区 |
| dwd_price_maintenance_snap | 价格维护快照 | 1job-nc_sal_profit | 按月分区 |
| dwd_fact_product_inbound_snap | 产成品入库快照 | 1job-nc_sal_profit | 按月分区 |
| dwd_fact_product_sale_snap | 产成品销售快照 | 1job-nc_sal_profit | 按月分区 |
| **库存链** | | | |
| dwd_ia_monthnab | 月结存 | 2-1job-dwd_ia_monthnab_snap | OPTIMIZE FINAL |
| dwd_ia_monthnab_adjust | 月结存(影子表) | 2-1job-dwd_ia_monthnab_snap | TRUNCATE |
| dwd_ia_monthnab_snap | 月结存快照 | 2-1job-dwd_ia_monthnab_snap | 按月分区 |
| dwd_ic_flow | 库存流水 | 2job-nc_stock_1h | 增量 ts |
| dwd_ic_flow_adjust | 库存流水(影子表) | 2job-nc_stock_1h | TRUNCATE |
| dwd_ic_flow_rd45 | 库存流水(RD45) | 2job-nc_stock_1h | 增量 ts |
| dwd_po_order_detail_all | 采购订单明细 | 2job-nc_stock_1h | 增量 ts |
| dwd_material_stock_price | 物料库存价格 | 2job-nc_stock_1h | 按月分区 |
| **OA/财务** | | | |
| dwd_oa_cg_wlbj | OA物料报价 | 1job-nc_sal_profit | 按月分区 |
| dwd_gl_balance | 总账科目余额 | 4job-nc_fin | 按月分区 |
| **帆软填报** | | | |
| dwd_fin_net_profit | 净利润预算（年行） | 3job-FRdata | 按年分区 |
| dwd_fin_net_profitmth | 净利润预算（月行） | 3job-FRdata | 按年分区 |
| dwd_fin_profit_detail | 利润明细 | 3job-FRdata | 按年分区 |
| dwd_fin_profitmth_detail | 利润明细(月) | 3job-FRdata | 按年分区 |
| dwd_fin_budget_detail | 预算明细 | 3job-FRdata | 按年分区 |
| dwd_fin_budgetmth_detail | 预算明细(月) | 3job-FRdata | 按年分区 |
| dwd_fin_budgetmth_detail_fx | 预算明细(修正) | 3job-FRdata | 按年分区 |
| dwd_fin_gross_profit | **毛利粗利配置** | 3job-FRdata(新增) | 按年分区 |

### DWS 汇总层（7 张）

| 表名 | 说明 | 工作流 | 写入策略 |
|---|---|---|---|
| dws_ia_material_day_stock | 日库存 | 2-2sub-dws_ia_material_day_stock | 按日分区 |
| dws_formula_product_day | 配方产品日汇总 | 1-1job-dwd_so_saleorder | 按日分区 |
| dws_cust_rebate_actual_m | 客户返利月汇总 | 1-1job-dwd_so_saleorder | 按月分区 |
| dws_product_subject_cost | 科目成本汇总 | 1-1job-dwd_so_saleorder | 按月分区 |
| dws_so_costsharing | 成本分摊 | 1-1job-dwd_so_saleorder | 按月分区 |
| dws_oa_cg_wlbj | OA物料报价汇总 | 1job-nc_sal_profit | 按日分区 |
| dws_fr_cg_kcgzb | FR采购库存跟踪 | 1job-nc_sal_profit | 按日分区 |
| dws_material_stock_price | 物料库存价格 | 2job-nc_stock_1h | 按月分区 |

### ADS 应用层（1 张）

| 表名 | 说明 | 工作流 | 写入策略 |
|---|---|---|---|
| ads_sales_profit_contribution_snap | 客户配方销售净贡献 | 1job-nc_sal_profit | 按月分区 |

### RPT/UF/TB 报表层（5 张）

| 表名 | 说明 | 工作流 | 写入策略 |
|---|---|---|---|
| rpt_forecast_sale_num | 销量预测 | 3job-FRdata | 按月分区 |
| tb_guidance_price | 指导价 | 3job-FRdata | 按年分区 |
| UF_DIM_MATERIAL_RD4 | 物料UF | 2job-nc_stock_1h | TRUNCATE |
| UF_FORMULA_PRODUCT | 配方UF | 1-2job-dim_formula_product_snap_1w | TRUNCATE |

---

## 二、核心表字段明细

### dim_unit — 公司/组织维表

| 字段 | 类型 | 说明 |
|---|---|---|
| d_org_type | LowCardinality(String) | 组织类型（公司/部门） |
| d_region_code | String | 大区编码 |
| d_region_name | String | 大区名称 |
| d_corp_id | FixedString(20) | 公司主键 |
| d_corp_code | String | 公司编码 |
| d_corp_name | String | 公司名称 |
| d_corp_sname | String | 公司简称 |
| d_corp_busi_status | String | 公司经营状态 |
| d_unit_id | FixedString(20) | 业务单元主键 |
| d_unit_code | String | 业务单元编码 |
| d_unit_name | String | 业务单元名称 |
| d_unit_sname | String | 业务单元简称 |

### dim_material — 物料维表

| 字段 | 类型 | 说明 |
|---|---|---|
| d_material_id | FixedString(20) | 物料主键 |
| d_material_vid | FixedString(20) | 物料版本主键 |
| d_corp_id | FixedString(20) | 物料所属公司 |
| d_material_code | FixedString(10) | 物料编码 |
| d_material_name | String | 物料名称 |
| d_class_code4 | FixedString(4) | 大类编码 |
| d_class_name4 | String | 大类名称 |
| d_class_code6 | FixedString(6) | 小类编码 |
| d_class_name6 | String | 小类名称 |
| d_prodline_id | FixedString(20) | 产线主键 |
| d_prodline_code | String | 产线编码 |
| d_prodline_name | String | 产线名称 |
| d_material_block | String | 物料板块 |

### dwd_so_saleorder — 销售订单（核心）

> 来源：NC so_saleorder + 19 张关联表
> 字段：order_id, order_uid, order_row, d_bill_code, is_gift, bill_ts_char, client_class_flag, client_dclass_code, d_corp_id, d_material_id, f_sale_qty, f_sale_amt 等

### dwd_so_profit — 销售利润明细

> 来源：dwd_so_saleorder + dwd_so_priceform + dwd_so_cost + dws_cust_rebate_actual_m + dws_product_subject_cost + dws_formula_product_day + dws_ia_material_day_stock
> 字段：order_id, order_uid, order_row, d_bill_code, is_gift, f_sale_qty, f_sale_amt, f_cost_amt, f_rebate_amt, f_profit 等
> dictGet：dim_material_dict, dim_unit_dict, dim_client_dict, dim_formula_product_dictpack

### dwd_fin_gross_profit — 毛利粗利配置表（新建）

| 字段 | 类型 | 说明 |
|---|---|---|
| gross_profit_year | UInt16 | 年份 |
| d_material_id | FixedString(20) | 物料主键 |
| d_material_code | String | 物料编码 |
| d_material_name | String | 物料名称（维表） |
| d_material_name_fr | String | 物料名称（FR填报） |
| d_class_code4 | String | 大类编码 |
| d_class_name4 | String | 大类名称 |
| d_class_name4_fr | String | 大类名称（FR填报） |
| d_class_code6 | String | 小类编码 |
| d_class_name6 | String | 小类名称 |
| d_class_name6_fr | String | 小类名称（FR填报） |
| d_prodline_code | String | 产线编码 |
| d_prodline_name | String | 产线名称 |
| d_profit_corp_id | FixedString(20) | 利润归属公司主键 |
| d_profit_corp_code | String | 利润归属公司编码 |
| d_profit_corp_name | String | 利润归属公司名称 |
| d_profit_corp_sname | String | 利润归属公司简称 |
| d_profit_region_code | String | 利润归属大区编码 |
| d_profit_region_name | String | 利润归属大区名称 |
| d_produce_corp_id | FixedString(20) | 生产公司主键 |
| d_produce_corp_code | String | 生产公司编码 |
| d_produce_corp_name | String | 生产公司名称 |
| d_produce_corp_sname | String | 生产公司简称 |
| particle_size | String | 粒径 |
| product_series | String | 产品系列 |
| strategy_name | String | 战略产品（是;否） |
| f_gross_red | Decimal(18,6) | 配销差红线 |
| ts_char | String | 源时间戳 |
| ts | DateTime MATERIALIZED | 更新时间 |

---

## 三、表关系（数据血缘）

### 销售利润链（最核心）

```
NC Oracle 源表
  ├─ so_saleorder ──────────────────→ dwd_so_saleorder
  ├─ prm_priceform_p ──────────────→ dwd_so_priceform
  ├─ ia_i5bill + cm_prodcost ──────→ dwd_so_cost
  ├─ sr_settle + so_arsub ─────────→ dwd_cust_rebate_actual_m
  └─ cm_prodcost + resa_factorasoa → dwd_product_subject_cost
                                          │
                                          ▼
  dwd_so_saleorder + dwd_so_priceform + dwd_so_cost
  + dwd_cust_rebate_actual_m + dwd_product_subject_cost
  + dws_formula_product_day + dws_ia_material_day_stock
                                          │
                                          ▼
                                     dwd_so_profit
                                          │
                                          ▼
  + dwd_price_maintenance_snap + dim_fact_row_price_snap
                                          │
                                          ▼
                              ads_sales_profit_contribution_snap
```

### 库存链

```
NC Oracle 源表
  ├─ ia_monthnab ─────────→ dwd_ia_monthnab → dwd_ia_monthnab_snap
  ├─ ic_flow ─────────────→ dwd_ic_flow
  ├─ ia_detailledger ─────→ ods_ia_detailledger
  └─ po_order ────────────→ dwd_po_order_detail_all
                                          │
                                          ▼
  dwd_ia_monthnab_snap + dwd_ic_flow + dwd_po_order_detail_all
  + dwd_so_cost + dictGet(dim_material_dict, dim_unit_dict)
                                          │
                                          ▼
                                 dws_ia_material_day_stock
```

### 帆软填报链

```
帆软 Oracle 填报
  ├─ DWD_FIN_NET_PROFIT ──→ dwd_fin_net_profit → dwd_fin_net_profitmth
  ├─ DWD_FIN_PROFIT_DETAIL → dwd_fin_profit_detail → dwd_fin_profitmth_detail
  ├─ DWD_FIN_BUDGET_DETAIL → dwd_fin_budget_detail → dwd_fin_budgetmth_detail
  ├─ DWD_FIN_GROSS_PROFIT ─→ dwd_fin_gross_profit (新增)
  ├─ tb_guidance_price ────→ tb_guidance_price
  └─ yc_xsjh ─────────────→ rpt_forecast_sale_num
```

### 配方产品链

```
NC bd_bom + bd_material ──→ dim_formula_product_snap
                              │
                              ▼
                        dim_formula_product_day_snap
                              │
                              ▼
                        dws_formula_product_day → dwd_so_profit
```

### 维表关系

```
dim_unit ──── dictGet('dim_unit_dict')  ←── 几乎所有 DWD/DWS 表
dim_material ── dictGet('dim_material_dict') ←── 几乎所有 DWD/DWS 表
dim_client ─── dictGet('dim_client_dict') ←── dwd_so_profit, dws_cust_rebate_actual_m
dim_formula_product_dictpack ←── dwd_so_profit, ads_sales_profit_contribution_snap
dim_unit_dict2 ── dictGet ←── dws_oa_cg_wlbj（OA 报价）
dim_material_dict2 ── dictGet ←── dws_oa_cg_wlbj, dim_row_product_snap
```

---

## 四、写入策略汇总

| 策略 | 表 | 说明 |
|---|---|---|
| TRUNCATE 全量 | dim_*, UF_* | 维表每日全量刷新 |
| OPTIMIZE FINAL | dwd_ia_monthnab | ReplacingMergeTree 去重 |
| 增量 ts > 上次 | dwd_so_saleorder, dwd_ic_flow, dwd_po_order_detail_all, ods_ia_detailledger | 增量拉取 |
| DROP PARTITION + 全量 | 大部分 DWD/DWS/ADS | 按月/年分区覆盖 |
| 按年 DROP PARTITION | dwd_fin_*（帆软填报类） | 按年全量覆盖 |
