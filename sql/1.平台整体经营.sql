
----平台整体经营表现----

WITH order_summary as (
SELECT 
    o.order_id,
    o.order_status,
    SUM(i.item_total_value) as order_gmv
FROM olist_orders o
LEFT JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY o.order_id, o.order_status
)

SELECT 
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) as delivered_orders,
    ROUND(SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
    ::NUMERIC/COUNT(order_id) * 100, 2) || '%' as delivery_rate,
    ROUND(SUM(order_gmv)::NUMERIC, 2) as total_gmv,
    ROUND(AVG(order_gmv)::NUMERIC, 2) as aov
FROM order_summary

/*

1. 业务规模概览 (Overall Business Scale)
• 市场体量：平台在统计周期内处理了近 10万 (99,441) 个订单，实现了约 1,584万 的总交易额 (GMV)。这说明平台已经具备了相当规模的市场覆盖能力和资金吞吐量。

• 客单价分析 (AOV)：平均每个订单的金额为 160.58。这个数字对于零售电商平台来说处于中等偏上水平。

• 建议进一步分析不同品类（如家电 vs. 饰品）的客单价差异。如果 AOV 较高是受少数高价商品驱动，平台可能需要增加凑单活动来提升普通商品的件单价。

2. 运营效率与履约质量 (Operational Efficiency)
• 极高的送达率 (97.02%)：这是一个非常出色的表现。97% 的妥投率意味着平台的物流链路（从卖家发货到快递承运再到客户签收）非常稳定且高效。

• 异常订单关注：虽然表现优秀，但仍有约 3% (2,963个) 的订单未能成功送达（包括已取消、未发货或运输中丢失）。

• 建议专门查询 order_status 非 delivered 的订单分布。如果是 canceled（取消）占比高，需排查是否是库存不足或支付问题；如果是 unavailable（缺货），则需加强对供应商的库存管理。

3. 盈利能力与增长潜力
• GMV 构成：由于 GMV (1584万) 包含了运费（Freight），你可以通过对比 price 总和与 freight_value 总和来判断运费成本对消费者购买决策的影响。

• 如果运费占比过高，可能会抑制客单价的进一步增长。

总结：
• 平台经营表现强劲。总订单量接近 10万大关，GMV 突破 1500万，
  展现了良好的市场基础。特别是在履约端，97.02% 的送达率体现了极高的物流可靠性。
  后续建议关注 3% 未妥投订单的归因分析，并尝试通过营销手段提升 160.58 的客单价，
  以挖掘更大的盈利空间。




[

  {

    "total_orders": "99441",

    "delivered_orders": "96478",

    "delivery_rate": "97.02%",

    "total_gmv": "15843553.24",

    "aov": "160.58"

  }

]

*/

-------------------------------------------------------------------------
----月度趋势分析----

SELECT
    TO_CHAR(order_purchase_timestamp, 'YYYY-MM') as month,
    COUNT(o.order_id) as monthly_orders,
    ROUND(SUM(item_total_value)::NUMERIC, 2) as monthly_gmv
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY MONTH
ORDER BY MONTH

/*
1. 整体趋势：爆发式增长
• 增长速度惊人：从 2017 年 1 月的 955 单增长到 2017 年 11 月的 8,665 单，短短 10 个月内订单量翻了 9 倍。

• GMV 破百万里程碑：2017 年 11 月是平台的一个重要转折点，单月成交额首次突破 100 万。

2. 关键节点分析：双十一/黑色星期五效应
• 年度高峰（2017-11）：2017 年 11 月是整个数据周期中的最高点，订单量（8,665）和 GMV（117.9 万）均达到峰值。

• 这反映了该市场在 11 月具有极强的促销敏感度（可能是巴西的 Black Friday）。虽然 12 月有所回落，
  但整体水位（基线）已经明显提升，留存下了大量活跃用户。

3. 业务稳定性：进入成熟期
• 平台稳定性提升：进入 2018 年后，月度订单量稳定在 7,000 - 8,000 之间，GMV 稳定在 100 万 - 110 万 左右。

• 这说明平台已经走出了初期的高速扩张阶段，进入了稳定的运营期。2018 年上半年的表现非常稳健，没有出现大幅波动。

4. 异常数据提示（Data Quality Alert）
数据断层与结束：

2016-09 至 2016-12：订单极少且不连续，属于平台试运行或数据录入初期。

2018-09：数据突然跌至 1 单。

• 这显然不是业务崩盘，而是数据集采集截止。在做报告时，应明确说明“2018年9月数据不完整，不纳入趋势评估”，以免误导决策。

[
  {
    "month": "2016-09",
    "monthly_orders": "6",
    "monthly_gmv": "354.75"
  },
  {
    "month": "2016-10",
    "monthly_orders": "363",
    "monthly_gmv": "56808.84"
  },
  {
    "month": "2016-12",
    "monthly_orders": "1",
    "monthly_gmv": "19.62"
  },
  {
    "month": "2017-01",
    "monthly_orders": "955",
    "monthly_gmv": "137188.49"
  },
  {
    "month": "2017-02",
    "monthly_orders": "1951",
    "monthly_gmv": "286280.62"
  },
  {
    "month": "2017-03",
    "monthly_orders": "3000",
    "monthly_gmv": "432048.59"
  },
  {
    "month": "2017-04",
    "monthly_orders": "2684",
    "monthly_gmv": "412422.24"
  },
  {
    "month": "2017-05",
    "monthly_orders": "4136",
    "monthly_gmv": "586190.95"
  },
  {
    "month": "2017-06",
    "monthly_orders": "3583",
    "monthly_gmv": "502963.04"
  },
  {
    "month": "2017-07",
    "monthly_orders": "4519",
    "monthly_gmv": "584971.62"
  },
  {
    "month": "2017-08",
    "monthly_orders": "4910",
    "monthly_gmv": "668204.60"
  },
  {
    "month": "2017-09",
    "monthly_orders": "4831",
    "monthly_gmv": "720398.91"
  },
  {
    "month": "2017-10",
    "monthly_orders": "5322",
    "monthly_gmv": "769312.37"
  },
  {
    "month": "2017-11",
    "monthly_orders": "8665",
    "monthly_gmv": "1179143.77"
  },
  {
    "month": "2017-12",
    "monthly_orders": "6308",
    "monthly_gmv": "863547.23"
  },
  {
    "month": "2018-01",
    "monthly_orders": "8208",
    "monthly_gmv": "1107301.89"
  },
  {
    "month": "2018-02",
    "monthly_orders": "7672",
    "monthly_gmv": "986908.96"
  },
  {
    "month": "2018-03",
    "monthly_orders": "8217",
    "monthly_gmv": "1155126.82"
  },
  {
    "month": "2018-04",
    "monthly_orders": "7975",
    "monthly_gmv": "1159698.04"
  },
  {
    "month": "2018-05",
    "monthly_orders": "7925",
    "monthly_gmv": "1149781.82"
  },
  {
    "month": "2018-06",
    "monthly_orders": "7078",
    "monthly_gmv": "1022677.11"
  },
  {
    "month": "2018-07",
    "monthly_orders": "7092",
    "monthly_gmv": "1058728.03"
  },
  {
    "month": "2018-08",
    "monthly_orders": "7248",
    "monthly_gmv": "1003308.47"
  },
  {
    "month": "2018-09",
    "monthly_orders": "1",
    "monthly_gmv": "166.46"
  }
]
*/