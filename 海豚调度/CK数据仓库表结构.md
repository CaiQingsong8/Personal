# ClickHouse 数据仓库表结构

## 数据分层

```
Oracle源表 → ODS(贴源层) → DWD(明细层) → DWS(汇总层) → ADS(应用层)
                                ↑
                          DIM(维度层)
```

---

## ODS层（贴源层）- 1张表

| 表名 | 来源 | 工作流 |
|------|------|--------|
| ods_ia_detailledger | ia_detailledger + 维表关联 | 2job-nc_stock_1h |

---

## DIM层（维度层）- 17张表

| 表名 | 来源 | 工作流 |
|------|------|--------|
| dim_material | BD_BRANDDOC, BD_DEFDOC, BD_MARBASCLASS | 0dim-table_1h |
| dim_material_uat | BD_BRANDDOC, BD_DEFDOC, BD_MARBASCLASS | 0dim-table_1h |
| dim_material_rd45 | dwd_ic_flow_rd45 | 2job-nc_stock_1h |
| dim_client | DIM_CLIENT | 0dim-table_1h |
| dim_supplier | BD_DEFDOC, bd_address, bd_areacl | 0dim-table_1h |
| dim_stordoc | bd_stordoc | 0dim-table_1h |
| dim_unit | dim_unit (NC) | 0dim-table_1h |
| dim_bd_defdoc | bd_defdoc | 0dim-table_1h |
| dim_bd_defdoclist | bd_defdoclist | 0dim-table_1h |
| dim_bd_defdoc_uat | bd_defdoc | 0dim-table_1h |
| dim_bd_custsale | bd_custsale, bd_defdoc | 0dim-table_1h |
| dim_formula_product_snap | BD_BRANDDOC, BD_MARBASCLASS, bd_bom | 1-2job-dim_formula_product_snap_1w |
| dim_row_product_snap | dim_formula_product_snap, dim_material | 1-2job-dim_formula_product_snap_1w |
| dim_fact_row_price_snap | dim_row_product_snap, dws_ia_material_day_stock, dws_oa_cg_wlbj | 1job-nc_sal_profit |
| dim_formula_product_day_snap | dim_formula_product_dict, dim_formula_product_snap, dws_ia_material_day_stock | 1-1job-dwd_so_saleorder |
| uf_formula_product | dim_formula_product_dict | 1-2job-dim_formula_product_snap_1w |
| uf_dim_material_rd4 | dim_material_rd45, dws_ia_material_day_stock | 2job-nc_stock_1h |

---

## DWD层（明细层）- 29张表

### 财务类
| 表名 | 来源 | 工作流 |
|------|------|--------|
| dwd_gl_balance | gl_balance + bd_accasoa + bd_account | 4job-nc_fin |

### 库存类
| 表名 | 来源 | 工作流 |
|------|------|--------|
| dwd_ia_monthnab | ia_monthnab + 维表 | 2-1job-dwd_ia_monthnab_snap |
| dwd_ia_monthnab_adjust | ia_monthnab | 2-1job-dwd_ia_monthnab_snap |
| dwd_ia_monthnab_snap | dwd_ia_monthnab | 2-1job-dwd_ia_monthnab_snap |
| dwd_ic_flow | ic_flow + 维表 | 2job-nc_stock_1h |
| dwd_ic_flow_adjust | ic_flow | 2job-nc_stock_1h |
| dwd_ic_flow_rd45 | ic_flow + 维表 | 2job-nc_stock_1h |
| dwd_po_order_detail_all | PO_ORDER + PO_ORDER_B | 2job-nc_stock_1h |

### 销售类
| 表名 | 来源 | 工作流 |
|------|------|--------|
| dwd_so_saleorder | so_saleorder + 维表 | 1-1job-dwd_so_saleorder |
| dwd_so_cost | bd_customer + bd_marbasclass | 1-1job-dwd_so_saleorder |
| dwd_so_priceform | prm_priceform_p | 1-1job-dwd_so_saleorder |
| dwd_so_profit | dwd_so_saleorder + dws_cust_rebate_actual_m | 1-1job-dwd_so_saleorder |
| dwd_so_profit_old | dwd_so_cost + dwd_so_saleorder | 1-1job-dwd_so_saleorder |
| dwd_cust_rebate_actual_m | bd_customer + bd_custsale | 1-1job-dwd_so_saleorder |
| dwd_sal_product | alphafeed (CK自引用) | 1-1job-dwd_so_saleorder |
| dwd_product_subject_cost | cm_prodcost + 维表 | 1-1job-dwd_so_saleorder |
| dwd_price_maintenance_snap | bd_customer + 维表 | 1job-nc_sal_profit |
| dwd_fact_product_inbound_snap | kc_ccprk1 + 维表 | 1job-nc_sal_profit |
| dwd_oa_cg_wlbj | cg_wlbj + HrmResource | 1job-nc_sal_profit |
| dwd_plcy_discount_detail_ysnap | bd_billtype + bd_customer | 1job-nc_sal_profit |

### 财务预算类
| 表名 | 来源 | 工作流 |
|------|------|--------|
| dwd_fin_budget_detail | dwd_fin_budget_detail (FR填报) | 3job-FRdata |
| dwd_fin_budgetmth_detail | dim_client + dim_material | 3job-FRdata |
| dwd_fin_budgetmth_detail_fx | dwd_fin_budgetmth_detail | 3job-FRdata |
| dwd_fin_profit_detail | dwd_fin_profit_detail (FR填报) | 3job-FRdata |
| dwd_fin_profitmth_detail | dim_client + dim_material | 3job-FRdata |
| dwd_fin_net_profit | dwd_fin_net_profit (FR填报) | 3job-FRdata |
| dwd_fin_net_profitmth | dwd_fin_net_profit + dim_unit_dict | 3job-FRdata |
| dwd_fin_gross_profit | DIM_MATERIAL + DIM_UNIT (FR填报) | 3job-FRdata |

---

## DWS层（汇总层）- 7张表

| 表名 | 来源 | 工作流 |
|------|------|--------|
| dws_ia_material_day_stock | dwd_ia_monthnab_snap + dwd_ic_flow | 2-2sub-dws_ia_material_day_stock |
| dws_oa_cg_wlbj | dwd_oa_cg_wlbj | 1job-nc_sal_profit |
| dws_fr_cg_kcgzb | cg_kcgzb | 1job-nc_sal_profit |
| dws_cust_rebate_actual_m | dwd_cust_rebate_actual_m + dwd_so_saleorder | 1-1job-dwd_so_saleorder |
| dws_product_subject_cost | dwd_product_subject_cost | 1-1job-dwd_so_saleorder |
| dws_so_costsharing | BD_CUSTOMER + BD_DEFDOC | 1-1job-dwd_so_saleorder |
| dws_formula_product_day | dim_formula_product_day_snap + dws_ia_material_day_stock | 1-1job-dwd_so_saleorder |

---

## ADS层（应用层）- 1张表

| 表名 | 来源 | 工作流 |
|------|------|--------|
| ads_sales_profit_contribution_snap | dim_fact_row_price_snap + dim_formula_product_dictpack + dwd_cust_rebate_actual_m | 1job-nc_sal_profit |

---

## 其他 - 2张表

| 表名 | 来源 | 工作流 |
|------|------|--------|
| tb_guidance_price | tb_guidance_price (FR填报) | 3job-FRdata |
| rpt_forecast_sale_num | yc_xsjh | 3job-FRdata |

---

## 统计

| 层级 | 表数量 |
|------|--------|
| ODS | 1 |
| DIM | 17 |
| DWD | 29 |
| DWS | 7 |
| ADS | 1 |
| 其他 | 2 |
| **总计** | **57** |
