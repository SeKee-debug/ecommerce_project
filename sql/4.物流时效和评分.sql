----准时 vs 延迟订单的评分对比分析----
SELECT 
    CASE WHEN is_late = TRUE THEN 'Late' ELSE 'On-time' END AS delivery_status,
    COUNT(o.order_id) AS total_orders,
    -- 平均评分
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
    -- 负评比例 (1-2分)
    ROUND(
        SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)::NUMERIC 
        / COUNT(o.order_id) * 100, 2
    ) || '%' AS negative_review_rate
FROM olist_orders o
JOIN olist_order_reviews r ON o.order_id = r.order_id
GROUP BY delivery_status;

/*
核心发现：
• 准时送达的订单平均分为 4.21（表现优秀），而一旦发生延迟，评分直接暴跌至 2.57

• 在 5 分制的评价体系中，2.57 分意味着该订单在用户心中已经处于“极不满意”状态。
  物流延迟不仅仅是让用户多等几天，而是直接改变了用户对商品乃至整个平台的质量感知。

负评风险：
• 负评率对比 (54.02% vs. 11.38%)：延迟订单的负评率（1-2分）高达 54.02%，是准时订单（11.38%）的 4.7 倍。

• 洞察：这意味着每发生一起物流延迟，就有一半以上的概率收获一个差评。这种高频的负面反馈会迅速拉低店铺和品类的整体权重，
  甚至导致用户流失到竞争对手平台。

用户容忍度：
• 即使商品本身完美，漫长的等待也会磨灭用户的好感。数据证明，11.38% 的准时订单依然有负评（可能源于质量问题），
  但延迟订单中却有高达 54% 的负评。

• 推论：物流时效是用户评价的“基准线”。基准线守住了，用户才会去评价商品本身；基准线崩塌了，
  用户往往会通过给差评来宣泄愤怒，此时商品质量再好也无济于事。

• 数据模型：目前延迟订单占比约为 7.7% (7701 / (7701 + 91523))。

总结：
• 数据证明，物流延迟对用户体验具有‘一票否决权’。延迟订单的平均分仅为 2.57，且负评率激增近 5 倍。
  目前平台 7.7% 的延迟订单贡献了不成比例的负面声量。

  
针对性建议 (Actionable Recommendations)
建立“延迟预警”机制：
• 既然 54% 的延迟会导致差评，平台应在订单即将超过 estimated_delivery_date 前，
  主动向用户推送补偿优惠券或诚恳的道歉信。主动告知比让用户被动等待更能挽回评分。

卖家激励与惩罚政策：
• 针对那 54% 负评率的“重灾区”，应对经常导致延迟的卖家进行限流或罚款，
  因为他们的物流短板正在消耗平台的品牌信用（Brand Equity）。

重新定义“承诺时效”：
• 分析结果显示准时订单表现极好，说明用户并不反感“慢”，但非常反感“迟”。建议在前端页面预留 
  1-2 天的物流缓冲期，将更多的“延迟”转化为“准时（即使稍慢）”。

  [
  {
    "delivery_status": "Late",
    "total_orders": "7701",
    "avg_review_score": "2.57",
    "negative_review_rate": "54.02%"
  },
  {
    "delivery_status": "On-time",
    "total_orders": "91523",
    "avg_review_score": "4.21",
    "negative_review_rate": "11.38%"
  }
]


*/


----配送时长区间 (Bins) 对评分的影响----
SELECT 
    CASE 
        WHEN delivery_days <= 7 THEN '0-7 Days'
        WHEN delivery_days <= 14 THEN '8-14 Days'
        WHEN delivery_days <= 21 THEN '15-21 Days'
        ELSE 'Over 21 Days'
    END AS delivery_window,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score
FROM olist_orders o
JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE delivery_days IS NOT NULL  -- 排除未送达订单
GROUP BY delivery_window
ORDER BY MIN(delivery_days);



/*
核心发现：
• 断崖式下跌：配送时间在 21 天以内时，评分尚能维持在 4.10 以上（属于良好范围）。
  但一旦突破 21 天，评分直接从 4.10 暴跌至 3.01。

• 这说明 21 天是巴西电商用户心理容忍的极限。超过这个时间，用户的购买喜悦感会完全消失，
  取而代之的是极度的焦虑和不满。

用户容忍度分析：14 天内的“黄金期”
低敏感区（0-14天）：

• 0-7 天评分：4.41

• 8-14 天评分：4.29

• 洞察：两者的差距仅为 0.12。这说明只要能在两周内送到，用户并不会因为早几天或晚几天而产生太大的情绪波动。
  对于平台来说，将 12 天的物流压缩到 8 天带来的评分提升，远不如将 25 天的物流压缩到 18 天带来的提升大。

订单分布带来的运营压力：
• 规模占比：超过 21 天的订单有 10,897 个，占比超过 11%。

• 后果：正是这 11% 的订单贡献了大量的低分，严重拉低了全平台的平均评分。
  如果能解决这部分超长待机的订单，平台的整体口碑将会有质的飞跃。


分析显示，配送时长与用户评分并非线性下降，而是存在一个明显的‘21天断崖’。只要物流控制在 14 天内，
用户满意度极高且稳定；一旦超过 21 天，评分将断崖式下降。

物流分级管理（Tiered Management）：

• 核心目标：不一定要追求极致的快（0-7天），但一定要消灭“极慢”（Over 21 days）。

• 策略：将资源集中在优化那些预计耗时超过 20 天的线路上。

设置 14 天主动触达机制：

• 当订单进入第 15 天仍未送达时，系统应自动触发“安抚流程”（如发送物流进度更新或小额补偿）。因为数据证明，从这一刻起，用户的评价风险开始迅速上升。

重新定义“偏远地区”承诺：

• 既然 21 天是红线，对于那些注定超过 21 天的偏远地区订单，应在下单前给予更明显的提示。提前的心理预期（EDD）管理，能有效缓解 3.01 分这种断崖式下跌。

运费与时效的权衡：

• 既然 0-7 天和 8-14 天评分差异极小，平台可以考虑推出更多“经济型”但稳定的物流方案（目标 10-14 天送达），从而在保证 4.2+ 评分的同时降低物流成本。

[
  {
    "delivery_window": "0-7 Days",
    "total_orders": "33685",
    "avg_review_score": "4.41"
  },
  {
    "delivery_window": "8-14 Days",
    "total_orders": "36396",
    "avg_review_score": "4.29"
  },
  {
    "delivery_window": "15-21 Days",
    "total_orders": "15381",
    "avg_review_score": "4.10"
  },
  {
    "delivery_window": "Over 21 Days",
    "total_orders": "10897",
    "avg_review_score": "3.01"
  }
]

*/