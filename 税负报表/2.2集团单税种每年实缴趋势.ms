{
  "properties" : { },
  "id" : "copy1776916639398d78643",
  "script" : null,
  "groupId" : "aef38b24a7d54eb390a128d6b422e050",
  "name" : "2.2集团单税种每年实缴趋势",
  "createTime" : null,
  "updateTime" : 1776996310602,
  "lock" : null,
  "createBy" : null,
  "updateBy" : "18838479803",
  "path" : "/groupYearOneTax",
  "method" : "POST",
  "parameters" : [ ],
  "options" : [ ],
  "requestBody" : "{\n  \"monthDt\": \"2026-03\",\n  \"Corp\": \"\",\n  \"TaxCode\": \"222110\"\n}",
  "headers" : [ ],
  "paths" : [ ],
  "responseBody" : "{\n    \"rawChatData\": {\n        \"title\": [\n            {\n                \"text\": \"全集团应交个人所得税2017年~2026年\",\n                \"left\": \"center\",\n                \"top\": 0,\n                \"textStyle\": {\n                    \"fontSize\": 12,\n                    \"color\": \"#FFD700\"\n                }\n            }\n        ],\n        \"legend\": {\n            \"bottom\": 35,\n            \"left\": \"center\",\n            \"data\": [\n                \"应交个人所得税 - 当期实缴\",\n                \"应交个人所得税 - 同比变动\"\n            ],\n            \"textStyle\": {\n                \"fontSize\": 12,\n                \"color\": \"#FFFFFF\"\n            }\n        },\n        \"tooltip\": {\n            \"trigger\": \"axis\"\n        },\n        \"grid\": {\n            \"left\": \"3%\",\n            \"right\": \"4%\",\n            \"bottom\": 50,\n            \"top\": 60,\n            \"containLabel\": true\n        },\n        \"xAxis\": {\n            \"type\": \"category\",\n            \"data\": [\n                \"2017年\",\n                \"2018年\",\n                \"2019年\",\n                \"2020年\",\n                \"2021年\",\n                \"2022年\",\n                \"2023年\",\n                \"2024年\",\n                \"2025年\",\n                \"2026年\"\n            ],\n            \"axisLabel\": {\n                \"fontSize\": 12,\n                \"color\": \"#FFFFFF\",\n                \"fontWeight\": \"bold\"\n            }\n        },\n        \"yAxis\": {\n            \"type\": \"value\",\n            \"name\": \"万元\",\n            \"axisLabel\": {\n                \"color\": \"#FFFFFF\"\n            },\n            \"splitLine\": {\n                \"lineStyle\": {\n                    \"color\": \"rgba(255,255,255,0.1)\"\n                }\n            }\n        },\n        \"series\": [\n            {\n                \"name\": \"应交个人所得税 - 当期实缴\",\n                \"type\": \"line\",\n                \"smooth\": false,\n                \"symbol\": \"circle\",\n                \"symbolSize\": 6,\n                \"itemStyle\": {\n                    \"color\": \"#4472C4\"\n                },\n                \"lineStyle\": {\n                    \"color\": \"#4472C4\",\n                    \"width\": 2\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"top\",\n                    \"fontSize\": 11,\n                    \"color\": \"#4472C4\",\n                    \"fontWeight\": \"bold\"\n                },\n                \"data\": [\n                    1215.54,\n                    1934.88,\n                    2629.5,\n                    1834.71,\n                    3057.7,\n                    4868.88,\n                    2103.6,\n                    2347.97,\n                    2701.52,\n                    1617.78\n                ],\n                \"markLine\": {\n                    \"silent\": true,\n                    \"symbol\": \"none\",\n                    \"lineStyle\": {\n                        \"color\": \"#70AD47\",\n                        \"type\": \"solid\",\n                        \"width\": 2\n                    },\n                    \"data\": [\n                        {\n                            \"yAxis\": 0\n                        }\n                    ],\n                    \"label\": {\n                        \"show\": false\n                    }\n                }\n            },\n            {\n                \"name\": \"应交个人所得税 - 同比变动\",\n                \"type\": \"line\",\n                \"smooth\": false,\n                \"symbol\": \"circle\",\n                \"symbolSize\": 8,\n                \"itemStyle\": {\n                    \"color\": \"#FF4444\"\n                },\n                \"lineStyle\": {\n                    \"color\": \"#FF4444\",\n                    \"width\": 2\n                },\n                \"label\": {\n                    \"show\": true,\n                    \"position\": \"bottom\",\n                    \"fontSize\": 11,\n                    \"color\": \"#FF4444\",\n                    \"fontWeight\": \"bold\",\n                    \"backgroundColor\": \"rgba(0,0,0,0.5)\",\n                    \"padding\": [\n                        2,\n                        4\n                    ],\n                    \"borderRadius\": 2\n                },\n                \"data\": [\n                    1215.54,\n                    719.34,\n                    694.62,\n                    -794.79,\n                    1222.99,\n                    1811.18,\n                    -2765.28,\n                    244.37,\n                    353.55,\n                    -1083.74\n                ]\n            }\n        ]\n    }\n}",
  "description" : null,
  "requestBodyDefinition" : null,
  "responseBodyDefinition" : null
}
================================
import resp

if (body?.monthDt) { body.monthDt = body.monthDt.split(",") }
if (body?.Corp) { body.Corp = body.Corp.split(",") }
if (body?.TaxCode) { body.TaxCode = body.TaxCode.split(",") }

var thisYear = body?.monthDt ? Integer.parseInt(body.monthDt[0].substring(0, 4)) : 2026

list = db.FRCK.select("""
WITH
    #{body?.monthDt} AS param_month1,
    substr(param_month1, 1, 4) AS this_year,
    toInt32(this_year) AS y,
    toString(y - 9) AS start_year,
    #{body?.Corp} AS corp1
select
	
    d_subject_name,
    concat(if(corp1='','全集团',dictGet('dim_unit_dict2', 'd_corp_sname',corp1)),d_subject_name,start_year,'年~',y,'年') as title,
    round(sumIf(f_creditamount, years = toString(y-9)) / 10000, 2) as y0,
    round(sumIf(f_creditamount, years = toString(y-8)) / 10000, 2) as y1,
    round(sumIf(f_creditamount, years = toString(y-7)) / 10000, 2) as y2,
    round(sumIf(f_creditamount, years = toString(y-6)) / 10000, 2) as y3,
    round(sumIf(f_creditamount, years = toString(y-5)) / 10000, 2) as y4,
    round(sumIf(f_creditamount, years = toString(y-4)) / 10000, 2) as y5,
    round(sumIf(f_creditamount, years = toString(y-3)) / 10000, 2) as y6,
    round(sumIf(f_creditamount, years = toString(y-2)) / 10000, 2) as y7,
    round(sumIf(f_creditamount, years = toString(y-1)) / 10000, 2) as y8,
    round(sumIf(f_creditamount, years = toString(y))   / 10000, 2) as y9,
    -- 同比变动：本期 - 上期（SQL层计算）
    round(sumIf(f_creditamount, years = toString(y-8)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-9)) / 10000, 2) as d1,
    round(sumIf(f_creditamount, years = toString(y-7)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-8)) / 10000, 2) as d2,
    round(sumIf(f_creditamount, years = toString(y-6)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-7)) / 10000, 2) as d3,
    round(sumIf(f_creditamount, years = toString(y-5)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-6)) / 10000, 2) as d4,
    round(sumIf(f_creditamount, years = toString(y-4)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-5)) / 10000, 2) as d5,
    round(sumIf(f_creditamount, years = toString(y-3)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-4)) / 10000, 2) as d6,
    round(sumIf(f_creditamount, years = toString(y-2)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-3)) / 10000, 2) as d7,
    round(sumIf(f_creditamount, years = toString(y-1)) / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-2)) / 10000, 2) as d8,
    round(sumIf(f_creditamount, years = toString(y))   / 10000, 2)
        - round(sumIf(f_creditamount, years = toString(y-1)) / 10000, 2) as d9
from dwd_gl_balance
<where>
    1=1
    AND years BETWEEN toString(y-9) AND toString(y)
    AND d_subject_code IN (#{body?.TaxCode})
    AND rn = 1
    AND months <> '00'
    <if test="body?.Corp != null and body?.Corp != ''">
        AND d_corp_code IN (#{body?.Corp})
    </if>
</where>
group by d_subject_name
order by d_subject_name
""")

var xData = []
var xi
for(xi in range(0, 9)) {
    xData.add((thisYear - 9 + xi) + '年')
}
// 获取 SQL 中的 dSubjectName 字段
var taxName = list.size() > 0 ? list.get(0).get('dSubjectName') : '税种'
// 获取 SQL 中封装的 title 字段
var chartTitle = list.size() > 0 ? list.get(0).get('title') : '各项税费历年变动趋势'
var actualData = []
var diffData = []

if (list.size() > 0) {
    var row = list.get(0)
    var ykeys = ['y0','y1','y2','y3','y4','y5','y6','y7','y8','y9']
    var dkeys = ['y0','d1','d2','d3','d4','d5','d6','d7','d8','d9']
    var fi
    for(fi in range(0, 9)) {
        var yval = row.get(ykeys.get(fi))
        var dval = row.get(dkeys.get(fi))
        if (yval == null) { yval = 0 }
        if (dval == null) { dval = 0 }
        actualData.add(yval)
        diffData.add(dval)
    }
}

return resp.json({
    rawChatData: {
        title: [
            {
                text: list.length > 0 ? list[0].title : '',
                left: 'center', top: 0,
                textStyle: { fontSize: 12, color: '#FFD700' }
            }
        ],

        legend: {
            bottom: 35,              // 1. 图例移到最下方
            left: 'center',
            data: [taxName + ' - 当期实缴', taxName + ' - 同比变动'],
            textStyle: { fontSize: 12, color: '#FFFFFF' }
        },
        tooltip: { trigger: 'axis' },
        grid: { left: '3%', right: '4%', bottom: 50, top: 60, containLabel: true },
        xAxis: {
            type: 'category',
            data: xData,
            axisLabel: {
                fontSize: 12,
                color: '#FFFFFF',        // 4. 年份颜色加白
                fontWeight: 'bold'       // 4. 加粗
            }
        },
        yAxis: {
            type: 'value', name: '万元',
            axisLabel: { color: '#FFFFFF' },
            splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } }
        },
        series: [
            {
                name: taxName + ' - 当期实缴',
                type: 'line',
                smooth: false,
                symbol: 'circle', symbolSize: 6,
                itemStyle: { color: '#4472C4' },
                lineStyle: { color: '#4472C4', width: 2 },
                label: {
                    show: true, position: 'top', fontSize: 11,
                    color: '#4472C4',
                    fontWeight: 'bold'
                },
                data: actualData,
                markLine: {                          // 2. y=0 绿色虚线加粗
                    silent: true, symbol: 'none',
                    lineStyle: { color: '#70AD47', type: 'solid', width: 2 },
                    data: [{ yAxis: 0 }],
                    label: { show: false }
                }
            },
            {
                name: taxName + ' - 同比变动',
                type: 'line',
                smooth: false,
                symbol: 'circle', symbolSize: 8,     // 3. 点放大
                itemStyle: { color: '#FF4444' },
                lineStyle: { color: '#FF4444', width: 2 },
                label: {
                    show: true, position: 'bottom',   // 3. 负值标签移到下方避免重叠
                    fontSize: 11,
                    color: '#FF4444',
                    fontWeight: 'bold',               // 3. 加粗
                    backgroundColor: 'rgba(0,0,0,0.5)', // 3. 加背景增强可读性
                    padding: [2, 4],
                    borderRadius: 2
                },
                data: diffData
            }
        ]
    }
})