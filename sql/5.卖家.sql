
WITH sellers_metrics as (
    SELECT 
        i.seller_id,
        -- 1. 卖家 GMV (仅计算商品价格总和)
        SUM(i.price) AS total_gmv,
        -- 2. 卖家订单量 (去重统计订单数)
        COUNT(DISTINCT i.order_id) AS total_orders,
        -- 3. 平均运费
        AVG(i.freight_value) AS avg_freight_value,
        -- 4. 卖家平均评分
        AVG(r.review_score) AS avg_review_score,
        -- 5. 卖家延迟率 (is_late 为 True 的订单数 / 总订单数)
        -- 注意：这里假设 orders_cleaned 中的 is_late 是 boolean 类型
        CAST(SUM(CASE WHEN o.is_late = TRUE THEN 1 ELSE 0 END) AS FLOAT) / 
        COUNT(o.order_id) AS late_delivery_rate
    FROM olist_order_items i
    JOIN olist_orders o ON i.order_id = o.order_id
    LEFT JOIN olist_order_reviews r ON i.order_id = r.order_id
    GROUP BY i.seller_id
    )

SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    ROUND(m.total_gmv::numeric, 2) AS gmv,
    m.total_orders,
    ROUND(m.avg_review_score::numeric, 2) AS avg_score,
    ROUND(m.avg_freight_value::numeric, 2) AS avg_freight,
    ROUND((m.late_delivery_rate * 100)::numeric, 2) || '%' AS late_rate,
    -- 简单的逻辑分类
    CASE 
        WHEN m.total_gmv > 5000 AND m.avg_review_score >= 4.5 THEN '明星卖家 (Top Tier)'
        WHEN m.avg_review_score < 3.0 OR m.late_delivery_rate > 0.2 THEN '重点监控 (High Risk)'
        ELSE '普通卖家'
    END AS seller_category
FROM 
    olist_sellers s
JOIN 
    sellers_metrics m ON s.seller_id = m.seller_id
ORDER BY 
    m.total_gmv DESC;

---------------------------------------

WITH seller_metrics AS (
    SELECT 
        i.seller_id,
        SUM(i.price) AS total_gmv,
        AVG(r.review_score) AS avg_score,
        CAST(SUM(CASE WHEN o.is_late = TRUE THEN 1 ELSE 0 END) AS FLOAT) / COUNT(o.order_id) AS late_rate
    FROM olist_order_items i
    JOIN olist_orders o ON i.order_id = o.order_id
    LEFT JOIN olist_order_reviews r ON i.order_id = r.order_id
    GROUP BY i.seller_id
),
categorized_sellers AS (
    SELECT 
        CASE 
            WHEN total_gmv > 5000 AND avg_score >= 4.5 AND late_rate < 0.1 THEN '明星卖家 (高销高分低延迟)'
            WHEN avg_score < 3.0 OR late_rate > 0.2 THEN '重点监控 (低分或高延迟风险)'
            ELSE '普通/潜力卖家'
        END AS category,
        total_gmv
    FROM seller_metrics
)

SELECT 
    category,
    COUNT(*) AS 卖家数量,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) || '%' AS 数量占比,
    ROUND(SUM(total_gmv)::numeric, 2) AS 贡献总GMV,
    ROUND(SUM(total_gmv) * 100.0 / SUM(SUM(total_gmv)) OVER(), 2) || '%' AS GMV占比
FROM categorized_sellers
GROUP BY category
ORDER BY 卖家数量 DESC;

/*
• 明星卖家极度稀缺：平台仅有 1.52%（47家）的卖家能同时做到“高销量、高评分、低延迟”。

• GMV 杠杆效应：虽然明星卖家数量极少，但他们的人均产值极高。普通卖家虽然占了约 90% 的 GMV，但因为基数巨大（2486家），个体贡献较分散。

显著的服务质量风险
• 高风险卖家比例偏高：有 18.16% 的卖家处于“重点监控”状态。

• 低效产出：这 500 多家风险卖家仅贡献了 6.32% 的 GMV，却可能消耗了平台 80% 以上的售后客服资源。

总结：这些卖家对销售额贡献不大，但对平台口碑（评分）和物流声誉（延迟）伤害极大。清理或整改这部分卖家，对 GMV 损失很小，但能大幅提升用户体验。
*/