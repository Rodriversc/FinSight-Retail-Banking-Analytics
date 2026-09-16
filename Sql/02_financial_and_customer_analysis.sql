-- ============================================================
-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 02 - Financial and Customer Analysis
-- ============================================================


-- 3B.1 - financiële metrics per individuele klant --
 
WITH klant_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CASE
                WHEN flow_direction = 'Inflow'
                THEN amount_eur
                ELSE 0
            END
        ) AS totale_inflow,
 
        ABS(
            SUM(
                CASE
                    WHEN flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ) AS totale_outflow,
 
        SUM(amount_eur) AS netto_cashflow
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT TOP 100
    customer_id,
    aantal_transacties,
    totale_inflow,
    totale_outflow,
    netto_cashflow
 
FROM klant_metrics
 
ORDER BY aantal_transacties DESC;
 
 
-- 3B.2 - financieel gedrag per klantsegment --
 
WITH klant_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CASE
                WHEN flow_direction = 'Inflow'
                THEN amount_eur
                ELSE 0
            END
        ) AS totale_inflow,
 
        ABS(
            SUM(
                CASE
                    WHEN flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ) AS totale_outflow,
 
        SUM(amount_eur) AS netto_cashflow
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT
    c.segment,
 
    COUNT(DISTINCT c.customer_id) AS aantal_klanten,
 
    ROUND(
        AVG(CAST(k.aantal_transacties AS DECIMAL(10,2))),
        2
    ) AS gem_transacties_per_klant,
 
    ROUND(
        AVG(k.totale_inflow),
        2
    ) AS gem_inflow_per_klant,
 
    ROUND(
        AVG(k.totale_outflow),
        2
    ) AS gem_outflow_per_klant,
 
    ROUND(
        AVG(k.netto_cashflow),
        2
    ) AS gem_netto_cashflow_per_klant
 
FROM dbo.customers_raw AS c
 
INNER JOIN klant_metrics AS k
    ON c.customer_id = k.customer_id
 
GROUP BY c.segment
 
ORDER BY gem_netto_cashflow_per_klant DESC;
 
 
-- 3B.3 - klantprofiel per segment: inkomen, risicoscore en digitale activiteit --
 
SELECT
    segment,
 
    COUNT(*) AS aantal_klanten,
 
    ROUND(
        AVG(CAST(annual_income_eur AS DECIMAL(12,2))),
        2
    ) AS gemiddeld_jaarinkomen_eur,
 
    ROUND(
        AVG(CAST(risk_score AS DECIMAL(10,2))),
        1
    ) AS gemiddelde_risicoscore,
 
    SUM(
        CASE
            WHEN digital_active = 1
            THEN 1
            ELSE 0
        END
    ) AS digitaal_actieve_klanten
 
FROM dbo.customers_raw
 
GROUP BY segment
 
ORDER BY gemiddeld_jaarinkomen_eur DESC;
 
 
-- 3B.4 - digitale adoptie per klantsegment --
 
SELECT
    segment,
 
    COUNT(*) AS aantal_klanten,
 
    SUM(
        CASE
            WHEN digital_active = 1
            THEN 1
            ELSE 0
        END
    ) AS digitaal_actief,
 
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN digital_active = 1
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        1
    ) AS digitaal_actief_pct
 
FROM dbo.customers_raw
 
GROUP BY segment
 
ORDER BY digitaal_actief_pct DESC;