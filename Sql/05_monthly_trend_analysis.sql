-- ============================================================
-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 05 - Monthly Trend Analysis
-- ============================================================
 
USE FinSight;
GO

-- 3E.1 - maandelijks aantal transacties --
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
    COUNT(*) AS aantal_transacties
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    )
 
ORDER BY maand;
 
 
-- 3E.2 - maandelijkse inflow, outflow en netto cashflow --
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
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
    ) AS netto_cashflow_eur
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    )
 
ORDER BY maand;
 
 
-- 3E.3 - gemiddeld transactiebedrag per maand --
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
    COUNT(*) AS aantal_transacties,
 
    ROUND(
        AVG(ABS(amount_eur)),
        2
    ) AS gemiddeld_transactiebedrag_eur
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    )
 
ORDER BY maand;
 
 
-- 3E.4 - maandelijkse trend suspicious transactions --
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
    COUNT(*) AS aantal_transacties,
 
    SUM(
        CAST(is_suspicious AS INT)
    ) AS suspicious_transacties,
 
    ROUND(
        100.0 * SUM(CAST(is_suspicious AS INT))
        / COUNT(*),
        2
    ) AS suspicious_rate_pct
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    )
 
ORDER BY maand;
 
 
-- 3E.5 - maandelijkse trend internationale transacties --
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
    COUNT(*) AS aantal_transacties,
 
    SUM(
        CAST(is_international AS INT)
    ) AS internationale_transacties,
 
    ROUND(
        100.0 * SUM(CAST(is_international AS INT))
        / COUNT(*),
        2
    ) AS international_rate_pct
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    )
 
ORDER BY maand;
 
 
-- 3E.6 - maandelijkse uitgaven voor Travel en E-commerce --
 
SELECT
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    ) AS maand,
 
    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN category = 'Travel'
                    AND flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ),
        2
    ) AS travel_uitgaven_eur,
 
    ROUND(
        ABS(
            SUM(
                CASE
                    WHEN category = 'E-commerce'
                    AND flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ),
        2
    ) AS ecommerce_uitgaven_eur
 
FROM dbo.transactions_clean
 
GROUP BY
    DATEFROMPARTS(
        YEAR(transaction_datetime),
        MONTH(transaction_datetime),
        1
    )
 
ORDER BY maand;
 
 
-- 3E.7 - maand-op-maand groei van het aantal transacties --
 
WITH maand_metrics AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(transaction_datetime),
            MONTH(transaction_datetime),
            1
        ) AS maand,
 
        COUNT(*) AS aantal_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY
        DATEFROMPARTS(
            YEAR(transaction_datetime),
            MONTH(transaction_datetime),
            1
        )
),
 
vorige_maand AS
(
    SELECT
        maand,
        aantal_transacties,
 
        LAG(aantal_transacties) OVER (
            ORDER BY maand
        ) AS transacties_vorige_maand
 
    FROM maand_metrics
)
 
SELECT
    maand,
    aantal_transacties,
    transacties_vorige_maand,
 
    ROUND(
        100.0 *
        (aantal_transacties - transacties_vorige_maand)
        / NULLIF(transacties_vorige_maand, 0),
        2
    ) AS groei_pct
 
FROM vorige_maand
 
ORDER BY maand;
 
 
-- 3E.8 - maand-op-maand groei van totale uitgaven --
 
WITH maand_metrics AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(transaction_datetime),
            MONTH(transaction_datetime),
            1
        ) AS maand,
 
        ABS(
            SUM(
                CASE
                    WHEN flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ) AS totale_uitgaven_eur
 
    FROM dbo.transactions_clean
 
    GROUP BY
        DATEFROMPARTS(
            YEAR(transaction_datetime),
            MONTH(transaction_datetime),
            1
        )
),
 
vorige_maand AS
(
    SELECT
        maand,
        totale_uitgaven_eur,
 
        LAG(totale_uitgaven_eur) OVER (
            ORDER BY maand
        ) AS uitgaven_vorige_maand
 
    FROM maand_metrics
)
 
SELECT
    maand,
 
    ROUND(
        totale_uitgaven_eur,
        2
    ) AS totale_uitgaven_eur,
 
    ROUND(
        uitgaven_vorige_maand,
        2
    ) AS uitgaven_vorige_maand_eur,
 
    ROUND(
        100.0 *
        (totale_uitgaven_eur - uitgaven_vorige_maand)
        / NULLIF(uitgaven_vorige_maand, 0),
        2
    ) AS groei_pct
 
FROM vorige_maand
 
ORDER BY maand;