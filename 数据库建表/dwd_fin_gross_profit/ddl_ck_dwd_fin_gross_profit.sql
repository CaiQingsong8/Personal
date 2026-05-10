-- ==================================================
-- 表名：ck.dwd_fin_gross_profit
-- 主题域：DWD - 财务
-- 来源：Oracle → CK DATAX（query_dwd_fin_gross_profit.sql）
-- 说明：毛利粗利配置表，字段与查询 SELECT 完全一致
--       公司维度由 Oracle dim_unit 解析（org_type='公司'）
--       物料维度由 Oracle dim_material 解析（MATERIAL_CODE）
-- 分区：按 gross_profit_year（年份）
-- 引擎：ReplacingMergeTree(ts)
-- 创建时间：2026-04-30
-- ==================================================

CREATE TABLE IF NOT EXISTS dwd_fin_gross_profit
(
    -- ==================== 基础 ====================
    gross_profit_year     UInt16 COMMENT '年份（如2026）',

    -- ==================== 物料 ====================
    d_material_id         FixedString(20) COMMENT '物料主键',
    d_material_code       String          COMMENT '物料编码',
    d_material_name       String          COMMENT '物料名称（维表）',
    d_material_name_fr    String          COMMENT '物料名称（FR填报）',

    -- ==================== 大小类 ====================
    d_class_code4         String COMMENT '大类编码',
    d_class_name4         String COMMENT '大类名称（维表）',
    d_class_name4_fr      String COMMENT '大类名称（FR填报）',
    d_class_code6         String COMMENT '小类编码',
    d_class_name6         String COMMENT '小类名称（维表）',
    d_class_name6_fr      String COMMENT '小类名称（FR填报）',

    -- ==================== 产线 ====================
    d_prodline_code       String COMMENT '产线编码',
    d_prodline_name       String COMMENT '产线名称',

    -- ==================== 利润归属公司 ====================
    d_profit_corp_id      FixedString(20) COMMENT '利润归属公司主键',
    d_profit_corp_code    String          COMMENT '利润归属公司编码',
    d_profit_corp_name    String          COMMENT '利润归属公司名称',
    d_profit_corp_sname   String          COMMENT '利润归属公司简称',
    d_profit_region_code  String          COMMENT '利润归属大区编码',
    d_profit_region_name  String          COMMENT '利润归属大区名称',

    -- ==================== 生产公司 ====================
    d_produce_corp_id     FixedString(20) COMMENT '生产公司主键',
    d_produce_corp_code   String          COMMENT '生产公司编码',
    d_produce_corp_name   String          COMMENT '生产公司名称',
    d_produce_corp_sname  String          COMMENT '生产公司简称',

    -- ==================== 产品属性 ====================
    particle_size         String COMMENT '粒径',
    product_series        String COMMENT '产品系列',
    strategy_name         String COMMENT '战略产品（是;否）',

    -- ==================== 指标 ====================
    f_gross_red           Decimal(18, 6) COMMENT '配销差红线',

    -- ==================== ETL ====================
    ts_char               String   COMMENT '源时间戳（字符）',
    ts                    DateTime MATERIALIZED toDateTime(ts_char) COMMENT '更新时间'
)
ENGINE = ReplacingMergeTree(ts)
PARTITION BY gross_profit_year
ORDER BY (d_profit_corp_id, d_material_id, gross_profit_year)
SETTINGS index_granularity = 8192
COMMENT '毛利粗利配置表 - 来源帆软填报';
