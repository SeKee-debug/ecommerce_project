SELECT 
    p.product_category_name_english as category,
    -- 规模指标
    COUNT(DISTINCT i.order_id) as total_orders,
    ROUND(SUM(i.item_total_value)::NUMERIC, 2) as total_gmv,
    -- 体验指标
    ROUND(AVG(r.review_score)::NUMERIC, 2) as avg_review_score,
    -- 成本指标
    ROUND(AVG(i.freight_value)::NUMERIC, 2) as avg_freight,
    -- 运费占比指标 (freight_ratio = freight_value / item_total_value)
    ROUND(AVG(i.freight_value / i.item_total_value)::NUMERIC * 100, 2) || '%' as avg_freight_ratio
FROM olist_order_items i
JOIN olist_products p ON i.product_id = p.product_id
LEFT JOIN olist_order_reviews r ON i.order_id = r.order_id
GROUP BY category
ORDER BY total_gmv DESC;

------------------------------------

/*
1. 核心增长引擎：三大“现金牛”品类
Health & Beauty (健康美容)：

• 表现：GMV 全平台第一（144.6万），且评分高达 4.14。

• 洞察：这是平台最健康的品类。它的 avg_freight_ratio 约为 19.93%，处于合理区间。高评分意味着极强的客户粘性和低退货率，应作为品牌化和营销投入的首选。

Watches & Gifts (手表礼品)：

• 表现：GMV 位居第二（130.6万），但 avg_freight_ratio 仅为 13.14%。

• 洞察：这是平台盈利效率最高的品类。由于客单价高、体积小，运费对交易的摩擦极小。它是平台利润的核心来源，建议通过节日促销进一步放大规模。

2. “大而全”但体验承压的风险区
Bed Bath Table (家居床上用品)：

• 表现：订单量全平台最高（9,417单），但评分仅为 3.90。

• 洞察：这是典型的“引流品类”，虽能支撑起订单规模，但用户满意度低于平均水平。结合 20.3% 的运费占比，说明这类商品在大规模配送中容易出现物流损坏或描述不符的问题。

Furniture Decor (家具装饰)：

• 表现：订单量大（6,449单），但评分同样只有 3.90，且运费占比上升至 23.28%。

• 洞察：由于家具类商品通常较重且依赖长途运输，高昂的运费（平均 20.72）正在侵蚀用户体验。若不解决大件物流的破损和时效问题，该品类很难产生复购。

3. 高成本预警：受限于物流的品类
Housewares (家用品)：

• 数据点：avg_freight_ratio 高达 25.19%。

• 洞察：每卖出 100 块钱的东西，消费者就要付 25 块钱运费。这种高昂的物流附加费会严重抑制消费者的购买决策，使其在面对线下实体店或本地电商时缺乏竞争力。

4. 极端质量风险点
Fashion Male Clothing (男装时尚)：

• 数据点：评分跌至 3.64，是列表中的最低值之一。

• 洞察：虽然其运费占比不高（19.94%），但极低的评分暗示了严重的质量问题或尺码标准混乱。对于时尚类目，这种评分会导致极高的退货成本，建议对该类目的 Top 卖家进行服务质量约谈或重新审核。

总结：
平台目前形成了以‘健康美容’为核心、‘手表礼品’为利润高地的稳健格局。然而，家居与家具两大高频品类正面临 20% 以上的高额运费摩擦和评分下滑风险。


针对性建议 (Actionable Recommendations)
分级营销策略：

• 健康美容/手表：加大站内广告投放，作为平台的“门面”和利润引擎。

• 家居/家具：重点优化物流，引入更专业的“大件物流”合作伙伴，或尝试在核心消费城市（如 SP 圣保罗）推行本地仓储以降低那 23%+ 的运费占比。

运费杠杆优化：

• 对于 Housewares 等运费占比超过 25% 的类目，建议推行“组合销售（Bundling）”，通过提高订单总额来降低平均单件商品的运费占比。

负面监控：

• 针对评分低于 3.9 的三个核心大类（Bed Bath Table, Computers Accessories, Furniture Decor），
  需要下钻分析评论关键词。如果是由于“产品质量”，则加强品控；如果是“配送延迟”，则需重新校准物流承诺时间。

*/