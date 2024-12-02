WITH ads AS (
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) AS daily_sum
    FROM vk_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
    UNION ALL
    SELECT
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) AS daily_sum
    FROM ya_ads
    GROUP BY campaign_date, utm_source, utm_medium, utm_campaign
),

paid_clicks AS (
    SELECT
        s.visitor_id,
        s.visit_date,
        s."source",
        s.medium,
        s.campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM sessions AS s
    LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id
    WHERE
        s.medium != 'organic'
--        AND s.visit_date <= COALESCE(l.created_at, '4444-01-01')
),

indexed_paid_clicks AS (
    SELECT
        *,
        row_number()
            OVER (PARTITION BY visitor_id ORDER BY visit_date DESC)
        AS session_number
    FROM paid_clicks
),

last_paid_clicks AS (
    SELECT
        i.visitor_id,
        i.visit_date::date,
        i."source" AS utm_source,
        i.medium AS utm_medium,
        i.campaign AS utm_campaign,
        i.amount,
        ad.daily_sum,
        CASE i.visit_date < i.created_at WHEN TRUE THEN 1 ELSE 0 END AS flag
    FROM indexed_paid_clicks AS i
    LEFT JOIN ads AS ad
        ON
            date_trunc('day', i.visit_date) = ad.campaign_date
            AND i."source" = ad.utm_source
            AND i.medium = ad.utm_medium
            AND i.campaign = ad.utm_campaign
    WHERE
        i.session_number = 1
        AND i."source" IN ('yandex', 'vk', 'telegram')
)

SELECT
    visit_date,
    count(visitor_id) AS visitors_count,
    utm_source,
    utm_medium,
    utm_campaign,
    min(daily_sum) AS total_cost,
    sum(flag) AS leads_count,
    sum(sign(amount))::int AS purchases_count,
    sum(amount) AS revenue
FROM last_paid_clicks
GROUP BY visit_date, utm_source, utm_medium, utm_campaign
ORDER BY
    revenue DESC NULLS LAST, visit_date ASC, visitors_count DESC,
    utm_source ASC, utm_medium ASC, utm_campaign ASC;
