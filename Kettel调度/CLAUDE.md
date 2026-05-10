# Kettel 调度项目

## 项目概述
澳华集团 ETL 数据调度项目，使用 Kettle (Pentaho Data Integration) 从各业务系统抽取数据到报表数据库。

## 目录结构
```
kettel调度/
├── .kettle/                    # Kettle 项目配置
│   ├── kettle.properties       # 全局变量
│   └── shared.xml              # 共享数据库连接
├── 主入口.kjb                  # 主调度作业 (入口)
├── CRM/                        # CRM 系统数据
│   ├── CRM业务.kjb
│   └── *.ktr
├── OA/                         # OA 系统数据
│   ├── OA业务.kjb
│   ├── HR同步/
│   ├── 考勤管理/
│   ├── 品控类流程/
│   ├── 融资流程/
│   ├── 设备管理/
│   ├── 生产管理建模/
│   └── 试用人员管理/
├── 财务类/                     # 财务数据 (IPO成本等)
│   ├── IPO成本拆分.kjb
│   ├── JOB子流程/
│   ├── 大类拆分/
│   ├── 大类战略汇总/
│   └── 战略拆分/
├── 采购类/                     # 采购模块数据
│   ├── 采购模块每日更新.kjb
│   └── JOB子流程/
├── 档案类/                     # 基础档案数据
│   ├── 档案基础.kjb
│   ├── 转换/
│   └── 作业/
├── 生产类/                     # 生产数据
│   ├── 生产流程.kjb
│   ├── BOM.kjb
│   └── 代加工成本业务线新.kjb
└── 销售类/                     # 销售数据
    ├── 销售主表ETL/
    ├── 销售外表ETL/
    └── 销售对账单ETL/
└── CK数仓/                     # ClickHouse 数仓 ETL
    ├── CK数仓主入口.kjb        # 数仓主调度
    ├── 0dim-table_1h/          # DIM 维度层全量刷新
    ├── 1-1job-dwd_so_saleorder/ # 销售利润链
    ├── 1-2job-dim_formula_product_snap_1w/ # 配方产品快照
    ├── 1job-nc_sal_profit/     # 销售利润相关
    ├── 2job-nc_stock_1h/       # 库存链
    ├── 2-1job-dwd_ia_monthnab_snap/ # 月结存快照
    ├── 2-2sub-dws_ia_material_day_stock/ # 日库存汇总
    ├── 3job-FRdata/            # 帆软填报数据
    └── 4job-nc_fin/            # NC 财务数据
```

## 执行顺序

### 业务系统 ETL (主入口.kjb)
1. 档案基础数据 → 2. OA业务数据 → 3. 采购模块数据 → 4. 生产类数据 → 5. CRM业务数据 → 6. 财务类数据 → 7. 销售类数据

### CK 数仓 ETL (CK数仓主入口.kjb)
1. 0dim-table_1h (维度层) → 2. 1-2job-dim_formula_product_snap_1w (配方快照) → 3. 1-1job-dwd_so_saleorder (销售利润链) → 4. 1job-nc_sal_profit (销售利润) → 5. 2job-nc_stock_1h (库存链) → 6. 2-1job-dwd_ia_monthnab_snap (月结存) → 7. 2-2sub-dws_ia_material_day_stock (日库存) → 8. 3job-FRdata (帆软填报) → 9. 4job-nc_fin (财务)

## 主要数据库连接
- `finereport_fbdbuser` - 报表数据库 (Oracle)
- `nc65_ncread` - NC ERP 数据库 (Oracle)
- `ecology_ecology` - OA 泛微数据库
- `CRM-Master` - CRM 数据库

## 常用变量
- `${updtime}` - OA 模块更新时间
- `${cgupdtime}` - 采购模块更新时间
- `${CW_UPD_TIME}` - 财务模块更新时间
- `${Internal.Entry.Current.Directory}` - 当前作业目录
