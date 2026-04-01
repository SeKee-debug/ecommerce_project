SELECT 
    c.customer_state AS state,
    -- 订单量与销售额
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(i.item_total_value)::NUMERIC, 2) AS total_gmv,
    -- 体验指标：平均评分
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
    -- 体验指标：平均配送时长（下单到送达）
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::NUMERIC, 2) AS avg_delivery_days,
    -- 体验指标：延迟率（实际送达时间 > 预计送达时间）
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)::NUMERIC 
        / COUNT(DISTINCT o.order_id) * 100, 2
    ) || '%' AS late_delivery_rate
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_items i ON o.order_id = i.order_id
LEFT JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'  -- 只计算已送达订单的体验，因为未送达订单没有完整的物流时长
GROUP BY c.customer_state
ORDER BY total_orders DESC;

/*
1. 市场贡献
• 圣保罗州 (SP) 的核心地位：SP 一个州的订单量（40,501）占了总样本的 40% 以上，GMV 贡献也接近 40%。
  它是平台的支柱市场，且各项指标（评分 4.18，物流 8.26 天）均远优于平均水平。

• 头部梯队：SP、RJ、MG、RS 和 PR 这五个州贡献了绝大部分的销售额。如果资源有限，应优先巩固这些地区的市场地位。

2. 高贡献但低体验的地区
• 里约热内卢 (RJ) 的物流风险：

• 异常点：作为订单量第二大的州（12,350单），其延迟率高达 14.95%，平均配送时间（14.7天）比周边的 SP 长了近一倍。

• 后果：这直接导致了其评分下降至 3.87。这说明 RJ 地区的物流效率已成为限制平台在该地区进一步发展的瓶颈。

• 东北部各州 (BA, CE, MA, AL)：

• 这些地区订单量虽小，但体验极差。例如 AL（阿拉戈斯州） 的延迟率竟然高达 26.2%，配送时长接近 24 天，评分仅为 3.82。

3. 物流时效与用户评分的强正相关性
数据揭示了一个清晰的规律：配送越久，评分越低。

• 高效区：SP（8.26天，4.18分）。

• 低效区：MA、AL、CE（配送均超过 20 天，评分均低于 3.9）。

• 特例分析：AP（阿马帕州） 虽然平均配送时长最长（27.75天），但评分却有 4.26。
  这可能说明该地区用户对物流已有“偏远心理预期”，或者当地的商品稀缺性较高，用户容忍度更强。

4. 延迟率预警
• AL (26.2%) 和 MA (22.7%) 的延迟率意味着每 4-5 个订单中就有 1 个无法准时送达。这不仅影响评分，还会大幅增加客服投诉成本和退货风险。

总结：
平台地区表现呈现明显的两极分化：东南区（以 SP 为首）贡献了近 70% 的 GMV 且运营极其高效；而以 RJ 为首的部分高产地区正面临严重的物流阻塞，
延迟率居高不下。建议下一季度的运营重心放在优化 RJ 的物流链路，并针对东北部高延迟省份重新校准 EDD 算法，以减缓评分下滑趋势。

业务建议
针对 RJ（里约）进行专项优化：
• RJ 订单量大但延迟高。建议排查是当地末端派送问题，还是分拨中心效率问题。考虑到其规模，哪怕将延迟率降低 5%，也能挽回大量潜在流失客户。

设置动态预计到达时间 (EDD)：
• 对于 AL、MA 等延迟率极高的州，系统应自动在下单页延长“预计送达时间”。与其承诺做不到的快，不如给用户一个准确的慢预期。

仓库布局优化 (Fulfilment Center)：
• 目前的物流优势高度集中在东南区（SP/MG）。若要拓展北部和东北部市场，考虑在 BA（巴伊亚州）或 PE（伯南布哥州）建立区域性仓储或分拨点，以打破“跨区运输”导致的漫长时耗。

运费策略调整：
• 对比 SP 和 RR 的配送天数（8天 vs 27天），若运费相差不大，则北部订单对平台来说可能是亏损的（高投诉、高咨询、长资金占用期）。可以考虑针对偏远地区设置更高的免邮门槛。
*/