{
  "properties" : { },
  "id" : "copy1776845166813d26901",
  "script" : null,
  "groupId" : "aef38b24a7d54eb390a128d6b422e050",
  "name" : "1.3单税种各公司应交同比差异",
  "createTime" : null,
  "updateTime" : 1776905502232,
  "lock" : null,
  "createBy" : "18838479803",
  "updateBy" : "18838479803",
  "path" : "/groupTaxDiff",
  "method" : "POST",
  "parameters" : [ ],
  "options" : [ ],
  "requestBody" : "{\n  \"monthDt\": \"2026-03\",\n  \"Corp\": \"1001\",\n  \"TaxCode\": \"\"\n}",
  "headers" : [ ],
  "paths" : [ ],
  "responseBody" : "{\n    \"rawChatData\": {\n        \"title\": {\n            \"text\": \"单税种各公司应交同比情况（图5）\",\n            \"left\": \"center\",\n            \"top\": 8,\n            \"textStyle\": {\n                \"fontSize\": 16,\n                \"fontWeight\": \"bold\",\n                \"color\": \"rgba(255,255,255,0.85)\"\n            }\n        },\n        \"legend\": {\n            \"top\": 40,\n            \"left\": \"center\",\n            \"data\": [\n                {\n                    \"name\": \"同比增额\",\n                    \"icon\": \"rect\"\n                },\n                {\n                    \"name\": \"同比增幅\",\n                    \"icon\": \"triangle\"\n                }\n            ],\n            \"itemWidth\": 12,\n            \"itemHeight\": 12,\n            \"textStyle\": {\n                \"fontSize\": 12,\n                \"color\": \"#FFFFFF\"\n            }\n        },\n        \"tooltip\": {\n            \"trigger\": \"axis\",\n            \"axisPointer\": {\n                \"type\": \"shadow\"\n            }\n        },\n        \"grid\": {\n            \"left\": \"3%\",\n            \"right\": \"6%\",\n            \"bottom\": 60,\n            \"top\": 90,\n            \"containLabel\": true\n        },\n        \"xAxis\": {\n            \"type\": \"category\",\n            \"data\": [],\n            \"axisLabel\": {\n                \"interval\": 0,\n                \"rotate\": 30,\n                \"fontSize\": 11,\n                \"color\": \"#8EBBFF\"\n            },\n            \"axisTick\": {\n                \"alignWithLabel\": true\n            }\n        },\n        \"yAxis\": [\n            {\n                \"type\": \"value\",\n                \"name\": \"万元\",\n                \"nameTextStyle\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#888\"\n                },\n                \"axisLabel\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#888\"\n                },\n                \"splitLine\": {\n                    \"lineStyle\": {\n                        \"color\": \"rgba(255,255,255,0.1)\"\n                    }\n                }\n            },\n            {\n                \"type\": \"value\",\n                \"name\": \"同比增幅\",\n                \"nameTextStyle\": {\n                    \"fontSize\": 11,\n                    \"color\": \"#70AD47\"\n                },\n                \"axisLabel\": {\n                    \"formatter\": \"{value}%\",\n                    \"fontSize\": 11,\n                    \"color\": \"#70AD47\"\n                },\n                \"splitLine\": {\n                    \"show\": false\n                },\n                \"min\": -400,\n                \"max\": 650\n            }\n        ],\n        \"series\": [\n            {\n                \"name\": \"同比增额\",\n                \"type\": \"bar\",\n                \"yAxisIndex\": 0,\n                \"barWidth\": \"40%\",\n                \"itemStyle\": {\n                    \"color\": \"#4472C4\"\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#4472C4\"\n                },\n                \"data\": []\n            },\n            {\n                \"name\": \"同比增幅\",\n                \"type\": \"scatter\",\n                \"yAxisIndex\": 1,\n                \"symbol\": \"triangle\",\n                \"symbolSize\": 12,\n                \"itemStyle\": {\n                    \"color\": \"#70AD47\"\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 10,\n                    \"color\": \"#FF4444\",\n                    \"formatter\": \"{c}%\"\n                },\n                \"data\": [],\n                \"markLine\": {\n                    \"silent\": true,\n                    \"symbol\": \"none\",\n                    \"lineStyle\": {\n                        \"color\": \"#70AD47\",\n                        \"type\": \"dashed\",\n                        \"width\": 1\n                    },\n                    \"data\": [\n                        {\n                            \"yAxis\": 0\n                        }\n                    ],\n                    \"label\": {\n                        \"show\": true,\n                        \"position\": \"end\",\n                        \"formatter\": \"0%\",\n                        \"color\": \"#70AD47\",\n                        \"fontSize\": 10\n                    }\n                }\n            }\n        ]\n    }\n}",
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
    d_subject_name,d_corp_id
     ,dictGet('dim_unit_dict', 'd_corp_sname', d_corp_id) as d_corp_sname
     , round(sum(f_debitamount1) / 10000, 2)   as payable_amt
     , round(sum(f_creditamount1) / 10000, 2)  as actual_amt
     , round(sum(f_debitamount_yoy) / 10000, 2)  as payable_yoy_amt
     ,payable_amt-payable_yoy_amt as diff_amt
     , round(
        if(payable_yoy_amt = 0, 0,
           100*(payable_amt -payable_yoy_amt) / payable_yoy_amt
        ), 2
       ) as yoy_rate
    ,case
        when diff_amt > 200  then 200
        when diff_amt < -100 then -100
        else diff_amt
    end as diff_amt_adjust
    ,case
        when yoy_rate > 600  then 600
        when yoy_rate < -400 then -400
        else yoy_rate
    end as yoy_rate_adjust
from (
         select d_subject_id, d_subject_code, d_subject_name,d_corp_id,
                sum(f_debitamount) as f_debitamount1,
                sum(f_creditamount) as f_creditamount1,
                0 as f_debitamount_yoy, 0 as f_creditamount_yoy
         from dwd_gl_balance
        <where>
            1=1
            AND month_dt = param_month
            AND d_subject_code IN (#{body?.TaxCode})
            and rn = 1
        </where>
         group by d_subject_id, d_subject_code, d_subject_name,d_corp_id
         union all
         select d_subject_id, d_subject_code, d_subject_name,d_corp_id,
                0 as f_debitamount1, 0 as f_creditamount1,
                sum(f_debitamount) as f_debitamount_yoy,
                sum(f_creditamount) as f_creditamount_yoy
         from dwd_gl_balance
        <where>
            1=1
            AND month_dt = last_year_param_month
            AND d_subject_code IN (#{body?.TaxCode})
            and rn
        </where>
         group by d_subject_id, d_subject_code, d_subject_name,d_corp_id

         )
group by d_subject_id, d_subject_code, d_subject_name,d_corp_id
order by d_subject_code
""")
return resp.json({
    rawChatData: option = {
        title: {
            text: '单税种各公司应交同比情况（图5）',
            left: 'center', top: 8,
            textStyle: { fontSize: 16, fontWeight: 'bold', color: 'rgba(255,255,255,0.85)' }
        },
        legend: {
            top: 40, left: 'center',
            data: [
                { name: '同比增额', icon: 'rect' },
                { name: '同比增幅', icon: 'triangle' }
            ],
            itemWidth: 12, itemHeight: 12,
            textStyle: { fontSize: 12, color: '#FFFFFF' }
        },
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: '3%', right: '6%', bottom: 60, top: 90, containLabel: true },
        xAxis: {
            type: 'category',
            data: list.map(item => item.dCorpSname),
            axisLabel: { interval: 0, rotate: 30, fontSize: 11, color: '#8EBBFF' },
            axisTick: { alignWithLabel: true }
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
                min: -400,
                max: 650
            }
        ],
        series: [
            {
                name: '同比增额',
                type: 'bar',
                yAxisIndex: 0,
                barWidth: '40%',
                itemStyle: { color: '#4472C4' },
                label: {
                    show: true, position: 'top',
                    fontSize: 10, color: '#4472C4'
                },
                data: list.map(item => item.diffAmtAdjust)
            },
            {
                name: '同比增幅',
                type: 'scatter',
                yAxisIndex: 1,
                symbol: 'triangle', symbolSize: 12,
                itemStyle: { color: '#70AD47' },
                label: {
                    show: true, position: 'top',
                    fontSize: 10, color: '#FF4444',
                    formatter: '{c}%'
                },
                data: list.map(item => item.yoyRateAdjust),
                markLine: {
                    silent: true, symbol: 'none',
                    lineStyle: { color: '#70AD47', type: 'dashed', width: 1 },
                    data: [{ yAxis: 0 }],
                    label: { show: true, position: 'end', formatter: '0%', color: '#70AD47', fontSize: 10 }
                }
            }
        ]
    }
})