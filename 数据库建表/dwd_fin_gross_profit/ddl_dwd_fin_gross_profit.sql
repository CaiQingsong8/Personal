-- auto-generated definition
create table DWD_FIN_GROSS_PROFIT
(
    UUID                 NUMBER,
    D_MATERIAL_CODE      VARCHAR2(100),
    D_MATERIAL_NAME      VARCHAR2(200),
    D_PROFIT_CORP_SNAME  VARCHAR2(200),
    D_PRODUCE_CORP_SNAME VARCHAR2(200),
    D_CLASS_NAME6        VARCHAR2(100),
    D_CLASS_NAME4        VARCHAR2(100),
    PARTICLE_SIZE        VARCHAR2(100),
    PRODUCT_SERIES       VARCHAR2(200),
    STRATEGY_NAME        VARCHAR2(50),
    F_GROSS_RED          NUMBER(18, 6),
    GROSS_PROFIT_YEAR    NUMBER(4),
    ETL_CREATE_TIME      DATE default SYSDATE
)
;

comment on table DWD_FIN_GROSS_PROFIT is '毛利粗利配置表 - 来源帆软填报'
;

comment on column DWD_FIN_GROSS_PROFIT.UUID is '序号'
;

comment on column DWD_FIN_GROSS_PROFIT.D_MATERIAL_CODE is '物料编码'
;

comment on column DWD_FIN_GROSS_PROFIT.D_MATERIAL_NAME is '物料名称'
;

comment on column DWD_FIN_GROSS_PROFIT.D_PROFIT_CORP_SNAME is '利润归属公司'
;

comment on column DWD_FIN_GROSS_PROFIT.D_PRODUCE_CORP_SNAME is '生产公司'
;

comment on column DWD_FIN_GROSS_PROFIT.D_CLASS_NAME6 is '小类'
;

comment on column DWD_FIN_GROSS_PROFIT.D_CLASS_NAME4 is '大类'
;

comment on column DWD_FIN_GROSS_PROFIT.PARTICLE_SIZE is '粒径'
;

comment on column DWD_FIN_GROSS_PROFIT.PRODUCT_SERIES is '产品系列'
;

comment on column DWD_FIN_GROSS_PROFIT.STRATEGY_NAME is '战略产品（是;否）'
;

comment on column DWD_FIN_GROSS_PROFIT.F_GROSS_RED is '配销差红线'
;

comment on column DWD_FIN_GROSS_PROFIT.ETL_CREATE_TIME is '数据入库时间'
;

create index IDX_GROSS_PROFIT_MATERIAL
    on DWD_FIN_GROSS_PROFIT (D_MATERIAL_CODE)
;

create index IDX_GROSS_PROFIT_CORP
    on DWD_FIN_GROSS_PROFIT (D_PROFIT_CORP_SNAME)
;

create index IDX_GROSS_PROFIT_YEAR
    on DWD_FIN_GROSS_PROFIT (GROSS_PROFIT_YEAR)
;
