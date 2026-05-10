-- ==================================================
-- 视图：v_sale_cost_rebate
-- 用途：销售 / 成本 / 返利 三表 UNION ALL 汇总
-- 说明：data_type 标记数据来源，维度字段共享，指标字段错开
-- 数据源：dwd_so_profit（销售）+ dwd_so_cost（成本）+ dwd_cust_rebate_actual_m（返利）
-- 参数：
--   ${start_dt} 如 '2026-05'，空则默认当月
--   ${end_dt}   如 '2026-08'，空则默认当月
-- 不传参时自动查询当月；传参时按范围查询
-- ==================================================

SELECT
    '销售'                              AS data_type,
    t.month_dt,
    t.d_corp_id,
    t.d_corp_code,
    t.d_corp_name,
    t.d_corp_sname,
    t.d_material_id,
    t.d_material_code,
    t.d_material_name,
    t.d_class_code4,
    t.d_class_name4,
    t.d_class_code6,
    t.d_class_name6,
    t.d_client_id,
    t.d_client_code,
    t.d_client_name,
    t.d_salesman_id,
    t.d_salesman_code,
    t.d_salesman_name,
    t.d_bill_code,
    -- 销售指标
    t.f_num                                    AS f_sale_num,
    t.f_second_num                             AS f_sale_second_num,
    t.f_base_discount,
    t.f_base_discount_ton,
    t.f_promotion_discount,
    t.f_promotion_discount_ton,
    t.f_profit_amount,
    t.f_cost_amount                            AS f_sale_cost_amount,
    t.f_stock_price,
    t.f_rebate_amount                          AS f_sale_rebate_amount,
    -- 成本（留空）
    CAST(NULL AS Decimal(18,6))                AS f_cost_num,
    CAST(NULL AS Decimal(18,6))                AS f_cost_amount,
    CAST(NULL AS Decimal(18,6))                AS f_cost_ton,
    -- 返利（留空）
    CAST(NULL AS Decimal(18,6))                AS f_rebate_amt,
    CAST(NULL AS Decimal(18,6))                AS f_rebate_qty,
    CAST(NULL AS Decimal(18,6))                AS f_payout_amt
FROM dwd_so_profit t
WHERE t.month_dt >= if('${start_dt}' = '',
                        substr(toYYYYMM(now()), 1, 4) || '-' || substr(toYYYYMM(now()), 5, 2),
                        '${start_dt}')
  AND t.month_dt <= if('${end_dt}' = '',
                        substr(toYYYYMM(now()), 1, 4) || '-' || substr(toYYYYMM(now()), 5, 2),
                        '${end_dt}')

UNION ALL

SELECT
    '成本'                              AS data_type,
    t.month_dt,
    t.d_corp_id,
    t.d_corp_code,
    t.d_corp_name,
    t.d_corp_sname,
    t.d_material_id,
    t.d_material_code,
    t.d_material_name,
    t.d_class_code4,
    t.d_class_name4,
    t.d_class_code6,
    t.d_class_name6,
    t.d_client_id,
    t.d_client_code,
    t.d_client_name,
    t.d_salesman_id,
    t.d_salesman_code,
    t.d_salesman_name,
    t.d_bill_code,
    -- 销售（留空）
    CAST(NULL AS Decimal(18,6))                AS f_sale_num,
    CAST(NULL AS Decimal(18,6))                AS f_sale_second_num,
    CAST(NULL AS Decimal(18,6))                AS f_base_discount,
    CAST(NULL AS Decimal(18,6))                AS f_base_discount_ton,
    CAST(NULL AS Decimal(18,6))                AS f_promotion_discount,
    CAST(NULL AS Decimal(18,6))                AS f_promotion_discount_ton,
    CAST(NULL AS Decimal(18,6))                AS f_profit_amount,
    CAST(NULL AS Decimal(18,6))                AS f_sale_cost_amount,
    CAST(NULL AS Decimal(18,6))                AS f_stock_price,
    CAST(NULL AS Decimal(18,6))                AS f_sale_rebate_amount,
    -- 成本指标
    t.f_num                                    AS f_cost_num,
    t.f_cost_amount                            AS f_cost_amount,
    t.f_cost_ton                               AS f_cost_ton,
    -- 返利（留空）
    CAST(NULL AS Decimal(18,6))                AS f_rebate_amt,
    CAST(NULL AS Decimal(18,6))                AS f_rebate_qty,
    CAST(NULL AS Decimal(18,6))                AS f_payout_amt
FROM dwd_so_cost t
WHERE t.month_dt >= if('${start_dt}' = '',
                        substr(toYYYYMM(now()), 1, 4) || '-' || substr(toYYYYMM(now()), 5, 2),
                        '${start_dt}')
  AND t.month_dt <= if('${end_dt}' = '',
                        substr(toYYYYMM(now()), 1, 4) || '-' || substr(toYYYYMM(now()), 5, 2),
                        '${end_dt}')

UNION ALL

SELECT
    '返利'                              AS data_type,
    t.biz_mth                                  AS month_dt,
    t.d_corp_id,
    t.d_corp_code,
    t.d_corp_name,
    t.d_corp_sname,
    CAST(NULL AS FixedString(20))              AS d_material_id,
    CAST(NULL AS String)                       AS d_material_code,
    CAST(NULL AS String)                       AS d_material_name,
    CAST(NULL AS String)                       AS d_class_code4,
    CAST(NULL AS String)                       AS d_class_name4,
    CAST(NULL AS String)                       AS d_class_code6,
    CAST(NULL AS String)                       AS d_class_name6,
    t.d_client_id,
    t.d_client_code,
    t.d_client_name,
    CAST(NULL AS FixedString(20))              AS d_salesman_id,
    CAST(NULL AS String)                       AS d_salesman_code,
    CAST(NULL AS String)                       AS d_salesman_name,
    CAST(NULL AS String)                       AS d_bill_code,
    -- 销售（留空）
    CAST(NULL AS Decimal(18,6))                AS f_sale_num,
    CAST(NULL AS Decimal(18,6))                AS f_sale_second_num,
    CAST(NULL AS Decimal(18,6))                AS f_base_discount,
    CAST(NULL AS Decimal(18,6))                AS f_base_discount_ton,
    CAST(NULL AS Decimal(18,6))                AS f_promotion_discount,
    CAST(NULL AS Decimal(18,6))                AS f_promotion_discount_ton,
    CAST(NULL AS Decimal(18,6))                AS f_profit_amount,
    CAST(NULL AS Decimal(18,6))                AS f_sale_cost_amount,
    CAST(NULL AS Decimal(18,6))                AS f_stock_price,
    CAST(NULL AS Decimal(18,6))                AS f_sale_rebate_amount,
    -- 成本（留空）
    CAST(NULL AS Decimal(18,6))                AS f_cost_num,
    CAST(NULL AS Decimal(18,6))                AS f_cost_amount,
    CAST(NULL AS Decimal(18,6))                AS f_cost_ton,
    -- 返利指标
    t.f_rebate_amt,
    t.f_rebate_qty,
    t.f_payout_amt
FROM dwd_cust_rebate_actual_m t
WHERE t.biz_mth >= if('${start_dt}' = '',
                       substr(toYYYYMM(now()), 1, 4) || '-' || substr(toYYYYMM(now()), 5, 2),
                       '${start_dt}')
  AND t.biz_mth <= if('${end_dt}' = '',
                       substr(toYYYYMM(now()), 1, 4) || '-' || substr(toYYYYMM(now()), 5, 2),
                       '${end_dt}')
;
