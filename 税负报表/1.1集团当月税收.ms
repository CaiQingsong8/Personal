{
  "properties" : { },
  "id" : "2094c84549c642dd80f2f4fb7fdaf3dd",
  "script" : null,
  "groupId" : "aef38b24a7d54eb390a128d6b422e050",
  "name" : "1.1集团当月税收",
  "createTime" : null,
  "updateTime" : 1776938875369,
  "lock" : null,
  "createBy" : null,
  "updateBy" : "18838479803",
  "path" : "/groupMonthlyTax",
  "method" : "POST",
  "parameters" : [ ],
  "options" : [ ],
  "requestBody" : "{\n  \"monthDt\": \"2026-03\",\n  \"Corp\": \"\",\n  \"TaxCode\": \"\"\n}",
  "headers" : [ ],
  "paths" : [ ],
  "responseBody" : "{\n    \"rawChatData\": {\n        \"title\": {\n            \"text\": \"集团合并累计税费（图1）\",\n            \"left\": \"center\",\n            \"top\": 8,\n            \"textStyle\": {\n                \"fontSize\": 16,\n                \"fontWeight\": \"bold\",\n                \"color\": \"#333\"\n            }\n        },\n        \"legend\": {\n            \"bottom\": 15,\n            \"left\": \"center\",\n            \"data\": [\n                {\n                    \"name\": \"应交税费\",\n                    \"icon\": \"rect\"\n                },\n                {\n                    \"name\": \"实缴税费\",\n                    \"icon\": \"rect\"\n                },\n                {\n                    \"name\": \"应交同比增幅\",\n                    \"icon\": \"triangle\"\n                }\n            ],\n            \"itemWidth\": 12,\n            \"itemHeight\": 12,\n            \"textStyle\": {\n                \"fontSize\": 12\n            }\n        },\n        \"tooltip\": {\n            \"trigger\": \"axis\",\n            \"axisPointer\": {\n                \"type\": \"shadow\"\n            }\n        },\n        \"grid\": {\n            \"left\": \"3%\",\n            \"right\": \"6%\",\n            \"bottom\": 40,\n            \"top\": 90,\n            \"containLabel\": true\n        },\n        \"xAxis\": {\n            \"type\": \"category\",\n            \"data\": [\n                \"进项税额\",\n                \"销项税额\",\n                \"进项税额转出\",\n                \"转出未交增值税\",\n                \"应交城建税\",\n                \"应交教育费附加\",\n                \"应交房产税\",\n                \"应交土地使用税\",\n                \"应交印花税\",\n                \"应交车辆使用税\",\n                \"应交个人所得税\",\n                \"应交企业所得税\",\n                \"未交增值税\",\n                \"待认证进项税额\",\n                \"简易计税\",\n                \"应交水利基金\",\n                \"资源税\",\n                \"环境保护税\"\n            ],\n            \"axisLabel\": {\n                \"interval\": 0,\n                \"rotate\": 30,\n                \"fontSize\": 11,\n                \"color\": \"#8EBBFF\"\n            },\n            \"axisTick\": {\n                \"alignWithLabel\": true\n            }\n        },\n        \"yAxis\": [\n            {\n                \"type\": \"value\",\n                \"name\": \"万元\",\n                \"nameTextStyle\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#888\"\n                },\n                \"axisLabel\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#888\"\n                },\n                \"splitLine\": {\n                    \"lineStyle\": {\n                        \"color\": \"rgba(255,255,255,0.1)\"\n                    }\n                }\n            },\n            {\n                \"type\": \"value\",\n                \"name\": \"同比增幅\",\n                \"nameTextStyle\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#70AD47\"\n                },\n                \"axisLabel\": {\n                    \"formatter\": \"{value}%\",\n                    \"fontSize\": 11,\n                    \"color\": \"#70AD47\"\n                },\n                \"splitLine\": {\n                    \"show\": false\n                },\n                \"max\": 220,\n                \"min\": -120\n            }\n        ],\n        \"series\": [\n            {\n                \"name\": \"应交税费\",\n                \"type\": \"bar\",\n                \"yAxisIndex\": 0,\n                \"barWidth\": \"30%\",\n                \"barGap\": \"10%\",\n                \"itemStyle\": {\n                    \"color\": \"#4472C4\"\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#4472C4\"\n                },\n                \"data\": [\n                    417.6,\n                    161.45,\n                    7.5,\n                    0.02,\n                    0.56,\n                    0.42,\n                    38.93,\n                    25.28,\n                    12.28,\n                    0.04,\n                    567.11,\n                    0,\n                    28.74,\n                    35.85,\n                    -0.65,\n                    0.01,\n                    0,\n                    2.33\n                ]\n            },\n            {\n                \"name\": \"实缴税费\",\n                \"type\": \"bar\",\n                \"yAxisIndex\": 0,\n                \"barWidth\": \"30%\",\n                \"itemStyle\": {\n                    \"color\": \"#ED7D31\"\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#ED7D31\"\n                },\n                \"data\": [\n                    75.82,\n                    453.62,\n                    24.14,\n                    0.02,\n                    0.55,\n                    0.44,\n                    40.9,\n                    13.59,\n                    46.77,\n                    0.04,\n                    68.03,\n                    448.35,\n                    110.08,\n                    23.68,\n                    0,\n                    0,\n                    0.02,\n                    3.28\n                ]\n            },\n            {\n                \"name\": \"应交同比增幅\",\n                \"type\": \"scatter\",\n                \"yAxisIndex\": 1,\n                \"symbol\": \"triangle\",\n                \"symbolSize\": 12,\n                \"itemStyle\": {\n                    \"color\": \"#70AD47\"\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#70AD47\",\n                    \"formatter\": \"{c}%\"\n                },\n                \"data\": [\n                    200,\n                    39.6,\n                    171.74,\n                    0,\n                    200,\n                    200,\n                    0.75,\n                    0,\n                    75.18,\n                    0,\n                    200,\n                    -100,\n                    29.46,\n                    68.55,\n                    -187.84,\n                    0,\n                    0,\n                    0\n                ],\n                \"markLine\": {\n                    \"silent\": true,\n                    \"symbol\": \"none\",\n                    \"lineStyle\": {\n                        \"color\": \"#70AD47\",\n                        \"type\": \"dashed\",\n                        \"width\": 1\n                    },\n                    \"data\": [\n                        {\n                            \"yAxis\": 0\n                        }\n                    ],\n                    \"label\": {\n                        \"show\": true,\n                        \"position\": \"end\",\n                        \"formatter\": \"0%\",\n                        \"color\": \"#70AD47\",\n                        \"fontSize\": 10\n                    }\n                }\n            }\n        ]\n    }\n}",
  "description" : null,
  "requestBodyDefinition" : null,
  "responseBodyDefinition" : null
}
================================
import resp
if (body?.monthDt) {
    body.monthDt = body.monthDt.split(",")
}
if (body?.Corp) {
    body.Corp = body.Corp.split(",")
}
if (body?.TaxCode) {
    body.TaxCode = body.TaxCode.split(",")
}
list = db.FRCK.select("""
WITH 
    --eg：2026-02
    #{body?.monthDt} AS param_month1,
    substr(param_month1, 1, 7) as param_month,
    --本年年末 2026-12
    concat(substr(param_month, 1, 4), '-12') AS param_yearmth_end,
    --本年月初 2026-01
    concat(substr(param_month, 1, 4), '-01') AS param_yearmth_start,
    --同期2025-02
    substr(toString(addYears(param_month, -1)),1,7)AS last_year_param_month,
    --环期2026-01
    substr(toString(addMonths(param_month, -1)),1,7)AS param_last_month,
    --本年 2026
    substr(param_month, 1, 4) AS this_year,
    --去年 2025
    substr(param_last_month, 1, 4) AS last_year
select
    d_subject_name
     , round(sum(f_debitamount1) / 10000, 2)   as payable_amt
     , round(sum(f_creditamount1) / 10000, 2)  as actual_amt
     , round(sum(f_debitamount_yoy) / 10000, 2)  as payable_yoy_amt
     ,payable_amt-payable_yoy_amt as diff_amt
     , round(
        if(payable_yoy_amt = 0, 0,
           100*(payable_amt -payable_yoy_amt) / payable_yoy_amt
        ), 2
       ) as yoy_rate
     ,case when yoy_rate>200 then 200
           when yoy_rate< -200 then -200
           else yoy_rate end as yoy_rate_adjust
from (
         select d_subject_id, d_subject_code, d_subject_name,
                sum(f_debitamount) as f_debitamount1,
                sum(f_creditamount) as f_creditamount1,
                0 as f_debitamount_yoy, 0 as f_creditamount_yoy
         from dwd_gl_balance
        <where>
            1=1
            AND month_dt = param_month
            and d_subject_code like '2221%'
            and rn = 1
        </where>
         group by d_subject_id, d_subject_code, d_subject_name
         union all
         select d_subject_id, d_subject_code, d_subject_name,
                0 as f_debitamount1, 0 as f_creditamount1,
                sum(f_debitamount) as f_debitamount_yoy,
                sum(f_creditamount) as f_creditamount_yoy
         from dwd_gl_balance
        <where>
            1=1
            AND month_dt = last_year_param_month
            and d_subject_code like '2221%'
            and rn
        </where>
         group by d_subject_id, d_subject_code, d_subject_name

         )
group by d_subject_id, d_subject_code, d_subject_name
order by d_subject_code
""")
return resp.json({
    rawChatData: option = {
        title: {
            text: '集团合并累计税费（图1）',
            left: 'center',
            top: 8,
            textStyle: {
                fontSize: 16,
                fontWeight: 'bold',
                color: '#333'
            }
        },
        legend: {
            bottom: 15,
            left: 'center',
            data: [{
                    name: '应交税费',
                    icon: 'rect'
                },
                {
                    name: '实缴税费',
                    icon: 'rect'
                },
                {
                    name: '应交同比增幅',
                    icon: 'triangle'
                }
            ],
            itemWidth: 12,
            itemHeight: 12,
            textStyle: {
                fontSize: 12
            }
        },
        tooltip: {
            trigger: 'axis',
            axisPointer: {
                type: 'shadow'
            }
        },
        grid: { left: '3%', right: '6%', bottom: 40, top: 90, containLabel: true },
        xAxis: {
            type: 'category',
            data: list.map(item=>item.dSubjectName),
            axisLabel: {
                interval: 0,
                rotate: 30,
                fontSize: 11,
                color: '#8EBBFF'
            },
            axisTick: {
                alignWithLabel: true
            }
        },
        yAxis: [{
                type: 'value',
                name: '万元',
                nameTextStyle: {
                    fontSize: 11,
                    color: '#888'
                },
                axisLabel: {
                    fontSize: 11,
                    color: '#888'
                },
                splitLine: {
                    lineStyle: {
                        color: 'rgba(255,255,255,0.1)'
                    }
                }
            },
            {
            type: 'value', name: '同比增幅',
            nameTextStyle: { fontSize: 11, color: '#70AD47' },
            axisLabel: { formatter: '{value}%', fontSize: 11, color: '#70AD47' },
            splitLine: { show: false },
            max: 220,
            min: -120}
        ],
        series: [
            {
                name: '应交税费',
                type: 'bar',
                yAxisIndex: 0,
                barWidth: '30%',
                barGap: '10%',
                itemStyle: {
                    color: '#4472C4'
                },
                label: {
                    show: true,
                    position: 'top',
                    fontSize: 10,
                    color: '#4472C4'
                },
                data: list.map(item=>item.payableAmt)
            },
            {
                name: '实缴税费',
                type: 'bar',
                yAxisIndex: 0,
                barWidth: '30%',
                itemStyle: {
                    color: '#ED7D31'
                },
                label: {
                    show: true,
                    position: 'top',
                    fontSize: 10,
                    color: '#ED7D31'
                },
                data: list.map(item=>item.actualAmt)
            },
            {
                name: '应交同比增幅',
                type: 'scatter',
                yAxisIndex: 1,
                symbol: 'triangle',
                symbolSize: 12,
                itemStyle: {
                    color: '#70AD47'
                },
                label: {
                    show: true,
                    position: 'top',
                    fontSize: 10,
                    color: '#70AD47',
                    formatter: '{c}%'
                },
                data: list.map(item=>item.yoyRateAdjust),
                markLine: {
                    silent: true,
                    symbol: 'none',
                    lineStyle: {
                        color: '#70AD47',
                        type: 'dashed',
                        width: 1
                    },
                    data: [{ yAxis: 0 }],
                    label: {
                        show: true,
                        position: 'end',
                        formatter: '0%',
                        color: '#70AD47',
                        fontSize: 10
                    }
                }
            }
        ]
    }
})