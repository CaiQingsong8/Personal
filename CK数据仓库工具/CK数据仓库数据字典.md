# ClickHouse 数据仓库数据字典

> 自动生成 | 数据来源：script.sql + workflow JSON

## 数据分层

```
Oracle源表 → ODS(贴源层) → DWD(明细层) → DWS(汇总层) → ADS(应用层)
                                ↑
                          DIM(维度层)
```

---

## ODS层（贴源层）- 2张表

### ods_fx_client_forecast
**层级**: ODS | **工作流**: - | **字段数**: 36
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_code` | String | 大区编码 |
| `d_region_name` | String | 大区名称 |
| `d_dept_id` | String | 部门ID |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `client_forecast_uid` | String | 纷享销客客户预测唯一主键 |
| `d_corp_id` | String | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_area_id` | String | 区域主键 |
| `d_area_code` | String | 区域编码 |
| `d_area_name` | String | 区域名称 |
| `d_client_id` | String | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `is_strategic` | String | 真实大客户：入池，达标等 |
| `is_strategic_flag` | String | 标记大客户：1标记，0未标记 |
| `d_prodline_id` | String | 产品线主键 |
| `d_prodline_code` | String | 产品线编码 |
| `d_prodline_name` | String | 产品线 |
| `d_product_sub_id` | String | 产品品种or小类主键：跟nc分类无关联 |
| `d_product_sub_code` | String | 产品品种or小类编码：跟nc分类无关 |
| `d_product_sub_name` | String | 产品品种or小类名称：跟nc分类无关 |
| `f_budget_qty` | Decimal(18, 6) | 预算销量：财务/管理层制定的正式销售目标（通常按年/季） |
| `f_forecast_qty` | Decimal(18, 6) | 预测销量：基于历史趋势、市场动态等生成的销量预估，一般月初填写本月预测 |
| `dr` | String | 0：未删除，1：删除 |
| `ts_char` | String | NC 系统最后同步时间戳（用于增量捕获） |
| `ts` | DateTime materialized coalesce(parseDateTimeBestEffortOrNull(ts_char), now()) | 业务日期（物化） |
| `month_dt` | String | YYYY-MM年月 |
| `insert_ts` | DateTime default now() | 自动生成写入时间 |
| `year` | UInt16   default toYear(toDate(concat(month_dt, '-01'))) |  |
| `f_forecast_qty_high` | Decimal(18, 6) | 高价值预测销量：基于历史趋势、市场动态等生成的销量预估，一般月初填写本月预测 |
| `f_forecast_qty_animal` | Decimal(18, 6) | 动保预测销量：基于历史趋势、市场动态等生成的销量预估，一般月初填写本月预测 |
| `f_budget_qty_high` | Decimal(18, 6) | 高价值预算销量：财务/管理层制定的正式销售目标（通常按年/季） |
| `f_budget_qty_animal` | Decimal(18, 6) | 动保预算销量：财务/管理层制定的正式销售目标（通常按年/季） |

### ods_ia_detailledger
**层级**: ODS | **工作流**: 2job-nc_stock_1h | **字段数**: 61
**上游表**: bd_marbasclass, bd_material, ia_detailledger
**底层数据源(Oracle)**: bd_marbasclass, bd_material, ia_detailledger

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `cdetailledgerid` | String | 单据明细表主键 |
| `pk_book` | String | 所属账簿 |
| `pk_group` | String | 所属集团 |
| `pk_org` | String | 成本域 |
| `caccountperiod` | String | 会计期间 |
| `cbilltypecode` | String | 单据类型 |
| `cbiztypeid` | String | 业务类型 |
| `cbill_bid` | String | 单据子表主键 |
| `cbillid` | String | 单据主表主键 |
| `vbillcode` | String | 单据号 |
| `dbilldate` | String | 单据日期 |
| `dbizdate` | String | 业务日期 |
| `dmakedate` | String | 制单日期 |
| `cstockorgid` | String | 库存组织最新版本 |
| `cstockorgvid` | String | 库存组织 |
| `cstordocid` | String | 仓库 |
| `cstordocmanid` | String | 库管员 |
| `ctrantypeid` | String | 出入库类型 |
| `cvendorid` | String | 供应商 |
| `casscustid` | String | 客户 |
| `crowno` | String | 行号 |
| `cinventoryid` | String | 物料 |
| `cinventoryvid` | String | 物料版本 |
| `cinvclass_sid` | String | 物料小类:6位 |
| `class_code6` | String | 物小类编码(最小6位) |
| `class_name6` | String | 物料小类名称 |
| `cinvclassid` | String | 物料大类：4位 |
| `class_code4` | String | 物大类编码(最小4位) |
| `class_name4` | String | 物料大类名称 |
| `cunitid` | String | 主单位 |
| `castunitid` | String | 单位 |
| `nmny` | Decimal(28, 8) | 金额 |
| `nnum` | Decimal(28, 8) | 主数量 |
| `nadjustnum` | Decimal(28, 8) | 调整数量 |
| `nastnum` | Decimal(28, 8) | 数量 |
| `nprice` | Decimal(28, 8) | 单价 |
| `nvarymny` | Decimal(28, 8) | 差异金额 |
| `vchangerate` | String | 换算率 |
| `vfirstcode` | String | 源头单据号 |
| `vfirstrowno` | String | 源头单据行号 |
| `vfirsttrantype` | String | 源头交易类型 |
| `vfirsttype` | String | 源头单据类型 |
| `cfirstbid` | String | 源头单据分录 |
| `cfirstid` | String | 源头单据 |
| `vsrccode` | String | 来源单据号 |
| `vsrcrowno` | String | 来源分录行号 |
| `vsrctrantype` | String | 来源交易类型 |
| `vsrctype` | String | 来源单据类型 |
| `csrcbid` | String | 来源单据分录 |
| `csrcid` | String | 来源单据 |
| `csrcmodulecode` | String | 来源模块编码 |
| `fdispatchflag` | Int32 | 收发类别 |
| `cdeptid` | String | 部门最新版本 |
| `cdeptvid` | String | 部门 |
| `vbatchcode` | String | 批次号 |
| `vproducebatch` | String | 产成品生产批次 |
| `vproduceordercode` | String | 生产订单号 |
| `cpsnid` | String | 业务员 |
| `dr` | Int32 | 删除标识 |
| `ts` | String | 修改时间字符型 |
| `ts_dt` | DateTime | 修改时间日期型 |

---

## DIM层（维度层）- 38张表

### dim_bd_custsale
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 45
**上游表**: bd_custsale, bd_defdoc
**底层数据源(Oracle)**: bd_custsale, bd_defdoc

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `billingcust` | String | 开票客户[客户基本信息] |
| `channel` | String | 渠道类型[渠道类型] |
| `creationtime` | String | 创建日期 |
| `creator` | String | 创建人[用户] |
| `currencydefault` | String | 默认交易币种[币种] |
| `dataoriginflag` | Int32 | 分布式(0=本级产生，1=上级下发，2=下级上报，3=本级产生已上报下发，-1=系统预置， ？) |
| `discountrate` | Decimal(20, 8) | 扣率 |
| `issuecust` | String | 收货客户[客户基本信息] |
| `modifiedtime` | String | 最后修改日期 |
| `modifier` | String | 最后修改人[用户] |
| `ordertypedefault` | String | 默认订单类型[单据类型 ] |
| `paytermdefault` | String | 默认收款协议[收款协议] |
| `pk_customer` | String | 客户基本信息[客户基本信息] |
| `pk_custsale` | String | 客户销售信息主键[主键] |
| `pk_custsaleclass` | String | 客户销售分类[客户销售分类] |
| `pk_financeorg` | String | 结算财务组织[组织_业务单元_财务组织] |
| `pk_group` | String | 所属集团[组织_集团] |
| `pk_liabilitycenter` | String | 利润中心[组织_业务单元_利润中心] |
| `pk_org` | String | 所属销售组织[组织_业务单元_销售组织] |
| `pk_paycust` | String | 付款客户[客户基本信息] |
| `pk_receiveorg` | String | 应收组织[组织_业务单元_财务组织] |
| `pk_tradeterm` | String | 贸易术语[贸易术语] |
| `prepaidratio` | Float64 | 预收款比例 |
| `respdept` | String | 专管部门[组织_部门] |
| `respperson` | String | 专管业务员[人员基本信息] |
| `shippingtype` | String | 运输方式[运输方式] |
| `stockpriceratio` | Float64 | 物料最低售价比例 |
| `def1` | String | 自定义项1(预留字段) |
| `def10` | String | 自定义项10(日期) |
| `def11` | String | 自定义项11(日期) |
| `pk_area` | String | 自定义项12（区域or聚焦镇主键） |
| `area_code` | String | 自定义表（区域or聚焦镇编码bd_defdoc.code） |
| `area_name` | String | 自定义表（区域or聚焦镇名称bd_defdoc.name） |
| `def13` | String | 自定义项13(预留字段) |
| `def2` | String | 自定义项2(固定编码) |
| `def3` | String | 自定义项3(固定编码) |
| `def4` | String | 自定义项4(固定编码) |
| `def5` | String | 聚焦镇主键(缺失) |
| `def6` | String | 自定义项6(固定编码) |
| `def7` | String | 自定义项7(固定编码) |
| `def8` | String | 核算单位主键 |
| `def9` | String | 分配状态(枚举值：Y，N) |
| `dr` | String | 关闭或删除标志(1未关闭；0关闭) |
| `ts` | String | 关闭或删除时间 |
| `updtime` | String | 数据更新时间(抽数时间) |

### dim_bd_custsale_dict
**层级**: DIM | **工作流**: - | **字段数**: 44
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `pk_customer` | String |  |
| `pk_org` | String |  |
| `billingcust` | String |  |
| `channel` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `currencydefault` | String |  |
| `dataoriginflag` | Int32 |  |
| `discountrate` | Decimal(20, 8) |  |
| `issuecust` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `ordertypedefault` | String |  |
| `paytermdefault` | String |  |
| `pk_custsale` | String |  |
| `pk_custsaleclass` | String |  |
| `pk_financeorg` | String |  |
| `pk_group` | String |  |
| `pk_liabilitycenter` | String |  |
| `pk_paycust` | String |  |
| `pk_receiveorg` | String |  |
| `pk_tradeterm` | String |  |
| `prepaidratio` | Float64 |  |
| `respdept` | String |  |
| `respperson` | String |  |
| `shippingtype` | String |  |
| `stockpriceratio` | Float64 |  |
| `def1` | String |  |
| `def10` | String |  |
| `def11` | String |  |
| `pk_area` | String |  |
| `area_code` | String |  |
| `area_name` | String |  |
| `def13` | String |  |
| `def2` | String |  |
| `def3` | String |  |
| `def4` | String |  |
| `def5` | String |  |
| `def6` | String |  |
| `def7` | String |  |
| `def8` | String |  |
| `def9` | String |  |
| `dr` | String |  |
| `ts` | String |  |

### dim_bd_defdoc
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 33
**上游表**: bd_defdoc
**底层数据源(Oracle)**: bd_defdoc

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `code` | String 'RD001''）' | 档案编码（唯一业务编码，如  |
| `creationtime` | String '2025-10-01 12:34:56''）' | 创建时间（NC 原始字符串，格式如  |
| `creator` | FixedString(20) | 创建人主键（sm_user.pk_user） |
| `dataoriginflag` | String | 数据来源标志：0=手工录入，1=系统生成，2=接口导入 |
| `datatype` | String | 数据类型：1=文本，2=数值，3=日期，4=布尔等（NC 内部定义） |
| `enablestate` | String | 启用状态：2=启用，3=停用（NC 特有状态码） |
| `innercode` | String | 内部编码（NC 内部使用，通常与 code 相同或为空） |
| `memo` | String | 备注信息 |
| `mnecode` | String | 助记码（用于快速检索） |
| `modifiedtime` | String | 最后修改时间（NC 原始字符串） |
| `modifier` | String | 修改人主键（sm_user.pk_user） |
| `name` | String | 档案名称（主语言，如中文） |
| `name2` | String | 档案名称（第二语言，如英文） |
| `pid` | String | 父级档案主键（用于树形结构，如分类层级） |
| `pk_defdoc` | FixedString(20) | 档案主键（对应 NC 表 pk_defdoc，固定20字节） |
| `pk_defdoclist` | FixedString(20) | 档案明细行主键（对应 NC 表 pk_defdoclist，固定20字节） |
| `pk_group` | FixedString(20) | 集团主键（org_group.pk_group） |
| `pk_org` | String | 组织主键（org_orgs.pk_org） |
| `shortname` | String | 简称（主语言） |
| `shortname2` | String | 简称（第二语言） |
| `shortname6` | String | 超短名称（常用于打印或界面紧凑显示） |
| `def1` | LowCardinality(String) | 自定义字段1 |
| `def2` | LowCardinality(String) | 自定义字段2 |
| `def3` | LowCardinality(String) | 自定义字段3 |
| `def4` | LowCardinality(String) | 自定义字段4 |
| `def5` | LowCardinality(String) | 自定义字段5 |
| `def6` | LowCardinality(String) | 自定义字段6 |
| `def7` | LowCardinality(String) | 自定义字段7 |
| `def8` | LowCardinality(String) | 自定义字段8 |
| `def9` | LowCardinality(String) | 自定义字段9 |
| `dr` | String '0''=有效，''1''=删除（NC 标准字段）' | 逻辑删除标记： |
| `ts_char` | String | NC 时间戳（字符串格式，用于增量捕获或全量比对） |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) '2025-01-01''）' | ts_char 的物化 DateTime 列，用于 WHERE 条件加速（如 ts_dt >=  |

### dim_bd_defdoc_dict
**层级**: DIM | **工作流**: - | **字段数**: 33
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `pk_defdoc` | String |  |
| `code` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `dataoriginflag` | String |  |
| `datatype` | String |  |
| `enablestate` | String |  |
| `innercode` | String |  |
| `memo` | String |  |
| `mnecode` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `name` | String |  |
| `name2` | String |  |
| `pid` | String |  |
| `pk_defdoclist` | String |  |
| `pk_group` | String |  |
| `pk_org` | String |  |
| `shortname` | String |  |
| `shortname2` | String |  |
| `shortname6` | String |  |
| `def1` | String |  |
| `def2` | String |  |
| `def3` | String |  |
| `def4` | String |  |
| `def5` | String |  |
| `def6` | String |  |
| `def7` | String |  |
| `def8` | String |  |
| `def9` | String |  |
| `dr` | String |  |
| `ts_char` | String |  |
| `ts` | DateTime |  |

### dim_bd_defdoc_uat
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 33
**上游表**: bd_defdoc
**底层数据源(Oracle)**: bd_defdoc

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `code` | String 'RD001''）' | 档案编码（唯一业务编码，如  |
| `creationtime` | String '2025-10-01 12:34:56''）' | 创建时间（NC 原始字符串，格式如  |
| `creator` | FixedString(20) | 创建人主键（sm_user.pk_user） |
| `dataoriginflag` | String | 数据来源标志：0=手工录入，1=系统生成，2=接口导入 |
| `datatype` | String | 数据类型：1=文本，2=数值，3=日期，4=布尔等（NC 内部定义） |
| `enablestate` | String | 启用状态：2=启用，3=停用（NC 特有状态码） |
| `innercode` | String | 内部编码（NC 内部使用，通常与 code 相同或为空） |
| `memo` | String | 备注信息 |
| `mnecode` | String | 助记码（用于快速检索） |
| `modifiedtime` | String | 最后修改时间（NC 原始字符串） |
| `modifier` | String | 修改人主键（sm_user.pk_user） |
| `name` | String | 档案名称（主语言，如中文） |
| `name2` | String | 档案名称（第二语言，如英文） |
| `pid` | String | 父级档案主键（用于树形结构，如分类层级） |
| `pk_defdoc` | FixedString(20) | 档案主键（对应 NC 表 pk_defdoc，固定20字节） |
| `pk_defdoclist` | FixedString(20) | 档案明细行主键（对应 NC 表 pk_defdoclist，固定20字节） |
| `pk_group` | FixedString(20) | 集团主键（org_group.pk_group） |
| `pk_org` | String | 组织主键（org_orgs.pk_org） |
| `shortname` | String | 简称（主语言） |
| `shortname2` | String | 简称（第二语言） |
| `shortname6` | String | 超短名称（常用于打印或界面紧凑显示） |
| `def1` | LowCardinality(String) | 自定义字段1 |
| `def2` | LowCardinality(String) | 自定义字段2 |
| `def3` | LowCardinality(String) | 自定义字段3 |
| `def4` | LowCardinality(String) | 自定义字段4 |
| `def5` | LowCardinality(String) | 自定义字段5 |
| `def6` | LowCardinality(String) | 自定义字段6 |
| `def7` | LowCardinality(String) | 自定义字段7 |
| `def8` | LowCardinality(String) | 自定义字段8 |
| `def9` | LowCardinality(String) | 自定义字段9 |
| `dr` | String '0''=有效，''1''=删除（NC 标准字段）' | 逻辑删除标记： |
| `ts_char` | String | NC 时间戳（字符串格式，用于增量捕获或全量比对） |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) '2025-01-01''）' | ts_char 的物化 DateTime 列，用于 WHERE 条件加速（如 ts_dt >=  |

### dim_bd_defdoc_uat_dict
**层级**: DIM | **工作流**: - | **字段数**: 33
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `pk_defdoc` | String |  |
| `code` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `dataoriginflag` | String |  |
| `datatype` | String |  |
| `enablestate` | String |  |
| `innercode` | String |  |
| `memo` | String |  |
| `mnecode` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `name` | String |  |
| `name2` | String |  |
| `pid` | String |  |
| `pk_defdoclist` | String |  |
| `pk_group` | String |  |
| `pk_org` | String |  |
| `shortname` | String |  |
| `shortname2` | String |  |
| `shortname6` | String |  |
| `def1` | String |  |
| `def2` | String |  |
| `def3` | String |  |
| `def4` | String |  |
| `def5` | String |  |
| `def6` | String |  |
| `def7` | String |  |
| `def8` | String |  |
| `def9` | String |  |
| `dr` | String |  |
| `ts_char` | String |  |
| `ts` | DateTime |  |

### dim_bd_defdoclist
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 28
**上游表**: bd_defdoclist
**底层数据源(Oracle)**: bd_defdoclist

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `associatename` | String | 关联名称（如关联的业务对象名称） |
| `bpfcomponentid` | String | BPF组件ID（NC内部使用） |
| `code` | String 'RD001-01''）' | 档案明细编码（如  |
| `codectlgrade` | String | 编码控制级别（NC内部逻辑） |
| `coderule` | String | 编码规则（如前缀+流水号） |
| `componentid` | String | 组件ID（NC UI 或逻辑组件标识） |
| `creationtime` | String '2025-10-01 12:34:56''）' | 创建时间（NC原始字符串，格式如  |
| `creator` | FixedString(20) | 创建人主键（sm_user.pk_user） |
| `dataoriginflag` | String | 数据来源标志：0=手工，1=系统，2=接口 |
| `docclass` | String 'freeitem'' | 文档分类（如  |
| `''material_class''）'` |  |  |
| `doclevel` | String | 文档层级（用于树形结构深度） |
| `doctype` | String 'list'' | 文档类型（如  |
| `''tree''）'` |  |  |
| `funcode` | String | 功能编码（NC模块标识） |
| `isgrade` | String 'Y''/''N'' 或 ''1''/''0''' | 是否分级： |
| `isrelease` | String 'Y''/''N''' | 是否已发布： |
| `mngctlmode` | String | 管理控制模式（如审批流、版本控制等） |
| `modifiedtime` | String | 最后修改时间（NC原始字符串） |
| `modifier` | FixedString(20) | 修改人主键（sm_user.pk_user） |
| `name` | String | 明细名称（主语言） |
| `name2` | String | 明细名称（第二语言，如英文） |
| `pk_defdoclist` | FixedString(20) | 档案明细主键（唯一标识，对应 NC 表 pk_defdoclist） |
| `pk_group` | FixedString(20) | 集团主键（org_group.pk_group） |
| `pk_org` | FixedString(20) | 组织主键（org_orgs.pk_org） |
| `dr` | String '0''=有效，''1''=删除' | 逻辑删除标记： |
| `ts_char` | String | NC时间戳（字符串格式，用于增量比对） |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) '2025-01-01''）' | ts_char 的物化 DateTime 列，支持高效范围查询（如 WHERE ts_dt >=  |

### dim_bd_defdoclist_dict
**层级**: DIM | **工作流**: - | **字段数**: 26
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `pk_defdoclist` | String |  |
| `associatename` | String |  |
| `bpfcomponentid` | String |  |
| `code` | String |  |
| `codectlgrade` | String |  |
| `coderule` | String |  |
| `componentid` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `dataoriginflag` | String |  |
| `docclass` | String |  |
| `doclevel` | String |  |
| `doctype` | String |  |
| `funcode` | String |  |
| `isgrade` | String |  |
| `isrelease` | String |  |
| `mngctlmode` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `name` | String |  |
| `name2` | String |  |
| `pk_group` | String |  |
| `pk_org` | String |  |
| `dr` | String |  |
| `ts_char` | String |  |
| `ts` | DateTime |  |

### dim_client
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 85
**上游表**: dim_client
**CK内部依赖**: dim_client

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_code` | String | 大区编码 |
| `d_region_name` | String | 大区名称 |
| `d_corp_id` | FixedString(20) | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_unit_type` | String | 单位类型 |
| `d_unit_id` | FixedString(20) | 单位ID |
| `d_unit_code` | String | 单位编码 |
| `d_unit_name` | String | 单位名称 |
| `d_unit_sname` | String | 单位简称 |
| `d_unit_lname` | String | 单位全称 |
| `d_dept_id` | FixedString(20) | 部门ID |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_town_id` | FixedString(20) | 片区ID |
| `d_town_name` | String | 片区名称 |
| `d_salesman_id` | FixedString(20) | 业务员ID |
| `d_salesman_name` | String | 业务员名称 |
| `client_aera_id` | FixedString(20) | 客户区域ID |
| `client_aera_code` | String | 客户区域编码 |
| `client_aera_name` | String | 客户区域名称 |
| `client_id_adress` | String | 客户详细地址 |
| `business_aera_id` | String | 经营区域主键 |
| `business_aera` | String | 经营区域 |
| `business_province` | String | 经营省份 |
| `business_city` | String | 经营市区 |
| `d_client_id` | FixedString(20) | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_stat_code` | String | 客户状态编码 |
| `d_client_name` | String | 客户名称 |
| `d_client_sname` | String | 客户简称 |
| `d_client_mobile` | String | 客户手机号 |
| `tax_code` | String | 税号 |
| `is_corp_flag` | Int8 | 0个人户·1公司户2内部客户 |
| `is_corp_name` | String | 公司户[内部客户]  个人户 公司户   个人户[港澳台]   个人户[海外护照]    公司户[服务机构]  未知 |
| `general_flag` | Int32 | 是否一般纳税人标识 |
| `general_name` | String | 是否一般纳税人名称 |
| `product_name` | String | 主营产品 |
| `frozen_flag` | Int32 | 冻结标识 |
| `frozen_name` | String | 冻结状态名称 |
| `assign_flag` | Int32 | 是否分配标识 |
| `assign_name` | String | 是否分配名称 |
| `custclass_flag` | Int32 | 客户分类标识 |
| `custclass_name` | String | 客户分类名称 |
| `regist_flag` | Int32 | 注册标识 |
| `regist_name` | String | 注册名称 |
| `del_flag` | String | 删除标识 |
| `del_name` | String | 删除状态名称 |
| `custstatus_flag` | Int32 | 客户状态标识 |
| `custstatus_name` | String | 客户状态名称 |
| `unitbusi_flag` | Int32 | 单位业务标识 |
| `unitbusi_name` | String | 单位业务名称 |
| `corpbusi_flag` | Int32 | 公司业务标识 |
| `corpbusi_name` | String | 公司业务名称 |
| `start_status` | Int32 | 启用状态 |
| `client_dclass_code` | String | 客户分类编码 |
| `client_dclass_name` | String | 客户分类名称 |
| `client_updtime` | String | 客户更新时间 |
| `regist_starttime` | String | 注册开始时间 |
| `regist_endtime` | String | 注册结束时间 |
| `opening_date` | String | 开户日期 |
| `dept_status` | String | 部门状态 |
| `town_status` | String | 片区状态 |
| `salesman_status` | String | 业务员状态 |
| `client_class` | String | 客户等级 |
| `first_order_date` | String | 首单日期 |
| `d_main_prodline_name` | String | 主营产品线 |
| `f_main_sale_num` | Int32 | 主营销售数量 |
| `f_main_prodline_name_amounT` | String | 主营产品线(金额) |
| `f_main_sale_amount` | Int32 | 主营销售金额 |
| `f_main_sale_num_animal` | Int32 | 主营销售数量(动物) |
| `d_main_class_code4` | String | 主营品类4编码 |
| `d_main_class_name4` | String | 主营品类4名称 |
| `f_main_class4_num` | Int32 | 主营品类4数量 |
| `f_main_class_code4_amount` | String | 主营品类4编码(金额) |
| `f_main_class_name4_amount` | String | 主营品类4名称(金额) |
| `f_main_class4_amount` | Int32 | 主营品类4金额 |
| `d_unit_sale_id` | FixedString(20) | 销售组织ID |
| `d_unit_sale_code` | String | 销售组织编码 |
| `d_unit_sale_name` | String | 销售组织名称 |
| `d_unit_sale_lname` | String | 销售组织全称 |
| `updtime` | String | 更新时间 |
| `original_unit_code` | String | 原始单位编码 |
| `original_unit_name` | String | 原始单位名称 |

### dim_client_dict
**层级**: DIM | **工作流**: - | **字段数**: 85
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_id` | String |  |
| `d_corp_id` | String |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_unit_type` | String |  |
| `d_unit_id` | String |  |
| `d_unit_code` | String |  |
| `d_unit_name` | String |  |
| `d_unit_sname` | String |  |
| `d_unit_lname` | String |  |
| `d_dept_id` | String |  |
| `d_dept_code` | String |  |
| `d_dept_name` | String |  |
| `d_town_id` | String |  |
| `d_town_name` | String |  |
| `d_salesman_id` | String |  |
| `d_salesman_name` | String |  |
| `client_aera_id` | String |  |
| `client_aera_code` | String |  |
| `client_aera_name` | String |  |
| `client_id_adress` | String |  |
| `business_aera_id` | String |  |
| `business_aera` | String |  |
| `business_province` | String |  |
| `business_city` | String |  |
| `d_client_code` | String |  |
| `d_client_stat_code` | String |  |
| `d_client_name` | String |  |
| `d_client_sname` | String |  |
| `d_client_mobile` | String |  |
| `tax_code` | String |  |
| `is_corp_flag` | Int8 |  |
| `is_corp_name` | String |  |
| `general_flag` | Int32 |  |
| `general_name` | String |  |
| `product_name` | String |  |
| `frozen_flag` | Int32 |  |
| `frozen_name` | String |  |
| `assign_flag` | Int32 |  |
| `assign_name` | String |  |
| `custclass_flag` | Int32 |  |
| `custclass_name` | String |  |
| `regist_flag` | Int32 |  |
| `regist_name` | String |  |
| `del_flag` | String |  |
| `del_name` | String |  |
| `custstatus_flag` | Int32 |  |
| `custstatus_name` | String |  |
| `unitbusi_flag` | Int32 |  |
| `unitbusi_name` | String |  |
| `corpbusi_flag` | Int32 |  |
| `corpbusi_name` | String |  |
| `start_status` | Int32 |  |
| `client_dclass_code` | String |  |
| `client_dclass_name` | String |  |
| `client_updtime` | String |  |
| `regist_starttime` | String |  |
| `regist_endtime` | String |  |
| `opening_date` | String |  |
| `dept_status` | String |  |
| `town_status` | String |  |
| `salesman_status` | String |  |
| `client_class` | String |  |
| `first_order_date` | String |  |
| `d_main_prodline_name` | String |  |
| `f_main_sale_num` | Int32 |  |
| `f_main_prodline_name_amounT` | String |  |
| `f_main_sale_amount` | Int32 |  |
| `f_main_sale_num_animal` | Int32 |  |
| `d_main_class_code4` | String |  |
| `d_main_class_name4` | String |  |
| `f_main_class4_num` | Int32 |  |
| `f_main_class_code4_amount` | String |  |
| `f_main_class_name4_amount` | String |  |
| `f_main_class4_amount` | Int32 |  |
| `d_unit_sale_id` | String |  |
| `d_unit_sale_code` | String |  |
| `d_unit_sale_name` | String |  |
| `d_unit_sale_lname` | String |  |
| `updtime` | String |  |
| `original_unit_code` | String |  |
| `original_unit_name` | String |  |

### dim_client_dict2
**层级**: DIM | **工作流**: - | **字段数**: 85
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_code` | String |  |
| `d_corp_code` | String |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_unit_type` | String |  |
| `d_unit_id` | String |  |
| `d_unit_code` | String |  |
| `d_unit_name` | String |  |
| `d_unit_sname` | String |  |
| `d_unit_lname` | String |  |
| `d_dept_id` | String |  |
| `d_dept_code` | String |  |
| `d_dept_name` | String |  |
| `d_town_id` | String |  |
| `d_town_name` | String |  |
| `d_salesman_id` | String |  |
| `d_salesman_name` | String |  |
| `client_aera_id` | String |  |
| `client_aera_code` | String |  |
| `client_aera_name` | String |  |
| `client_id_adress` | String |  |
| `business_aera_id` | String |  |
| `business_aera` | String |  |
| `business_province` | String |  |
| `business_city` | String |  |
| `d_client_id` | String |  |
| `d_client_stat_code` | String |  |
| `d_client_name` | String |  |
| `d_client_sname` | String |  |
| `d_client_mobile` | String |  |
| `tax_code` | String |  |
| `is_corp_flag` | Int8 |  |
| `is_corp_name` | String |  |
| `general_flag` | Int32 |  |
| `general_name` | String |  |
| `product_name` | String |  |
| `frozen_flag` | Int32 |  |
| `frozen_name` | String |  |
| `assign_flag` | Int32 |  |
| `assign_name` | String |  |
| `custclass_flag` | Int32 |  |
| `custclass_name` | String |  |
| `regist_flag` | Int32 |  |
| `regist_name` | String |  |
| `del_flag` | String |  |
| `del_name` | String |  |
| `custstatus_flag` | Int32 |  |
| `custstatus_name` | String |  |
| `unitbusi_flag` | Int32 |  |
| `unitbusi_name` | String |  |
| `corpbusi_flag` | Int32 |  |
| `corpbusi_name` | String |  |
| `start_status` | Int32 |  |
| `client_dclass_code` | String |  |
| `client_dclass_name` | String |  |
| `client_updtime` | String |  |
| `regist_starttime` | String |  |
| `regist_endtime` | String |  |
| `opening_date` | String |  |
| `dept_status` | String |  |
| `town_status` | String |  |
| `salesman_status` | String |  |
| `client_class` | String |  |
| `first_order_date` | String |  |
| `d_main_prodline_name` | String |  |
| `f_main_sale_num` | Int32 |  |
| `f_main_prodline_name_amounT` | String |  |
| `f_main_sale_amount` | Int32 |  |
| `f_main_sale_num_animal` | Int32 |  |
| `d_main_class_code4` | String |  |
| `d_main_class_name4` | String |  |
| `f_main_class4_num` | Int32 |  |
| `f_main_class_code4_amount` | String |  |
| `f_main_class_name4_amount` | String |  |
| `f_main_class4_amount` | Int32 |  |
| `d_unit_sale_id` | String |  |
| `d_unit_sale_code` | String |  |
| `d_unit_sale_name` | String |  |
| `d_unit_sale_lname` | String |  |
| `updtime` | String |  |
| `original_unit_code` | String |  |
| `original_unit_name` | String |  |

### dim_fact_row_price_snap
**层级**: DIM | **工作流**: 1job-nc_sal_profit | **字段数**: 24
**上游表**: dim_row_product_snap, dws_ia_material_day_stock, dws_oa_cg_wlbj
**CK内部依赖**: dim_row_product_snap, dws_ia_material_day_stock, dws_oa_cg_wlbj

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_joinid` | String | 产品代工公司ID（关联使用） |
| `d_production_type` | FixedString(6) | 生产类型：自产 / 代工  |
| `d_product_id` | FixedString(20) | 产品ID |
| `d_product_code` | FixedString(10) | 产品编码 |
| `d_product_name` | String | 产品名称 |
| `d_formula_id` | FixedString(20) | 配方ID |
| `d_formula_code` | FixedString(10) | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `d_row_id` | FixedString(20) | 原料ID |
| `d_row_code` | FixedString(10) | 原料编码 |
| `d_row_name` | String | 原料名称 |
| `f_row_ratio_num` | Decimal(18, 6) | 原料配比（行级） |
| `f_product_ratio_num` | Decimal(18, 6) | 产品配比 |
| `f_latest_price_kg` | Decimal(18, 6) | 最新单价（元/千克） |
| `f_latest_price_kg_avg30` | Decimal(18, 6) | 30天均价（元/千克） |
| `f_latest_price_kg_avg365` | Decimal(18, 6) | 365天均价（元/千克） |
| `f_latest_price_kg_avgall` | Decimal(18, 6) | 历史累计均价（元/千克） |
| `f_price_kg` | Decimal(18, 6) | 最终采用价格（元/千克）：优先3最新单价，否则在途，否则库存 |
| `f_stock_price_kg` | Decimal(18, 6) | 库存单价（元/千克） |
| `f_transit_price_kg_avg30` | Decimal(18, 6) | 在途30天移动均价（元/千克） |
| `updt` | Date | 更新日期（快照日期） |

### dim_formula_product_day_snap
**层级**: DIM | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 57
**上游表**: dim_formula_product_dict, dim_formula_product_snap, dws_ia_material_day_stock
**CK内部依赖**: dim_formula_product_dict, dim_formula_product_snap, dws_ia_material_day_stock

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `bom_uid` | FixedString(20) | bom维护唯一主键 |
| `bom_version` | String | bom版本号(默认使用最高版本) |
| `bom_status` | String | bom审批自由状态 |
| `vertion_type` | String | 1有效版本，2无效版本 |
| `is_default` | String | Y默认 N  |
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_product_id` | FixedString(20) | 成品主键 |
| `d_product_code` | FixedString(10) | 成品编码 |
| `d_product_name` | String | 成品名称 |
| `d_product_measure` | String | 成品计量单位 |
| `d_product_type` | String | 成品型号 |
| `d_class_code1` | FixedString(1) | 物料分类编码(1位) |
| `d_class_name1` | String | 物料分类编码(1位)名 |
| `d_class_code2` | FixedString(2) | 物料分类编码(2位) |
| `d_class_name2` | String | 物料分类编码(2位)名 |
| `d_class_code4` | FixedString(4) | 物料分类编码(4位) |
| `d_class_name4` | String | 物料分类编码(4位)名 |
| `d_class_code6` | FixedString(6) | 物料分类编码(6位) |
| `d_class_name6` | String | 物料分类编码(6位)名 |
| `d_formula_id` | FixedString(20) | 配方主键 |
| `d_formula_code` | FixedString(10) | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `d_formula_measure` | String | 配方计量单位 |
| `d_formula_type` | String | 配方型号 |
| `d_row_code1` | FixedString(1) | 原料分类编码(1位) |
| `d_row_name1` | String | 原料分类编码(1位)名 |
| `d_row_id` | FixedString(20) | 原料主键 |
| `d_row_code` | FixedString(10) | 原料编码 |
| `d_row_name` | String | 原料名称 |
| `d_row_measure` | String |  |
| `d_row_type` | String |  |
| `f_ratio_num` | Decimal(18, 6) | 配方比例 |
| `f_day_price` | Decimal(18, 6) | 添加剂实时价格补充调整 |
| `f_parent_num` | Decimal(18, 6) | 父项主数量 |
| `f_day_price_old` | Decimal(18, 6) | 原料实时价格 |
| `f_row_amount` | Decimal(18, 6) | 原料实时金额：配方比例*原料实时价格 |
| `is_right` | String | 自带价格TRUE 添加剂库存无价格FALSE 有价格TRUE1 |
| `formula_date` | FixedString(19) | 配方制单日期 |
| `start_date` | FixedString(19) | 生效日期 |
| `end_date` | FixedString(19) | 失效日期 |
| `creationtime` | FixedString(19) | 创建日期 |
| `creator` | String | 创建人 |
| `modifiedtime` | FixedString(19) | 修改日期 |
| `modifier` | String | 修改人 |
| `updt` | Date | 更新日期：年月日分区字段依据 |
| `d_brand_id` | FixedString(20) | 品牌主键 |
| `d_brand_code` | String | 品牌编码 |
| `d_brand_name` | String | 品牌 |
| `d_package_id` | FixedString(20) | 包装袋主键 |
| `d_package_code` | FixedString(10) | 包装袋编码 |
| `d_package_name` | String | 包装袋名称 |
| `f_package_ton_num` | Int32 | 单吨包装袋需要的数量 |
| `f_package_price` | Decimal(18, 6) | 单条包装袋价格 |
| `f_package_ton_price` | Decimal(18, 6) | 单吨包装袋价格 |

### dim_formula_product_dict
**层级**: DIM | **工作流**: - | **字段数**: 34
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | String |  |
| `d_formula_id` | String |  |
| `bom_uid` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_class_code1` | String |  |
| `d_class_name1` | String |  |
| `d_class_code2` | String |  |
| `d_class_name2` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_formula_uid` | String |  |
| `d_formula_code` | String |  |
| `d_formula_name` | String |  |
| `d_formula_measure` | String |  |
| `d_formula_type` | String |  |
| `d_brand_id` | String |  |
| `d_brand_code` | String |  |
| `d_brand_name` | String |  |
| `d_row_id` | String |  |
| `d_row_code` | String |  |
| `d_row_name` | String |  |
| `d_row_measure` | String |  |
| `d_row_type` | String |  |
| `f_ratio_num` | Decimal(18, 6) |  |
| `formula_date` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `updt` | Date |  |

### dim_formula_product_dict3
**层级**: DIM | **工作流**: - | **字段数**: 35
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_formula_id` | String |  |
| `bom_uid` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_corp_id_defined` | String |  |
| `d_corp_code_defined` | String |  |
| `d_corp_name_defined` | String |  |
| `d_corp_joinid` | String |  |
| `d_production_type` | String |  |
| `d_class_code1` | String |  |
| `d_class_name1` | String |  |
| `d_class_code2` | String |  |
| `d_class_name2` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_formula_code` | String |  |
| `d_formula_name` | String |  |
| `d_formula_measure` | String |  |
| `d_formula_type` | String |  |
| `d_row_id` | String |  |
| `d_row_code` | String |  |
| `d_row_name` | String |  |
| `d_row_measure` | String |  |
| `d_row_type` | String |  |
| `f_ratio_num` | Decimal(18, 6) |  |
| `formula_date` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `updt` | Date |  |

### dim_formula_product_dictpack
**层级**: DIM | **工作流**: - | **字段数**: 35
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_formula_id` | String |  |
| `bom_uid` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_corp_id_defined` | String |  |
| `d_corp_code_defined` | String |  |
| `d_corp_name_defined` | String |  |
| `d_corp_joinid` | String |  |
| `d_production_type` | String |  |
| `d_class_code1` | String |  |
| `d_class_name1` | String |  |
| `d_class_code2` | String |  |
| `d_class_name2` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_formula_code` | String |  |
| `d_formula_name` | String |  |
| `d_formula_measure` | String |  |
| `d_formula_type` | String |  |
| `d_row_id` | String |  |
| `d_row_code` | String |  |
| `d_row_name` | String |  |
| `d_row_measure` | String |  |
| `d_row_type` | String |  |
| `f_ratio_num` | Decimal(18, 6) |  |
| `formula_date` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `updt` | Date |  |

### dim_formula_product_snap
**层级**: DIM | **工作流**: 1-2job-dim_formula_product_snap_1w | **字段数**: 46
**上游表**: bd_bom, bd_bom_b, bd_branddoc, bd_marbasclass, bd_material, bd_measdoc, material, org_orgs_v, sm_user
**底层数据源(Oracle)**: bd_bom, bd_bom_b, bd_marbasclass, bd_material, bd_measdoc, material, org_orgs_v, sm_user

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `bom_uid` | FixedString(20) | bom维护唯一主键 |
| `bom_version` | String | bom版本号(默认使用最高版本) |
| `bom_status` | String | bom审批自由状态 |
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_class_code1` | FixedString(1) | 物料分类编码(1位) |
| `d_class_name1` | String | 物料分类编码(1位)名 |
| `d_class_code2` | FixedString(2) | 物料分类编码(2位) |
| `d_class_name2` | String | 物料分类编码(2位)名 |
| `d_class_code4` | FixedString(4) | 物料分类编码(4位) |
| `d_class_name4` | String | 物料分类编码(4位)名 |
| `d_class_code6` | FixedString(6) | 物料分类编码(6位) |
| `d_class_name6` | String | 物料分类编码(6位)名 |
| `d_formula_id` | FixedString(20) | 配方主键 |
| `d_formula_code` | FixedString(10) | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `d_formula_measure` | String | 配方计量单位 |
| `d_formula_type` | String | 配方型号 |
| `d_row_code1` | FixedString(1) | 原料分类编码(1位) |
| `d_row_name1` | String | 原料分类编码(1位)名 |
| `d_row_id` | FixedString(20) | 原料主键 |
| `d_row_code` | FixedString(10) | 原料编码 |
| `d_row_name` | String | 原料名称 |
| `d_row_measure` | String |  |
| `d_row_type` | String |  |
| `f_ratio_num` | Decimal(18, 6) materialized multiIf((d_row_code1 = '2') AND (f_ratio_num_old < 1),
                                                           f_ratio_num_old * 1000,
                                                           f_ratio_num_old) | 配方比例：全部校正为千克 |
| `f_ratio_num_old` | Decimal(18, 6) | 配方比例：原始数据 |
| `rn` | Nullable(Int8) | rn=1筛选配方 |
| `rn2` | Nullable(Int8) | rn2=1筛选成品对应配方编码，过滤袋子 |
| `formula_date` | FixedString(19) | 配方制单日期 |
| `start_date` | FixedString(19) | 生效日期 |
| `end_date` | FixedString(19) | 失效日期 |
| `creationtime` | FixedString(19) | 创建日期 |
| `creator` | String | 创建人 |
| `modifiedtime` | FixedString(19) | 修改日期 |
| `modifier` | String | 修改人 |
| `updt` | Date | 更新日期：年月分区字段依据 |
| `d_brand_id` | FixedString(20) | 品牌主键 |
| `d_brand_code` | String | 品牌编码 |
| `d_brand_name` | String | 品牌 |
| `vertion_type` | String | 1有效版本，2无效版本 |
| `is_default` | String | Y默认 N  |
| `f_parent_num` | Decimal(18, 6) | 父项主数量 |
| `f_assit_parent_num` | Decimal(18, 6) | 父项辅数量 |

### dim_fx_client
**层级**: DIM | **工作流**: - | **字段数**: 24
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `client_uid` | String | 纷享销客客户档案唯一主键 |
| `d_corp_id` | String | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_area_id` | String | 区域主键 |
| `d_area_code` | String | 区域编码 |
| `d_area_name` | String | 区域名称 |
| `d_client_id` | String | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_client_type_id` | String | 客户分类主键：提档 新开 流失 等 |
| `d_client_type` | String | 客户分类：提档 新开 流失 等 |
| `d_client_level_id` | String | 客户等级主键：S A B C D等 |
| `d_client_level` | String | 客户等级：S A B C D等 |
| `is_strategic` | String | 真实大客户：入池，达标等 |
| `is_strategic_flag` | String | 标记大客户：1标记，0未标记 |
| `f_budget_qty` | Decimal(18, 6) | 预算销量：财务/管理层制定的正式销售目标（通常按年/季） |
| `f_forecast_qty` | Decimal(18, 6) | 预测销量：基于历史趋势、市场动态等生成的销量预估，一般月初填写本月预测 |
| `dr` | String | 0：未删除，1：删除 |
| `ts` | DateTime | NC 系统最后同步时间戳（用于增量捕获） |
| `year` | UInt16           default toYear(now()) | 年分区字段：默认为当前年，但允许覆盖 |
| `insert_ts` | DateTime         default now() | 自动生成写入时间 |
| `is_achieve` | Nullable(String) default '未达标' | 是否达标：达标 未达标 |

### dim_fx_organization
**层级**: DIM | **工作流**: - | **字段数**: 13
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `organization_uid` | String | OA组织架构唯一主键 |
| `d_parent_id` | String | 父级OAid |
| `d_desc_name` | String | 简称 |
| `d_name` | String | 名称 |
| `d_nc_id` | String | 组织NCid |
| `d_org_type` | String | 组织类型  1公司 2区域（聚焦镇） 3部门 |
| `d_crm_corpid` | String | crm公司id |
| `d_crm_deptid` | String | crm部门ID |
| `d_crmid` | String | 组织crmid |
| `dr` | String | 0：未删除，1：删除 |
| `ts` | DateTime | NC 系统最后同步时间戳（用于增量捕获） |
| `insert_ts` | DateTime default now() | 自动生成写入时间 |
| `d_code` | String | 编码 |

### dim_fx_organization_dict
**层级**: DIM | **工作流**: - | **字段数**: 13
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_nc_id` | String |  |
| `organization_uid` | String |  |
| `d_parent_id` | String |  |
| `d_desc_name` | String |  |
| `d_name` | String |  |
| `d_org_type` | String |  |
| `d_crm_corpid` | String |  |
| `d_crm_deptid` | String |  |
| `d_crmid` | String |  |
| `dr` | String |  |
| `ts` | DateTime |  |
| `insert_ts` | DateTime |  |
| `d_code` | String |  |

### dim_fx_organization_dict_parent
**层级**: DIM | **工作流**: - | **字段数**: 13
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `organization_uid` | String |  |
| `d_parent_id` | String |  |
| `d_desc_name` | String |  |
| `d_name` | String |  |
| `d_nc_id` | String |  |
| `d_org_type` | String |  |
| `d_crm_corpid` | String |  |
| `d_crm_deptid` | String |  |
| `d_crmid` | String |  |
| `dr` | String |  |
| `ts` | DateTime |  |
| `insert_ts` | DateTime |  |
| `d_code` | String |  |

### dim_ia_material_snap
**层级**: DIM | **工作流**: - | **字段数**: 26
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司主键（org_costregion.pk_org → org_financeorg） |
| `d_corp_code` | String | 公司编码（来自 dim_unit_dict 字典） |
| `d_corp_name` | String | 公司全称（来自 dim_unit_dict 字典） |
| `d_corp_sname` | String | 公司简称（来自 dim_unit_dict 字典） |
| `d_corp_busi_status` | FixedString(1) | 公司经营状态：Y/N（来自 dim_unit_dict 字典） |
| `d_region_name` | String | 大区名称（来自 dim_unit_dict 字典） |
| `d_material_id` | FixedString(20) | 物料主键（cinventoryid） |
| `d_material_code` | String | 物料编码（来自 dim_material_dict 字典） |
| `d_material_name` | String | 物料名称（来自 dim_material_dict 字典） |
| `d_class_code1` | String | 一级业务分类编码（原料/添加剂/包装物等，来自 dim_material_dict） |
| `d_class_name1` | String | 一级业务分类名称（原料/添加剂/包装物等，来自 dim_material_dict） |
| `d_class_code2` | String | 二级业务分类编码（来自 dim_material_dict） |
| `d_class_name2` | String | 二级业务分类名称（来自 dim_material_dict） |
| `d_class_code4` | String | 四级业务分类编码（来自 dim_material_dict） |
| `d_class_name4` | String | 四级业务分类名称（来自 dim_material_dict） |
| `d_class_code6` | String | 六级业务分类编码（来自 dim_material_dict） |
| `d_class_name6` | String | 六级业务分类名称（来自 dim_material_dict） |
| `measdoc_name` | String | 主计量单位名称（来自 dim_material_dict） |
| `f_opening_price` | Decimal(18, 6) '期初'' 的 f_price 平均值）' | 期初单价（仅 d_tag= |
| `f_stock_price` | Decimal(18, 6) | 实时库存单价（= f_stock_amt / f_po_stock_qty，分母为有价数量） |
| `f_stock_amt` | Decimal(18, 6) | 库存总金额（sum(f_amt_original)） |
| `f_stock_qty` | Decimal(18, 6) | 实时结存数量（sum(f_qty)，含正负变动） |
| `f_po_stock_qty` | Decimal(18, 6) | 有采购价格支撑的库存数量（排除 f_price_original=0 的行） |
| `stock_ts` | DateTime | 最新库存流水时间戳（max(bill_ts)） |
| `stock_dt` | Date | 最新库存流水日期（max(bill_dt)） |
| `biz_dt` | Date | 业务日期分区字段，格式 YYYY-MM-DD（对应 ETL 调度日） |

### dim_material
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 52
**上游表**: bd_branddoc, bd_defdoc, bd_marbasclass, bd_material, bd_materialconvert, bd_mattaxes, bd_measdoc, bd_prodline, org_orgs, so_saleorder_b 等12张
**底层数据源(Oracle)**: bd_defdoc, bd_marbasclass, bd_material, bd_mattaxes, bd_measdoc, bd_prodline, org_orgs, so_saleorder_b 等9张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_id` | FixedString(20) | 物料主键 |
| `d_material_vid` | FixedString(20) | 物料版本主键 |
| `material_version` | String | 物料版本 |
| `assign_status` | Int32 | 物料分配状态编码 |
| `assign_status_name` | String | 物料分配状态 |
| `d_corp_id` | FixedString(20) | 物料所属公司主键 |
| `d_corp_code` | String | 物料所属公司编码 |
| `d_corp_name` | String | 物料所属公司名称 |
| `d_material_code` | FixedString(10) | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_material_sname` | String | 物料简称 |
| `d_material_block` | String | 物料板块 |
| `d_class_code1` | FixedString(1) |  |
| `d_class_name1` | String |  |
| `d_class_code2` | FixedString(5) |  |
| `d_class_name2` | String |  |
| `d_class_code4` | FixedString(4) |  |
| `d_class_name4` | String |  |
| `d_class_code6` | FixedString(6) |  |
| `d_class_name6` | String |  |
| `d_prodline_id` | FixedString(20) |  |
| `d_prodline_code` | String |  |
| `d_prodline_name` | String | 产线 |
| `class_id` | FixedString(20) |  |
| `measure_id` | FixedString(20) | 计量单位主键 |
| `measure_name` | String | 计量单位名称 |
| `second_measure_id` | FixedString(20) | 第二计量单位主键 |
| `second_measure_name` | String | 第二计量单位名称 |
| `measure_conversion` | String | 换算率 |
| `measure_ratio` | Decimal(18, 6) | 主/辅 比率 |
| `brand_id` | FixedString(20) |  |
| `brand_name` | String | 品牌名称 |
| `material_spec` | String | 规格 |
| `material_type` | String | 物料类型 |
| `strategy_id` | FixedString(20) | 战略产品主键 |
| `strategy_name` | String | 战略产品名称 |
| `strategy_prename` | String | 战略产品 |
| `salton_factor` | Decimal(18, 2) | 销售吨系数 |
| `proton_factor` | Decimal(18, 2) | 生产吨系数 |
| `breedton_factor` | Decimal(18, 2) | 品种生产吨系数 |
| `materialtax_id` | FixedString(20) | 物料税类主键 |
| `materialtax_code` | String | 物料税类编码 |
| `materialtax_name` | String | 物料税类名称 |
| `materialtax_rate` | Decimal(18, 2) | 物料税类比率 |
| `particle_size` | String | 粒径 |
| `material_attribute` | String | 物料属性 |
| `product_tag` | String | 产品标签 |
| `f_sale_amount` | Decimal(18, 2) | 累计销售额(近一年) |
| `creationtime` | String |  |
| `modifiedtime` | String |  |
| `updt` | DateTime |  |
| `product_tag_code` | String | 产品标签编码 |

### dim_material_dict
**层级**: DIM | **工作流**: - | **字段数**: 49
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_id` | String |  |
| `assign_status` | Int32 |  |
| `assign_status_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `d_material_sname` | String |  |
| `d_material_block` | String |  |
| `d_class_code1` | String |  |
| `d_class_name1` | String |  |
| `d_class_code2` | String |  |
| `d_class_name2` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_prodline_id` | String |  |
| `d_prodline_code` | String |  |
| `d_prodline_name` | String |  |
| `class_id` | String |  |
| `measure_id` | String |  |
| `measure_name` | String |  |
| `second_measure_id` | String |  |
| `second_measure_name` | String |  |
| `measure_conversion` | String |  |
| `measure_ratio` | Decimal(18, 6) |  |
| `brand_id` | String |  |
| `brand_name` | String |  |
| `material_spec` | String |  |
| `material_type` | String |  |
| `strategy_id` | String |  |
| `strategy_name` | String |  |
| `strategy_prename` | String |  |
| `salton_factor` | Decimal(18, 2) |  |
| `proton_factor` | Decimal(18, 2) |  |
| `breedton_factor` | Decimal(18, 2) |  |
| `materialtax_id` | String |  |
| `materialtax_code` | String |  |
| `materialtax_name` | String |  |
| `materialtax_rate` | Decimal(18, 2) |  |
| `particle_size` | String |  |
| `material_attribute` | String |  |
| `product_tag_code` | String |  |
| `product_tag` | String |  |
| `f_sale_amount` | Decimal(18, 2) |  |
| `creationtime` | String |  |
| `modifiedtime` | String |  |

### dim_material_dict2
**层级**: DIM | **工作流**: - | **字段数**: 49
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_code` | String |  |
| `d_material_id` | String |  |
| `assign_status` | Int32 |  |
| `assign_status_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_material_name` | String |  |
| `d_material_sname` | String |  |
| `d_material_block` | String |  |
| `d_class_code1` | String |  |
| `d_class_name1` | String |  |
| `d_class_code2` | String |  |
| `d_class_name2` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_prodline_id` | String |  |
| `d_prodline_code` | String |  |
| `d_prodline_name` | String |  |
| `class_id` | String |  |
| `measure_id` | String |  |
| `measure_name` | String |  |
| `second_measure_id` | String |  |
| `second_measure_name` | String |  |
| `measure_conversion` | String |  |
| `measure_ratio` | Decimal(18, 6) |  |
| `brand_id` | String |  |
| `brand_name` | String |  |
| `material_spec` | String |  |
| `material_type` | String |  |
| `strategy_id` | String |  |
| `strategy_name` | String |  |
| `strategy_prename` | String |  |
| `salton_factor` | Decimal(18, 2) |  |
| `proton_factor` | Decimal(18, 2) |  |
| `breedton_factor` | Decimal(18, 2) |  |
| `materialtax_id` | String |  |
| `materialtax_code` | String |  |
| `materialtax_name` | String |  |
| `materialtax_rate` | Decimal(18, 2) |  |
| `particle_size` | String |  |
| `material_attribute` | String |  |
| `product_tag_code` | String |  |
| `product_tag` | String |  |
| `f_sale_amount` | Decimal(18, 2) |  |
| `creationtime` | String |  |
| `modifiedtime` | String |  |

### dim_material_rd45
**层级**: DIM | **工作流**: 2job-nc_stock_1h | **字段数**: 22
**上游表**: dwd_ic_flow_rd45
**CK内部依赖**: dwd_ic_flow_rd45

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `material_rd45_uid` | FixedString(60) |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_material_id` | FixedString(20) |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `measdoc_id` | FixedString(20) |  |
| `measdoc_name` | String |  |
| `second_measdoc_id` | FixedString(20) |  |
| `second_measdoc_name` | String |  |
| `d_mat_attr8_id` | FixedString(20) |  |
| `d_mat_attr8_code` | String |  |
| `d_mat_attr8_name` | String |  |
| `f_stock` | Decimal(18, 6) |  |
| `f_amt` | Decimal(18, 6) |  |
| `f_price` | Decimal(18, 6) |  |
| `f_inbound_qty` | Decimal(18, 6) |  |
| `f_outbound_qty` | Decimal(18, 6) |  |
| `ts` | DateTime |  |
| `latest_buzi_ts` | DateTime |  |

### dim_material_uat
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 50
**上游表**: bd_branddoc, bd_defdoc, bd_marbasclass, bd_material, bd_materialconvert, bd_mattaxes, bd_measdoc, bd_prodline, org_orgs, so_saleorder_b 等12张
**底层数据源(Oracle)**: bd_defdoc, bd_marbasclass, bd_material, bd_mattaxes, bd_measdoc, bd_prodline, org_orgs, so_saleorder_b 等9张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_id` | FixedString(20) | 物料主键 |
| `d_material_vid` | FixedString(20) | 物料版本主键 |
| `material_version` | String | 物料版本 |
| `assign_status` | Int32 | 物料分配状态编码 |
| `assign_status_name` | String | 物料分配状态 |
| `d_corp_id` | FixedString(20) | 物料所属公司主键 |
| `d_corp_code` | String | 物料所属公司编码 |
| `d_corp_name` | String | 物料所属公司名称 |
| `d_material_code` | FixedString(10) | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_material_sname` | String | 物料简称 |
| `d_material_block` | String | 物料板块 |
| `d_class_code1` | FixedString(1) |  |
| `d_class_name1` | String |  |
| `d_class_code2` | FixedString(5) |  |
| `d_class_name2` | String |  |
| `d_class_code4` | FixedString(4) |  |
| `d_class_name4` | String |  |
| `d_class_code6` | FixedString(6) |  |
| `d_class_name6` | String |  |
| `d_prodline_id` | FixedString(20) |  |
| `d_prodline_code` | String |  |
| `d_prodline_name` | String | 产线 |
| `class_id` | FixedString(20) |  |
| `measure_id` | FixedString(20) | 计量单位主键 |
| `measure_name` | String | 计量单位名称 |
| `second_measure_id` | FixedString(20) | 第二计量单位主键 |
| `second_measure_name` | String | 第二计量单位名称 |
| `measure_conversion` | String | 换算率 |
| `brand_id` | FixedString(20) |  |
| `brand_name` | String | 品牌名称 |
| `material_spec` | String | 规格 |
| `material_type` | String | 物料类型 |
| `strategy_id` | FixedString(20) | 战略产品主键 |
| `strategy_name` | String | 战略产品名称 |
| `strategy_prename` | String | 战略产品 |
| `salton_factor` | Decimal(18, 2) | 销售吨系数 |
| `proton_factor` | Decimal(18, 2) | 生产吨系数 |
| `breedton_factor` | Decimal(18, 2) | 品种生产吨系数 |
| `materialtax_id` | FixedString(20) | 物料税类主键 |
| `materialtax_code` | String | 物料税类编码 |
| `materialtax_name` | String | 物料税类名称 |
| `materialtax_rate` | Decimal(18, 2) | 物料税类比率 |
| `particle_size` | String | 粒径 |
| `material_attribute` | String | 物料属性 |
| `product_tag` | String | 产品标签 |
| `f_sale_amount` | Decimal(18, 2) | 累计销售额(近一年) |
| `creationtime` | String |  |
| `modifiedtime` | String |  |
| `updt` | DateTime |  |

### dim_material_uat_dict
**层级**: DIM | **工作流**: - | **字段数**: 47
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_id` | String |  |
| `assign_status` | Int32 |  |
| `assign_status_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `d_material_sname` | String |  |
| `d_material_block` | String |  |
| `d_class_code1` | String |  |
| `d_class_name1` | String |  |
| `d_class_code2` | String |  |
| `d_class_name2` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_prodline_id` | String |  |
| `d_prodline_code` | String |  |
| `d_prodline_name` | String |  |
| `class_id` | String |  |
| `measure_id` | String |  |
| `measure_name` | String |  |
| `second_measure_id` | String |  |
| `second_measure_name` | String |  |
| `measure_conversion` | String |  |
| `brand_id` | String |  |
| `brand_name` | String |  |
| `material_spec` | String |  |
| `material_type` | String |  |
| `strategy_id` | String |  |
| `strategy_name` | String |  |
| `strategy_prename` | String |  |
| `salton_factor` | Decimal(18, 2) |  |
| `proton_factor` | Decimal(18, 2) |  |
| `breedton_factor` | Decimal(18, 2) |  |
| `materialtax_id` | String |  |
| `materialtax_code` | String |  |
| `materialtax_name` | String |  |
| `materialtax_rate` | Decimal(18, 2) |  |
| `particle_size` | String |  |
| `material_attribute` | String |  |
| `product_tag` | String |  |
| `f_sale_amount` | Decimal(18, 2) |  |
| `creationtime` | String |  |
| `modifiedtime` | String |  |

### dim_row_product_snap
**层级**: DIM | **工作流**: 1-2job-dim_formula_product_snap_1w | **字段数**: 55
**上游表**: dim_formula_product_snap, dim_material
**CK内部依赖**: dim_formula_product_snap, dim_material

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `bom_uid` | FixedString(20) | bom维护唯一主键 |
| `bom_version` | String | bom版本号(默认使用最高版本) |
| `bom_status` | String | bom审批自由状态 |
| `d_corp_id` | FixedString(20) | 配方所属公司主键 |
| `d_corp_code` | String | 配方所属公司编码 |
| `d_corp_name` | String | 配方所属公司名称 |
| `d_corp_sname` | String | 配方所属公司简称 |
| `d_corp_id_defined` | FixedString(20) | 产品所属公司主键 |
| `d_corp_code_defined` | String | 产品所属公司编码 |
| `d_corp_name_defined` | String | 产品所属公司名称 |
| `d_corp_joinid` | String | 代工时公司为配方所属公司主键否则为空-关联用 |
| `d_production_type` | String | 生产方式：自产or代工 |
| `d_class_code1` | FixedString(1) | 物料分类编码(1位) |
| `d_class_name1` | String | 物料分类编码(1位)名 |
| `d_class_code2` | FixedString(2) | 物料分类编码(2位) |
| `d_class_name2` | String | 物料分类编码(2位)名 |
| `d_class_code4` | FixedString(4) | 物料分类编码(4位) |
| `d_class_name4` | String | 物料分类编码(4位)名 |
| `d_class_code6` | FixedString(6) | 物料分类编码(6位) |
| `d_class_name6` | String | 物料分类编码(6位)名 |
| `d_product_id` | FixedString(20) | 成品主键 |
| `d_product_code` | FixedString(10) | 成品编码 |
| `d_product_name` | String | 成品名称 |
| `d_product_measure` | String | 成品计量单位 |
| `d_product_type` | String | 成品型号 |
| `d_formula_code1` | FixedString(1) | 配方分类编码(1位) |
| `d_formula_name1` | String | 配方分类编码(1位)名 |
| `d_formula_id` | FixedString(20) | 配方主键 |
| `d_formula_code` | FixedString(10) | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `d_formula_measure` | String | 配方计量单位 |
| `d_formula_type` | String | 配方型号 |
| `d_father_row_code1` | FixedString(1) | 添加剂或原料分类编码(1位) |
| `d_father_row_name1` | String | 添加剂或原料分类编码(1位)名 |
| `d_father_row_id` | FixedString(20) | 添加剂或原料主键 |
| `d_father_row_code` | FixedString(10) | 添加剂或原料编码 |
| `d_father_row_name` | String | 添加剂或原料名称 |
| `d_father_row_measure` | String | 添加剂或原料计量单位 |
| `d_father_row_type` | String | 添加剂或原料型号 |
| `d_row_id` | FixedString(20) | 原料主键 |
| `d_row_code` | FixedString(10) | 原料编码 |
| `d_row_name` | String | 原料名称 |
| `d_row_measure` | String | 原料计量单位 |
| `d_row_type` | String | 原料型号 |
| `f_product_ratio_num` | Decimal(16, 5) | 成品配方比例 |
| `f_father_row_ratio_num` | Decimal(16, 5) | 添加剂配方比例 |
| `f_row_ratio_num` | Decimal(16, 5) | 原料配方比例 |
| `formula_date` | FixedString(19) | 配方制单日期 |
| `start_date` | FixedString(19) | 生效日期 |
| `end_date` | FixedString(19) | 失效日期 |
| `creationtime` | FixedString(19) | 创建日期 |
| `creator` | String | 创建人 |
| `modifiedtime` | FixedString(19) | 修改日期 |
| `modifier` | String | 修改人 |
| `updt` | Date | 更新日期：年月分区字段依据 |

### dim_stordoc
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 39
**上游表**: bd_stordoc
**底层数据源(Oracle)**: bd_stordoc

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `code` | String 'WH001''）' | 仓库编码（如  |
| `creationtime` | String | 创建时间（NC原始字符串） |
| `creator` | FixedString(20) | 创建人主键 |
| `csflag` | String | CS标志（NC内部业务标识） |
| `dataoriginflag` | String | 数据来源：0=手工，1=系统，2=接口 |
| `enablestate` | String | 启用状态：2=启用，3=停用 |
| `gubflag` | String | GUB标志（集团统一业务标识） |
| `isagentstore` | String 'Y''/''N''' | 是否代销仓： |
| `isatpaffected` | String 'Y''/''N''' | 是否参与ATP计算： |
| `iscalculatedinvcost` | String 'Y''/''N''' | 是否计算库存成本： |
| `iscommissionout` | String 'Y''/''N''' | 是否委外仓： |
| `isdirectstore` | String 'Y''/''N''' | 是否直发仓： |
| `isobligate` | String 'Y''/''N''' | 是否必选仓库： |
| `isretail` | String 'Y''/''N''' | 是否零售仓： |
| `isshopstore` | String 'Y''/''N''' | 是否门店仓： |
| `isstoreontheway` | String 'Y''/''N''' | 是否在途仓： |
| `memo` | String | 备注 |
| `modifiedtime` | String | 最后修改时间（NC原始字符串） |
| `modifier` | String | 修改人主键 |
| `mrpflag` | String | MRP标志（是否参与MRP运算） |
| `name` | String | 仓库名称（主语言） |
| `name2` | String | 仓库名称（第二语言） |
| `name3` | String | 仓库名称（第三语言，如本地化名称） |
| `operatesupplier` | String | 运营供应商编码或主键 |
| `phone` | String | 联系电话 |
| `pk_address` | FixedString(20) | 地址主键（关联地址档案） |
| `pk_group` | FixedString(20) | 集团主键 |
| `pk_org` | FixedString(20) | 组织主键 |
| `pk_stordoc` | FixedString(20) | 仓库档案主键（唯一标识） |
| `principalcode` | String | 负责人编码 |
| `proflag` | String | 项目标志（是否项目仓） |
| `storaddr` | String | 仓库地址（文本描述） |
| `iskptaxstore` | String 'Y''/''N''' | 是否开票税务仓： |
| `profitcentre` | String | 利润中心编码 |
| `def1` | LowCardinality(String) | 自定义字段1（如区域、温区等） |
| `def2` | LowCardinality(String) | 自定义字段2 |
| `dr` | String '0''=有效，''1''=删除' | 逻辑删除标记： |
| `ts_char` | String | NC 时间戳（字符串格式，用于增量捕获或全量比对） |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) '2025-01-01''）' | ts_char 的物化 DateTime 列，用于 WHERE 条件加速（如 ts_dt >=  |

### dim_stordoc_dict
**层级**: DIM | **工作流**: - | **字段数**: 39
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `pk_stordoc` | String |  |
| `code` | String |  |
| `creationtime` | String |  |
| `creator` | String |  |
| `csflag` | String |  |
| `dataoriginflag` | String |  |
| `enablestate` | String |  |
| `gubflag` | String |  |
| `isagentstore` | String |  |
| `isatpaffected` | String |  |
| `iscalculatedinvcost` | String |  |
| `iscommissionout` | String |  |
| `isdirectstore` | String |  |
| `isobligate` | String |  |
| `isretail` | String |  |
| `isshopstore` | String |  |
| `isstoreontheway` | String |  |
| `memo` | String |  |
| `modifiedtime` | String |  |
| `modifier` | String |  |
| `mrpflag` | String |  |
| `name` | String |  |
| `name2` | String |  |
| `name3` | String |  |
| `operatesupplier` | String |  |
| `phone` | String |  |
| `pk_address` | String |  |
| `pk_group` | String |  |
| `pk_org` | String |  |
| `principalcode` | String |  |
| `proflag` | String |  |
| `storaddr` | String |  |
| `iskptaxstore` | String |  |
| `profitcentre` | String |  |
| `def1` | String |  |
| `def2` | String |  |
| `dr` | String |  |
| `ts_char` | String |  |
| `ts` | DateTime |  |

### dim_supplier
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 24
**上游表**: bd_address, bd_areacl, bd_countryzone, bd_defdoc, bd_region, bd_supplier, bd_supplierclass, sm_user
**底层数据源(Oracle)**: bd_address, bd_areacl, bd_countryzone, bd_defdoc, bd_region, bd_supplier, bd_supplierclass, sm_user

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_supplier_id` | FixedString(20) | 供应商主键（来自 bd_supplier.pk_supplier） |
| `d_supplier_code` | String | 供应商编码（来自 bd_supplier.code） |
| `d_supplier_name` | String | 供应商名称（来自 bd_supplier.name） |
| `d_supplier_class_id` | FixedString(20) | 供应商分类主键（来自 bd_supplierclass.pk_supplierclass） |
| `d_supplier_class_code` | String | 供应商分类编码（来自 bd_supplierclass.code） |
| `d_supplier_class_name` | String | 供应商分类名称（来自 bd_supplierclass.name） |
| `taxpayer_id` | String | 统一社会信用代码（来自 bd_supplier.taxpayerid） |
| `mobile` | String | 供应商手机号（来自 bd_supplier.tel1） |
| `fax` | String | 传真（来自 bd_supplier.fax1） |
| `country_name` | String | 国家名称（来自 bd_countryzone.name） |
| `province_name` | String | 省份名称（来自 bd_region.name，关联 province） |
| `city_name` | String | 城市名称（来自 bd_region.name，关联 city） |
| `district_name` | String | 县区名称（来自 bd_region.name，关联 vsection） |
| `address_detail` | String | 详细地址（来自 bd_address.detailinfo） |
| `areacl_name` | String | 地区分类名称（来自 bd_areacl.name） |
| `creator_name` | String | 创建人姓名（来自 sm_user.user_name，关联 creator） |
| `creation_ts` | DateTime | 创建时间（来自 bd_supplier.creationtime） |
| `modifier_name` | String | 最后修改人姓名（来自 sm_user.user_name，关联 modifier） |
| `modified_ts` | DateTime | 最后修改时间（来自 bd_supplier.modifiedtime） |
| `enable_state` | String comment '启用状态（1:未启用 |  |
| `2:已启用` |  |  |
| `3:已停用` |  |  |
| `其他:状态异常）'` |  |  |
| `d_supplier_attr` | String '1001A210000000AJB6FH''）' | 供应商属性（自定义档案值，如原料/添加剂/五金等；来源 BD_DEFDOC.NAME，限定 PK_DEFDOCLIST= |

### dim_supplier_dict
**层级**: DIM | **工作流**: - | **字段数**: 21
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_supplier_id` | String |  |
| `d_supplier_code` | String |  |
| `d_supplier_name` | String |  |
| `d_supplier_class_id` | String |  |
| `d_supplier_class_code` | String |  |
| `d_supplier_class_name` | String |  |
| `taxpayer_id` | String |  |
| `mobile` | String |  |
| `fax` | String |  |
| `country_name` | String |  |
| `province_name` | String |  |
| `city_name` | String |  |
| `district_name` | String |  |
| `address_detail` | String |  |
| `areacl_name` | String |  |
| `creator_name` | String |  |
| `creation_ts` | DateTime |  |
| `modifier_name` | String |  |
| `modified_ts` | DateTime |  |
| `enable_state` | String |  |
| `d_supplier_attr` | String |  |

### dim_supplier_dict2
**层级**: DIM | **工作流**: - | **字段数**: 21
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_supplier_code` | String |  |
| `d_supplier_id` | String |  |
| `d_supplier_name` | String |  |
| `d_supplier_class_id` | String |  |
| `d_supplier_class_code` | String |  |
| `d_supplier_class_name` | String |  |
| `taxpayer_id` | String |  |
| `mobile` | String |  |
| `fax` | String |  |
| `country_name` | String |  |
| `province_name` | String |  |
| `city_name` | String |  |
| `district_name` | String |  |
| `address_detail` | String |  |
| `areacl_name` | String |  |
| `creator_name` | String |  |
| `creation_ts` | DateTime |  |
| `modifier_name` | String |  |
| `modified_ts` | DateTime |  |
| `enable_state` | String |  |
| `d_supplier_attr` | String |  |

### dim_unit
**层级**: DIM | **工作流**: 0dim-table_1h | **字段数**: 28
**上游表**: dim_unit
**CK内部依赖**: dim_unit

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_org_type` | LowCardinality(String) |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_corp_busi_status` | String |  |
| `d_unit_id` | FixedString(20) |  |
| `d_unit_code` | String |  |
| `d_unit_name` | String |  |
| `d_unit_sname` | String |  |
| `d_unit_lname` | String |  |
| `d_unit_type` | String |  |
| `d_unit_busi_status` | String |  |
| `d_unit_sale_id` | FixedString(20) |  |
| `d_unit_sale_code` | String |  |
| `d_unit_sale_name` | String |  |
| `d_unit_sale_busi_status` | String |  |
| `d_unit_sale_lname` | String |  |
| `d_dept_id` | FixedString(20) |  |
| `d_dept_name` | String |  |
| `d_dept_code` | String |  |
| `d_dept_status` | String |  |
| `d_town_id` | FixedString(20) |  |
| `d_town_name` | String |  |
| `d_town_status` | String |  |
| `updt` | DateTime |  |

### dim_unit_dict
**层级**: DIM | **工作流**: - | **字段数**: 9
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | String |  |
| `d_org_type` | String |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_corp_busi_status` | String |  |
| `updt` | DateTime |  |

### dim_unit_dict2
**层级**: DIM | **工作流**: - | **字段数**: 9
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_code` | String |  |
| `d_org_type` | String |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_corp_busi_status` | String |  |
| `updt` | DateTime |  |

### v_dim_client
**层级**: DIM | **工作流**: - | **字段数**: 24
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `client_uid` | String |  |
| `d_region_id` | String |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_area_id` | String |  |
| `d_area_name` | String |  |
| `d_client_id` | String |  |
| `d_client_code` | String |  |
| `d_client_name` | String |  |
| `d_client_type` | String |  |
| `d_client_level` | String |  |
| `is_strategic` | String |  |
| `is_strategic_flag` | String |  |
| `is_achieve` | Nullable(String) |  |
| `f_budget_qty` | Decimal(18, 6) |  |
| `f_forecast_qty` | Decimal(18, 6) |  |
| `dr` | String |  |
| `ts` | DateTime |  |
| `this_year` | UInt16 |  |
| `insert_ts` | DateTime |  |

---

## DWD层（明细层）- 34张表

### dwd_cust_rebate_actual_m
**层级**: DWD | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 42
**上游表**: bd_billtype, bd_customer, bd_custsale, bd_defdoc, bd_material, org_dept, org_financeorg, so_arsub, so_arsub_b, sr_settle 等11张
**底层数据源(Oracle)**: bd_billtype, bd_customer, bd_custsale, bd_defdoc, bd_material, org_dept, org_financeorg, so_arsub 等11张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `prm_uid` | String | 唯一主键 (carsubid) |
| `d_corp_id` | FixedString(20) | 财务组织ID |
| `d_corp_code` | String | 财务组织编码 |
| `d_corp_name` | String | 财务组织名称 |
| `d_corp_sname` | String | 财务组织简称 |
| `d_profit_corp_id` | String |  |
| `d_profit_corp_code` | String |  |
| `d_profit_corp_sname` | String |  |
| `d_profit_region_name` | String         default dictGet('alphafeed.dim_unit_dict', 'd_region_name', d_profit_corp_id) | 业绩归属大区名称 |
| `d_billtype_code` | String | 单据类型编码 |
| `d_billtype_name` | String | 单据类型名称 |
| `d_client_id` | FixedString(20) | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_unit_id` | FixedString(20) | 核算单位ID |
| `d_unit_code` | String | 核算单位编码 |
| `d_unit_name` | String | 核算单位名称 |
| `d_dept_id` | FixedString(20) | 部门ID |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_material_id` | FixedString(20) | 物料ID |
| `d_material_code` | String | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `f_rebate_amt` | Decimal(18, 6) default 0. | 返利金额（实际值，元） |
| `f_payout_amt` | Decimal(18, 6) default 0. | 兑付金额（实际值，元） |
| `f_rebate_price` | Decimal(18, 6) default 0. | 返利单价（理论值，元） |
| `f_rebate_qty` | Decimal(18, 6) default 0. | 返利数量（理论值，吨） |
| `f_rebate_settle_amt` | Decimal(18, 6) default 0. | 结算单返利金额（理论值，元） |
| `line_number` | Int32 | 行号 |
| `note` | String | 备注 |
| `prm_billcode` | String | 销售费用单单据号 |
| `settle_billcode` | String | 返利结算单单据号 |
| `audit_mth` | String | 审核月份 (YYYY-MM) |
| `biz_mth` | String | 业务月份 (YYYY-MM) |
| `dw_load_dt` | DateTime       default now() | 数据加载时间 |
| `f_rebate1_amt` | Decimal(18, 6) default 0. | 返利金额（实际值，元 预收款为返利总金额） |
| `f_rebate1_qty` | Decimal(18, 6) default 0. | 返利数量（理论值，吨 预收款为返款比例） |
| `biz_dt` | String | 单据日期 |
| `audit_dt` | String | 审核日期 |
| `close_dt` | String | 兑付关闭日期 |
| `close_mth` | String | 兑付关闭月份 |
| `is_reversal` | String materialized if((close_mth != '') AND ((f_rebate_amt - f_payout_amt) != 0), 'Y', 'N') |  |

### dwd_fact_product_inbound_snap
**层级**: DWD | **工作流**: 1job-nc_sal_profit | **字段数**: 23
**上游表**: dim_material, dim_unit, kc_ccprk1
**CK内部依赖**: dim_material, dim_unit

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_id` | FixedString(20) | 产品主键（来自 DIM_MATERIAL.material_pk） |
| `d_material_uid` | String | 产品-公司级唯一ID：自产=material_pk，代工=material_pk\|\|corp_pk |
| `d_material_code` | FixedString(10) | 物料编码（wlbm） |
| `d_material_name` | String | 物料名称 |
| `d_material_type` | String | 物料类型 |
| `d_class_code1` | FixedString(1) | 物料分类编码(1位) |
| `d_class_name1` | String | 物料分类编码(1位)名 |
| `d_class_code2` | FixedString(2) | 物料分类编码(2位) |
| `d_class_name2` | String | 物料分类编码(2位)名 |
| `d_class_code4` | FixedString(4) | 物料分类编码(4位) |
| `d_class_name4` | String | 物料分类编码(4位)名 |
| `d_class_code6` | FixedString(6) | 物料分类编码(6位) |
| `d_class_name6` | String | 物料分类编码(6位)名 |
| `d_corp_id_product` | FixedString(20) | 实际入库公司ID（来自 DIM_UNIT.corp_pk） |
| `d_corp_code_product` | String | 实际入库公司编码（gsbm） |
| `d_corp_name_product` | String | 实际入库公司名称（gsmc） |
| `d_corp_id_defined` | FixedString(20) | 产品定义公司ID（来自 DIM_MATERIAL.corp_pk） |
| `d_corp_code_defined` | String | 产品定义公司编码 |
| `d_corp_name_defined` | String | 产品定义公司名称 |
| `d_corp_joinid` | String | 产品代工公司ID（关联使用） |
| `d_production_type` | String | 生产类型：自产 / 代工 / 未知 |
| `f_inbound_qty` | Decimal(18, 4) | 近12个月累计入库数量 |
| `updt` | DateTime default now() | 快照生成时间，用于按月分区 |

### dwd_fact_product_sale_snap
**层级**: DWD | **工作流**: - | **字段数**: 17
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_material_id` | FixedString(20) | 产品主键（来自 DIM_MATERIAL.material_pk） |
| `d_material_code` | FixedString(10) | 物料编码（wlbm） |
| `d_material_name` | String | 物料名称 |
| `d_class_code1` | FixedString(1) | 物料分类编码(1位) |
| `d_class_name1` | String | 物料分类编码(1位)名 |
| `d_class_code2` | FixedString(2) | 物料分类编码(2位) |
| `d_class_name2` | String | 物料分类编码(2位)名 |
| `d_class_code4` | FixedString(4) | 物料分类编码(4位) |
| `d_class_name4` | String | 物料分类编码(4位)名 |
| `d_class_code6` | FixedString(6) | 物料分类编码(6位) |
| `d_class_name6` | String | 物料分类编码(6位)名 |
| `d_corp_id_sale` | FixedString(20) | 产品销售公司主键 |
| `d_corp_code_sale` | String | 产品销售公司编码 |
| `d_corp_name_sale` | String | 产品销售公司名称 |
| `f_sale_qty` | Decimal(18, 4) | 近12个月累计销售主数量 |
| `f_sale_amt` | Decimal(18, 4) | 近12个月累计销售金额 |
| `updt` | DateTime default now() | 快照生成时间，用于按月分区 |

### dwd_fin_budget_detail
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 40
**上游表**: dwd_fin_budget_detail
**CK内部依赖**: dwd_fin_budget_detail

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_attr` | String | 客户属性 |
| `d_region_name` | String | 大区 |
| `d_corp_sname` | String | 公司简称 |
| `d_town_name` | String | 聚焦镇 |
| `d_town_type` | String | 聚焦镇类型 |
| `d_prodline_name` | String | 产品线 |
| `d_class_name4` | String | 大类 |
| `d_class_name6` | String | 小类 |
| `d_client_name` | String | 客户名称 |
| `vip_client` | String | 大客户 |
| `product_series` | String | 产品系列(不同规格合并) |
| `strategy_name` | String | 战略产品 |
| `group_product_proj` | String | 集团级产品线项目 |
| `core_market` | String | 核心市场 |
| `product_positioning` | String | 产品定位 |
| `f_budget_m01` | Decimal(18, 6) | 1月预算 |
| `f_budget_m02` | Decimal(18, 6) | 2月预算 |
| `f_budget_m03` | Decimal(18, 6) | 3月预算 |
| `f_budget_m04` | Decimal(18, 6) | 4月预算 |
| `f_budget_m05` | Decimal(18, 6) | 5月预算 |
| `f_budget_m06` | Decimal(18, 6) | 6月预算 |
| `f_budget_m07` | Decimal(18, 6) | 7月预算 |
| `f_budget_m08` | Decimal(18, 6) | 8月预算 |
| `f_budget_m09` | Decimal(18, 6) | 9月预算 |
| `f_budget_m10` | Decimal(18, 6) | 10月预算 |
| `f_budget_m11` | Decimal(18, 6) | 11月预算 |
| `f_budget_m12` | Decimal(18, 6) | 12月预算 |
| `budget_year` | UInt16 | 年份（如 2026） |
| `etl_create_time` | DateTime       default now() | 数据入库时间 |
| `uuid` | Nullable(Int32) | 唯一序号 |
| `is_client_matched` | FixedString(1) default 'Y' | 客户是否匹配 |
| `d_client_id` | Nullable(String) | 客户主键 |
| `d_client_code` | Nullable(String) | 客户编码 |
| `d_salesman_id` | Nullable(String) | 销售员主键 |
| `d_salesman_name` | Nullable(String) | 销售员 |
| `d_client_mobile` | Nullable(String) | 客户手机号 |
| `d_tax_code` | Nullable(String) | 客户税号 |
| `general_name` | Nullable(String) | 客户可用状态 |
| `is_strategy` | FixedString(1) default 'Y' | 是否战略产品 |
| `dr` | FixedString(1) default multiIf(
            (((((((((((abs(f_budget_m01) + abs(f_budget_m02)) + abs(f_budget_m03)) + abs(f_budget_m04)) +
                    abs(f_budget_m05)) + abs(f_budget_m06)) + abs(f_budget_m07)) + abs(f_budget_m08)) +
                abs(f_budget_m09)) + abs(f_budget_m10)) + abs(f_budget_m11)) + abs(f_budget_m12)) = 0, '1',
            '0') | 删除标记：0保留 1删除 |

### dwd_fin_budgetmth_detail
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 41
**上游表**: dim_client, dim_material, dim_unit_dict, dwd_fin_budget_detail
**CK内部依赖**: dim_client, dim_material, dim_unit_dict, dwd_fin_budget_detail

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_attr` | String | 客户属性 |
| `d_region_name` | String | 大区 |
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_dept_id` | String | 部门主键 |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_town_name` | String | 聚焦镇 |
| `d_town_type` | String | 聚焦镇类型 |
| `d_prodline_name` | String | 产品线 |
| `d_class_code4` | String | nc大类编码（4位） |
| `d_class_name4` | String | nc大类名称（4位） |
| `d_class_code6` | String | nc小类编码（6位） |
| `d_class_name6` | String | nc小类名称（6位） |
| `d_client_id` | FixedString(20) | 客户主键 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `vip_client` | String | 大客户 |
| `product_series` | String | 产品系列(不同规格合并) |
| `strategy_name` | String | 战略产品 |
| `group_product_proj` | String | 集团级产品线项目 |
| `core_market` | String | 核心市场 |
| `product_positioning` | String | 产品定位 |
| `f_budget` | Decimal(18, 6) | 销量预算 |
| `budget_year` | UInt16 | 年份（如 2026） |
| `budget_month` | FixedString(7) | 月份（如 2026） |
| `etl_create_time` | DateTime       default now() | 数据入库时间 |
| `d_class_code2` | String | nc分类编码（2位） |
| `d_class_name2` | String | nc分类名称（2位） |
| `uuid` | Nullable(Int32) | 唯一id |
| `is_client_matched` | FixedString(1) default 'Y' | 客户是否匹配 |
| `d_salesman_id` | Nullable(String) | 销售员主键 |
| `d_salesman_name` | Nullable(String) | 销售员 |
| `d_client_mobile` | Nullable(String) | 客户手机号 |
| `d_tax_code` | Nullable(String) | 客户税号 |
| `general_name` | Nullable(String) | 客户可用状态 |
| `is_strategy` | FixedString(1) default 'Y' | 是否战略产品 |
| `f_budget_high` | Decimal(18, 6) default multiIf(is_strategy = 'Y', f_budget, 0) | 高价值预算销量预算 |
| `dr` | FixedString(1) default '0' | 删除标记 |

### dwd_fin_budgetmth_detail_fx
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 37
**上游表**: dwd_fin_budgetmth_detail
**CK内部依赖**: dwd_fin_budgetmth_detail

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_attr` | String | 客户属性 |
| `d_region_name` | String | 大区 |
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_dept_id` | String | 部门主键 |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_town_name` | String | 聚焦镇 |
| `d_town_type` | String | 聚焦镇类型 |
| `d_prodline_name` | String | 产品线 |
| `d_class_code4` | String | nc大类编码（4位） |
| `d_class_name4` | String | nc大类名称（4位） |
| `d_client_id` | FixedString(20) | 客户主键 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `vip_client` | String | 大客户 |
| `group_product_proj` | String | 集团级产品线项目 |
| `core_market` | String | 核心市场 |
| `product_positioning` | String | 产品定位 |
| `f_budget` | Decimal(18, 6) | 销量预算 |
| `budget_year` | UInt16 | 年份（如 2026） |
| `budget_month` | FixedString(7) | 月份（如 2026） |
| `etl_create_time` | DateTime       default now() | 数据入库时间 |
| `d_class_code2` | String | nc分类编码（2位） |
| `d_class_name2` | String | nc分类名称（2位） |
| `is_client_matched` | FixedString(1) default 'Y' | 客户是否匹配 |
| `d_salesman_id` | Nullable(String) | 销售员主键 |
| `d_salesman_name` | Nullable(String) | 销售员 |
| `d_client_mobile` | Nullable(String) | 客户手机号 |
| `d_tax_code` | Nullable(String) | 客户税号 |
| `general_name` | Nullable(String) | 客户可用状态 |
| `is_strategy` | FixedString(1) default 'Y' | 是否战略产品 |
| `f_budget_high` | Decimal(18, 6) default multiIf(is_strategy = 'Y', f_budget, 0) | 高价值销量预算 |
| `uuid` | Nullable(Int64) | 聚合之后的最大唯一序号 |
| `is_etl` | FixedString(1) default 'N' | 同步标记 |

### dwd_fin_gross_profit
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 29
**上游表**: dim_material, dim_unit, dwd_fin_gross_profit
**CK内部依赖**: dim_material, dim_unit, dwd_fin_gross_profit

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `gross_profit_year` | UInt16 | 年份（如2026） |
| `d_material_id` | FixedString(20) | 物料主键 |
| `d_material_code` | String | 物料编码 |
| `d_material_name` | String | 物料名称（维表） |
| `d_material_name_fr` | String | 物料名称（FR填报） |
| `d_class_code4` | String | 大类编码 |
| `d_class_name4` | String | 大类名称（维表） |
| `d_class_name4_fr` | String | 大类名称（FR填报） |
| `d_class_code6` | String | 小类编码 |
| `d_class_name6` | String | 小类名称（维表） |
| `d_class_name6_fr` | String | 小类名称（FR填报） |
| `d_prodline_code` | String | 产线编码 |
| `d_prodline_name` | String | 产线名称 |
| `d_profit_corp_id` | FixedString(20) | 利润归属公司主键 |
| `d_profit_corp_code` | String | 利润归属公司编码 |
| `d_profit_corp_name` | String | 利润归属公司名称 |
| `d_profit_corp_sname` | String | 利润归属公司简称 |
| `d_profit_region_code` | String | 利润归属大区编码 |
| `d_profit_region_name` | String | 利润归属大区名称 |
| `d_produce_corp_id` | FixedString(20) | 生产公司主键 |
| `d_produce_corp_code` | String | 生产公司编码 |
| `d_produce_corp_name` | String | 生产公司名称 |
| `d_produce_corp_sname` | String | 生产公司简称 |
| `particle_size` | String | 粒径 |
| `product_series` | String | 产品系列 |
| `strategy_name` | String | 战略产品（是;否） |
| `f_gross_red` | Decimal(18, 6) | 配销差红线 |
| `ts_char` | String | 源时间戳（字符） |
| `ts` | DateTime materialized toDateTime(ts_char) | 更新时间 |

### dwd_fin_net_profit
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 18
**上游表**: dwd_fin_net_profit
**CK内部依赖**: dwd_fin_net_profit

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_name` | String | 大区 |
| `d_corp_sname` | String | 公司简称 |
| `f_net_m01` | Decimal(18, 6) | 1月预算 |
| `f_net_m02` | Decimal(18, 6) | 2月预算 |
| `f_net_m03` | Decimal(18, 6) | 3月预算 |
| `f_net_m04` | Decimal(18, 6) | 4月预算 |
| `f_net_m05` | Decimal(18, 6) | 5月预算 |
| `f_net_m06` | Decimal(18, 6) | 6月预算 |
| `f_net_m07` | Decimal(18, 6) | 7月预算 |
| `f_net_m08` | Decimal(18, 6) | 8月预算 |
| `f_net_m09` | Decimal(18, 6) | 9月预算 |
| `f_net_m10` | Decimal(18, 6) | 10月预算 |
| `f_net_m11` | Decimal(18, 6) | 11月预算 |
| `f_net_m12` | Decimal(18, 6) | 12月预算 |
| `net_profit_year` | UInt16 | 年份(如2026) |
| `uuid` | UInt64 | 序号(Oracle源主键) |
| `ts_char` | String | ETL入库时间字符串(冗余原始值) |
| `ts` | DateTime materialized toDateTime(ts_char) | ETL入库时间 |

### dwd_fin_net_profitmth
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 11
**上游表**: dim_unit_dict, dwd_fin_net_profit
**CK内部依赖**: dim_unit_dict, dwd_fin_net_profit

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_name` | String | 大区 |
| `d_corp_id` | String | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_sname` | String | 公司简称 |
| `d_corp_name` | String | 公司全称 |
| `net_profit_year` | UInt16 | 年份(如2026) |
| `net_month` | String | 月份(如2026-01) |
| `f_ne_profit` | Decimal(18, 6) | 当月净利润预算 |
| `uuid` | UInt64 | 序号(源表主键) |
| `ts_char` | String | ETL入库时间字符串 |
| `ts` | DateTime materialized toDateTime(ts_char) | ETL入库时间 |

### dwd_fin_profit_detail
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 40
**上游表**: dwd_fin_profit_detail
**CK内部依赖**: dwd_fin_profit_detail

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_attr` | String | 客户属性 |
| `d_region_name` | String | 大区 |
| `d_corp_sname` | String | 公司简称 |
| `d_town_name` | String | 聚焦镇 |
| `d_town_type` | String | 聚焦镇类型 |
| `d_prodline_name` | String | 产品线 |
| `d_class_name4` | String | 大类 |
| `d_class_name6` | String | 小类 |
| `d_client_name` | String | 客户名称 |
| `vip_client` | String | 大客户 |
| `product_series` | String | 产品系列(不同规格合并) |
| `strategy_name` | String | 战略产品 |
| `group_product_proj` | String | 集团级产品线项目 |
| `core_market` | String | 核心市场 |
| `product_positioning` | String | 产品定位 |
| `f_profit_m01` | Decimal(18, 6) | 1月预算 |
| `f_profit_m02` | Decimal(18, 6) | 2月预算 |
| `f_profit_m03` | Decimal(18, 6) | 3月预算 |
| `f_profit_m04` | Decimal(18, 6) | 4月预算 |
| `f_profit_m05` | Decimal(18, 6) | 5月预算 |
| `f_profit_m06` | Decimal(18, 6) | 6月预算 |
| `f_profit_m07` | Decimal(18, 6) | 7月预算 |
| `f_profit_m08` | Decimal(18, 6) | 8月预算 |
| `f_profit_m09` | Decimal(18, 6) | 9月预算 |
| `f_profit_m10` | Decimal(18, 6) | 10月预算 |
| `f_profit_m11` | Decimal(18, 6) | 11月预算 |
| `f_profit_m12` | Decimal(18, 6) | 12月预算 |
| `profit_year` | UInt16 | 年份（如 2026） |
| `etl_create_time` | DateTime       default now() | 数据入库时间 |
| `uuid` | Nullable(Int32) | 唯一序号 |
| `is_client_matched` | FixedString(1) default 'Y' | 客户是否匹配 |
| `d_client_id` | Nullable(String) | 客户主键 |
| `d_client_code` | Nullable(String) | 客户编码 |
| `d_salesman_id` | Nullable(String) | 销售员主键 |
| `d_salesman_name` | Nullable(String) | 销售员 |
| `d_client_mobile` | Nullable(String) | 客户手机号 |
| `d_tax_code` | Nullable(String) | 客户税号 |
| `general_name` | Nullable(String) | 客户可用状态 |
| `is_strategy` | FixedString(1) default 'Y' | 是否战略产品 |
| `dr` | FixedString(1) default multiIf(
            (((((((((((abs(f_profit_m01) + abs(f_profit_m02)) + abs(f_profit_m03)) + abs(f_profit_m04)) +
                    abs(f_profit_m05)) + abs(f_profit_m06)) + abs(f_profit_m07)) + abs(f_profit_m08)) +
                abs(f_profit_m09)) + abs(f_profit_m10)) + abs(f_profit_m11)) + abs(f_profit_m12)) = 0, '1',
            '0') | 删除标记：0保留 1删除 |

### dwd_fin_profitmth_detail
**层级**: DWD | **工作流**: 3job-FRdata | **字段数**: 41
**上游表**: dim_client, dim_material, dim_unit_dict, dwd_fin_profit_detail
**CK内部依赖**: dim_client, dim_material, dim_unit_dict, dwd_fin_profit_detail

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_client_attr` | String | 客户属性 |
| `d_region_name` | String | 大区 |
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_dept_id` | String | 部门主键 |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_town_name` | String | 聚焦镇 |
| `d_town_type` | String | 聚焦镇类型 |
| `d_prodline_name` | String | 产品线 |
| `d_class_code4` | String | nc大类编码（4位） |
| `d_class_name4` | String | nc大类名称（4位） |
| `d_class_code6` | String | nc小类编码（6位） |
| `d_class_name6` | String | nc小类名称（6位） |
| `d_client_id` | FixedString(20) | 客户主键 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `vip_client` | String | 大客户 |
| `product_series` | String | 产品系列(不同规格合并) |
| `strategy_name` | String | 战略产品 |
| `group_product_proj` | String | 集团级产品线项目 |
| `core_market` | String | 核心市场 |
| `product_positioning` | String | 产品定位 |
| `f_profit` | Decimal(18, 6) | 毛利预算 |
| `profit_year` | UInt16 | 年份（如 2026） |
| `profit_month` | FixedString(7) | 月份（如 2026） |
| `etl_create_time` | DateTime       default now() | 数据入库时间 |
| `d_class_code2` | String | nc分类编码（2位） |
| `d_class_name2` | String | nc分类名称（2位） |
| `uuid` | Nullable(Int32) | 唯一id |
| `is_client_matched` | FixedString(1) default 'Y' | 客户是否匹配 |
| `d_salesman_id` | Nullable(String) | 销售员主键 |
| `d_salesman_name` | Nullable(String) | 销售员 |
| `d_client_mobile` | Nullable(String) | 客户手机号 |
| `d_tax_code` | Nullable(String) | 客户税号 |
| `general_name` | Nullable(String) | 客户可用状态 |
| `is_strategy` | FixedString(1) default 'Y' | 是否战略产品 |
| `f_profit_high` | Decimal(18, 6) default multiIf(is_strategy = 'Y', f_profit, 0) | 高价值预算毛利预算 |
| `dr` | FixedString(1) default '0' | 删除标记 |

### dwd_fx_checkinsobj
**层级**: DWD | **工作流**: - | **字段数**: 10
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `uuid` | String | 唯一id (去重主键) |
| `d_region_name` | String | 大区 |
| `d_corp_sname` | String | 公司简称 |
| `d_corp_name` | String | 公司全称 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_vip_client_name` | String | 大客户名称 |
| `d_signer` | String | 签到人员 |
| `checkinsobj_status` | String | 外勤拜访状态 |
| `finish_time` | Date | 完成时间 (用于分区) |

### dwd_fx_demonstration
**层级**: DWD | **工作流**: - | **字段数**: 11
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `uuid` | String | 唯一id (去重主键) |
| `d_region_name` | String | 大区 |
| `d_corp_sname` | String | 公司简称 |
| `d_corp_name` | String | 公司全称 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_vip_client_name` | String | 大客户名称 |
| `d_demo_code` | String | 示范户编号 |
| `demo_status` | String | 示范户状态 |
| `f_demo_case_count` | String | 示范户案例个数 |
| `admission_date` | Date | 准入日期 |

### dwd_fx_marketingeventobj
**层级**: DWD | **工作流**: - | **字段数**: 10
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `uuid` | String | 唯一id (去重主键) |
| `d_region_name` | String | 大区 |
| `d_corp_sname` | String | 公司简称 |
| `d_corp_name` | String | 公司全称 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_vip_client_name` | String | 大客户名称 |
| `marketing_name` | String | 营销活动名称 |
| `marketing_status` | String | 大客户营销活动状态 |
| `end_date` | Date | 结束日期 |

### dwd_gl_balance
**层级**: DWD | **工作流**: 4job-nc_fin | **字段数**: 17
**上游表**: bd_accasoa, bd_account, gl_balance, org_financeorg
**底层数据源(Oracle)**: bd_accasoa, bd_account, gl_balance, org_financeorg

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `years` | String | 年度 |
| `months` | String | 期间 |
| `month_dt` | String | 年月 |
| `d_subject_id` | FixedString(20) | 科目主键 |
| `d_subject_code` | String | 科目编码 |
| `d_subject_name` | String | 科目名称 |
| `f_debitamount` | Decimal(18, 6) | 借方金额 |
| `f_creditamount` | Decimal(18, 6) | 贷方金额 |
| `f_period_amount` | Decimal(18, 6) | 本期发生额 |
| `f_opening_balance` | Decimal(18, 6) | 期初余额 |
| `f_balance` | Decimal(18, 6) | 期末余额 |
| `rn` | UInt32 | 行号 |
| `ts_char` | String | 时间戳原始字符 |
| `ts` | DateTime materialized toDateTime(ts_char) | 时间戳 |

### dwd_ia_monthnab
**层级**: DWD | **工作流**: 2-1job-dwd_ia_monthnab_snap | **字段数**: 33
**上游表**: bd_accperiodmonth, bd_marbasclass, bd_material, bd_measdoc, ia_monthnab, org_costregion, org_financeorg
**底层数据源(Oracle)**: bd_accperiodmonth, bd_marbasclass, bd_material, bd_measdoc, ia_monthnab, org_costregion, org_financeorg

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `ia_monthnab_uid` | FixedString(20) | 物料月末结存主键 |
| `d_corp_id` | FixedString(20) | 公司主键（org_costregion.pk_org → org_financeorg） |
| `d_costregion_code` | String | 成本域编码（org_costregion.code） |
| `d_costregion_name` | String | 成本域全称（org_costregion.name） |
| `d_corp_code` | String | 公司编码（org_financeorg.code） |
| `d_corp_name` | String | 公司全称（org_financeorg.name） |
| `d_corp_sname` | String | 公司简称（org_financeorg.shortname） |
| `d_material_id` | FixedString(20) | 物料主键（cinventoryid） |
| `d_material_code` | String | 物料编码（bd_material.code） |
| `d_material_name` | String | 物料名称（bd_material.name） |
| `d_material_type` | String | 物料型号（bd_material.materialtype） |
| `d_cinvclass_sid` | FixedString(20) | 物料小类主键（6级，pk_marbasclass） |
| `d_class_code6` | String | 物料小类编码（6位） |
| `d_class_name6` | String | 物料小类名称 |
| `d_cinvclassid` | FixedString(20) | 物料大类主键（4级） |
| `d_class_code4` | String | 物料大类编码（4位） |
| `d_class_name4` | String | 物料大类名称 |
| `d_class_code2` | String | 物料中类编码（3级） |
| `d_class_name2` | String | 物料中类名称 |
| `d_class_code1` | String | 一级业务分类编码（原料/添加剂/包装物等） |
| `d_class_name1` | String | 一级业务分类名称（原料/添加剂/包装物等） |
| `measdoc_id` | FixedString(20) | 主计量单位主键（bd_material.pk_measdoc） |
| `measdoc_name` | String | 主计量单位名称（bd_measdoc.name） |
| `f_qty` | Decimal(18, 6) | 期末结存数量（nabnum） |
| `f_price` | Decimal(18, 6) | 期末结存单价（nabprice） |
| `f_price_mth` | Decimal(18, 6) | 全月平均单价（nmonthprice） |
| `f_amt` | Decimal(18, 6) | 期末结存金额（nabmny） |
| `f_dif_rate` | Decimal(18, 6) | 差异率（nvariancerate） |
| `ts_char` | String '2025-10-01 12:34:56''）' | NC 系统最后同步时间戳（用于增量捕获，格式如  |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 同步时间（物化，用于 ReplacingMergeTree） |
| `dr` | String '0''=有效，''1''=删除' | 逻辑删除标记： |
| `month_dt` | String 'YYYY-MM''' | 会计期间分区字段，格式  |
| `d_material_vid` | FixedString(20) |  |

### dwd_ia_monthnab_adjust
**层级**: DWD | **工作流**: 2-1job-dwd_ia_monthnab_snap | **字段数**: 3
**上游表**: ia_monthnab
**底层数据源(Oracle)**: ia_monthnab

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `ia_monthnab_uid` | FixedString(20) | 月结存唯一主键（cmonthnabid） |
| `ts_char` | String | NC 系统最后同步时间戳（用于增量捕获） |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 物化同步时间戳 |

### dwd_ia_monthnab_snap
**层级**: DWD | **工作流**: 2-1job-dwd_ia_monthnab_snap | **字段数**: 32
**上游表**: dwd_ia_monthnab
**CK内部依赖**: dwd_ia_monthnab

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司主键（org_costregion.pk_org → org_financeorg） |
| `d_corp_code` | String | 公司编码（org_financeorg.code） |
| `d_corp_name` | String | 公司全称（org_financeorg.name） |
| `d_corp_sname` | String | 公司简称（org_financeorg.shortname） |
| `d_material_id` | FixedString(20) | 物料主键（cinventoryid） |
| `d_material_code` | String | 物料编码（bd_material.code） |
| `d_material_name` | String | 物料名称（bd_material.name） |
| `d_material_type` | String | 物料型号（bd_material.materialtype） |
| `d_cinvclass_sid` | FixedString(20) | 物料小类主键（6级，pk_marbasclass） |
| `d_class_code6` | String | 物料小类编码（6位） |
| `d_class_name6` | String | 物料小类名称 |
| `d_cinvclassid` | FixedString(20) | 物料大类主键（4级） |
| `d_class_code4` | String | 物料大类编码（4位） |
| `d_class_name4` | String | 物料大类名称 |
| `d_class_code2` | String | 物料中类编码（3级） |
| `d_class_name2` | String | 物料中类名称 |
| `d_class_code1` | String | 一级业务分类编码（原料/添加剂/包装物等） |
| `d_class_name1` | String | 一级业务分类名称（原料/添加剂/包装物等） |
| `measdoc_id` | FixedString(20) | 主计量单位主键（bd_material.pk_measdoc） |
| `measdoc_name` | String | 主计量单位名称（bd_measdoc.name） |
| `f_qty` | Decimal(38, 10) | 期末结存数量（nabnum） |
| `f_price` | Decimal(38, 10) | 期末结存单价（nabprice） |
| `f_price_mth` | Decimal(38, 10) | 全月平均单价（nmonthprice） |
| `f_amt` | Decimal(38, 10) | 期末结存金额（nabmny） |
| `f_dif_rate` | Decimal(38, 10) | 差异率（nvariancerate） |
| `ts_char` | String '2025-10-01 12:34:56''）' | NC 系统最后同步时间戳（用于增量捕获，格式如  |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 同步时间（物化，用于 ReplacingMergeTree） |
| `dr` | String '0''=有效，''1''=删除' | 逻辑删除标记： |
| `month_dt_biz` | String 'YYYY-MM''' | 会计期间业务日期，格式  |
| `month_dt` | String 'YYYY-MM''' | 会计期间分区字
	段，格式  |
| `current_month_dt` | String materialized formatDateTime(addMonths(toDate(concat(month_dt, '-01')), 1), '%Y-%m') |  |
| `measure_ratio` | Decimal(18, 6) default dictGet('alphafeed.dim_material_dict', 'measure_ratio', d_material_id) |  |

### dwd_ic_flow
**层级**: DWD | **工作流**: 2job-nc_stock_1h | **字段数**: 87
**上游表**: bd_billtype, bd_customer, bd_defdoc, bd_marbasclass, bd_material, bd_measdoc, bd_psndoc, bd_stordoc, bd_supplier, ic_flow 等12张
**底层数据源(Oracle)**: bd_billtype, bd_customer, bd_defdoc, bd_marbasclass, bd_material, bd_measdoc, bd_psndoc, bd_stordoc 等12张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `flow_uid` | FixedString(20) | 流水唯一主键（pk_flow） |
| `bill_code` | String | 单据编号（vbillcode） |
| `first_billhid` | String | 源头单据主键（cfirstbillhid） |
| `first_billcode` | String | 源头单据编号（vfirstbillcode） |
| `row_no` | String | 行号（crowno） |
| `row_note` | String | 行备注（vnotebody） |
| `d_billtype_id` | FixedString(20) | 出入库类型主键（ctrantypeid） |
| `d_billtype_name` | String | 出入库类型名称（billtypename） |
| `d_corp_id` | FixedString(20) | 公司主键（corpoid） |
| `d_corp_code` | String | 公司编码（org_corp.code） |
| `d_corp_name` | String | 公司全称（org_corp.name） |
| `d_corp_sname` | String | 公司简称（org_corp.shortname） |
| `d_warehouse_id` | FixedString(20) | 仓库主键（cwarehouseid） |
| `d_warehouse_code` | String | 仓库编码（bd_stordoc.code） |
| `d_warehouse_name` | String | 仓库名称（bd_stordoc.name） |
| `d_client_id` | FixedString(20) | 客户主键（ccustomerid） |
| `d_client_code` | String | 客户编码（bd_customer.code） |
| `d_client_name` | String | 客户名称（bd_customer.name） |
| `d_supplier_id` | FixedString(20) | 供应商主键（cvendorid） |
| `d_supplier_code` | String | 供应商编码（bd_supplier.code） |
| `d_supplier_name` | String | 供应商名称（bd_supplier.name） |
| `d_material_id` | FixedString(20) | 物料主键（cmaterialvid） |
| `d_material_vid` | FixedString(20) | 物料最新版本主键（pk_source） |
| `d_material_code` | String | 物料编码（bd_material.code） |
| `d_material_name` | String | 物料名称（bd_material.name） |
| `d_cinvclass_sid` | FixedString(20) | 物料小类主键（6级分类 pk_marbasclass） |
| `d_class_code6` | String | 物料小类编码（6位） |
| `d_class_name6` | String | 物料小类名称6 |
| `d_cinvclassid` | FixedString(20) | 物料大类主键（4级分类 pk_marbasclass） |
| `d_class_code4` | String | 物料大类编码（4位） |
| `d_class_name4` | String | 物料大类名称4 |
| `d_class_code2` | String | 物料分类编码（2位） |
| `d_class_name2` | String | 物料分类名称2 |
| `d_class_code1` | String | 物料分类编码（1位） |
| `d_class_name1` | String | 物料分类名称1 |
| `f_inbound_auxqty` | Decimal(38, 10) | 实入辅数量（ninassistnum） |
| `f_inbound_qty` | Decimal(38, 10) | 实入主数量（ninnum） |
| `f_should_inbound_qty` | Decimal(38, 10) | 应入主数量（nshouldinnum） |
| `f_outbound_auxqty` | Decimal(38, 10) | 实出辅数量（noutassistnum） |
| `f_outbound_qty` | Decimal(38, 10) | 实出主数量（noutnum） |
| `f_should_outbound_qty` | Decimal(38, 10) | 应出主数量（nshouldoutnum） |
| `f_amt` | Decimal(38, 10) | 金额（出库&入库）：采购入库用 vbodyuserdef7（结算金额），其他用 ncostmny |
| `f_price` | Decimal(38, 10) | 单价（出库&入库）：采购入库用 vbodyuserdef8（结算单价），其他用 ncostprice |
| `f_settled_qty_cr0` | Decimal(38, 10) | 采购入库(CR0)用vbodyuserdef6（结算数量） |
| `f_price_cr0` | Decimal(38, 10) | 采购入库(CR0)单价（vbodyuserdef10 转数值） |
| `measdoc_id` | FixedString(20) | 主计量单位主键（cunitid） |
| `measdoc_name` | String | 主计量单位名称 |
| `assist_measdoc_id` | FixedString(20) | 辅计量单位主键（castunitid） |
| `assist_measdoc_name` | String | 辅计量单位名称 |
| `bill_flag` | String | 单据状态：1=删除，2=自由，3=签字，4=审核，5=审核中，6=审核不通过，7=已调差 |
| `is_gift` | String | 是否赠品：Y/N |
| `is_returned` | String | 是否退货：Y/N |
| `cost_object` | String | 成本对象（ccostobject） |
| `source_billhid` | String | 来源单据主键（csourcebillhid） |
| `dr` | String '0''=有效，''1''=删除' | 逻辑删除标记： |
| `salesman_id` | FixedString(20) | 业务员主键（cbizid） |
| `salesman_code` | String | 业务员编码（bd_psndoc.code） |
| `salesman_name` | String | 业务员姓名（bd_psndoc.name） |
| `modifier_id` | FixedString(20) | 修改人主键（modifier） |
| `modifier_code` | String | 修改人用户编码（sm_user.user_code） |
| `modifier_name` | String | 修改人姓名（sm_user.user_name） |
| `creator_id` | FixedString(20) | 创建人主键（creator） |
| `creator_code` | String | 创建人用户编码（sm_user.user_code） |
| `creator_name` | String | 创建人姓名（sm_user.user_name） |
| `modified_ts_char` | String '2025-10-01 12:34:56''）' | 最后修改时间（modifiedtime，格式如  |
| `creation_ts_char` | String | 创建时间（creationtime） |
| `bill_ts_char` | String | 单据日期（dbilldate，用于分区） |
| `biz_ts_char` | String | 业务日期（dbizdate） |
| `ts_char` | String | NC 系统最后同步时间戳（用于增量捕获） |
| `bill_ts` | DateTime materialized parseDateTimeBestEffort(bill_ts_char) | 单据日期（物化，用于查询过滤） |
| `biz_ts` | DateTime materialized parseDateTimeBestEffort(biz_ts_char) | 业务日期（物化） |
| `month_dt` | String 'YYYY-MM''（来自 SUBSTR(dbilldate, 1, 7)）' | 分区字段，格式  |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 业务日期（物化） |
| `bill_dt` | Date materialized toDate(bill_ts) |  |
| `d_mat_attr1_id` | LowCardinality(String) | 配件属性主键1（vfree1） |
| `d_mat_attr2_id` | LowCardinality(String) | 配件属性主键2（vfree2） |
| `d_mat_attr3_id` | LowCardinality(String) | 配件属性主键3（vfree3） |
| `d_mat_attr4_id` | LowCardinality(String) | 配件属性主键4（vfree4） |
| `d_mat_attr5_id` | LowCardinality(String) | 配件属性主键5（vfree5） |
| `d_mat_attr6_id` | LowCardinality(String) | 配件属性主键6（vfree6） |
| `d_mat_attr7_id` | LowCardinality(String) | 配件属性主键7（vfree7） |
| `d_mat_attr9_id` | LowCardinality(String) | 预留属性主键9（vfree9） |
| `d_mat_attr10_id` | LowCardinality(String) | 预留属性主键10（vfree10） |
| `d_mat_attr8_id` | LowCardinality(String) | 研发物质属性主键（vfree8） |
| `d_mat_attr8_code` | LowCardinality(String) | 研发物质属性编码（bd_defdoc.code） |
| `d_mat_attr8_name` | LowCardinality(String) | 研发物质属性名称（bd_defdoc.name） |
| `measure_ratio` | Decimal(18, 6) default dictGet('alphafeed.dim_material_dict', 'measure_ratio', d_material_id) |  |

### dwd_ic_flow_adjust
**层级**: DWD | **工作流**: 2job-nc_stock_1h | **字段数**: 3
**上游表**: ic_flow
**底层数据源(Oracle)**: ic_flow

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `flow_uid` | FixedString(20) | 流水唯一主键（pk_flow） |
| `ts_char` | String | NC 系统最后同步时间戳（用于增量捕获） |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 物化同步时间戳 |

### dwd_ic_flow_rd45
**层级**: DWD | **工作流**: 2job-nc_stock_1h | **字段数**: 87
**上游表**: bd_billtype, bd_customer, bd_defdoc, bd_marbasclass, bd_material, bd_measdoc, bd_psndoc, bd_stordoc, bd_supplier, ic_flow 等12张
**底层数据源(Oracle)**: bd_billtype, bd_customer, bd_defdoc, bd_marbasclass, bd_material, bd_measdoc, bd_psndoc, bd_stordoc 等12张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `flow_uid` | FixedString(20) | 流水唯一主键（pk_flow） |
| `bill_code` | String | 单据编号（vbillcode） |
| `first_billhid` | String | 源头单据主键（cfirstbillhid） |
| `first_billcode` | String | 源头单据编号（vfirstbillcode） |
| `row_no` | String | 行号（crowno） |
| `row_note` | String | 行备注（vnotebody） |
| `d_billtype_id` | FixedString(20) | 出入库类型主键（ctrantypeid） |
| `d_billtype_name` | String | 出入库类型名称（billtypename） |
| `d_corp_id` | FixedString(20) | 公司主键（corpoid） |
| `d_corp_code` | String | 公司编码（org_corp.code） |
| `d_corp_name` | String | 公司全称（org_corp.name） |
| `d_corp_sname` | String | 公司简称（org_corp.shortname） |
| `d_warehouse_id` | FixedString(20) | 仓库主键（cwarehouseid） |
| `d_warehouse_code` | String | 仓库编码（bd_stordoc.code） |
| `d_warehouse_name` | String | 仓库名称（bd_stordoc.name） |
| `d_client_id` | FixedString(20) | 客户主键（ccustomerid） |
| `d_client_code` | String | 客户编码（bd_customer.code） |
| `d_client_name` | String | 客户名称（bd_customer.name） |
| `d_supplier_id` | FixedString(20) | 供应商主键（cvendorid） |
| `d_supplier_code` | String | 供应商编码（bd_supplier.code） |
| `d_supplier_name` | String | 供应商名称（bd_supplier.name） |
| `d_material_id` | FixedString(20) | 物料主键（cmaterialvid） |
| `d_material_vid` | FixedString(20) | 物料最新版本主键（pk_source） |
| `d_material_code` | String | 物料编码（bd_material.code） |
| `d_material_name` | String | 物料名称（bd_material.name） |
| `d_mat_attr8_id` | FixedString(20) | 研发物质属性主键（vfree8） |
| `d_mat_attr8_code` | String | 研发物质属性编码（bd_defdoc.code） |
| `d_mat_attr8_name` | String | 研发物质属性名称（bd_defdoc.name） |
| `d_cinvclass_sid` | FixedString(20) | 物料小类主键（6级分类 pk_marbasclass） |
| `d_class_code6` | String | 物料小类编码（6位） |
| `d_class_name6` | String | 物料小类名称6 |
| `d_cinvclassid` | FixedString(20) | 物料大类主键（4级分类 pk_marbasclass） |
| `d_class_code4` | String | 物料大类编码（4位） |
| `d_class_name4` | String | 物料大类名称4 |
| `d_class_code2` | String | 物料分类编码（2位） |
| `d_class_name2` | String | 物料分类名称2 |
| `d_class_code1` | String | 物料分类编码（1位） |
| `d_class_name1` | String | 物料分类名称1 |
| `f_inbound_auxqty` | Decimal(38, 10) | 实入辅数量（ninassistnum） |
| `f_inbound_qty` | Decimal(38, 10) | 实入主数量（ninnum） |
| `f_should_inbound_qty` | Decimal(38, 10) | 应入主数量（nshouldinnum） |
| `f_outbound_auxqty` | Decimal(38, 10) | 实出辅数量（noutassistnum） |
| `f_outbound_qty` | Decimal(38, 10) | 实出主数量（noutnum） |
| `f_should_outbound_qty` | Decimal(38, 10) | 应出主数量（nshouldoutnum） |
| `f_amt` | Decimal(38, 10) | 金额（出库&入库）：采购入库用 vbodyuserdef7（结算金额），其他用 ncostmny |
| `f_price` | Decimal(38, 10) | 单价（出库&入库）：采购入库用 vbodyuserdef8（结算单价），其他用 ncostprice |
| `f_settled_qty_cr0` | Decimal(38, 10) | 采购入库(CR0)用vbodyuserdef6（结算数量） |
| `f_price_cr0` | Decimal(38, 10) | 采购入库(CR0)单价（vbodyuserdef10 转数值） |
| `measdoc_id` | FixedString(20) | 主计量单位主键（cunitid） |
| `measdoc_name` | String | 主计量单位名称 |
| `assist_measdoc_id` | FixedString(20) | 辅计量单位主键（castunitid） |
| `assist_measdoc_name` | String | 辅计量单位名称 |
| `bill_flag` | String | 单据状态：1=删除，2=自由，3=签字，4=审核，5=审核中，6=审核不通过，7=已调差 |
| `is_gift` | String | 是否赠品：Y/N |
| `is_returned` | String | 是否退货：Y/N |
| `cost_object` | String | 成本对象（ccostobject） |
| `source_billhid` | String | 来源单据主键（csourcebillhid） |
| `dr` | String '0''=有效，''1''=删除' | 逻辑删除标记： |
| `salesman_id` | FixedString(20) | 业务员主键（cbizid） |
| `salesman_code` | String | 业务员编码（bd_psndoc.code） |
| `salesman_name` | String | 业务员姓名（bd_psndoc.name） |
| `modifier_id` | FixedString(20) | 修改人主键（modifier） |
| `modifier_code` | String | 修改人用户编码（sm_user.user_code） |
| `modifier_name` | String | 修改人姓名（sm_user.user_name） |
| `creator_id` | FixedString(20) | 创建人主键（creator） |
| `creator_code` | String | 创建人用户编码（sm_user.user_code） |
| `creator_name` | String | 创建人姓名（sm_user.user_name） |
| `d_mat_attr1_id` | LowCardinality(String) | 配件属性主键1（vfree1） |
| `d_mat_attr2_id` | LowCardinality(String) | 配件属性主键2（vfree2） |
| `d_mat_attr3_id` | LowCardinality(String) | 配件属性主键3（vfree3） |
| `d_mat_attr4_id` | LowCardinality(String) | 配件属性主键4（vfree4） |
| `d_mat_attr5_id` | LowCardinality(String) | 配件属性主键5（vfree5） |
| `d_mat_attr6_id` | LowCardinality(String) | 配件属性主键6（vfree6） |
| `d_mat_attr7_id` | LowCardinality(String) | 配件属性主键7（vfree7） |
| `d_mat_attr9_id` | LowCardinality(String) | 预留属性主键9（vfree9） |
| `d_mat_attr10_id` | LowCardinality(String) | 预留属性主键10（vfree10） |
| `modified_ts_char` | String '2025-10-01 12:34:56''）' | 最后修改时间（modifiedtime，格式如  |
| `creation_ts_char` | String | 创建时间（creationtime） |
| `bill_ts_char` | String | 单据日期（dbilldate，用于分区） |
| `biz_ts_char` | String | 业务日期（dbizdate） |
| `ts_char` | String | NC 系统最后同步时间戳（用于增量捕获） |
| `bill_ts` | DateTime materialized parseDateTimeBestEffort(bill_ts_char) | 单据日期（物化，用于查询过滤） |
| `biz_ts` | DateTime materialized parseDateTimeBestEffort(biz_ts_char) | 业务日期（物化） |
| `month_dt` | String 'YYYY-MM''（来自 SUBSTR(dbilldate, 1, 7)）' | 分区字段，格式  |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 业务日期（物化） |
| `bill_dt` | Date materialized toDate(bill_ts) |  |
| `measure_ratio` | Decimal(18, 6) default dictGet('alphafeed.dim_material_dict', 'measure_ratio', d_material_id) |  |

### dwd_oa_cg_wlbj
**层级**: DWD | **工作流**: 1job-nc_sal_profit | **字段数**: 11
**上游表**: formtable_main_147, formtable_main_147_dt1, hrmresource, workflow_requestbase
**底层数据源(Oracle)**: formtable_main_147, formtable_main_147_dt1, workflow_requestbase

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | Nullable(String)          default NULL | 公司主键（预留，未来关联 组织 填充） |
| `d_corp_code` | String | 公司编码（来源 GSBM） |
| `d_corp_name` | String | 公司名称 |
| `d_material_id` | Nullable(String)          default NULL | 物料主键（预留，未来关联 物料 填充） |
| `d_material_code` | FixedString(10) | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `f_price_ton` | Decimal(15, 2) | 单吨报价 |
| `f_freight_amt` | Decimal(15, 2) | 运费 |
| `input_by` | String | 填报人员 |
| `biz_dt` | Date | 报价日期 |
| `updt` | Nullable(FixedString(19)) default '2025-08-12 09:00:00' | 更新时间 |

### dwd_plcy_discount_detail_ysnap
**层级**: DWD | **工作流**: 1job-nc_sal_profit | **字段数**: 35
**上游表**: bd_billtype, bd_customer, bd_marbasclass, bd_material, org_orgs, sr_marcombine, sr_marcombine_b, sr_plcy, sr_plcy_caldet, sr_plcy_calrule 等12张
**底层数据源(Oracle)**: bd_billtype, bd_customer, bd_marbasclass, bd_material, org_orgs, sr_marcombine, sr_marcombine_b, sr_plcy 等12张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司id |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司 |
| `d_client_id` | FixedString(20) | 客户id |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_plcytype_id` | FixedString(20) | 政策项目id |
| `d_plcytypename` | String | 政策项目 |
| `d_plcy_id` | FixedString(20) | 返利政策主实体id |
| `d_plcy_code` | String | 政策编号 |
| `d_plcy_name` | String | 政策名称 |
| `d_mar_combine_name` | String | 物料组合名称 |
| `d_mar_dim_flag` | UInt8 | 归类=物料维度指标设定方式 0=全部物料，1=产品线，2=品牌，3=物料基本分类，4=物料销售分类，5=物料，6=物料组合 |
| `d_mar_dim_flagname` | String | 物料维度标志名称 |
| `d_material_dim` | String | 物料维度设定 |
| `bremoveflag` | String          default '' | Y排除 N保留 默认保留，原为Nullable |
| `d_material_dim_id` | FixedString(20) default '' | 物料维度设定主键 |
| `d_material_dim_code` | String | 物料维度设定编码 |
| `d_material_dim_name` | String | 物料维度设定名称 |
| `d_class_id` | FixedString(20) default '' | 2 4 6位分类ID，为空则代表物料（原Nullable） |
| `d_material_id` | FixedString(20) default '' | 物料主键，为空则代表分类（原Nullable） |
| `f_total_disamt` | Decimal(18, 4)  default 0. | 已返利金额，原为Nullable |
| `f_total_max_disamt` | Decimal(18, 4) | 返利金额上限 |
| `f_min_disqty` | Decimal(18, 4)  default 0. | 下限数量(吨)，原为Nullable |
| `f_max_disqty` | Decimal(18, 4)  default 0. | 上限数量(吨)，原为Nullable |
| `f_disprice_ton` | Decimal(18, 4)  default 0. | 折扣金额(元/吨)，原为Nullable |
| `f_disprice_real_ton` | Decimal(18, 4)  default 0. | 实际折扣金额(元/吨)，带负号可以抵消，原为Nullable |
| `dmakedate` | Date | 申请日期 |
| `vnote` | String          default '' | 政策描述，原为Nullable |
| `fstatusflag` | UInt8 | 返利政策状态 0=自由，1=审批中，2=审批不通过，3=审批通过，5=关闭 |
| `dbegindate` | Date | 生效日期 |
| `denddate` | Date | 失效日期 |
| `fperiodflag` | UInt8 | 执行周期=返利周期 0=月，1=季，2=半年，3=年，4=非周期 |
| `fprmtypeflag` | UInt8 | 促销参与返利方式 1=计量计奖，2=不计量不计奖，3=计量不计奖，4=自定义 |
| `year_dt` | UInt16 | 年度 |

### dwd_po_order_detail_all
**层级**: DWD | **工作流**: 2job-nc_stock_1h | **字段数**: 50
**上游表**: bd_billtype, bd_defdoc, bd_marbasclass, bd_material, bd_measdoc, bd_payment, bd_payperiod, bd_supplier, org_purchaseorg, po_order 等12张
**底层数据源(Oracle)**: bd_billtype, bd_defdoc, bd_marbasclass, bd_material, bd_measdoc, bd_supplier, org_purchaseorg, po_order 等9张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_bill_code` | String |  |
| `d_order_id` | FixedString(20) |  |
| `d_order_b_id` | FixedString(20) |  |
| `is_basis` | String |  |
| `order_status` | String |  |
| `contract_type` | String |  |
| `is_pay_close` | String |  |
| `is_closed` | String |  |
| `row_no` | String |  |
| `d_order_type_name` | String |  |
| `d_order_owner_name` | String |  |
| `d_delivery_method` | String |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_short_name` | String |  |
| `d_supplier_id` | FixedString(20) |  |
| `d_supplier_code` | String |  |
| `d_supplier_name` | String |  |
| `d_supplier_class_id` | FixedString(20) |  |
| `d_material_id` | FixedString(20) |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `d_material_type` | String |  |
| `measdoc_id` | FixedString(20) |  |
| `measdoc_name` | String |  |
| `d_class_id` | FixedString(20) |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_pay_term_name` | String |  |
| `d_pay_point_name` | String |  |
| `f_order_qty` | Decimal(18, 6) |  |
| `f_unit_price` | Decimal(18, 6) |  |
| `f_freight_amt` | Decimal(18, 6) |  |
| `f_payment_days` | Decimal(18, 6) |  |
| `order_dt_char` | String |  |
| `plan_arrv_dt_char` | String |  |
| `creation_ts_char` | String |  |
| `order_dt` | DateTime materialized parseDateTimeBestEffort(order_dt_char) |  |
| `plan_arrv_dt` | DateTime materialized parseDateTimeBestEffort(plan_arrv_dt_char) |  |
| `creation_ts` | DateTime materialized parseDateTimeBestEffort(creation_ts_char) |  |
| `month_dt` | String |  |
| `ts` | String |  |
| `ts_dt` | DateTime materialized parseDateTimeBestEffort(ts) |  |
| `d_material_vid` | FixedString(20) |  |
| `dr` | FixedString(1) | 子表删除标记（0未删除 1删除）:如果主表d为1，子表必须变为1 |
| `dr_a` | FixedString(1) | 主表删除标记（0未删除 1删除） |
| `is_latest_version` | FixedString(1) | 是否最新版本(Y N) |

### dwd_price_maintenance_snap
**层级**: DWD | **工作流**: 1job-nc_sal_profit | **字段数**: 21
**上游表**: bd_channeltype, bd_custclass, bd_customer, bd_material_v, bd_measdoc, org_salesorg, prm_tariff, sm_user
**底层数据源(Oracle)**: bd_channeltype, bd_custclass, bd_customer, bd_material_v, bd_measdoc, org_salesorg, prm_tariff, sm_user

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_channel_name` | String |  |
| `d_channel_code` | String |  |
| `d_channel_id` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_material_id` | String |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `d_client_id` | String |  |
| `d_client_code` | String |  |
| `d_client_name` | String |  |
| `f_price` | Decimal(18, 6) |  |
| `measdoc_name` | String |  |
| `enablestate` | UInt8 |  |
| `rn` | UInt64 |  |
| `modify_name` | String |  |
| `modify_dt` | DateTime |  |
| `updt` | Date |  |
| `client_dclass_code` | Nullable(String) | 客户分类:K1 K2 K3 |
| `client_dclass_name` | Nullable(String) | 客户分类名称 |

### dwd_prm_promoteprice_detail_ysnap
**层级**: DWD | **工作流**: - | **字段数**: 38
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `uniq_id` | FixedString(20) | 主键 pk_promoteprice |
| `d_corp_id` | FixedString(20) | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sale_id` | FixedString(20) | 销售组织ID |
| `d_tariff_def_id` | FixedString(20) | 价目表ID |
| `d_belong_sale_id` | FixedString(20) | 价目表所属销售组织ID |
| `d_channel_type_id` | FixedString(20) | 渠道类型ID |
| `d_material_id` | FixedString(20) | 物料ID |
| `d_material_code` | String | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_material_inner_code` | String | 物料分类内部码 |
| `d_client_id` | FixedString(20) | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_customer_inner_code` | String | 客户分类内部码 |
| `d_measure_id` | FixedString(20) | 计量单位ID |
| `d_price_type_id` | FixedString(20) | 价格项ID |
| `d_curr_type_code` | String | 币种 |
| `d_ask_uni_code` | String | 询价优先码 |
| `f_price_factor` | Decimal(28, 8) default 0. | 价格指数 |
| `f_price_prompt` | Decimal(28, 8) default 0. | 促销价 |
| `f_price` | Decimal(28, 8) default 0. | 新价格 |
| `begin_date` | Date | 生效日期 |
| `end_date` | FixedString(19) | 失效日期 |
| `closed_time` | FixedString(19) | 关闭时间 |
| `create_date` | FixedString(19) | 创建日期 |
| `update_date` | FixedString(19) | 更新日期 |
| `rn` | UInt8 | 序号：在未关闭状态下，最近一次更新排前面 |
| `vsrcsys` | String         default 'NC' | 来源系统 |
| `vsrcsysid` | FixedString(20) | 来源系统主键ID |
| `limit_model_flag` | String | 限量模式 |
| `adj_promote_id` | FixedString(20) | 促销价格调整单主表ID |
| `adj_promote_b_id` | FixedString(20) | 促销价格调整单子表ID |
| `is_relate_base` | FixedString(1) | 是否与基价相关 Y是 N否 |
| `is_closed` | FixedString(1) | 是否关闭 Y是 N否 |
| `dr` | FixedString(1) | 删除标记 0未删 1删除：过期 dr删除0或者关闭Y均视为删除 |
| `year_dt` | UInt16 | 年份（基于生效日期 begin_date） |

### dwd_product_subject_cost
**层级**: DWD | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 19
**上游表**: bd_material, bd_measdoc, cm_prodcost, cm_prodcost_b, org_factory, resa_factorasoa, temp
**底层数据源(Oracle)**: bd_material, bd_measdoc, cm_prodcost, cm_prodcost_b, org_factory, resa_factorasoa, temp

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `subject_uid` | String | 唯一主键 |
| `subject_id` | String | 主键 |
| `d_corp_id` | String | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `rn` | Int8 | 序号 |
| `d_factorcode` | String | 核算要素编码 |
| `d_factorname` | String | 核算要素名称 |
| `d_product_id` | String | 成本对象主键 |
| `d_product_code` | String | 成本对象编码 |
| `d_product_name` | String | 成本对象名称 |
| `d_product_measure` | String | 计量单位名称 |
| `d_product_spec` | String | 材料规格 |
| `d_product_type` | String | 材料型号 |
| `f_product_qty` | Decimal(18, 6) | 产成品/配方产量 |
| `f_cost_amount` | Decimal(18, 6) | 产成品/配方成本 |
| `biz_mth` | String comment '更新时间:YYYY-MM -1个月 |  |
| `即业务日期比更新日期延迟一个月'` |  |  |
| `updt` | Date | 更新时间:YYYY-MM-DD |

### dwd_so_cost
**层级**: DWD | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 43
**上游表**: bd_custclass, bd_customer, bd_marbasclass, bd_material, bd_psndoc, ia_i5bill, ia_i5bill_b, org_dept_v, org_stockorg
**底层数据源(Oracle)**: bd_custclass, bd_customer, bd_marbasclass, bd_material, bd_psndoc, ia_i5bill, ia_i5bill_b, org_dept_v 等9张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `socost_id` | FixedString(20) | 销售成本结转单表头主键 |
| `socost_uid` | FixedString(20) | 销售成本结转单表体唯一主键 |
| `d_bill_code` | LowCardinality(String) | 源头单据号 |
| `order_row` | LowCardinality(String) | 源头单据行号 |
| `socost_row` | LowCardinality(String) | 成本结转单行号 |
| `bill_ts_char` | String | 业务日期 |
| `bill_date` | Date materialized toDate(bill_ts_char) | 业务日期 |
| `bill_ts` | DateTime materialized toDateTime(bill_ts_char) | 业务日期 |
| `d_corp_id` | FixedString(20) | 库存组织主键 |
| `d_corp_code` | LowCardinality(String) | 库存组织编码 |
| `d_corp_name` | String | 库存组织名称 |
| `d_corp_sname` | String | 库存组织简称 |
| `d_profit_corp_id` | FixedString(20) | 利润归属公司主键 |
| `d_profit_corp_code` | String | 利润归属公司编码 |
| `d_profit_corp_sname` | String | 利润归属公司简称 |
| `d_profit_region_name` | String default dictGet('alphafeed.dim_unit_dict', 'd_region_name', d_profit_corp_id) | 业绩归属大区名称 |
| `d_dept_vid` | FixedString(20) | 部门版本主键 |
| `d_dept_id` | FixedString(20) | 部门主键 |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_material_id` | FixedString(20) | 物料主键 |
| `d_material_code` | String | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_class_code6` | LowCardinality(String) | 物料6级分类编码 |
| `d_class_name6` | String | 物料6级分类名称 |
| `d_class_code4` | LowCardinality(String) | 物料4级分类编码 |
| `d_class_name4` | String | 物料4级分类名称 |
| `d_client_id` | FixedString(20) | 客户主键 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_cust_detail_code` | LowCardinality(String) | 客户细分类型编码 |
| `d_cust_detail_name` | String | 客户细分类型名称 |
| `d_salesman_id` | FixedString(20) | 业务员主键 |
| `d_salesman_code` | String | 业务员编码 |
| `d_salesman_name` | String | 业务员名称 |
| `f_num` | Decimal(18, 6) | 主数量 |
| `f_second_num` | Decimal(18, 6) | 辅数量 |
| `f_cost_amount` | Decimal(18, 6) | 成本金额 |
| `f_cost_ton` | Decimal(18, 6) | 吨成本单价 |
| `dr` | LowCardinality(String) | 逻辑删除标记 |
| `ts_char` | String | 时间戳 |
| `ts` | DateTime materialized toDateTime(ts_char) | 版本时间戳 |
| `month_dt` | FixedString(7) | 月份分区 YYYY-MM |

### dwd_so_priceform
**层级**: DWD | **工作流**: - | **字段数**: 21
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `priceform_uid` | FixedString(20) | 价格组成实体唯一主键（表体唯一） |
| `d_bill_id` | FixedString(20) | 单据主键（表头主键） |
| `d_corp_id` | FixedString(20) | 基准折扣表销售组织 |
| `d_pricepolicy_id` | FixedString(20) | 定价策略主键 |
| `d_pricepolicy_corp_id` | FixedString(20) | 定价策略销售组织主键 |
| `tariffdef_id` | FixedString(20) | 价目表主键 |
| `d_tariffdef_corp_id` | FixedString(20) | 价目表销售组织主键 |
| `f_discount` | Decimal(18, 6) | 折扣 |
| `f_net_price` | Decimal(18, 6) | 净价 |
| `f_price` | Decimal(18, 6) | 原价 |
| `f_query_discount` | Decimal(18, 6) | 询价折扣 |
| `f_query_net_price` | Decimal(18, 6) | 询价净价 |
| `f_query_price` | Decimal(18, 6) | 询价原价 |
| `f_base_discount` | Decimal(18, 6) | 基准折扣 |
| `f_promotion_discount` | Decimal(18, 6) | 促销折扣:折上折 |
| `priceform_str` | String | 价格公式字符串 |
| `group_id` | FixedString(20) | 集团主键 |
| `dr` | LowCardinality(String) | 逻辑删除标记 |
| `ts_char` | String | 源系统时间戳 |
| `ts` | DateTime materialized toDateTime(ts_char) | 版本时间戳 |
| `month_dt` | Int32 materialized toYYYYMM(ts) | 月份分区 数字YYYYMM |

### dwd_so_profit
**层级**: DWD | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 175
**上游表**: dwd_so_priceform, dwd_so_saleorder, dws_cust_rebate_actual_m, dws_formula_product_day, dws_ia_material_day_stock, dws_product_subject_cost, v_dim_client
**CK内部依赖**: dwd_so_priceform, dwd_so_saleorder, dws_cust_rebate_actual_m, dws_formula_product_day, dws_ia_material_day_stock, dws_product_subject_cost

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `order_id` | FixedString(20) | 订单主键ID |
| `order_uid` | FixedString(20) | 订单唯一标识UID |
| `order_row` | String | 订单行号 |
| `d_bill_code` | String | 单据编号 |
| `status_flag` | String | 状态标识: 1=自由，2=审批通过 |
| `is_gift` | String | 是否赠品标识 (Y/N) |
| `production_mode` | FixedString(6) comment '生产模式：代工 |  |
| `自产'` |  |  |
| `bill_ts_char` | String | 单据时间字符 |
| `bill_ts` | DateTime | 单据时间戳 |
| `bill_date` | Date | 单据日期 |
| `client_class_flag` | String | 客户分类Flag |
| `client_class_name` | String | 客户分类名称 |
| `client_dclass_code` | String | 客户明细分类编码 |
| `client_dclass_name` | String | 客户明细分类名称 |
| `is_corp_flag` | String | 是否集团客户Flag (字典获取) |
| `is_corp_name` | String | 是否集团客户名称 (字典获取) |
| `d_client_type` | String | 纷享销客客户类型 |
| `d_client_level` | String | 纷享销客客户等级 |
| `is_strategic` | String | 是否战略客户 |
| `is_strategic_flag` | String | 战略客户Flag |
| `d_client_id` | FixedString(20) | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_salesman_id` | FixedString(20) | 业务员ID |
| `d_salesman_code` | String | 业务员编码 |
| `d_salesman_name` | String | 业务员名称 |
| `d_region_id` | FixedString(20) | 大区ID |
| `d_region_name` | String | 大区名称 |
| `d_corp_id` | FixedString(20) | 公司ID |
| `d_corp_vid` | FixedString(20) | 公司版本ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_dept_vid` | FixedString(20) | 部门版本ID |
| `d_dept_id` | FixedString(20) | 部门ID |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_stock_corp_id` | FixedString(20) | 库存组织ID |
| `d_stock_corp_code` | String | 库存组织编码 |
| `d_stock_corp_name` | String | 库存组织名称 |
| `d_stock_id` | FixedString(20) | 仓库ID |
| `d_stock_code` | String | 仓库编码 |
| `d_stock_name` | String | 仓库名称 |
| `d_salaera_id` | FixedString(20) | 销售片区ID |
| `d_town_id` | FixedString(20) | 销售区域[聚焦镇]ID |
| `d_town_code` | String | 销售区域[聚焦镇]编码 |
| `d_town_name` | String | 销售区域[聚焦镇]名称 |
| `d_profit_corp_sname` | String | 业绩归属公司简称 |
| `d_profit_corp_code` | String | 业绩归属公司编码 |
| `d_profit_corp_id` | FixedString(20) | 业绩归属公司主键 |
| `d_profit_region_name` | String default dictGet('alphafeed.dim_unit_dict', 'd_region_name', d_profit_corp_id) | 业绩归属大区名称 |
| `d_product_corp_id` | Nullable(FixedString(20)) | 生产公司ID |
| `d_product_corp_code` | String | 生产公司编码 |
| `d_product_corp_name` | String | 生产公司名称 |
| `creationtime` | String | 创建时间 |
| `dmakedate` | String | 制单日期 |
| `modifiedtime` | String | 修改时间 |
| `taudittime` | String | 审核时间 |
| `d_material_id` | FixedString(20) | 物料ID |
| `d_material_code` | FixedString(10) | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_formula_id` | FixedString(20) | 配方ID (字典获取) |
| `d_formula_code` | String | 配方编码 (字典获取) |
| `d_formula_name` | String | 配方名称 (字典获取) |
| `d_package_id` | FixedString(20) | 包装袋主键 |
| `d_package_code` | FixedString(10) | 包装袋编码 |
| `d_package_name` | String | 包装袋名称 |
| `measure_ratio` | Decimal(18, 6) | 主单位/辅单位 换算率 |
| `d_prodline_id` | String | 产品线ID |
| `d_prodline_code` | String | 产品线编码 |
| `d_prodline_name` | String | 产品线名称 |
| `product_tag_code` | Nullable(String) | 产品系列标签编码 |
| `product_tag` | Nullable(String) | 产品系列标签 |
| `d_cinvclass_sid` | FixedString(20) | 物料分类SID |
| `d_class_code6` | String | 六级分类编码 |
| `d_class_name6` | String | 六级分类名称 |
| `d_cinvclassid` | FixedString(20) | 物料分类ID |
| `d_class_code4` | String | 四级分类编码 |
| `d_class_name4` | String | 四级分类名称 |
| `d_class_code2` | String | 二级分类编码 |
| `d_class_name2` | String | 二级分类名称 |
| `d_class_code1` | String | 一级分类编码 |
| `d_class_name1` | String | 一级分类名称 |
| `measdoc_id` | FixedString(20) | 主计量单位ID |
| `measdoc_name` | String | 主计量单位名称 |
| `is_high` | UInt8 materialized multiIf(empty(strategy_name) OR (strategy_name = '无'), 0, 1) | 是否高价值产品：1是 0否 |
| `f_num` | Decimal(18, 6) | 主数量 |
| `f_num_high` | Decimal(18, 6) materialized multiIf(is_high = 0, 0, f_num) | 高价值销量（空或"无"时为0） |
| `f_sale_num` | Decimal(18, 6) materialized multiIf(is_gift = 'N', f_num, 0) | 销售数量（不含赠送） |
| `f_gift_num` | Decimal(18, 6) materialized multiIf(is_gift = 'Y', f_num, 0) | 赠送数量 |
| `f_sale_num_high` | Decimal(18, 6) materialized multiIf((is_high = 0) OR (is_gift = 'Y'), 0, f_num) | 高价值销量（非高价值或赠品时为0） |
| `second_measdoc_id` | FixedString(20) | 辅计量单位ID |
| `second_measdoc_name` | String | 辅计量单位名称 |
| `f_second_num` | Decimal(18, 6) | 辅数量 |
| `f_unitprice_intax` | Decimal(18, 6) | 含税单价 |
| `f_unitprice_extax` | Decimal(18, 6) | 不含税单价 |
| `f_discount_amount` | Decimal(18, 6) | 折扣金额 |
| `f_base_discount` | Decimal(18, 6) | 基础折扣金额 (计算: c.f_base_discount * a.f_num) |
| `f_base_discount_ton` | Decimal(18, 6) | 基础折扣吨数 (来源 c) |
| `f_promotion_discount` | Decimal(18, 6) | 促销金额 (计算: c.f_promotion_discount * a.f_num) |
| `f_promotion_discount_ton` | Decimal(18, 6) | 促销吨数 (来源 c) |
| `f_sale_amount` | Decimal(18, 6) | 销售金额 |
| `f_total_amount` | Decimal(18, 6) | 挂牌销售金额 |
| `f_manufacture_cost_ton` | Decimal(18, 6) | 单吨制造费用 (取 d 或 d1 表) |
| `f_manufacture_cost_amt` | Decimal(18, 6) materialized f_manufacture_cost_ton * f_num | 制造成本(金额)=制造吨成本*数量 |
| `f_package_cost_ton` | Decimal(18, 6) | 单吨包装费用 (逻辑判断后的最终值) |
| `f_package_cost_amt` | Decimal(18, 6) materialized f_package_cost_ton * f_num | 包装成本(金额)=包装吨成本*数量 |
| `f_package_cost_ton_now` | Decimal(18, 6) | 实时包装费 (取 d2.f_package_ton_price，销售则为0) |
| `f_formula_cost_ton1` | Decimal(18, 6) | 非实时配方成本 (取 d 或 d1 表) |
| `f_formula_cost_ton` | Nullable(Decimal(18, 6)) | 实时配方成本 (取 d2.f_formula_price，自产实时) |
| `f_formula_cost_amt` | Decimal(18, 6) materialized f_formula_cost_ton * f_num | 配方成本(金额)=配方吨成本*数量 |
| `f_material_cost_ton` | Decimal(18, 6) materialized f_package_cost_ton + f_formula_cost_ton | 总材料成本(吨)=包装吨成本+配方吨成本 |
| `f_material_cost_amt` | Decimal(18, 6) materialized f_material_cost_ton * f_num | 总材料成本(金额)=总材料吨成本*数量 |
| `f_cost_ton` | Decimal(18, 6) | 实时总单吨成本 (逻辑: 代工用存储成本 vs 自产用实时配方+包材+制造) |
| `f_cost_amount` | Decimal(18, 6) | 订单实时成本 (计算: toDecimal128(f_cost_ton,3)*toDecimal128(a.f_num,3)) |
| `f_cost_amount1` | Decimal(18, 6) | 非实时成本金额 (计算: d 或 d1 表的 f_cost_ton * 数量) |
| `f_cost_ton1` | Decimal(18, 6) | 非实时总单吨成本 (取 d 或 d1 表) |
| `f_stock_price` | Decimal(18, 6) | 当月实时结存成本 |
| `f_rebate_ton` | Decimal(18, 6) | 单吨返利金额 (逻辑: 年返 vs 月返 vs 0) |
| `f_rebate_amount` | Decimal(18, 6) | 返利金额 (计算: f_rebate_ton * a.f_num) |
| `f_discount_total` | Decimal(18, 6) materialized f_discount_amount + f_rebate_amount | 总折扣=折扣+返利 |
| `f_rebate_ton_mth` | Decimal(18, 6) | 单吨月返利金额 |
| `f_profit_amount` | Decimal(18, 6) | 毛利 (计算: f_sale_amount - f_cost_amount - f_rebate_amount) |
| `f_profit_ton_adjust` | Decimal(18, 6) materialized multiIf(f_num = 0, 0, toDecimal128(f_profit_amount_adjust, 6) /
                                                                               toDecimal128(f_num, 3)) | 单吨毛利校准 |
| `f_profit_ton` | Decimal(18, 6) materialized multiIf(f_num = 0, 0, toDecimal128(f_profit_amount, 6) /
                                                                               toDecimal128(f_num, 3)) | 单吨毛利 |
| `f_profit_amount_adjust` | Decimal(18, 6) materialized multiIf((production_mode = '代工') AND (f_stock_price = 0), 0,
                                                                 (production_mode = '自产') AND
                                                                 (f_formula_cost_ton = 0), 0,
                                                                 f_profit_amount) | 毛利校准：代工存储成本为0 ，自产配方成本为0 毛利均设为0 |
| `supply_time_id_vdef11` | String | 供货周期ID |
| `supply_time_name` | String | 供货周期名称 |
| `delivery_id_vbdef19` | String | 配送方式ID |
| `delivery_name` | String | 配送方式名称 |
| `strategy_id` | String | 销售策略ID |
| `strategy_name` | String | 销售策略名称 |
| `policy_id_vbdef20` | String | 价格政策ID |
| `policy_code` | String | 价格政策编码 |
| `policy_name` | String | 价格政策名称 |
| `billtype_id` | FixedString(20) | 单据类型ID |
| `billtype_code` | String | 单据类型编码 |
| `billtype_neme` | String | 单据类型名称 |
| `channeltype_id` | FixedString(20) | 渠道类型ID |
| `channeltype_code` | String | 渠道类型编码 |
| `channeltype_name` | String | 渠道类型名称 |
| `discount_id` | String | 折扣方案ID |
| `manager_id` | FixedString(20) | 负责人ID |
| `manager_code` | String | 负责人编码 |
| `manager_name` | String | 负责人名称 |
| `areaman_id` | FixedString(20) | 区域经理ID |
| `areaman_code` | String | 区域经理编码 |
| `areaman_name` | String | 区域经理名称 |
| `regionman_id` | FixedString(20) | 大区经理ID |
| `regionman_code` | String | 大区经理编码 |
| `regionman_name` | String | 大区经理名称 |
| `billmaker_id` | FixedString(20) | 制单人ID |
| `billmaker_code` | String | 制单人编码 |
| `billmaker_name` | String | 制单人名称 |
| `creator_id` | FixedString(20) | 创建人ID |
| `creator_code` | String | 创建人编码 |
| `creator_name` | String | 创建人名称 |
| `modifier_id` | String | 修改人ID |
| `modifier_code` | String | 修改人编码 |
| `modifier_name` | String | 修改人名称 |
| `ndiscountrate` | Decimal(18, 6) | 折扣率 |
| `npreceivemny` | Decimal(18, 6) | 应收金额 |
| `npreceivequota` | Decimal(18, 6) | 应收额度 |
| `npreceiverate` | Decimal(18, 6) | 回款率 |
| `nreceivedmny` | Decimal(18, 6) | 已收金额 |
| `ntotalnum` | Decimal(18, 6) | 总数量 |
| `ntotalorigmny` | Decimal(18, 6) | 原币总金额 |
| `ntotalorigsubmny` | Decimal(18, 6) | 原币折扣后金额 |
| `ntotalpiece` | Decimal(18, 6) | 总件数 |
| `ntotalvolume` | Decimal(18, 6) | 总体积 |
| `ntotalweight` | Decimal(18, 6) | 总重量 |
| `month_dt` | FixedString(7) | 业务月份YYYY-MM |
| `ts` | String | 修改时间戳 |
| `ts_char` | String | 修改时间戳字符 |

### dwd_so_profit_old
**层级**: DWD | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 167
**上游表**: dwd_so_cost, dwd_so_priceform, dwd_so_saleorder, dws_cust_rebate_actual_m, dws_product_subject_cost, v_dim_client
**CK内部依赖**: dwd_so_cost, dwd_so_priceform, dwd_so_saleorder, dws_cust_rebate_actual_m, dws_product_subject_cost

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `order_id` | FixedString(20) | 订单主键ID |
| `order_uid` | FixedString(20) | 订单唯一标识UID |
| `order_row` | String | 订单行号 |
| `d_bill_code` | String | 单据编号 |
| `is_gift` | String | 是否赠品标识 |
| `bill_ts_char` | String | 单据时间字符 |
| `bill_ts` | DateTime | 单据时间戳 |
| `bill_date` | Date | 单据日期 |
| `bill_year` | UInt16 materialized toYear(bill_ts) | 单据年份 |
| `client_class_flag` | String comment '内外部客户：0外 |  |
| `1内'` |  |  |
| `client_class_name` | String | 0：外部客户:，1：内部客户 |
| `client_dclass_code` | String | 客户明细分类编码 |
| `client_dclass_name` | String | 客户明细分类名称：K1 K2 K3 等 |
| `d_client_id` | FixedString(20) | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_salesman_id` | FixedString(20) | 业务员ID |
| `d_salesman_code` | String | 业务员编码 |
| `d_salesman_name` | String | 业务员名称 |
| `d_region_id` | FixedString(20) | 大区ID |
| `d_region_name` | String | 大区名称 |
| `d_corp_id` | FixedString(20) | 公司ID |
| `d_corp_vid` | FixedString(20) | 公司版本ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_dept_vid` | FixedString(20) | 部门版本ID |
| `d_dept_id` | FixedString(20) | 部门ID |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_stock_corp_id` | FixedString(20) | 库存组织ID |
| `d_stock_corp_code` | String | 库存组织编码 |
| `d_stock_corp_name` | String | 库存组织名称 |
| `d_stock_id` | FixedString(20) | 仓库ID |
| `d_stock_code` | String | 仓库编码 |
| `d_stock_name` | String | 仓库名称 |
| `d_salaera_id` | FixedString(20) | 销售片区ID |
| `d_town_id` | FixedString(20) | 乡镇ID |
| `d_town_code` | String | 乡镇编码 |
| `d_town_name` | String | 乡镇名称 |
| `supply_time_id_vdef11` | LowCardinality(String) | 供货周期ID |
| `supply_time_name` | LowCardinality(String) | 供货周期名称 |
| `delivery_id_vbdef19` | LowCardinality(String) | 配送方式ID |
| `delivery_name` | LowCardinality(String) | 配送方式名称 |
| `strategy_id` | LowCardinality(String) | 销售策略ID |
| `strategy_name` | LowCardinality(String) | 销售策略名称 |
| `d_material_id` | FixedString(20) | 物料ID |
| `d_material_code` | FixedString(10) | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_formula_id` | FixedString(20) | 配方ID |
| `d_formula_code` | String | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `d_prodline_id` | LowCardinality(String) | 产品线ID |
| `d_prodline_code` | LowCardinality(String) | 产品线编码 |
| `d_prodline_name` | LowCardinality(String) | 产品线名称 |
| `d_cinvclass_sid` | FixedString(20) | 物料分类SID |
| `d_class_code6` | String | 六级分类编码 |
| `d_class_name6` | String | 六级分类名称 |
| `d_cinvclassid` | FixedString(20) | 物料分类ID |
| `d_class_code4` | String | 四级分类编码 |
| `d_class_name4` | String | 四级分类名称 |
| `d_class_code2` | String | 二级分类编码 |
| `d_class_name2` | String | 二级分类名称 |
| `d_class_code1` | FixedString(1) | 一级分类编码 |
| `d_class_name1` | String | 一级分类名称 |
| `measdoc_id` | FixedString(20) | 主计量单位ID |
| `measdoc_name` | String | 主计量单位名称 |
| `f_num` | Decimal(18, 6) | 主数量 |
| `f_num_high` | Decimal(18, 6) materialized multiIf(empty(strategy_name) OR (strategy_name = '无'), 0, f_num) | 高价值销量（空或"无"时为0） |
| `f_sale_num` | Decimal(18, 6) materialized multiIf(is_gift = 'N', f_num, 0) | 销售数量（不含赠送） |
| `f_gift_num` | Decimal(18, 6) materialized multiIf(is_gift = 'Y', f_num, 0) | 赠送数量 |
| `second_measdoc_id` | FixedString(20) | 辅计量单位ID |
| `second_measdoc_name` | String | 辅计量单位名称 |
| `f_second_num` | Decimal(18, 6) | 辅数量 |
| `f_unitprice_intax` | Decimal(18, 6) | 含税单价 |
| `f_unitprice_extax` | Decimal(18, 6) | 不含税单价 |
| `f_discount_amount` | Decimal(18, 6) | 折扣金额 |
| `f_base_discount` | Decimal(18, 6) | 基础折扣金额（来源 dwd_so_priceform） |
| `f_base_discount_ton` | Decimal(18, 6) | 基础折扣吨数（来源 dwd_so_priceform） |
| `f_promotion_discount` | Decimal(18, 6) | 促销金额（来源 dwd_so_priceform） |
| `f_promotion_discount_ton` | Decimal(18, 6) | 促销吨数（来源 dwd_so_priceform） |
| `f_sale_amount` | Decimal(18, 6) | 销售金额（来源主表） |
| `f_sale_amount_high` | Decimal(18, 6) materialized multiIf(empty(strategy_name) OR (strategy_name = '无'), 0,
                                                                 f_sale_amount) | 高价值销售额（空或"无"时为0） |
| `f_total_amount` | Decimal(18, 6) | 挂牌销售金额（来源主表） |
| `f_cost_amount` | Decimal(18, 6) 'Y''即为买赠成本）' | 成本金额（来源 dwd_so_cost 其中is_gift= |
| `f_cost_ton` | Decimal(18, 6) | 成本吨数（来源 dwd_so_cost） |
| `f_profit_amount` | Decimal(18, 6)           default (f_sale_amount - f_cost_amount) - f_rebate_amount | 订单毛利润 |
| `creationtime` | String | 创建时间 |
| `dmakedate` | String | 制单日期 |
| `modifiedtime` | String | 修改时间 |
| `taudittime` | String | 审核时间 |
| `billtype_id` | FixedString(20) | 单据类型ID |
| `billtype_code` | String | 单据类型编码 |
| `billtype_neme` | String | 单据类型名称 |
| `channeltype_id` | FixedString(20) | 渠道类型ID |
| `channeltype_code` | String | 渠道类型编码 |
| `channeltype_name` | String | 渠道类型名称 |
| `policy_id_vbdef20` | LowCardinality(String) | 价格政策ID |
| `policy_code` | LowCardinality(String) | 价格政策编码 |
| `policy_name` | LowCardinality(String) | 价格政策名称 |
| `discount_id` | LowCardinality(String) | 折扣方案ID |
| `manager_id` | FixedString(20) | 负责人ID |
| `manager_code` | String | 负责人编码 |
| `manager_name` | String | 负责人名称 |
| `billmaker_id` | FixedString(20) | 制单人ID |
| `billmaker_code` | String | 制单人编码 |
| `billmaker_name` | String | 制单人名称 |
| `areaman_id` | FixedString(20) | 区域经理主键 |
| `areaman_code` | String | 区域经理编码 |
| `areaman_name` | String | 区域经理名称 |
| `regionman_id` | FixedString(20) | 大区经理主键 |
| `regionman_code` | String | 大区经理编码 |
| `regionman_name` | String | 大区经理名称 |
| `creator_id` | FixedString(20) | 创建人ID |
| `creator_code` | String | 创建人编码 |
| `creator_name` | String | 创建人名称 |
| `modifier_id` | LowCardinality(String) | 修改人ID |
| `modifier_code` | LowCardinality(String) | 修改人编码 |
| `modifier_name` | LowCardinality(String) | 修改人名称 |
| `ndiscountrate` | Decimal(18, 6) | 折扣率 |
| `npreceivemny` | Decimal(18, 6) | 应收金额 |
| `npreceivequota` | Decimal(18, 6) | 应收额度 |
| `npreceiverate` | Decimal(18, 6) | 回款率 |
| `nreceivedmny` | Decimal(18, 6) | 已收金额 |
| `ntotalnum` | Decimal(18, 6) | 总数量 |
| `ntotalorigmny` | Decimal(18, 6) | 原币总金额 |
| `ntotalorigsubmny` | Decimal(18, 6) | 原币折扣后金额 |
| `ntotalpiece` | Decimal(18, 6) | 总件数 |
| `ntotalvolume` | Decimal(18, 6) | 总体积 |
| `ntotalweight` | Decimal(18, 6) | 总重量 |
| `month_dt` | FixedString(7) | 业务月份YYYY-MM |
| `ts_char` | String | 修改时间戳字符 |
| `ts` | DateTime | 修改时间戳 |
| `f_rebate_ton` | Nullable(Decimal(18, 6)) default 0. | 单吨返利金额（按自然年均摊） |
| `f_rebate_amount` | Nullable(Decimal(18, 6)) default 0. | 返利金额（按自然年均摊） |
| `f_rebate_ton_mth` | Nullable(Decimal(18, 6)) default 0. | 单吨返利金额（按自然月均摊） |
| `is_corp_flag` | UInt8 | 0个人户·1公司户2内部客户 |
| `is_corp_name` | String | 公司户[内部客户]  个人户 公司户   个人户[港澳台]   个人户[海外护照]    公司户[服务机构]  未知 |
| `measure_ratio` | Decimal(18, 6) | 主单位/辅单位 换算率 |
| `d_client_type` | String | 纷享销客大客户类型：新增 提档 存量  |
| `d_client_level` | String | 纷享销客客户等级S A B C |
| `is_strategic` | String | 纷享销客真实大客户 |
| `is_strategic_flag` | String | 纷享销客大客户标记 1大客户 0不是大客户 |
| `is_high` | String                   default multiIf(empty(strategy_name) OR (strategy_name = '无'), 0, 1) | 是否高价值产品：1是 0否 |
| `f_discount_total` | Decimal(18, 6)           default f_discount_amount + f_rebate_amount | 总折扣 |
| `material_cost_ratio` | Decimal(18, 6)           default 0 | 材料成本占比（配方料 / 总成本） |
| `packaging_cost_ratio` | Decimal(18, 6)           default 0 | 包装袋成本占比（包装物 / 总成本） |
| `manufacture_cost_ratio` | Decimal(18, 6)           default 0 | 制造费用占比（制造费用 / 总成本） |
| `f_material_cost_ton` | Nullable(Decimal(18, 6)) default material_cost_ratio * f_cost_ton | 单吨材料费用 |
| `f_material_cost_amt` | Nullable(Decimal(18, 6)) default f_material_cost_ton * abs(f_num) | 材料费用 |
| `f_packaging_cost_ton` | Nullable(Decimal(18, 6)) default packaging_cost_ratio * f_cost_ton | 单吨包装袋费用 |
| `f_packaging_cost_amt` | Nullable(Decimal(18, 6)) default f_packaging_cost_ton * abs(f_num) | 包装袋费用 |
| `f_manufacture_cost_ton` | Nullable(Decimal(18, 6)) default manufacture_cost_ratio * f_cost_ton | 单吨制造费用 |
| `f_manufacture_cost_amt` | Nullable(Decimal(18, 6)) default f_manufacture_cost_ton * abs(f_num) | 制造费用 |
| `d_product_corp_id` | Nullable(FixedString(20)) | 生产公司ID |
| `d_product_corp_code` | String | 生产公司编码 |
| `d_product_corp_name` | String | 生产公司名称 |
| `formula_cost_ratio` | Nullable(Decimal(18, 6)) default 0 | 配方费用占比（配方费用 / 总成本） |
| `f_formula_cost_ton` | Nullable(Decimal(18, 6)) default formula_cost_ratio * f_cost_ton | 单吨配方费用 |
| `f_formula_cost_amt` | Nullable(Decimal(18, 6)) default f_formula_cost_ton * abs(f_num) | 配方费用 |
| `f_sale_num_high` | Decimal(18, 6) materialized multiIf(
            empty(strategy_name) OR (strategy_name = '无') OR (is_gift = 'Y'), 0,
            f_num) | 高价值销量（非高价值或赠品时为0） |
| `status_flag` | FixedString(1)           default '4' | 1=自由，2=审批通过，3=冻结，4=关闭，7=审批中，8=审批不通过，5=失效 |
| `d_profit_region_name` | String | 业绩归属大区名称 |
| `d_profit_corp_sname` | String | 业绩归属公司简称 |
| `d_profit_corp_code` | String | 业绩归属公司编码 |
| `d_profit_corp_id` | FixedString(20) | 业绩归属公司主键 |

### dwd_so_saleorder
**层级**: DWD | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 192
**上游表**: bd_billtype, bd_channeltype, bd_custclass, bd_customer, bd_custsale, bd_defdoc, bd_marbasclass, bd_material, bd_materialconvert, bd_measdoc 等19张
**底层数据源(Oracle)**: bd_billtype, bd_channeltype, bd_custclass, bd_customer, bd_custsale, bd_defdoc, bd_marbasclass, bd_material 等18张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `order_id` | FixedString(20) | 销售订单主表主键（csaleorderid） |
| `order_uid` | FixedString(20) | 销售订单行唯一主键（csaleorderbid） |
| `order_row` | String | 销售订单行号（crowno） |
| `d_bill_code` | String | 单据编号（vbillcode） |
| `is_gift` | String | 是否赠品：Y/N（blargessflag） |
| `bill_ts_char` | String | 单据日期字符（b.dbilldate） |
| `bill_ts` | DateTime materialized parseDateTimeBestEffort(bill_ts_char) | 单据时间（物化） |
| `bill_date` | Date materialized toDate(bill_ts) | 单据日期（物化） |
| `d_client_id` | FixedString(20) | 客户主键（ccustomerid） |
| `d_client_code` | String | 客户编码（bd_customer.code） |
| `d_client_name` | String | 客户名称（bd_customer.name） |
| `d_salesman_id` | FixedString(20) | 业务员主键（cemployeeid） |
| `d_salesman_code` | String | 业务员编码（bd_psndoc.code） |
| `d_salesman_name` | String | 业务员姓名（bd_psndoc.name） |
| `d_region_id` | FixedString(20) | 所属大区主键（vdef5） |
| `d_corp_id` | FixedString(20) | 销售组织主键（pk_org） |
| `d_corp_vid` | FixedString(20) | 销售组织版本主键（pk_org_v） |
| `d_corp_code` | String | 销售组织编码（org_corp.code） |
| `d_corp_name` | String | 销售组织名称（org_corp.name） |
| `d_corp_sname` | String | 销售组织简称（org_corp.shortname） |
| `d_product_corp_id` | FixedString(20) default dictGet('alphafeed.dim_material_dict', 'd_corp_id', d_material_id) |  |
| `d_product_corp_code` | String          default dictGet('alphafeed.dim_material_dict', 'd_corp_code', d_material_id) |  |
| `d_product_corp_name` | String          default dictGet('alphafeed.dim_material_dict', 'd_corp_name', d_material_id) |  |
| `d_dept_vid` | FixedString(20) | 部门版本主键（cdeptvid） |
| `d_dept_id` | FixedString(20) | 部门主键（cdeptid） |
| `d_dept_code` | String | 部门编码（org_dept_v.code） |
| `d_dept_name` | String | 部门名称（org_dept_v.name） |
| `d_stock_corp_id` | FixedString(20) | 发货仓库所属组织主键（csendstockorgid） |
| `d_stock_corp_code` | String | 发货仓库组织编码（org_stockorg.code） |
| `d_stock_corp_name` | String | 发货仓库组织名称（org_stockorg.name） |
| `d_stock_id` | FixedString(20) | 发货仓库主键（csendstordocid） |
| `d_stock_code` | String | 发货仓库编码（bd_stordoc.code） |
| `d_stock_name` | String | 发货仓库名称（bd_stordoc.name） |
| `d_salaera_id` | FixedString(20) | 销售区域主键（vdef4） |
| `d_town_id` | FixedString(20) | 聚焦镇主键（vdef3） |
| `d_town_code` | String | 聚焦镇编码 |
| `d_town_name` | String | 聚焦镇名称 |
| `supply_time_id_vdef11` | LowCardinality(String) | 供货时效主键（vdef11） |
| `supply_time_name` | LowCardinality(String) | 供货时效名称 |
| `delivery_id_vbdef19` | LowCardinality(String) | 提货方式主键（vbdef19） |
| `delivery_name` | LowCardinality(String) | 提货方式名称 |
| `strategy_id` | LowCardinality(String) | 战略分类主键（5+2，高价值产品，bd_material.def1） |
| `strategy_name` | LowCardinality(String) | 战略分类名称（5+2，高价值产品） |
| `d_material_vid` | FixedString(20) | 物料主键（cmaterialvid） |
| `d_material_code` | FixedString(10) | 物料编码（bd_material.code） |
| `d_material_name` | String | 物料名称（bd_material.name） |
| `d_formula_id` | FixedString(20) materialized dictGet('alphafeed.dim_formula_product_dict3', 'd_row_id',
                                                               d_material_id) | 配方主键 |
| `d_formula_code` | String materialized dictGet('alphafeed.dim_formula_product_dict3', 'd_row_code',
                                                      d_material_id) | 配方编码 |
| `d_formula_name` | String materialized dictGet('alphafeed.dim_formula_product_dict3', 'd_row_name',
                                                      d_material_id) | 配方名称 |
| `d_prodline_id` | LowCardinality(String) | 产品线主键（cprodlineid） |
| `d_prodline_code` | LowCardinality(String) | 产品线编码 |
| `d_prodline_name` | LowCardinality(String) | 产品线名称 |
| `product_tag_code` | Nullable(String) | 产品系列标签编码 |
| `product_tag` | Nullable(String) | 产品系列标签 |
| `d_cinvclass_sid` | FixedString(20) | 物料6级分类主键 |
| `d_class_code6` | String | 物料6级分类编码 |
| `d_class_name6` | String | 物料6级分类名称 |
| `d_cinvclassid` | FixedString(20) | 物料4级分类主键 |
| `d_class_code4` | String | 物料4级分类编码 |
| `d_class_name4` | String | 物料4级分类名称 |
| `d_class_code2` | String | 物料2级分类编码 |
| `d_class_name2` | String | 物料2级分类名称 |
| `d_class_code1` | FixedString(1) | 物料1级分类编码 |
| `d_class_name1` | String | 物料1级分类名称 |
| `measdoc_id` | FixedString(20) | 主计量单位主键 |
| `measdoc_name` | String | 主计量单位名称 |
| `second_measdoc_id` | FixedString(20) | 辅计量单位主键 |
| `second_measdoc_name` | String | 辅计量单位名称 |
| `f_num` | Decimal(18, 6) | 主数量 |
| `f_second_num` | Decimal(18, 6) | 辅数量 |
| `f_unitprice_intax` | Decimal(18, 6) | 含税单价 |
| `f_unitprice_extax` | Decimal(18, 6) | 无税单价 |
| `f_discount_amount` | Decimal(18, 6) | 折扣额 |
| `f_sale_amount` | Decimal(18, 6) | 销售金额 |
| `f_total_amount` | Decimal(18, 6) | 挂牌销售金额 |
| `creationtime` | String | 创建时间 |
| `dmakedate` | String | 制单日期 |
| `modifiedtime` | String | 最后修改时间 |
| `taudittime` | String | 审批时间 |
| `billtype_id` | FixedString(20) | 单据类型主键 |
| `billtype_code` | String | 单据类型编码 |
| `billtype_neme` | String | 单据类型名称 |
| `channeltype_id` | FixedString(20) | 销售渠道类型主键 |
| `channeltype_code` | String | 销售渠道类型编码 |
| `channeltype_name` | String | 销售渠道类型名称 |
| `policy_id_vbdef20` | LowCardinality(String) | 活动政策主键 |
| `policy_code` | LowCardinality(String) | 活动政策编码 |
| `policy_name` | LowCardinality(String) | 活动政策名称 |
| `discount_id` | LowCardinality(String) | 价格政策主键 |
| `manager_id` | FixedString(20) | 销售经理主键 |
| `manager_code` | String | 销售经理编码 |
| `manager_name` | String | 销售经理名称 |
| `areaman_id` | FixedString(20) | 区域经理主键 |
| `areaman_code` | String | 区域经理编码 |
| `areaman_name` | String | 区域经理名称 |
| `regionman_id` | FixedString(20) | 大区经理主键 |
| `regionman_code` | String | 大区经理编码 |
| `regionman_name` | String | 大区经理名称 |
| `billmaker_id` | FixedString(20) | 制单人主键 |
| `billmaker_code` | String | 制单人编码 |
| `billmaker_name` | String | 制单人名称 |
| `creator_id` | FixedString(20) | 创建人主键 |
| `creator_code` | String | 创建人编码 |
| `creator_name` | String | 创建人名称 |
| `modifier_id` | LowCardinality(String) | 修改人主键 |
| `modifier_code` | LowCardinality(String) | 修改人编码 |
| `modifier_name` | LowCardinality(String) | 修改人名称 |
| `approver_id` | FixedString(20) | 审批人主键 |
| `approver_code` | String | 审批人编码 |
| `approver_name` | String | 审批人名称 |
| `creviser_id` | LowCardinality(String) | 修订人主键 |
| `busiflow_id` | FixedString(20) | 业务流程主键 |
| `cinvoicecustid` | FixedString(20) | 开票客户主键 |
| `corigcurrencyid` | FixedString(20) | 原币币种主键 |
| `ctradewordid` | LowCardinality(String) | 贸易术语主键 |
| `ctransporttypeid` | LowCardinality(String) | 运输方式主键 |
| `adress_vdef1` | String | 地址 |
| `phone_vdef2` | String | 电话 |
| `cargoods_vdef17` | LowCardinality(String) | 随车物品 |
| `card_no_vdef21` | LowCardinality(String) | 身份证号 |
| `aeraid_vdef22` | LowCardinality(String) | 市场区域 |
| `note` | String | 付款备注 |
| `carno_id` | LowCardinality(String) | 车牌号主键 |
| `goodsweight` | LowCardinality(String) | 货物重量 |
| `drivername` | LowCardinality(String) | 司机姓名 |
| `driverphone` | LowCardinality(String) | 司机电话 |
| `cfreecustid` | LowCardinality(String) | 散户主键 |
| `fpfstatusflag` | String | 发票状态 |
| `status_flag` | String | 单据状态:1=自由，2=审批通过，3=冻结，4=关闭，7=审批中，8=审批不通过，5=失效， |
| `iprintcount` | LowCardinality(String) | 打印次数 |
| `iversion` | Int32 | 版本号 |
| `ndiscountrate` | Decimal(18, 6) | 折扣率 |
| `npreceivemny` | Decimal(18, 6) | 预收金额 |
| `npreceivequota` | Decimal(18, 6) | 预收额度 |
| `npreceiverate` | Decimal(18, 6) | 预收比例 |
| `nreceivedmny` | Decimal(18, 6) | 已收金额 |
| `ntotalnum` | Decimal(18, 6) | 总数量 |
| `ntotalorigmny` | Decimal(18, 6) | 总原币金额 |
| `ntotalorigsubmny` | Decimal(18, 6) | 总原币税额 |
| `ntotalpiece` | Decimal(18, 6) | 总件数 |
| `ntotalvolume` | Decimal(18, 6) | 总体积 |
| `ntotalweight` | Decimal(18, 6) | 总重量 |
| `vcooppohcode` | LowCardinality(String) | 协同采购单号 |
| `vcreditnum` | LowCardinality(String) | 信用编号 |
| `vnote` | LowCardinality(String) | 备注 |
| `vrevisereason` | LowCardinality(String) | 修订原因 |
| `vtrantypecode` | String | 交易类型编码 |
| `cbillsrcid` | LowCardinality(String) | 来源单据主键 |
| `vbillsrctype` | String | 来源单据类型 |
| `carsubtypeid` | LowCardinality(String) | 车辆子类型主键 |
| `chreceivecustid` | FixedString(20) | 收货客户主键 |
| `nlrgtotalorigmny` | Decimal(18, 6) | 大额原币金额 |
| `custbank_accpk` | LowCardinality(String) | 客户银行账户子户主键 |
| `custbank_pk` | LowCardinality(String) | 客户开户银行主键 |
| `badvfeeflag` | FixedString(1) | 是否预提费用 |
| `barsettleflag` | FixedString(1) | 是否结算 |
| `bcooptopoflag` | FixedString(1) | 是否协同 |
| `bcostsettleflag` | FixedString(1) | 是否成本结算 |
| `bfreecustflag` | FixedString(1) | 是否散户 |
| `binvoicendflag` | FixedString(1) | 是否已开票 |
| `boffsetflag` | FixedString(1) | 是否冲抵 |
| `boutendflag` | FixedString(1) | 是否出库完成 |
| `bpocooptomeflag` | FixedString(1) | 是否采购协同 |
| `bpreceiveflag` | FixedString(1) | 是否预收 |
| `bsendendflag` | FixedString(1) | 是否发货完成 |
| `submission_num_vdef12` | LowCardinality(String) | 签呈编号 |
| `settlement_id` | LowCardinality(String) | 结算方式主键 |
| `cpaytermid` | LowCardinality(String) | 付款条件主键 |
| `is_vdef10` | LowCardinality(String) | 枚举扩展字段 |
| `pk_group` | FixedString(20) | 集团主键 |
| `trevisetime` | LowCardinality(String) | 修订时间 |
| `dr` | String | 逻辑删除标记：0=有效 |
| `month_dt` | FixedString(7) | 单据月份（YYYY-MM，用于分区） |
| `ts_char` | String | NC 最后更新时间戳字符 |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 更新时间（物化） |
| `client_class_flag` | String comment '内外部客户：0外 |  |
| `1内'` |  |  |
| `client_class_name` | String | 0：外部客户:，1：内部客户 |
| `client_dclass_code` | String | 客户明细分类编码 |
| `client_dclass_name` | String | 客户明细分类名称：K1 K2 K3 等 |
| `bill_year` | UInt16 materialized toYear(bill_ts) | 单据年份（无符号整型） |
| `f_sale_amount_high` | Decimal(18, 6) materialized multiIf(empty(strategy_name) OR (strategy_name = '无'), 0,
                                                              f_sale_amount) | 高价值销售额（空或"无"时为0） |
| `f_num_high` | Decimal(18, 6) materialized multiIf(empty(strategy_name) OR (strategy_name = '无'), 0, f_num) | 高价值销量（空或"无"时为0） |
| `f_sale_num` | Decimal(18, 6) materialized multiIf(is_gift = 'N', f_num, 0) | 销售数量（不含赠送） |
| `f_gift_num` | Decimal(18, 6) materialized multiIf(is_gift = 'Y', f_num, 0) | 赠送数量 |
| `d_material_id` | Nullable(FixedString(20)) | 物料主键 |
| `is_corp_flag` | UInt8 | 0个人户·1公司户2内部客户 |
| `measure_ratio` | Decimal(18, 6) | 主单位/辅单位 换算率 |
| `d_profit_region_name` | String          default dictGet('alphafeed.dim_unit_dict', 'd_region_name', d_profit_corp_id) | 业绩归属大区名称 |
| `d_profit_corp_id` | String | 业绩归属公司主键 |
| `d_profit_corp_code` | String | 业绩归属公司编码 |
| `d_profit_corp_sname` | String | 业绩归属公司简称 |

### v_dwd_po_order_detail
**层级**: DWD | **工作流**: - | **字段数**: 50
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_bill_code` | String |  |
| `d_order_id` | FixedString(20) |  |
| `d_order_b_id` | FixedString(20) |  |
| `is_basis` | String |  |
| `order_status` | String |  |
| `contract_type` | String |  |
| `is_pay_close` | String |  |
| `is_closed` | String |  |
| `row_no` | String |  |
| `d_order_type_name` | String |  |
| `d_order_owner_name` | String |  |
| `d_delivery_method` | String |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_short_name` | String |  |
| `d_supplier_id` | FixedString(20) |  |
| `d_supplier_code` | String |  |
| `d_supplier_name` | String |  |
| `d_supplier_class_id` | FixedString(20) |  |
| `d_material_id` | FixedString(20) |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `d_material_type` | String |  |
| `measdoc_id` | FixedString(20) |  |
| `measdoc_name` | String |  |
| `d_class_id` | FixedString(20) |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_pay_term_name` | String |  |
| `d_pay_point_name` | String |  |
| `f_order_qty` | Decimal(18, 6) |  |
| `f_unit_price` | Decimal(18, 6) |  |
| `f_freight_amt` | Decimal(18, 6) |  |
| `f_payment_days` | Decimal(18, 6) |  |
| `order_dt_char` | String |  |
| `plan_arrv_dt_char` | String |  |
| `creation_ts_char` | String |  |
| `order_dt` | DateTime |  |
| `plan_arrv_dt` | DateTime |  |
| `creation_ts` | DateTime |  |
| `month_dt` | String |  |
| `ts` | String |  |
| `ts_dt` | DateTime |  |
| `d_material_vid` | FixedString(20) |  |
| `dr` | FixedString(1) |  |
| `dr_a` | FixedString(1) |  |
| `is_latest_version` | FixedString(1) |  |

### v_dwd_so_saleorder
**层级**: DWD | **工作流**: - | **字段数**: 50
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `data_type` | String |  |
| `data_flag` | String |  |
| `month_dt` | String |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_profit_region_name` | String |  |
| `d_profit_corp_id` | String |  |
| `d_profit_corp_code` | String |  |
| `d_profit_corp_sname` | String |  |
| `d_material_id` | Nullable(FixedString(20)) |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `product_tag` | String |  |
| `d_class_code4` | String |  |
| `d_class_name4` | String |  |
| `d_class_code6` | String |  |
| `d_class_name6` | String |  |
| `client_class_flag` | String |  |
| `d_client_id` | String |  |
| `d_client_code` | String |  |
| `d_client_name` | String |  |
| `d_salesman_id` | String |  |
| `d_salesman_code` | String |  |
| `d_salesman_name` | String |  |
| `d_bill_code` | String |  |
| `is_gift` | String |  |
| `f_sale_amount` | Decimal(38, 6) |  |
| `f_total_amount` | Decimal(38, 6) |  |
| `f_num` | Decimal(38, 6) |  |
| `f_sale_num` | Decimal(38, 6) |  |
| `f_gift_num` | Decimal(38, 6) |  |
| `f_sale_second_num` | Decimal(38, 6) |  |
| `f_discount_amount` | Decimal(38, 6) |  |
| `f_base_discount` | Decimal(38, 6) |  |
| `f_base_discount_ton` | Decimal(38, 6) |  |
| `f_promotion_discount` | Decimal(38, 6) |  |
| `f_promotion_discount_ton` | Decimal(38, 6) |  |
| `f_cost_num` | Decimal(38, 6) |  |
| `f_cost_amount` | Decimal(38, 6) |  |
| `f_cost_amount1` | Decimal(38, 6) |  |
| `f_gift_cost_amount` | Decimal(38, 6) |  |
| `f_adjust_cost_amount` | Decimal(38, 6) |  |
| `f_cost_ton` | Decimal(38, 6) |  |
| `d_billtype_code` | String |  |
| `d_billtype_name` | String |  |
| `f_rebate_amt` | Decimal(38, 6) |  |
| `f_rebate_qty` | Decimal(38, 6) |  |
| `f_payout_amt` | Decimal(38, 6) |  |

---

## DWS层（汇总层）- 8张表

### dws_cust_rebate_actual_m
**层级**: DWS | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 21
**上游表**: dwd_cust_rebate_actual_m, dwd_so_saleorder
**CK内部依赖**: dwd_cust_rebate_actual_m, dwd_so_saleorder

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `month_dt` | FixedString(7) |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_client_id` | FixedString(20) |  |
| `d_client_code` | String |  |
| `d_client_name` | String |  |
| `d_material_id` | FixedString(20) |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `f_rebate_amt_year` | Decimal(18, 6) default 0. |  |
| `f_rebate_num_year` | Decimal(18, 6) default 0. |  |
| `f_rebate_ton_year` | Decimal(18, 6) default 0. |  |
| `f_rebate_amt_mth` | Decimal(18, 6) default 0. |  |
| `f_rebate_num_mth` | Decimal(18, 6) default 0. |  |
| `f_rebate_ton_mth` | Decimal(18, 6) default 0. |  |
| `f_rebate_special_amt_year` | Decimal(18, 6) default 0. | 特殊奖年返利金额（35-Cxx-01 部分35-Cxx-06） |
| `f_rebate_special_ton_year` | Decimal(18, 6) default 0. | 特殊奖年均单吨返利金额（35-Cxx-01 部分35-Cxx-06） |
| `f_rebate_special_amt_mth` | Decimal(18, 6) default 0. | 特殊奖月返利金额（35-Cxx-01 部分35-Cxx-06） |
| `f_rebate_special_ton_mth` | Decimal(18, 6) default 0. | 特殊奖月均单吨返利金额（35-Cxx-01 部分35-Cxx-06） |

### dws_formula_product_day
**层级**: DWS | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 35
**上游表**: dim_formula_product_day_snap, dws_ia_material_day_stock
**CK内部依赖**: dim_formula_product_day_snap, dws_ia_material_day_stock

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_product_id` | FixedString(20) | 成品主键 |
| `d_product_code` | FixedString(10) | 成品编码 |
| `d_product_name` | String | 成品名称 |
| `d_product_measure` | String | 成品计量单位 |
| `d_product_type` | String | 成品型号 |
| `d_formula_id` | FixedString(20) | 配方主键 |
| `d_formula_code` | FixedString(10) | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `d_formula_measure` | String | 配方计量单位 |
| `d_formula_type` | String | 配方型号 |
| `f_ratio_num` | Decimal(18, 6) | 配方子项数量合计：一般为1000 |
| `f_parent_num` | Decimal(18, 6) | 父项主数量 |
| `f_formula_amount` | Decimal(18, 6) | 配方实时金额：sum(配方原料比例*原料实时价格) |
| `f_formula_price` | Decimal(18, 6) | 配方实时价格：金额/父项主数量 |
| `d_package_id` | FixedString(20) | 包装袋主键 |
| `d_package_code` | FixedString(10) | 包装袋编码 |
| `d_package_name` | String | 包装袋名称 |
| `f_package_ton_num` | Int32 | 单吨包装袋需要的数量 |
| `f_package_price` | Decimal(18, 6) | 单条包装袋价格 |
| `f_package_ton_price` | Decimal(18, 6) | 单吨包装袋价格 |
| `formula_date` | FixedString(19) | 配方制单日期 |
| `start_date` | FixedString(19) | 生效日期 |
| `end_date` | FixedString(19) | 失效日期 |
| `creationtime` | FixedString(19) | 创建日期 |
| `creator` | String | 创建人 |
| `modifiedtime` | FixedString(19) | 修改日期 |
| `modifier` | String | 修改人 |
| `updt` | Date | 更新日期：年月日分区字段依据 |
| `d_brand_id` | FixedString(20) | 品牌主键 |
| `d_brand_code` | String | 品牌编码 |
| `d_brand_name` | String | 品牌 |

### dws_fr_cg_kcgzb
**层级**: DWS | **工作流**: 1job-nc_sal_profit | **字段数**: 85
**上游表**: cg_kcgzb
**底层数据源(Oracle)**: cg_kcgzb

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `biz_dt` | Date | 业务日期 |
| `gsbm` | String | 公司编码 |
| `gsmc` | String | 公司名称 |
| `sjwlflbm` | String | 上级物料分类编码 |
| `sjwlflmc` | String | 上级物料分类名称 |
| `wlflbm` | String | 物料分类编码 |
| `wlflmc` | String | 物料分类名称 |
| `wlsx` | String | 物料属性 |
| `wlbk` | String | 物料板块 |
| `wlbm` | String | 物料编码 |
| `wlmc` | String | 物料名称 |
| `gsjc` | String | 供应商简称 |
| `cgsl` | Decimal(18, 4) | 采购数量 |
| `cgsl15` | Decimal(18, 4) | 15天内采购数量 |
| `cgsl30` | Decimal(18, 4) | 30天内采购数量 |
| `rksl` | Decimal(18, 4) | 入库数量 |
| `syrk` | Decimal(18, 4) | 上月入库 |
| `byrk` | Decimal(18, 4) | 本月入库 |
| `jrrk` | Decimal(18, 4) | 今日入库 |
| `zrrk` | Decimal(18, 4) | 昨日入库 |
| `rksl10` | Decimal(18, 4) | 10天内入库 |
| `rksl15` | Decimal(18, 4) | 15天内入库 |
| `rksl20` | Decimal(18, 4) | 20天内入库 |
| `rksl30` | Decimal(18, 4) | 30天内入库 |
| `cksl` | Decimal(18, 4) | 出库数量 |
| `jrck` | Decimal(18, 4) | 今日出库 |
| `zrck` | Decimal(18, 4) | 昨日出库 |
| `byck` | Decimal(18, 4) | 本月出库 |
| `jqck90` | Decimal(18, 4) | 近90天出库 |
| `jqck30` | Decimal(18, 4) | 近30天出库 |
| `jqck20` | Decimal(18, 4) | 近20天出库 |
| `jqck10` | Decimal(18, 4) | 近10天出库 |
| `syck` | Decimal(18, 4) | 上月出库 |
| `qntqck` | Decimal(18, 4) | 去年同期出库 |
| `dsyck` | Decimal(18, 4) | 当日出库 |
| `jqztsl` | Decimal(18, 4) | 近期在途数量 |
| `jqztsl15` | Decimal(18, 4) | 15天内在途 |
| `jqztsl30` | Decimal(18, 4) | 30天内在途 |
| `wlztsl30` | Decimal(18, 4) | 物料在途30天 |
| `mryl30` | Decimal(18, 4) | 每日用量30天平均 |
| `mryl20` | Decimal(18, 4) | 每日用量20天平均 |
| `mryl` | Decimal(18, 4) | 每日用量 |
| `mryl10` | Decimal(18, 4) | 每日用量10天平均 |
| `cgje` | Decimal(18, 4) | 采购金额 |
| `cgje15` | Decimal(18, 4) | 15天内采购金额 |
| `cgje30` | Decimal(18, 4) | 30天内采购金额 |
| `yf` | Decimal(18, 4) | 运费 |
| `rkje` | Decimal(18, 4) | 入库金额 |
| `rkjehyf` | Decimal(18, 4) | 入库金额（含运费） |
| `byrkje` | Decimal(18, 4) | 本月入库金额 |
| `jrrkje` | Decimal(18, 4) | 今日入库金额 |
| `byrkje15` | Decimal(18, 4) | 本月15天内入库金额 |
| `byrkje30` | Decimal(18, 4) | 本月30天内入库金额 |
| `jqztje` | Decimal(18, 4) | 近期在途金额 |
| `jqztje15` | Decimal(18, 4) | 15天内在途金额 |
| `jqztje30` | Decimal(18, 4) | 30天内在途金额 |
| `cgdj` | Decimal(18, 4) | 采购单价 |
| `rkdj` | Decimal(18, 4) | 入库单价 |
| `rkdjhyf` | Decimal(18, 4) | 入库单价（含运费） |
| `jqztdj` | Decimal(18, 4) | 近期在途单价 |
| `jqztdj15` | Decimal(18, 4) | 15天内在途单价 |
| `jqztdj30` | Decimal(18, 4) | 30天内在途单价 |
| `jqztdj1` | Decimal(18, 4) | 在途单价1 |
| `jqztdja` | Decimal(18, 4) | 在途单价A |
| `jqztdj15a` | Decimal(18, 4) | 在途单价15A |
| `jqztdj30a` | Decimal(18, 4) | 在途单价30A |
| `jrjc` | Decimal(18, 4) | 今日结存 |
| `ll_jrjc` | Decimal(18, 4) | 来料加工-今日结存 |
| `plc_jrjc` | Decimal(18, 4) | 配料仓-今日结存 |
| `qcjc` | Decimal(18, 4) | 期初结存数量 |
| `qcjcdj` | Decimal(18, 4) | 期初结存单价 |
| `qcjcje` | Decimal(18, 4) | 期初结存金额 |
| `jcsl` | Decimal(18, 4) | 结存数量 |
| `jcdj` | Decimal(18, 4) | 结存单价 |
| `jcje` | Decimal(18, 4) | 结存金额 |
| `ysyl` | Decimal(18, 4) | 预算用量 |
| `ysyl15` | Decimal(18, 4) | 预算用量15 |
| `aqts` | Decimal(18, 4) | 安全天数 |
| `ycsl` | Decimal(18, 4) | 预出数量 |
| `zxbj` | Decimal(18, 4) | 最新报价 |
| `qksl` | Decimal(18, 4) | 欠款数量 |
| `qkje` | Decimal(18, 4) | 欠款金额 |
| `ycjj` | Decimal(18, 4) | 预存价格 |
| `corp_id` | Nullable(FixedString(20)) | 公司主键 |
| `material_id` | Nullable(FixedString(20)) | 物料主键 |

### dws_ia_material_day_stock
**层级**: DWS | **工作流**: 2-2sub-dws_ia_material_day_stock | **字段数**: 61
**上游表**: dwd_ia_monthnab_snap, dwd_ic_flow, dwd_so_cost, v_dwd_po_order_detail
**CK内部依赖**: dwd_ia_monthnab_snap, dwd_ic_flow, dwd_so_cost

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_name` | String | 区域名称（来自 dim_unit_dict.d_region_name） |
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_busi_status` | String | 公司经营状态（来自 dim_unit_dict） |
| `d_corp_code` | String | 公司编码（来自 dim_unit_dict） |
| `d_corp_name` | String | 公司全称（来自 dim_unit_dict） |
| `d_corp_sname` | String | 公司简称（来自 dim_unit_dict） |
| `d_material_id` | FixedString(20) | 物料主键 |
| `d_material_code` | String | 物料编码（来自 dim_material_dict） |
| `d_material_name` | String | 物料名称（来自 dim_material_dict） |
| `d_class_code1` | String | 物料大类编码（1级，来自 dim_material_dict） |
| `d_class_name1` | String | 物料大类名称（1级，来自 dim_material_dict） |
| `measdoc_name` | String | 主计量单位名称（来自 dim_material_dict.measure_name） |
| `f_day_price` | Decimal(18, 6) | 当日加权单价 = f_amt / f_qty |
| `f_stock_price` | Decimal(18, 6) | 成本结转单：最近半年最近一个月数据 |
| `f_opening_price` | Decimal(18, 6) | 当月期初成本 |
| `f_opening_qty` | Decimal(18, 6) | 当月起初数量 |
| `f_day_qty` | Decimal(18, 6) | 当日期末库存数量（期初 + 净出入库） |
| `f_day_amt` | Decimal(18, 6) | 当日库存金额 = f_day_price * f_day_qty |
| `f_po_inbound_mth_qty` | Decimal(18, 6) | 本月采购入库数量（累计） |
| `f_po_inbound_mth_amt` | Decimal(18, 6) | 本月采购入库金额（累计） |
| `f_material_outbound_mth_qty` | Decimal(18, 6) | 本月材料出库数量（累计） |
| `f_material_outbound_mth_amt` | Decimal(18, 6) | 本月材料出库金额（=数量 * f_day_price） |
| `f_inbound_mth_qty` | Decimal(18, 6) | 本月总入库数量（不含转库入库） |
| `f_inbound_mth_amt` | Decimal(18, 6) | 本月总入库金额（=数量 * f_day_price） |
| `f_outbound_mth_qty` | Decimal(18, 6) | 本月总出库数量（不含转库出库） |
| `f_outbound_mth_amt` | Decimal(18, 6) | 本月总出库金额（=数量 * f_day_price） |
| `f_inbound_mth_flow` | Decimal(18, 6) | 本月入库流水总量（含转库） |
| `f_outbound_mth_flow` | Decimal(18, 6) | 本月出库流水总量（含转库） |
| `f_other_inbound_qty` | Decimal(18, 6) | 其他入库 |
| `f_other_inbound_mth_amt` | Decimal(18, 6) | 其他入库金额 |
| `f_other_outbound_qty` | Decimal(18, 6) | 其他出库 |
| `f_other_outbound_mth_amt` | Decimal(18, 6) | 其他出库金额 |
| `f_po_inbound_qty_today` | Decimal(18, 6) | 当日采购入库数量 |
| `f_po_inbound_amt_today` | Decimal(18, 6) | 当日采购入库金额 |
| `f_material_outbound_qty_today` | Decimal(18, 6) | 当日材料出库数量 |
| `f_material_outbound_amt_today` | Decimal(18, 6) | 当日材料出库金额（=数量 * f_day_price） |
| `f_inbound_qty_today` | Decimal(18, 6) | 当日总入库数量（不含转库） |
| `f_inbound_amt_today` | Decimal(18, 6) | 当日总入库金额（=数量 * f_day_price） |
| `f_outbound_qty_today` | Decimal(18, 6) | 当日总出库数量（不含转库） |
| `f_outbound_amt_today` | Decimal(18, 6) | 当日总出库金额（=数量 * f_day_price） |
| `f_inbound_flow_today` | Decimal(18, 6) | 当日入库流水总量 |
| `f_outbound_flow_today` | Decimal(18, 6) | 当日出库流水总量 |
| `f_daywill_qty` | Decimal(18, 6) | 当日可得数量 = f_day_qty + f_transit30d_qty1 |
| `f_daywill_price` | Decimal(18, 6) | 当日可得加权单价 |
| `f_daywill_amt` | Decimal(18, 6) | 当日可得金额 = f_day_amt + f_transit30d_amt |
| `f_order_qty1` | Decimal(18, 6) | 关联采购订单总数量 |
| `f_order_amt1` | Decimal(18, 6) | 关联采购订单总金额（不含运费） |
| `f_order_price` | Decimal(18, 6) | 采购订单平均单价 |
| `f_receipt_qty1` | Decimal(18, 6) | 已到货数量 |
| `f_transit_qty1` | Decimal(18, 6) | 总在途数量（未到货） |
| `f_transit_amt` | Decimal(18, 6) | 在途金额（=数量 * 订单单价） |
| `f_transit_price` | Decimal(18, 6) | 在途平均单价 |
| `f_transit30d_qty1` | Decimal(18, 6) | 30天内预计到货在途数量 |
| `f_transit30d_amt` | Decimal(18, 6) | 30天内在途金额 |
| `f_transit30d_price` | Decimal(18, 6) | 30天内在途平均单价 |
| `f_receipt_rate` | Decimal(18, 6) | 订单到货率 = 已到货 / 订单总量 |
| `month_dt` | String 'YYYY-MM''' | 业务月份，格式  |
| `bill_ts` | DateTime | 最后交易流水时间（max(bill_ts) from dwd_ic_flow） |
| `ts` | DateTime       default now() | 数据写入时间（用于 ReplacingMergeTree 版本控制） |
| `bill_dt` | Date | 业务日期（物化，用于日分区） |
| `measure_ratio` | Decimal(18, 6) default dictGet('alphafeed.dim_material_dict', 'measure_ratio', d_material_id) |  |

### dws_oa_cg_wlbj
**层级**: DWS | **工作流**: 1job-nc_sal_profit | **字段数**: 15
**上游表**: dwd_oa_cg_wlbj
**CK内部依赖**: dwd_oa_cg_wlbj

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_id` | FixedString(20) |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_material_id` | FixedString(20) |  |
| `d_material_code` | String |  |
| `d_material_name` | String |  |
| `f_price_ton` | Decimal(12, 4) |  |
| `f_price_ton_avg30` | Decimal(12, 4) |  |
| `f_price_ton_avg365` | Decimal(12, 4) |  |
| `f_price_ton_avg` | Decimal(12, 4) |  |
| `f_price_ton_avgall` | Decimal(12, 4) |  |
| `biz_dt` | Date |  |
| `updt` | Date |  |

### dws_product_subject_cost
**层级**: DWS | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 136
**上游表**: dwd_product_subject_cost
**CK内部依赖**: dwd_product_subject_cost

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | String | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_product_id` | String | 成本对象主键 |
| `d_product_code` | String | 成本对象编码 |
| `d_product_name` | String | 成本对象名称 |
| `d_product_measure` | String | 计量单位名称 |
| `d_product_spec` | String | 材料规格 |
| `d_product_type` | String | 材料型号 |
| `f_product_sum12_qty` | Decimal(18, 6) | 产成品/配方产量 |
| `f_cost_01_total` | Decimal(18, 6) | 01 制造费用 总成本 |
| `f_cost_01_unit` | Decimal(18, 6) | 01 制造费用 单位成本 |
| `f_cost_0101_total` | Decimal(18, 6) | 0101 水费 总成本 |
| `f_cost_0101_unit` | Decimal(18, 6) | 0101 水费 单位成本 |
| `f_cost_0102_total` | Decimal(18, 6) | 0102 电费 总成本 |
| `f_cost_0102_unit` | Decimal(18, 6) | 0102 电费 单位成本 |
| `f_cost_010201_total` | Decimal(18, 6) | 010201 用量电费（变动） 总成本 |
| `f_cost_010201_unit` | Decimal(18, 6) | 010201 用量电费（变动） 单位成本 |
| `f_cost_010202_total` | Decimal(18, 6) | 010202 基本电费（固定） 总成本 |
| `f_cost_010202_unit` | Decimal(18, 6) | 010202 基本电费（固定） 单位成本 |
| `f_cost_0103_total` | Decimal(18, 6) | 0103 经营物料 总成本 |
| `f_cost_0103_unit` | Decimal(18, 6) | 0103 经营物料 单位成本 |
| `f_cost_0104_total` | Decimal(18, 6) | 0104 维修费 总成本 |
| `f_cost_0104_unit` | Decimal(18, 6) | 0104 维修费 单位成本 |
| `f_cost_0105_total` | Decimal(18, 6) | 0105 燃料费用 总成本 |
| `f_cost_0105_unit` | Decimal(18, 6) | 0105 燃料费用 单位成本 |
| `f_cost_0106_total` | Decimal(18, 6) | 0106 人工费用 总成本 |
| `f_cost_0106_unit` | Decimal(18, 6) | 0106 人工费用 单位成本 |
| `f_cost_010601_total` | Decimal(18, 6) | 010601 工资和薪金 总成本 |
| `f_cost_010601_unit` | Decimal(18, 6) | 010601 工资和薪金 单位成本 |
| `f_cost_01060101_total` | Decimal(18, 6) | 01060101 生产工资 总成本 |
| `f_cost_01060101_unit` | Decimal(18, 6) | 01060101 生产工资 单位成本 |
| `f_cost_01060102_total` | Decimal(18, 6) | 01060102 仓储工资 总成本 |
| `f_cost_01060102_unit` | Decimal(18, 6) | 01060102 仓储工资 单位成本 |
| `f_cost_01060103_total` | Decimal(18, 6) | 01060103 叉车工资 总成本 |
| `f_cost_01060103_unit` | Decimal(18, 6) | 01060103 叉车工资 单位成本 |
| `f_cost_01060104_total` | Decimal(18, 6) | 01060104 劳务工资 总成本 |
| `f_cost_01060104_unit` | Decimal(18, 6) | 01060104 劳务工资 单位成本 |
| `f_cost_010602_total` | Decimal(18, 6) | 010602 住房公积金 总成本 |
| `f_cost_010602_unit` | Decimal(18, 6) | 010602 住房公积金 单位成本 |
| `f_cost_010603_total` | Decimal(18, 6) | 010603 绩效工资及奖金 总成本 |
| `f_cost_010603_unit` | Decimal(18, 6) | 010603 绩效工资及奖金 单位成本 |
| `f_cost_01060301_total` | Decimal(18, 6) | 01060301 生产绩效 总成本 |
| `f_cost_01060301_unit` | Decimal(18, 6) | 01060301 生产绩效 单位成本 |
| `f_cost_01060302_total` | Decimal(18, 6) | 01060302 仓储绩效 总成本 |
| `f_cost_01060302_unit` | Decimal(18, 6) | 01060302 仓储绩效 单位成本 |
| `f_cost_01060303_total` | Decimal(18, 6) | 01060303 叉车绩效 总成本 |
| `f_cost_01060303_unit` | Decimal(18, 6) | 01060303 叉车绩效 单位成本 |
| `f_cost_01060304_total` | Decimal(18, 6) | 01060304 劳务绩效 总成本 |
| `f_cost_01060304_unit` | Decimal(18, 6) | 01060304 劳务绩效 单位成本 |
| `f_cost_010604_total` | Decimal(18, 6) | 010604 职工福利金 总成本 |
| `f_cost_010604_unit` | Decimal(18, 6) | 010604 职工福利金 单位成本 |
| `f_cost_010605_total` | Decimal(18, 6) | 010605 离职补贴 总成本 |
| `f_cost_010605_unit` | Decimal(18, 6) | 010605 离职补贴 单位成本 |
| `f_cost_010606_total` | Decimal(18, 6) | 010606 社保费 总成本 |
| `f_cost_010606_unit` | Decimal(18, 6) | 010606 社保费 单位成本 |
| `f_cost_01060601_total` | Decimal(18, 6) | 01060601 养老保险 总成本 |
| `f_cost_01060601_unit` | Decimal(18, 6) | 01060601 养老保险 单位成本 |
| `f_cost_01060602_total` | Decimal(18, 6) | 01060602 医疗保险 总成本 |
| `f_cost_01060602_unit` | Decimal(18, 6) | 01060602 医疗保险 单位成本 |
| `f_cost_01060603_total` | Decimal(18, 6) | 01060603 工伤保险 总成本 |
| `f_cost_01060603_unit` | Decimal(18, 6) | 01060603 工伤保险 单位成本 |
| `f_cost_01060604_total` | Decimal(18, 6) | 01060604 生育保险 总成本 |
| `f_cost_01060604_unit` | Decimal(18, 6) | 01060604 生育保险 单位成本 |
| `f_cost_01060605_total` | Decimal(18, 6) | 01060605 失业保险 总成本 |
| `f_cost_01060605_unit` | Decimal(18, 6) | 01060605 失业保险 单位成本 |
| `f_cost_0107_total` | Decimal(18, 6) | 0107 差旅培训费 总成本 |
| `f_cost_0107_unit` | Decimal(18, 6) | 0107 差旅培训费 单位成本 |
| `f_cost_010701_total` | Decimal(18, 6) | 010701 差旅费 总成本 |
| `f_cost_010701_unit` | Decimal(18, 6) | 010701 差旅费 单位成本 |
| `f_cost_010702_total` | Decimal(18, 6) | 010702 通讯费 总成本 |
| `f_cost_010702_unit` | Decimal(18, 6) | 010702 通讯费 单位成本 |
| `f_cost_010703_total` | Decimal(18, 6) | 010703 员工培训 总成本 |
| `f_cost_010703_unit` | Decimal(18, 6) | 010703 员工培训 单位成本 |
| `f_cost_0108_total` | Decimal(18, 6) | 0108 搬运费用 总成本 |
| `f_cost_0108_unit` | Decimal(18, 6) | 0108 搬运费用 单位成本 |
| `f_cost_010801_total` | Decimal(18, 6) | 010801 叉车费用 总成本 |
| `f_cost_010801_unit` | Decimal(18, 6) | 010801 叉车费用 单位成本 |
| `f_cost_010802_total` | Decimal(18, 6) | 010802 搬运费 总成本 |
| `f_cost_010802_unit` | Decimal(18, 6) | 010802 搬运费 单位成本 |
| `f_cost_0109_total` | Decimal(18, 6) | 0109 折旧费 总成本 |
| `f_cost_0109_unit` | Decimal(18, 6) | 0109 折旧费 单位成本 |
| `f_cost_0110_total` | Decimal(18, 6) | 0110 实验费等其他 总成本 |
| `f_cost_0110_unit` | Decimal(18, 6) | 0110 实验费等其他 单位成本 |
| `f_cost_011001_total` | Decimal(18, 6) | 011001 实验费 总成本 |
| `f_cost_011001_unit` | Decimal(18, 6) | 011001 实验费 单位成本 |
| `f_cost_011002_total` | Decimal(18, 6) | 011002 其他 总成本 |
| `f_cost_011002_unit` | Decimal(18, 6) | 011002 其他 单位成本 |
| `f_cost_0111_total` | Decimal(18, 6) | 0111 劳务费 总成本 |
| `f_cost_0111_unit` | Decimal(18, 6) | 0111 劳务费 单位成本 |
| `f_cost_0112_total` | Decimal(18, 6) | 0112 环保费 总成本 |
| `f_cost_0112_unit` | Decimal(18, 6) | 0112 环保费 单位成本 |
| `f_cost_011201_total` | Decimal(18, 6) | 011201 电费 总成本 |
| `f_cost_011201_unit` | Decimal(18, 6) | 011201 电费 单位成本 |
| `f_cost_011202_total` | Decimal(18, 6) | 011202 折旧费 总成本 |
| `f_cost_011202_unit` | Decimal(18, 6) | 011202 折旧费 单位成本 |
| `f_cost_011203_total` | Decimal(18, 6) | 011203 物料支出 总成本 |
| `f_cost_011203_unit` | Decimal(18, 6) | 011203 物料支出 单位成本 |
| `f_cost_0113_total` | Decimal(18, 6) | 0113 房屋及设备租金 总成本 |
| `f_cost_0113_unit` | Decimal(18, 6) | 0113 房屋及设备租金 单位成本 |
| `f_cost_0114_total` | Decimal(18, 6) | 0114 待摊费用摊销 总成本 |
| `f_cost_0114_unit` | Decimal(18, 6) | 0114 待摊费用摊销 单位成本 |
| `f_cost_0115_total` | Decimal(18, 6) | 0115 无形资产摊销费 总成本 |
| `f_cost_0115_unit` | Decimal(18, 6) | 0115 无形资产摊销费 单位成本 |
| `f_cost_0116_total` | Decimal(18, 6) | 0116 使用权资产折旧费 总成本 |
| `f_cost_0116_unit` | Decimal(18, 6) | 0116 使用权资产折旧费 单位成本 |
| `f_cost_02_total` | Decimal(18, 6) | 02 材料费用 总成本 |
| `f_cost_02_unit` | Decimal(18, 6) | 02 材料费用 单位成本 |
| `f_cost_0201_total` | Decimal(18, 6) | 0201 配方料 总成本 |
| `f_cost_0201_unit` | Decimal(18, 6) | 0201 配方料 单位成本 |
| `f_cost_0202_total` | Decimal(18, 6) | 0202 添加剂料 总成本 |
| `f_cost_0202_unit` | Decimal(18, 6) | 0202 添加剂料 单位成本 |
| `f_cost_0203_total` | Decimal(18, 6) | 0203 包装物 总成本 |
| `f_cost_0203_unit` | Decimal(18, 6) | 0203 包装物 单位成本 |
| `f_cost_0204_total` | Decimal(18, 6) | 0204 回机料 总成本 |
| `f_cost_0204_unit` | Decimal(18, 6) | 0204 回机料 单位成本 |
| `f_cost_0205_total` | Decimal(18, 6) | 0205 回粉 总成本 |
| `f_cost_0205_unit` | Decimal(18, 6) | 0205 回粉 单位成本 |
| `f_cost_0206_total` | Decimal(18, 6) | 0206 原料 总成本 |
| `f_cost_0206_unit` | Decimal(18, 6) | 0206 原料 单位成本 |
| `f_cost_total` | Decimal(38, 6) materialized ifNull(f_cost_01_total, toDecimal32(0, 6)) +
                                                       ifNull(f_cost_02_total, toDecimal32(0, 6)) | 总成本 |
| `biz_mth` | String comment '更新时间:YYYY-MM -1个月 |  |
| `即业务日期比更新日期延迟一个月'` |  |  |
| `d_corp_sname` | Nullable(String) | 生产公司简称 |
| `biz_mth1` | String materialized formatDateTime(
            addMonths(parseDateTimeBestEffort(concat(biz_mth, '-01')), 1), '%Y-%m') | 业务月份 = 原始月份 + 1 |
| `hit_months` | String | 命中的最近三个月份（没有用最新月份填），成本单价就是这三个月份的加权平均 |
| `f_cost_unit` | Decimal(18, 6) materialized f_cost_01_unit + f_cost_02_unit | 单吨成本 |
| `f_cost_formula_unit` | Decimal(18, 6) materialized f_cost_02_unit - f_cost_0203_unit | 单吨配方成本（除包装袋） |
| `f_cost_packaging_unit` | Decimal(18, 6) materialized f_cost_0203_unit | 单吨包装袋成本 |
| `f_cost_formula_cost` | Decimal(18, 6) materialized f_cost_02_total - f_cost_0203_total | 配方成本（除包装袋） |
| `f_cost_packaging_cost` | Decimal(18, 6) materialized f_cost_0203_total | 包装袋成本 |
| `f_cost_material_unit` | Decimal(18, 6) materialized f_cost_02_unit | 单吨材料成本（配方+包装袋） |
| `f_cost_material_cost` | Decimal(18, 6) materialized f_cost_02_total | 材料成本（配方+包装袋） |
| `manufacture_cost_ratio` | Decimal(18, 6) materialized ifNull(f_cost_01_total, 0) / f_cost_total | 制造费用占比（制造费用 / 总成本） |
| `material_cost_ratio` | Decimal(18, 6) default ifNull(f_cost_formula_cost, 0) / f_cost_total | 材料成本占比（配方料成本 / 总成本） |
| `packaging_cost_ratio` | Decimal(18, 6) materialized ifNull(f_cost_0203_total, 0) / f_cost_total | 包装袋成本占比（包装物成本 / 总成本） |

### dws_sal_so_saleorder
**层级**: DWS | **工作流**: - | **字段数**: 106
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `order_pk` | String |  |
| `order1_pk` | String |  |
| `order_row` | String |  |
| `bill_code` | String |  |
| `bill_neme` | String |  |
| `gift_flag` | String |  |
| `billts` | String |  |
| `billdate` | String |  |
| `billmonth` | String |  |
| `billyear` | String |  |
| `first_order_date` | String |  |
| `material_pk` | String |  |
| `material_code` | String |  |
| `material_name` | String |  |
| `prodline_code` | String |  |
| `prodline_name` | String |  |
| `material_spec` | String |  |
| `strategy_name` | String |  |
| `product_name` | String |  |
| `class_code1` | String |  |
| `class_name1` | String |  |
| `class_code2` | String |  |
| `class_name2` | String |  |
| `class_code4` | String |  |
| `class_name4` | String |  |
| `class_code6` | String |  |
| `class_name6` | String |  |
| `num` | Float64 |  |
| `num_dongbao` | Float64 |  |
| `num_siliao` | Float64 |  |
| `num_high` | Float64 |  |
| `measure` | String |  |
| `second_num` | Float64 |  |
| `second_measure` | String |  |
| `unitprice_intax` | Float64 |  |
| `unitprice_extax` | Float64 |  |
| `discount_amount` | Float64 |  |
| `sale_amount` | Float64 |  |
| `sale_amount_dongbao` | Float64 |  |
| `sale_amount_siliao` | Float64 |  |
| `sale_amount_high` | Float64 |  |
| `ntotalorigmny` | Float64 |  |
| `total_amount` | Float64 |  |
| `cost_amount` | Float64 |  |
| `client_pk` | String |  |
| `client_code` | String |  |
| `client_name` | String |  |
| `general_flag` | Float64 |  |
| `general_name` | String |  |
| `custclass_flag` | Float64 |  |
| `custclass_name` | String |  |
| `client_dclass_code` | String |  |
| `client_dclass_name` | String |  |
| `region_code` | String |  |
| `region_name` | String |  |
| `corpbusi_name` | String |  |
| `corp_pk` | String |  |
| `corp_code` | String |  |
| `corp_name` | String |  |
| `corp_vpk` | String |  |
| `unitbusi_name` | String |  |
| `unit_pk` | String |  |
| `original_unit_code` | String |  |
| `original_unit_name` | String |  |
| `unit_code` | String |  |
| `unit_name` | String |  |
| `unit_sname` | String |  |
| `unit_lname` | String |  |
| `dept_vpk` | String |  |
| `dept_pk` | String |  |
| `dept_code` | String |  |
| `dept_name` | String |  |
| `town_pk` | String |  |
| `town_name` | String |  |
| `stock_pk` | String |  |
| `stock_code` | String |  |
| `stock_name` | String |  |
| `salesman_pk` | String |  |
| `salesman_code` | String |  |
| `salesman_name` | String |  |
| `areaman_name` | String |  |
| `regionman_name` | String |  |
| `manager_name` | String |  |
| `submission_num` | String |  |
| `cargo_num` | String |  |
| `policy_pk` | String |  |
| `policy_code` | String |  |
| `policy_name` | String |  |
| `vbillcode` | String |  |
| `vcooppohcode` | String |  |
| `creationtime` | String |  |
| `modifiedtime` | String |  |
| `billmaker_name` | String |  |
| `modifier_name` | String |  |
| `creator_name` | String |  |
| `busiflow_name` | String |  |
| `vnote` | String |  |
| `remarks` | String |  |
| `supply_time` | String |  |
| `vdef21_id` | String |  |
| `dr` | Float64 |  |
| `ts` | String |  |
| `tsdate` | String |  |
| `updtime` | String |  |
| `base_discount` | String |  |
| `promotion_discount` | String |  |

### dws_so_costsharing
**层级**: DWS | **工作流**: 1-1job-dwd_so_saleorder | **字段数**: 27
**上游表**: bd_billtype, bd_customer, bd_defdoc, bd_material, ia_iabill, ia_iabill_b, org_costregion, org_dept, org_financeorg
**底层数据源(Oracle)**: bd_billtype, bd_customer, bd_defdoc, bd_material, ia_iabill, ia_iabill_b, org_costregion, org_dept 等9张

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | FixedString(20) | 公司主键 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_corp_sname` | String | 公司简称 |
| `d_profit_corp_id` | FixedString(20) | 业绩归属公司主键 |
| `d_profit_corp_code` | String | 业绩归属公司编码 |
| `d_profit_corp_sname` | String | 业绩归属公司简称 |
| `d_profit_region_name` | String default dictGet('alphafeed.dim_unit_dict', 'd_region_name', d_profit_corp_id) | 业绩归属大区名称 |
| `d_dept_id` | String | 部门主键 |
| `d_dept_code` | String | 部门编码 |
| `d_dept_name` | String | 部门名称 |
| `d_material_id` | FixedString(20) | 物料主键 |
| `d_material_code` | String | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `d_billtype_id` | FixedString(20) | 单据类型主键 |
| `d_billtype_code` | String | 单据类型编码 |
| `d_billtype_name` | String | 单据类型名称 |
| `client_class` | String | 客户分类(经销商/养户等) |
| `custclass_flag` | String | 客户性质(0外部客户 1内部客户) |
| `d_client_id` | String | 客户主键 |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `bill_code` | String | 出库调整单据号 |
| `f_costsharing_amt` | Decimal(18, 6) | 调整分摊金额 |
| `bill_date_char` | String | 业务日期 |
| `bill_date` | Date materialized toDate(bill_date_char) | 版本时间戳 |
| `month_dt` | String | 分区 |

---

## ADS层（应用层）- 1张表

### ads_sales_profit_contribution_snap
**层级**: ADS | **工作流**: 1job-nc_sal_profit | **字段数**: 86
**上游表**: dim_fact_row_price_snap, dim_formula_product_dictpack, dwd_cust_rebate_actual_m, dwd_price_maintenance_snap, dwd_so_profit, dws_product_subject_cost
**CK内部依赖**: dim_fact_row_price_snap, dim_formula_product_dictpack, dwd_cust_rebate_actual_m, dwd_price_maintenance_snap, dwd_so_profit, dws_product_subject_cost

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_region_name` | String | 所属区域名称 |
| `d_corp_id` | String | 公司ID |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_town_id` | String | 所属乡镇ID |
| `d_town_name` | String | 所属乡镇名称 |
| `d_client_id` | String | 客户ID |
| `d_client_code` | String | 客户编码 |
| `d_client_name` | String | 客户名称 |
| `d_class_code2` | String | 产品二级分类编码 |
| `d_class_name2` | String | 产品二级分类名称 |
| `d_class_code4` | String | 产品四级分类编码 |
| `d_class_name4` | String | 产品四级分类名称 |
| `d_class_code6` | String | 产品六级分类编码 |
| `d_class_name6` | String | 产品六级分类名称 |
| `d_product_id` | String | 产品ID |
| `d_product_code` | String | 产品编码 |
| `d_product_name` | String | 产品名称 |
| `d_measure_name` | String | 计量单位 |
| `d_formula_id` | String | 配方ID |
| `d_formula_code` | String | 配方编码 |
| `d_formula_name` | String | 配方名称 |
| `f_sale_qty` | Decimal(18, 6) | 本月销量 |
| `f_sale_gift_qty` | Decimal(18, 6) | 本月赠送数量 |
| `f_rebate_qty` | Decimal(18, 6) | 本月返利数量 |
| `f_list_sale_amt` | Decimal(18, 6) | 本月挂牌销售金额 |
| `f_sale_amt` | Decimal(18, 6) | 本月实际销售金额 |
| `f_discount_amt` | Decimal(18, 6) | 本月总折扣金额 |
| `f_base_discount_amt` | Decimal(18, 6) | 本月基础折扣金额（负转正） |
| `f_prm_discount_amt` | Decimal(18, 6) | 本月促销折扣金额（负转正） |
| `f_rebate_amt` | Decimal(18, 6) | 本月返利金额 |
| `f_cost_amt` | Decimal(18, 6) | 本月成本金额（含赠送） |
| `f_list_sale_ton` | Decimal(18, 6) | 本月单吨挂牌价 = 挂牌金额 / 销量 |
| `f_discount_ton` | Decimal(18, 6) | 本月单吨总折扣 = 折扣金额 / 销量 |
| `f_base_discount_ton` | Decimal(18, 6) | 本月单吨基础折扣 = 基础折扣 / 销量 |
| `f_prm_discount_ton` | Decimal(18, 6) | 本月单吨促销折扣 = 促销折扣 / 销量 |
| `f_rebate_ton` | Decimal(18, 6) | 本月单吨返利 = 返利金额 / 返利数量 |
| `f_gift_cost_ton` | Decimal(18, 6) | 本月买赠成本 = (制造+材料成本)*赠送数量 |
| `f_total_dicount_ton` | Decimal(18, 6) | 本月单吨总折扣 = 买赠+返利+现金折扣（加权） |
| `f_sale_qty_year` | Decimal(18, 6) | 今年累计销量（1-本月） |
| `f_sale_gift_qty_year` | Decimal(18, 6) | 今年累计赠送数量 |
| `f_rebate_qty_year` | Decimal(18, 6) | 今年累计返利数量 |
| `f_list_sale_amt_year` | Decimal(18, 6) | 今年累计挂牌销售金额 |
| `f_sale_amt_year` | Decimal(18, 6) | 今年累计销售金额 |
| `f_discount_amt_year` | Decimal(18, 6) | 今年累计折扣金额 |
| `f_base_discount_amt_year` | Decimal(18, 6) | 今年累计基础折扣金额（负转正） |
| `f_prm_discount_amt_year` | Decimal(18, 6) | 今年累计促销折扣金额（负转正） |
| `f_rebate_amt_year` | Decimal(18, 6) | 今年累计返利金额 |
| `f_cost_amt_year` | Decimal(18, 6) | 今年累计成本金额（含赠送） |
| `f_list_sale_year_ton` | Decimal(18, 6) | 今年单吨挂牌价 = 挂牌金额 / 销量 |
| `f_discount_year_ton` | Decimal(18, 6) | 今年单吨总折扣 = 折扣金额 / 销量 |
| `f_base_discount_year_ton` | Decimal(18, 6) | 今年单吨基础折扣 = 基础折扣 / 销量 |
| `f_prm_discount_year_ton` | Decimal(18, 6) | 今年单吨促销折扣 = 促销折扣 / 销量 |
| `f_rebate_year_ton` | Decimal(18, 6) | 今年单吨返利 = 返利金额 / 返利数量 |
| `f_gift_cost_year_ton` | Decimal(18, 6) | 今年买赠成本 = (制造+材料成本)*赠送数量 |
| `f_total_dicount_year_ton` | Decimal(18, 6) | 今年单吨总折扣 = 买赠+返利+现金折扣（加权） |
| `f_sale_qty_lastyear` | Decimal(18, 6) | 去年同期销量（上年1-8月） |
| `f_list_sale_amt_lastyear` | Decimal(18, 6) | 去年同期挂牌销售金额 |
| `f_sale_amt_lastyear` | Decimal(18, 6) | 去年同期销售金额 |
| `f_discount_amt_lastyear` | Decimal(18, 6) | 去年同期折扣金额 |
| `f_base_discount_amt_lastyear` | Decimal(18, 6) | 去年同期基础折扣金额（负转正） |
| `f_prm_discount_amt_lastyear` | Decimal(18, 6) | 去年同期促销折扣金额（负转正） |
| `f_cost_amt_lastyear` | Decimal(18, 6) | 去年同期成本金额（含赠送） |
| `f_list_sale_lastyear_ton` | Decimal(18, 6) | 去年单吨挂牌价 = 挂牌金额 / 销量 |
| `f_discount_lastyear_ton` | Decimal(18, 6) | 去年单吨总折扣 = 折扣金额 / 销量 |
| `f_base_discount_lastyear_ton` | Decimal(18, 6) | 去年单吨基础折扣 = 基础折扣 / 销量 |
| `f_prm_discount_lastyear_ton` | Decimal(18, 6) | 去年单吨促销折扣 = 促销折扣 / 销量 |
| `f_formula_cost_ton` | Decimal(18, 6) | 综合单吨配方成本：最新/在途/库存加权 |
| `f_formula_latest_cost_ton` | Decimal(18, 6) | 单吨最新报价配方成本 |
| `f_formula_stock_cost_ton` | Decimal(18, 6) | 单吨库存价格配方成本 |
| `f_formula_transit_cost_ton_avg30` | Decimal(18, 6) | 单吨30天在途平均价格配方成本 |
| `d_packaging_id` | String | 包装袋主键 |
| `d_packaging_code` | String | 包装袋编码 |
| `d_packaging_name` | String | 包装袋名称 |
| `d_packaging_measure` | String | 包装袋计量单位 |
| `f_packaging_num_ton` | Decimal(18, 6) | 包装袋单吨用量 |
| `f_product_price_ton` | Decimal(18, 6) | 各公司产品定价（单吨） |
| `f_factory_cost_ton` | Decimal(18, 6) | 单吨成品制造成本（人工、折旧等） |
| `f_material_cost_ton` | Decimal(18, 6) | 单吨配方材料成本 |
| `f_manufacturing_cost_baseline_ton` | Decimal(18, 6) | 制造成本标准基线（默认0） |
| `f_manufacturing_cost_ton_diff` | Decimal(18, 6) | 制造成本差异（默认0） |
| `f_gross_profit_ton_computed` | Decimal(18, 6) | 计算毛利额/吨（默认0） |
| `f_gross_profit_red_line` | Decimal(18, 6) | 毛利红线（默认0） |
| `f_standard_sale_amt_ton` | Decimal(18, 6) | 标准销售收入/吨（默认0） |
| `f_baseline_discount_ton` | Decimal(18, 6) | 基准折扣/吨（默认0） |
| `uuiq_id` | FixedString(66) ,
    month_dt                          String ,
    d_formula_source                  Nullable(String) ,
    f_packaging_cost_ton              Nullable(Decimal(18, 4)) ,
    d_channel_name                    Nullable(String) ,
    d_channel_id                      Nullable(FixedString(20)) | 主键: 拼接年月+公司+客户+产品形成全局唯一) |

---

## OTHER层（其他）- 8张表

### crm_sys_office
**层级**: OTHER | **工作流**: - | **字段数**: 38
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `id` | String | 编号 |
| `parent_id` | String | 父级编号 |
| `parent_ids` | String | 所有父级编号 |
| `name` | String | 名称 |
| `sort` | Decimal(10) | 排序 |
| `area_id` | Nullable(String) | 归属区域 |
| `code` | Nullable(String) | 区域编码 |
| `type` | FixedString(1) | 机构类型 |
| `grade` | FixedString(1) | 机构等级 |
| `org_functions` | Nullable(String) | 组织职能 |
| `address` | Nullable(String) | 联系地址 |
| `zip_code` | Nullable(String) | 邮政编码 |
| `master` | Nullable(String) | 负责人 |
| `phone` | Nullable(String) | 电话 |
| `fax` | Nullable(String) | 传真 |
| `email` | Nullable(String) | 邮箱 |
| `useable` | Nullable(String) | 是否启用 |
| `primary_person` | Nullable(String) | 主负责人 |
| `deputy_person` | Nullable(String) | 副负责人 |
| `create_by` | String | 创建者 |
| `create_date` | DateTime | 创建时间 |
| `update_by` | String | 更新者 |
| `update_date` | DateTime | 更新时间 |
| `remarks` | Nullable(String) | 备注信息 |
| `del_flag` | FixedString(1) default '0' | 删除标记 |
| `identifier` | Nullable(String) | 标识符 |
| `vsrcsys` | Nullable(String) | 来源系统 |
| `vsrcsyscode` | Nullable(String) | 来源系统编码 |
| `vsrcsysname` | Nullable(String) | 来源系统名称 |
| `vsrcsys_update_date` | Nullable(DateTime) | 来源系统更新时间 |
| `vsrcsysid` | Nullable(String) | 来源系统主键id |
| `vsrcsysparentid` | Nullable(String) | 来源系统父级id |
| `vsrcsysparentids` | Nullable(String) | 来源系统所有的上级id |
| `def1` | Nullable(String) | 自定义项目1 |
| `def2` | Nullable(String) | 自定义项目2 |
| `def3` | Nullable(String) | 自定义项目3 |
| `def4` | Nullable(String) | 自定义项目4 |
| `def5` | Nullable(String) | 自定义项目5 |

### dict_product_cost_ratio_dict
**层级**: OTHER | **工作流**: - | **字段数**: 5
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | String |  |
| `d_product_id` | String |  |
| `manufacture_cost_ratio` | Decimal(18, 6) |  |
| `material_cost_ratio` | Decimal(18, 6) |  |
| `packaging_cost_ratio` | Decimal(18, 6) |  |

### dict_product_cost_ratio_dict1
**层级**: OTHER | **工作流**: - | **字段数**: 4
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_product_id` | String |  |
| `manufacture_cost_ratio` | Decimal(18, 6) |  |
| `material_cost_ratio` | Decimal(18, 6) |  |
| `packaging_cost_ratio` | Decimal(18, 6) |  |

### fx_dim_client_dict
**层级**: OTHER | **工作流**: - | **字段数**: 20
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_id` | String |  |
| `d_client_id` | String |  |
| `d_region_id` | String |  |
| `d_region_code` | String |  |
| `d_region_name` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_client_code` | String |  |
| `d_client_name` | String |  |
| `d_client_type` | String |  |
| `d_client_level` | String |  |
| `is_strategic` | String |  |
| `is_strategic_flag` | String |  |
| `f_budget_qty` | Decimal(18, 6) |  |
| `f_forecast_qty` | Decimal(18, 6) |  |
| `dr` | String |  |
| `ts` | DateTime |  |
| `this_year` | UInt16 |  |
| `insert_ts` | DateTime |  |

### nc_wms_barcode
**层级**: OTHER | **工作流**: - | **字段数**: 26
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `pk_corp` | FixedString(20) | 发码公司 |
| `pk_invcl` | String | 物料分类ID |
| `pk_inv` | FixedString(20) | 物料ID |
| `unit_id` | String | 计量单位 |
| `print_batch` | Int64 | 硬刷批次 |
| `code_mode` | String | 发码方式(1=发码后子印刷，2=包材供应商硬刷) |
| `pkg_supplier_id` | String | 包材供应商 |
| `coder_id` | String | 发码人 |
| `coding_time_char` | String | 发码时间时间戳字符 |
| `coding_time` | DateTime materialized parseDateTimeBestEffort(coding_time_char) | 发码时间时间戳（物化，用于查询过滤） |
| `barcode_type` | String | 条码类型 |
| `barcode` | String | 条码 |
| `barcode_status` | String | 条码状态 |
| `void_time` | String | 作废时间 |
| `voider_id` | String | 作废人 |
| `print_times` | Int64 | 打印次数 |
| `last_pt_time` | String | 最后打印时间 |
| `last_pt_id` | String | 最后打印人 |
| `export_times` | Int64 | 导出次数 |
| `last_export_time` | String | 最后导出时间 |
| `last_exporter_id` | String | 最后导出人 |
| `dr` | Int64 | 删除标记 |
| `ts_char` | String | 修改时间戳 |
| `batch_code` | Nullable(String) default NULL | 发码批次号 |
| `ts` | DateTime materialized parseDateTimeBestEffort(ts_char) | 修改时间戳（物化，用于查询过滤） |
| `month_dt` | String 'YYYY-MM''（来自 SUBSTR(dbilldate, 1, 7)）' | 分区字段，格式  |

### rpt_forecast_sale_num
**层级**: OTHER | **工作流**: 3job-FRdata | **字段数**: 16
**上游表**: yc_xsjh
**底层数据源(Oracle)**: yc_xsjh

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `month_dt` | String | 预测销量年月 |
| `d_corp_code` | String | 公司编码 |
| `d_corp_name` | String | 公司名称 |
| `d_product_code` | String | 产品编码 |
| `d_product_name` | String | 产品名称 |
| `d_product_corp_code` | String | 生产公司名称 |
| `d_product_corp_name` | String | 生产公司编码 |
| `delete_flag` | String | 删除标记 |
| `d_area_name` | String | 区域(部门) |
| `f_fcst_num` | Decimal(18, 6) | 自产销量（吨） |
| `f_fcst_num2` | Decimal(18, 6) | 生产预测销量 |
| `f_fcst_out_num` | Decimal(18, 6) | 委外加工数量（吨） |
| `creat_name` | String | 填报人 |
| `creat_time` | String | 填报时间 |
| `ts` | DateTime default now() | 记录时间 |
| `uuid` | UInt32 | 全局唯一ID |

### tb_guidance_price
**层级**: OTHER | **工作流**: 3job-FRdata | **字段数**: 8
**上游表**: tb_guidance_price

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `d_corp_code` | String | 公司编码 |
| `d_corp_sname` | String | 公司简称 |
| `d_material_code` | String | 物料编码 |
| `d_material_name` | String | 物料名称 |
| `f_guidance_price` | Decimal(18, 4) | 采购原料指导价格 |
| `modifyer` | String | 修改人 |
| `modifytime_char` | String | 修改时间 |
| `modifytime` | DateTime materialized parseDateTimeBestEffort(modifytime_char) | 修改时间(标准化) |

### v_fx_client_forecast
**层级**: OTHER | **工作流**: - | **字段数**: 31
**血缘关系**: 未在workflow中定义（可能是字典表或独立表）

| 字段名 | 数据类型 | 注释 |
|--------|----------|------|
| `client_forecast_uid` | String |  |
| `d_region_name` | String |  |
| `d_dept_id` | String |  |
| `d_dept_code` | String |  |
| `d_dept_name` | String |  |
| `d_corp_id` | String |  |
| `d_corp_code` | String |  |
| `d_corp_name` | String |  |
| `d_corp_sname` | String |  |
| `d_area_id` | String |  |
| `d_area_name` | String |  |
| `d_client_id` | String |  |
| `d_client_code` | String |  |
| `d_client_name` | String |  |
| `d_client_type` | String |  |
| `is_strategic` | String |  |
| `is_strategic_flag` | String |  |
| `is_achieve` | Nullable(String) |  |
| `d_prodline_name` | String |  |
| `d_product_sub_name` | String |  |
| `f_budget_qty` | Decimal(18, 6) |  |
| `f_budget_qty_animal` | Decimal(18, 6) |  |
| `f_budget_qty_high` | Decimal(18, 6) |  |
| `f_forecast_qty` | Decimal(18, 6) |  |
| `f_forecast_qty_animal` | Decimal(18, 6) |  |
| `f_forecast_qty_high` | Decimal(18, 6) |  |
| `month_dt` | String |  |
| `this_year` | String |  |
| `dr` | String |  |
| `ts` | DateTime |  |
| `insert_ts` | DateTime |  |

---

## 统计

| 层级 | 表数量 | 说明 |
|------|--------|------|
| ODS | 2 | 贴源层 |
| DIM | 38 | 维度层 |
| DWD | 34 | 明细层 |
| DWS | 8 | 汇总层 |
| ADS | 1 | 应用层 |
| OTHER | 8 | 其他 |
| **总计** | **91** | |
| **总字段数** | **3709** | |