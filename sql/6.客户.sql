WITH customer_spending AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(i.price) AS total_spent,
        MAX(o.order_purchase_timestamp) AS last_purchase_date
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered' -- 仅计算已送达的有效订单
    GROUP BY c.customer_unique_id
),
retention_stats AS (
    SELECT 
        COUNT(*) AS total_customers,
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
        AVG(total_spent) AS avg_per_customer,
        -- 找出前 5% 的高消费门槛
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_spent) AS top_5_percentile
    FROM customer_spending
)
SELECT 
    total_customers AS 总客户数,
    repeat_customers AS 复购客户数,
    ROUND((repeat_customers * 100.0 / total_customers)::numeric, 2) || '%' AS 复购率,
    ROUND(avg_per_customer::numeric, 2) AS 平均客户产值,
    ROUND(top_5_percentile::numeric, 2) AS 高价值门槛_前5
FROM retention_stats;
/*
1. 忠诚度极低：平台面临“留存挑战”
• 核心数据：复购率仅为 3.00%。

• 洞察：绝大多数客户（97%）在平台上属于“一锤子买卖”。这说明 Olist 目前更像是一个搜索引擎渠道（客户需要买某个东西，搜到了就买，买完就走），而不是一个具有品牌粘性的购物社区。

• 业务风险：获客成本（CAC）如果过高，平台将很难盈利，因为你几乎无法从客户的第二次、第三次购买中赚回成本。

• 价值分布：平均客户产值（ARPU）仅为 141.62。这意味着这前 5% 的人，其消费能力至少是普通客户的 3 倍 以上。这群人是平台最需要维护的“超级用户”。

是否存在高价值群体？
• 结论：存在，但规模极小。

[
  {
    "总客户数": "93358",
    "复购客户数": "2801",
    "复购率": "3.00%",
    "平均客户产值": "141.62",
    "高价值门槛_前5": "419.81"
  }
]

*/


---------------------------------------------

WITH rfm_base AS (
    SELECT 
        c.customer_unique_id,
        -- 计算距离参考日期（数据集最后一天）的天数
        DATE_PART('day', (SELECT MAX(order_purchase_timestamp) FROM olist_orders) - MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(i.price) AS monetary
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_items i ON o.order_id = i.order_id
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    recency AS 沉睡天数,
    frequency AS 购买频次,
    ROUND(monetary::numeric, 2) AS 总消费金额,
    CASE 
        WHEN frequency > 1 AND monetary > 500 AND recency < 90 THEN '核心VIP客户'
        WHEN frequency > 1 AND recency >= 90 THEN '需挽留高价值客户'
        WHEN frequency = 1 AND monetary > 500 THEN '高消费新客'
        ELSE '普通客户'
    END AS 客户等级
FROM rfm_base
ORDER BY monetary DESC
LIMIT 20; -- 先看前20名最顶级的客户


/*
核心发现：在前 20 名消费最高的客户中，80% 以上 被标记为“高消费新客”。

• 洞察：这些客户单次下单金额惊人（最高达到 13,440 雷亚尔，是平均值的 90 倍），但绝大多数人只买过一次。

• 很多客户的“沉睡天数”超过了 300-600 天。这意味着这些曾经贡献巨大的客户，在两年内都没有再回到平台。

2. “核心 VIP”极度稀缺（极高粘性者）
• 明星案例：customer_unique_id: c8460e42...

• 表现：购买频次 4 次，总消费 4,080，且沉睡天数仅 70 天。

• 分析：他是这名单里唯一的“健康”高价值客户——既有钱，又忠诚，且最近还活跃。这种客户是平台最应该分析的“种子用户”，
  需要搞清楚他买了什么，为什么他会反复回来。

3. 高客单价 vs. 低忠诚度
• 结论：平台具备吸引“购买昂贵商品（如大家电、专业设备）”客户的能力。

• 问题：这些客户在完成大件购买后，平台没能成功将他们转化为日常消费用户。
  他们把 Olist 当成了“大件购买工具”，而不是日常购物平台。

平台是否存在高价值客户群体？

• 存在，但目前的结构非常不稳定。




挽留高价值客户：

• 针对名单中沉睡天数在 100-200 天左右的“高消费新客”，发送高面额的无门槛优惠券。比起获客，挽回这批有钱人的成本更低。

分析购物篮：

• 调查这些高消费客户买的是什么品类。如果是办公用品或专业设备，可以针对性地推出企业采购（B2B）服务。

会员锁定：

• 如果客户单次消费超过 1000 雷亚尔，自动赠送 1 年的免邮权益或 VIP 身份，强行增加他的复购动机。


*/