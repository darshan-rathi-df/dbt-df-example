WITH "customer_r_score" AS (
  SELECT
    "customer_id",
    CASE
      WHEN MAX("created_at") IS NULL
      THEN 0
      ELSE CAST(EXTRACT(DAY FROM (
        DATE_TRUNC('month', CAST('2023-05-31' AS DATE)) - DATE_TRUNC('month', CAST(MAX("created_at") AS DATE))
      )) AS INT)
    END AS "diff_date"
  FROM "public"."fact_order_table"
  GROUP BY
    "customer_id"
), "customer_f_score" AS (
  SELECT
    "customer_id",
    COUNT(DISTINCT DATE_TRUNC('day', CAST("created_at" AS DATE))) AS "n_purchases"
  FROM "public"."fact_order_table"
  WHERE
    CAST("created_at" AS DATE) BETWEEN CAST('2023-04-30' AS DATE) - INTERVAL '30 day' AND CAST('2023-04-30' AS DATE)
  GROUP BY
    "customer_id"
), "customer_loyalty_score" AS (
  SELECT
    "c"."id" AS "customer_id",
    COALESCE((
      "f"."n_purchases" / 30.0
    ) * 100, 0) AS "f_score",
    COALESCE((
      (
        30 - "r"."diff_date"
      ) / 30.0
    ) * 100, 0) AS "r_score"
  FROM "public"."dim_customer_table" AS "c"
  LEFT JOIN "customer_r_score" AS "r"
    ON "c"."id" = "r"."customer_id"
  LEFT JOIN "customer_f_score" AS "f"
    ON "c"."id" = "f"."customer_id"
), "customer_churn" AS (
  SELECT
    "customer_id",
    CASE
      WHEN (
        "r_score" * "f_score" / 10000.0
      ) < 0
      THEN 0
      ELSE (
        "r_score" * "f_score" / 10000.0
      )
    END AS "loyalty_score",
    CASE WHEN (
      "r_score" * "f_score" / 10000.0
    ) < 0.2 THEN 1 ELSE 0 END AS "churn"
  FROM "customer_loyalty_score"
), "customer_churn_rate" AS (
  SELECT
    DATE_TRUNC('month', CAST("created_at" AS DATE)) AS "month",
    COUNT(DISTINCT "fact_order_table"."customer_id") FILTER(WHERE
      "churn" = 1) AS "churned_customers",
    COUNT(DISTINCT "fact_order_table"."customer_id") AS "total_customers"
  FROM "public"."fact_order_table"
  JOIN "customer_churn"
    ON "fact_order_table"."customer_id" = "customer_churn"."customer_id"
  WHERE
    CAST("created_at" AS DATE) BETWEEN CAST('2023-01-01' AS DATE) AND CAST('2023-05-31' AS DATE)
  GROUP BY
    "month"
)
SELECT
  TO_CHAR("month", 'YYYY-MM') AS "month",
  "churned_customers",
  "total_customers",
  ROUND(CAST("churned_customers" AS DECIMAL) / "total_customers" * 100, 2) AS "churn_rate"
FROM "customer_churn_rate"