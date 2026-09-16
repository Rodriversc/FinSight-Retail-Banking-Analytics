-- ============================================================
-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 08 - Views and Final KPI's
-- ============================================================



-- 3H.1 - algemene management KPI snapshot --
 
SELECT
    (SELECT COUNT(*) 
     FROM dbo.customers_raw) 
        AS totaal_klanten,
 
    (SELECT COUNT(*) 
     FROM dbo.accounts_raw) 
        AS totaal_accounts,
 
    (SELECT COUNT(*) 
     FROM dbo.loans_raw) 
        AS totaal_leningen,
 
    (SELECT COUNT(*) 
     FROM dbo.transactions_clean) 
        AS totaal_transacties,
 
    (SELECT ROUND(SUM(original_principal_eur), 2)
     FROM dbo.loans_raw) 
        AS totaal_verstrekt_krediet_eur,
 
    (SELECT ROUND(SUM(outstanding_balance_eur), 2)
     FROM dbo.loans_raw) 
        AS openstaand_krediet_eur,
 
    (SELECT ROUND(
                100.0 * SUM(CAST(default_flag AS INT))
                / NULLIF(COUNT(*), 0),
                2
            )
     FROM dbo.loans_raw) 
        AS default_rate_pct,
 
    (SELECT SUM(CAST(is_suspicious AS INT))
     FROM dbo.transactions_clean) 
        AS suspicious_transacties,
 
    (SELECT ROUND(
                100.0 * SUM(CAST(is_suspicious AS INT))
                / NULLIF(COUNT(*), 0),
                2
            )
     FROM dbo.transactions_clean) 
        AS suspicious_rate_pct;
GO
 
 
-- 3H.2 - view: Customer 360 samenvatting --
 
CREATE OR ALTER VIEW dbo.vw_customer_summary
AS
 
WITH account_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_accounts,
 
        COUNT(
            DISTINCT account_type
        ) AS aantal_accounttypes,
 
        SUM(opening_balance_eur)
            AS totaal_opening_balance_eur,
 
        MAX(credit_limit_eur)
            AS hoogste_credit_limit_eur
 
    FROM dbo.accounts_raw
 
    GROUP BY customer_id
),
 
loan_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_leningen,
 
        SUM(original_principal_eur)
            AS totaal_verstrekt_krediet_eur,
 
        SUM(outstanding_balance_eur)
            AS openstaand_krediet_eur,
 
        MAX(days_past_due)
            AS max_days_past_due,
 
        SUM(
            CAST(default_flag AS INT)
        ) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
transaction_metrics AS
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
        ) AS totale_inflow_eur,
 
        ABS(
            SUM(
                CASE
                    WHEN flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ) AS totale_outflow_eur,
 
        SUM(amount_eur)
            AS netto_cashflow_eur,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties,
 
        SUM(
            CAST(is_international AS INT)
        ) AS internationale_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT
    c.customer_id,
    c.country,
    c.age_group,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
    c.acquisition_channel,
    c.join_date,
    c.digital_active,
 
    ISNULL(a.aantal_accounts, 0)
        AS aantal_accounts,
 
    ISNULL(a.aantal_accounttypes, 0)
        AS aantal_accounttypes,
 
    ISNULL(a.totaal_opening_balance_eur, 0)
        AS totaal_opening_balance_eur,
 
    ISNULL(a.hoogste_credit_limit_eur, 0)
        AS hoogste_credit_limit_eur,
 
    ISNULL(l.aantal_leningen, 0)
        AS aantal_leningen,
 
    ISNULL(l.totaal_verstrekt_krediet_eur, 0)
        AS totaal_verstrekt_krediet_eur,
 
    ISNULL(l.openstaand_krediet_eur, 0)
        AS openstaand_krediet_eur,
 
    ISNULL(l.max_days_past_due, 0)
        AS max_days_past_due,
 
    ISNULL(l.aantal_defaults, 0)
        AS aantal_defaults,
 
    ISNULL(t.aantal_transacties, 0)
        AS aantal_transacties,
 
    ISNULL(t.totale_inflow_eur, 0)
        AS totale_inflow_eur,
 
    ISNULL(t.totale_outflow_eur, 0)
        AS totale_outflow_eur,
 
    ISNULL(t.netto_cashflow_eur, 0)
        AS netto_cashflow_eur,
 
    ISNULL(t.suspicious_transacties, 0)
        AS suspicious_transacties,
 
    ISNULL(t.internationale_transacties, 0)
        AS internationale_transacties
 
FROM dbo.customers_raw AS c
 
LEFT JOIN account_metrics AS a
    ON c.customer_id = a.customer_id
 
LEFT JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
LEFT JOIN transaction_metrics AS t
    ON c.customer_id = t.customer_id;
GO
 
 
-- 3H.3 - view: maandelijkse financiële KPI's --
 
CREATE OR ALTER VIEW dbo.vw_monthly_financial_kpis
AS
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
    COUNT(*) AS aantal_transacties,
 
    ROUND(
        SUM(
            CASE
                WHEN flow_direction = 'Inflow'
                THEN amount_eur
                ELSE 0
            END
        ),
        2
    ) AS inflow_eur,
 
    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ),
        2
    ) AS outflow_eur,
 
    ROUND(
        SUM(amount_eur),
        2
    ) AS netto_cashflow_eur,
 
    ROUND(
        AVG(ABS(amount_eur)),
        2
    ) AS gemiddeld_transactiebedrag_eur,
 
    SUM(
        CAST(is_suspicious AS INT)
    ) AS suspicious_transacties,
 
    ROUND(
        100.0 * SUM(CAST(is_suspicious AS INT))
        / NULLIF(COUNT(*), 0),
        2
    ) AS suspicious_rate_pct,
 
    SUM(
        CAST(is_international AS INT)
    ) AS internationale_transacties,
 
    ROUND(
        100.0 * SUM(CAST(is_international AS INT))
        / NULLIF(COUNT(*), 0),
        2
    ) AS international_rate_pct
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    );
GO
 
 
-- 3H.4 - view: risk monitoring per klant --
 
CREATE OR ALTER VIEW dbo.vw_risk_monitoring
AS
 
WITH loan_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_leningen,
 
        SUM(outstanding_balance_eur)
            AS openstaand_krediet_eur,
 
        MAX(days_past_due)
            AS max_days_past_due,
 
        SUM(
            CAST(default_flag AS INT)
        ) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
transaction_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT
    c.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    ISNULL(l.aantal_leningen, 0)
        AS aantal_leningen,
 
    ISNULL(l.openstaand_krediet_eur, 0)
        AS openstaand_krediet_eur,
 
    ISNULL(l.max_days_past_due, 0)
        AS max_days_past_due,
 
    ISNULL(l.aantal_defaults, 0)
        AS aantal_defaults,
 
    ISNULL(t.aantal_transacties, 0)
        AS aantal_transacties,
 
    ISNULL(t.suspicious_transacties, 0)
        AS suspicious_transacties,
 
    CASE
        WHEN ISNULL(l.aantal_defaults, 0) > 0
             OR ISNULL(l.max_days_past_due, 0) >= 90
        THEN 'High'
 
        WHEN ISNULL(l.max_days_past_due, 0) >= 30
             OR ISNULL(t.suspicious_transacties, 0) > 0
             OR c.risk_score < 600
        THEN 'Medium'
 
        ELSE 'Normal'
    END AS monitoring_level
 
FROM dbo.customers_raw AS c
 
LEFT JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
LEFT JOIN transaction_metrics AS t
    ON c.customer_id = t.customer_id;
GO
 
 
-- 3H.5 - managementoverzicht per klantsegment via Customer 360 view --
 
SELECT
    segment,
 
    COUNT(*) AS aantal_klanten,
 
    ROUND(
        AVG(
            CAST(annual_income_eur AS DECIMAL(12,2))
        ),
        2
    ) AS gemiddeld_inkomen_eur,
 
    ROUND(
        AVG(
            CAST(risk_score AS DECIMAL(10,2))
        ),
        1
    ) AS gemiddelde_risicoscore,
 
    ROUND(
        AVG(
            CAST(aantal_accounts AS DECIMAL(10,2))
        ),
        2
    ) AS gemiddeld_accounts_per_klant,
 
    ROUND(
        AVG(
            CAST(aantal_leningen AS DECIMAL(10,2))
        ),
        2
    ) AS gemiddeld_leningen_per_klant,
 
    ROUND(
        SUM(openstaand_krediet_eur),
        2
    ) AS totaal_openstaand_krediet_eur,
 
    SUM(aantal_defaults)
        AS totaal_defaults,
 
    SUM(suspicious_transacties)
        AS totaal_suspicious_transacties,
 
    ROUND(
        AVG(netto_cashflow_eur),
        2
    ) AS gemiddelde_netto_cashflow_eur
 
FROM dbo.vw_customer_summary
 
GROUP BY segment
 
ORDER BY gemiddeld_inkomen_eur DESC;
 
 
-- 3H.6 - managementoverzicht risk monitoring --
 
SELECT
    monitoring_level,
 
    COUNT(*) AS aantal_klanten,
 
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_klanten,
 
    ROUND(
        SUM(openstaand_krediet_eur),
        2
    ) AS openstaand_krediet_eur,
 
    SUM(aantal_defaults)
        AS aantal_defaults,
 
    SUM(suspicious_transacties)
        AS suspicious_transacties
 
FROM dbo.vw_risk_monitoring
 
GROUP BY monitoring_level
 
ORDER BY
    CASE monitoring_level
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END;
 
 
-- 3H.7 - top 25 klanten uit risk monitoring --
 
SELECT TOP 25
    customer_id,
    segment,
    annual_income_eur,
    risk_score,
    aantal_leningen,
    openstaand_krediet_eur,
    max_days_past_due,
    aantal_defaults,
    aantal_transacties,
    suspicious_transacties,
    monitoring_level
 
FROM dbo.vw_risk_monitoring
 
WHERE monitoring_level <> 'Normal'
 
ORDER BY
    CASE monitoring_level
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
 
    aantal_defaults DESC,
    max_days_past_due DESC,
    suspicious_transacties DESC,
    openstaand_krediet_eur DESC;
 
 
-- 3H.8 - maandelijkse KPI view controleren --
 
SELECT
    maand,
    aantal_transacties,
    inflow_eur,
    outflow_eur,
    netto_cashflow_eur,
    gemiddeld_transactiebedrag_eur,
    suspicious_transacties,
    suspicious_rate_pct,
    internationale_transacties,
    international_rate_pct
 
FROM dbo.vw_monthly_financial_kpis
 
ORDER BY maand;
 
 
-- 3H.9 - Customer 360 view controleren --
 
SELECT TOP 20
    customer_id,
    segment,
    annual_income_eur,
    risk_score,
    aantal_accounts,
    aantal_leningen,
    openstaand_krediet_eur,
    aantal_transacties,
    netto_cashflow_eur,
    suspicious_transacties
 
FROM dbo.vw_customer_summary
 
ORDER BY customer_id;
 
 
-- 3H.10 - controleren welke portfolio views bestaan --
 
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
 
FROM INFORMATION_SCHEMA.VIEWS
 
WHERE TABLE_NAME IN
(
    'vw_customer_summary',
    'vw_monthly_financial_kpis',
    'vw_risk_monitoring'
)
 
ORDER BY TABLE_NAME;