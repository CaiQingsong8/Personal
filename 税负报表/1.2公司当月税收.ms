{
  "properties" : { },
  "id" : "copy1776840361894d74167",
  "script" : null,
  "groupId" : "aef38b24a7d54eb390a128d6b422e050",
  "name" : "1.2公司当月税收",
  "createTime" : null,
  "updateTime" : 1777014228974,
  "lock" : null,
  "createBy" : "18838479803",
  "updateBy" : "18838479803",
  "path" : "/corpMonthlyTax",
  "method" : "POST",
  "parameters" : [ ],
  "options" : [ ],
  "requestBody" : "{\n  \"monthDt\": \"2026-03\",\n  \"Corp\": \"\",\n  \"TaxCode\": \"\"\n}",
  "headers" : [ ],
  "paths" : [ ],
  "responseBody" : "{\n    \"status\": false,\n    \"errorMsg\": \"出现错误：期待 'an identifier','and','or', 获得 '' at Row:1~1,Col:1~0\\n\\n\\\"\\r\\n  \",\n    \"code\": 0\n}",
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
var thisYear = body?.monthDt ? Integer.parseInt(body.monthDt[0].substring(0, 4)) : 2026
// 加上 .toString() 确保是字符串，或者给一个默认空字符串
var Corp = body?.Corp ? body.Corp.toString() : ""
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
    d_subject_name,d_corp_name
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
         select d_subject_id, d_subject_code, d_subject_name,d_corp_name,
                sum(f_debitamount) as f_debitamount1,
                sum(f_creditamount) as f_creditamount1,
                0 as f_debitamount_yoy, 0 as f_creditamount_yoy
         from dwd_gl_balance
        <where>
            1=1
            AND month_dt = param_month
            AND d_corp_code IN (#{body?.Corp})
            and d_subject_code like '2221%'
            and rn = 1
        </where>
         group by d_subject_id, d_subject_code, d_subject_name,d_corp_name
         union all
         select d_subject_id, d_subject_code, d_subject_name,d_corp_name,
                0 as f_debitamount1, 0 as f_creditamount1,
                sum(f_debitamount) as f_debitamount_yoy,
                sum(f_creditamount) as f_creditamount_yoy
         from dwd_gl_balance
        <where>
            1=1
            AND month_dt = last_year_param_month
            AND d_corp_code IN (#{body?.Corp})
            and d_subject_code like '2221%'
            and rn
        </where>
         group by d_subject_id, d_subject_code, d_subject_name,d_corp_name

         )
group by d_subject_id, d_subject_code, d_subject_name,d_corp_name
order by d_subject_code
""")
return resp.json({
    rawChatData: option = {
        title: [
            {
                text: list.length > 0 ? list[0].dCorpName : '',
                left: 'right', bottom: 15,
                textStyle: { fontSize: 16, fontWeight: 'bold', color: 'rgba(255,255,255,0.85)' }
            }
        ],

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