WITH paid_clicks AS (
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
        AND s.visit_date <= COALESCE(l.created_at, '4444-01-01')
),

indexed_paid_clicks AS (
    SELECT
        *,
        ROW_NUMBER()
            OVER (PARTITION BY visitor_id ORDER BY visit_date DESC)
        AS session_number
    FROM paid_clicks
)

SELECT
    i.visitor_id,
    i.visit_date,
    i."source" AS utm_source,
    i.medium AS utm_medium,
    i.campaign AS utm_campaign,
    i.lead_id,
    i.created_at,
    i.amount,
    i.closing_reason,
    i.status_id
FROM indexed_paid_clicks AS i
WHERE i.session_number = 1
ORDER BY
    i.amount DESC NULLS LAST, i.visit_date ASC,
    utm_source ASC, utm_medium ASC, utm_campaign ASC;
