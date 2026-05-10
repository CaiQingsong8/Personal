{
  "properties" : { },
  "id" : "copy1776827897621d17060",
  "script" : null,
  "groupId" : "aef38b24a7d54eb390a128d6b422e050",
  "name" : "1.1集团各月税收趋势",
  "createTime" : null,
  "updateTime" : 1776938895361,
  "lock" : null,
  "createBy" : null,
  "updateBy" : "18838479803",
  "path" : "/groupTaxTrend",
  "method" : "POST",
  "parameters" : [ ],
  "options" : [ ],
  "requestBody" : "{\n  \"monthDt\": \"2026-04\",\n  \"Corp\": \"\",\n  \"TaxCode\": \"222110\"\n}",
  "headers" : [ ],
  "paths" : [ ],
  "responseBody" : "{\n    \"rawChatData\": {\n        \"title\": {\n            \"text\": \"集团合并各项税费趋势（图2）\",\n            \"left\": \"center\",\n            \"top\": 8,\n            \"textStyle\": {\n                \"fontSize\": 16,\n                \"fontWeight\": \"bold\",\n                \"color\": \"#333\"\n            }\n        },\n        \"legend\": {\n            \"bottom\": 15,\n            \"left\": \"center\",\n            \"data\": [\n                \"应交税费\",\n                \"实缴税费\",\n                \"应交同比增幅\"\n            ],\n            \"textStyle\": {\n                \"fontSize\": 12\n            }\n        },\n        \"tooltip\": {\n            \"trigger\": \"axis\"\n        },\n        \"grid\": {\n            \"left\": \"3%\",\n            \"right\": \"6%\",\n            \"bottom\": 60,\n            \"top\": 90,\n            \"containLabel\": true\n        },\n        \"xAxis\": {\n            \"type\": \"category\",\n            \"data\": [\n                \"2026-01\",\n                \"2026-02\",\n                \"2026-03\",\n                \"2026-04\"\n            ],\n            \"axisLabel\": {\n                \"fontSize\": 12,\n                \"color\": \"#8EBBFF\"\n            }\n        },\n        \"yAxis\": [\n            {\n                \"type\": \"value\",\n                \"name\": \"万元\",\n                \"nameTextStyle\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#888\"\n                },\n                \"axisLabel\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#888\"\n                },\n                \"splitLine\": {\n                    \"lineStyle\": {\n                        \"color\": \"#eee\"\n                    }\n                }\n            },\n            {\n                \"type\": \"value\",\n                \"name\": \"同比增幅\",\n                \"nameTextStyle\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#70AD47\"\n                },\n                \"axisLabel\": {\n                    \"formatter\": \"{value}%\",\n                    \"fontSize\": 11,\n                    \"color\": \"#70AD47\"\n                },\n                \"splitLine\": {\n                    \"show\": false\n                },\n                \"max\": 220,\n                \"min\": -120\n            }\n        ],\n        \"series\": [\n            {\n                \"name\": \"应交税费\",\n                \"type\": \"line\",\n                \"yAxisIndex\": 0,\n                \"smooth\": false,\n                \"symbol\": \"circle\",\n                \"symbolSize\": 6,\n                \"itemStyle\": {\n                    \"color\": \"#4472C4\"\n                },\n                \"lineStyle\": {\n                    \"color\": \"#4472C4\",\n                    \"width\": 2\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#4472C4\"\n                },\n                \"data\": [\n                    137.4,\n                    440.38,\n                    567.11,\n                    0\n                ]\n            },\n            {\n                \"name\": \"实缴税费\",\n                \"type\": \"line\",\n                \"yAxisIndex\": 0,\n                \"smooth\": false,\n                \"symbol\": \"circle\",\n                \"symbolSize\": 6,\n                \"itemStyle\": {\n                    \"color\": \"#ED7D31\"\n                },\n                \"lineStyle\": {\n                    \"color\": \"#ED7D31\",\n                    \"width\": 2\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#ED7D31\"\n                },\n                \"data\": [\n                    101.36,\n                    1448.39,\n                    68.03,\n                    0\n                ]\n            },\n            {\n                \"name\": \"应交同比增幅\",\n                \"type\": \"line\",\n                \"yAxisIndex\": 1,\n                \"smooth\": false,\n                \"symbol\": \"circle\",\n                \"symbolSize\": 6,\n                \"itemStyle\": {\n                    \"color\": \"#70AD47\"\n                },\n                \"lineStyle\": {\n                    \"color\": \"#70AD47\",\n                    \"width\": 2\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#70AD47\",\n                    \"formatter\": \"{c}%\"\n                },\n                \"data\": [\n                    0,\n                    0,\n                    0,\n                    -100\n                ],\n                \"markLine\": {\n                    \"silent\": true,\n                    \"symbol\": \"none\",\n                    \"lineStyle\": {\n                        \"color\": \"#70AD47\",\n                        \"type\": \"dashed\",\n                        \"width\": 1\n                    },\n                    \"data\": [\n                        {\n                            \"yAxis\": 0\n                        }\n                    ],\n                    \"label\": {\n                        \"show\": true,\n                        \"position\": \"end\",\n                        \"formatter\": \"0%\",\n                        \"color\": \"#70AD47\",\n                        \"fontSize\": 10\n                    }\n                }\n            }\n        ]\n    }\n}",
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
    month_dt
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
         -- 本期 2026
         select
             month_dt,
             sum(f_debitamount)  as f_debitamount1,
             sum(f_creditamount) as f_creditamount1,
             0 as f_debitamount_yoy,
             0 as f_creditamount_yoy
         from dwd_gl_balance
         <where>
             1=1
             and years = this_year
             <if test="body?.TaxCode != null and body?.TaxCode != ''">
                 AND d_subject_code IN (#{body?.TaxCode})
             </if>
            and rn = 1
            and months <> '00'
         </where>
         group by month_dt

         union all

         -- 上期 2025，month_dt年份+1对齐到2026
         select
             param_month as month_dt,
             0 as f_debitamount1,
             0 as f_creditamount1,
             sum(f_debitamount)  as f_debitamount_yoy,
             sum(f_creditamount) as f_creditamount_yoy
         from dwd_gl_balance
         <where>
             1=1
             and years = last_year
             <if test="body?.TaxCode != null and body?.TaxCode != ''">
                 AND d_subject_code IN (#{body?.TaxCode})
             </if>
            and rn = 1
            and months <> '00'
         </where>
         group by month_dt
         )
group by month_dt
order by month_dt
""")


return resp.json({
    rawChatData: option = {
        title: {
            text: '集团合并各项税费趋势（图2）',
            left: 'center', top: 8,
            textStyle: { fontSize: 16, fontWeight: 'bold', color: '#333' }
        },
        legend: {
            bottom: 8,left: 'center',
            data: ['应交税费', '实缴税费', '应交同比增幅'],
            textStyle: { fontSize: 12 }
        },
        tooltip: { trigger: 'axis' },
        grid: { left: '3%', right: '6%', bottom: 60, top: 90, containLabel: true },
        xAxis: {
            type: 'category',
            data: list.map(item => item.monthDt),
            axisLabel: { fontSize: 12, color: '#8EBBFF' }
        },
        yAxis: [
            {
                type: 'value', name: '万元',
                nameTextStyle: { fontSize: 11, color: '#888' },
                axisLabel: { fontSize: 11, color: '#888' },
                splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } }
            },
            {
                type: 'value', name: '同比增幅',
                nameTextStyle: { fontSize: 11, color: '#70AD47' },
                axisLabel: { formatter: '{value}%', fontSize: 11, color: '#70AD47' },
                splitLine: { show: false },
                max: 220,
                min: -120
            }
        ],
        series: [
            {
                name: '应交税费', type: 'line', yAxisIndex: 0,
                smooth: false,
                symbol: 'circle', symbolSize: 6,
                itemStyle: { color: '#4472C4' },
                lineStyle: { color: '#4472C4', width: 2 },
                label: { show: true, position: 'top', fontSize: 10, color: '#4472C4' },
                data: list.map(item => item.payableAmt)
            },
            {
                name: '实缴税费', type: 'line', yAxisIndex: 0,
                smooth: false,
                symbol: 'circle', symbolSize: 6,
                itemStyle: { color: '#ED7D31' },
                lineStyle: { color: '#ED7D31', width: 2 },
                label: { show: true, position: 'top', fontSize: 10, color: '#ED7D31' },
                data: list.map(item => item.actualAmt)
            },
            {
                name: '应交同比增幅', type: 'line', yAxisIndex: 1,
                smooth: false,
                symbol: 'circle', symbolSize: 6,
                itemStyle: { color: '#70AD47' },
                lineStyle: { color: '#70AD47', width: 2 },
                label: {
                    show: true, position: 'top', fontSize: 10, color: '#70AD47',
                    formatter: '{c}%'
                },
                data: list.map(item => item.yoyRateAdjust),
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