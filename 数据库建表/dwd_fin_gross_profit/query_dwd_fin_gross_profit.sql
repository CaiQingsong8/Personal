-- ==================================================
-- DATAX Oracle → CK 查询：毛利粗利配置表（dwd_fin_gross_profit）
-- 用途：从 Oracle FR 填报表 + dim_unit + dim_material 维表解析后写入 CK
-- 说明：公司字段通过 dim_unit（org_type='公司'）解析
--       物料维度通过 dim_material（MATERIAL_CODE）解析
--       AS 别名保持 CK 命名规范（d_/f_ 前缀）
-- 数据源：Oracle
-- 目标表：CK dwd_fin_gross_profit
-- ==================================================

SELECT
    -- ==================== 基础 ====================
    a.GROSS_PROFIT_YEAR AS gross_profit_year,

    -- ==================== 物料 ====================
    m.MATERIAL_PK       AS d_material_id,
    a.D_MATERIAL_CODE   AS d_material_code,
    m.MATERIAL_NAME     AS d_material_name,
    a.D_MATERIAL_NAME   AS d_material_name_fr,

    -- ==================== 大小类 ====================
    m.CLASS_CODE4       AS d_class_code4,
    m.CLASS_NAME4       AS d_class_name4,
    a.D_CLASS_NAME4     AS d_class_name4_fr,
    m.CLASS_CODE6       AS d_class_code6,
    m.CLASS_NAME6       AS d_class_name6,
    a.D_CLASS_NAME6     AS d_class_name6_fr,

    -- ==================== 产线 ====================
    m.PRODLINE_CODE     AS d_prodline_code,
    m.PRODLINE_NAME     AS d_prodline_name,

    -- ==================== 利润归属公司 ====================
    pu.CORP_PK          AS d_profit_corp_id,
    pu.CORP_CODE        AS d_profit_corp_code,
    pu.CORP_NAME        AS d_profit_corp_name,
    a.D_PROFIT_CORP_SNAME AS d_profit_corp_sname,
    pu.REGION_CODE      AS d_profit_region_code,
    pu.REGION_NAME      AS d_profit_region_name,

    -- ==================== 生产公司 ====================
    au.CORP_PK          AS d_produce_corp_id,
    au.CORP_CODE        AS d_produce_corp_code,
    au.CORP_NAME        AS d_produce_corp_name,
    a.D_PRODUCE_CORP_SNAME AS d_produce_corp_sname,

    -- ==================== 产品属性 ====================
    a.PARTICLE_SIZE     AS particle_size,
    a.PRODUCT_SERIES    AS product_series,
    a.STRATEGY_NAME     AS strategy_name,

    -- ==================== 指标 ====================
    a.F_GROSS_RED       AS f_gross_red,

    -- ==================== ETL ====================
    TO_CHAR(a.ETL_CREATE_TIME, 'YYYY-MM-DD HH24:MI:SS') AS ts_char

FROM DWD_FIN_GROSS_PROFIT a
LEFT JOIN DIM_MATERIAL m
    ON m.MATERIAL_CODE = a.D_MATERIAL_CODE
LEFT JOIN DIM_UNIT pu
    ON pu.CORP_SNAME = a.D_PROFIT_CORP_SNAME
    AND pu.ORG_TYPE = '公司'
LEFT JOIN DIM_UNIT au
    ON au.CORP_SNAME = a.D_PRODUCE_CORP_SNAME
    AND au.ORG_TYPE = '公司'
WHERE a.GROSS_PROFIT_YEAR = '${gross_profit_year}'
ORDER BY a.GROSS_PROFIT_YEAR DESC, pu.CORP_CODE, a.D_MATERIAL_CODE
