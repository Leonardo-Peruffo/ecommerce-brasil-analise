-- ============================================================================
-- 1. ANÁLISE DE EVOLUÇÃO TEMPORAL COM WINDOW FUNCTIONS
-- ============================================================================

-- 1.1 Faturamento mensal com variação MoM (Month over Month)
WITH faturamento_mensal AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS ano,
        MONTH(o.order_purchase_timestamp) AS mes,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS periodo,
        SUM(oi.price + oi.freight_value) AS faturamento
    FROM dbo.orders_clean o
    INNER JOIN dbo.order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    periodo,
    faturamento,
    LAG(faturamento, 1) OVER (ORDER BY ano, mes) AS faturamento_mes_anterior,
    faturamento - LAG(faturamento, 1) OVER (ORDER BY ano, mes) AS variacao_absoluta,
    CAST(
        (faturamento - LAG(faturamento, 1) OVER (ORDER BY ano, mes)) * 100.0 / 
        NULLIF(LAG(faturamento, 1) OVER (ORDER BY ano, mes), 0) 
    AS DECIMAL(10,2)) AS variacao_percentual,
    SUM(faturamento) OVER (ORDER BY ano, mes) AS faturamento_acumulado
FROM faturamento_mensal
ORDER BY ano, mes;


-- 1.2 Média móvel de 3 meses do ticket médio
WITH ticket_mensal AS (
    SELECT 
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS periodo,
        COUNT(DISTINCT o.order_id) AS qtd_pedidos,
        SUM(oi.price + oi.freight_value) AS faturamento,
        SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id) AS ticket_medio
    FROM dbo.orders_clean o
    INNER JOIN dbo.order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT 
    periodo,
    ticket_medio,
    AVG(ticket_medio) OVER (
        ORDER BY periodo 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS media_movel_3m
FROM ticket_mensal
ORDER BY periodo;


-- ============================================================================
-- 2. RANKING E ANÁLISE DE PARETO
-- ============================================================================

-- 2.1 Top 10 categorias por faturamento com ranking e % acumulado
WITH categoria_faturamento AS (
    SELECT 
        p.product_category_name AS categoria,
        SUM(oi.price + oi.freight_value) AS faturamento,
        COUNT(DISTINCT oi.order_id) AS qtd_pedidos
    FROM dbo.order_items_clean oi
    INNER JOIN dbo.products_clean p ON oi.product_id = p.product_id
    INNER JOIN dbo.orders_clean o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name
),
categoria_ranked AS (
    SELECT 
        categoria,
        faturamento,
        qtd_pedidos,
        RANK() OVER (ORDER BY faturamento DESC) AS ranking,
        SUM(faturamento) OVER () AS faturamento_total,
        SUM(faturamento) OVER (ORDER BY faturamento DESC) AS faturamento_acumulado
    FROM categoria_faturamento
)
SELECT TOP 10
    ranking,
    categoria,
    faturamento,
    qtd_pedidos,
    CAST(faturamento * 100.0 / faturamento_total AS DECIMAL(5,2)) AS pct_faturamento,
    CAST(faturamento_acumulado * 100.0 / faturamento_total AS DECIMAL(5,2)) AS pct_acumulado
FROM categoria_ranked
ORDER BY ranking;


-- 2.2 Ranking de vendedores por estado com DENSE_RANK
WITH vendedor_stats AS (
    SELECT 
        s.seller_id,
        s.seller_state,
        s.seller_city,
        COUNT(DISTINCT oi.order_id) AS qtd_vendas,
        SUM(oi.price) AS valor_vendido
    FROM dbo.order_items_clean oi
    INNER JOIN dbo.olist_sellers_dataset s ON oi.seller_id = s.seller_id
    GROUP BY s.seller_id, s.seller_state, s.seller_city
)
SELECT 
    seller_state,
    seller_city,
    seller_id,
    qtd_vendas,
    valor_vendido,
    DENSE_RANK() OVER (PARTITION BY seller_state ORDER BY valor_vendido DESC) AS rank_no_estado,
    RANK() OVER (ORDER BY valor_vendido DESC) AS rank_geral
FROM vendedor_stats
ORDER BY seller_state, rank_no_estado;


-- ============================================================================
-- 3. ANÁLISE DE COHORT - RETENÇÃO DE CLIENTES
-- ============================================================================

-- 3.1 Cohort de primeira compra e análise de recompra
WITH primeira_compra AS (
    SELECT 
        c.customer_unique_id,
        MIN(CAST(o.order_purchase_timestamp AS DATE)) AS data_primeira_compra,
        FORMAT(MIN(o.order_purchase_timestamp), 'yyyy-MM') AS cohort_mes
    FROM dbo.orders_clean o
    INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
todas_compras AS (
    SELECT 
        c.customer_unique_id,
        CAST(o.order_purchase_timestamp AS DATE) AS data_compra,
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS mes_compra
    FROM dbo.orders_clean o
    INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_data AS (
    SELECT 
        pc.cohort_mes,
        tc.mes_compra,
        DATEDIFF(MONTH, pc.data_primeira_compra, tc.data_compra) AS meses_desde_primeira_compra,
        COUNT(DISTINCT pc.customer_unique_id) AS clientes_ativos
    FROM primeira_compra pc
    INNER JOIN todas_compras tc ON pc.customer_unique_id = tc.customer_unique_id
    GROUP BY pc.cohort_mes, tc.mes_compra, 
             DATEDIFF(MONTH, pc.data_primeira_compra, tc.data_compra)
)
SELECT 
    cohort_mes,
    meses_desde_primeira_compra,
    clientes_ativos,
    FIRST_VALUE(clientes_ativos) OVER (
        PARTITION BY cohort_mes 
        ORDER BY meses_desde_primeira_compra
    ) AS clientes_cohort_inicial,
    CAST(clientes_ativos * 100.0 / 
        FIRST_VALUE(clientes_ativos) OVER (
            PARTITION BY cohort_mes 
            ORDER BY meses_desde_primeira_compra
        ) AS DECIMAL(5,2)
    ) AS taxa_retencao
FROM cohort_data
WHERE meses_desde_primeira_compra <= 12
ORDER BY cohort_mes, meses_desde_primeira_compra;


-- ============================================================================
-- 4. ANÁLISE RFM (RECENCY, FREQUENCY, MONETARY)
-- ============================================================================

-- 4.1 Segmentação RFM dos clientes
WITH cliente_metricas AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp), '2018-10-17') AS recencia_dias,
        COUNT(DISTINCT o.order_id) AS frequencia,
        SUM(oi.price + oi.freight_value) AS valor_monetario
    FROM dbo.orders_clean o
    INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id
    INNER JOIN dbo.order_items_clean oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recencia_dias,
        frequencia,
        valor_monetario,
        NTILE(5) OVER (ORDER BY recencia_dias DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequencia) AS f_score,
        NTILE(5) OVER (ORDER BY valor_monetario) AS m_score
    FROM cliente_metricas
)
SELECT 
    customer_unique_id,
    recencia_dias,
    frequencia,
    valor_monetario,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4 THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
        ELSE 'Others'
    END AS segmento_cliente
FROM rfm_scores
ORDER BY valor_monetario DESC;


-- ============================================================================
-- 5. ANÁLISE DE PERFORMANCE DE ENTREGA
-- ============================================================================

-- 5.1 Taxa de atraso por estado com comparativo à média nacional
WITH entrega_stats AS (
    SELECT 
        c.customer_state,
        COUNT(*) AS total_pedidos,
        SUM(CASE WHEN o.flag_atraso = 1 THEN 1 ELSE 0 END) AS pedidos_atrasados,
        AVG(CAST(o.dias_entrega AS FLOAT)) AS media_dias_entrega
    FROM dbo.orders_clean o
    INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.dias_entrega IS NOT NULL
    GROUP BY c.customer_state
),
media_nacional AS (
    SELECT 
        AVG(CAST(dias_entrega AS FLOAT)) AS media_nacional_dias,
        CAST(SUM(flag_atraso) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS taxa_atraso_nacional
    FROM dbo.orders_clean
    WHERE order_status = 'delivered'
      AND dias_entrega IS NOT NULL
)
SELECT 
    e.customer_state AS estado,
    e.total_pedidos,
    e.pedidos_atrasados,
    CAST(e.pedidos_atrasados * 100.0 / e.total_pedidos AS DECIMAL(5,2)) AS taxa_atraso_pct,
    CAST(e.media_dias_entrega AS DECIMAL(5,1)) AS media_dias_entrega,
    CAST(m.media_nacional_dias AS DECIMAL(5,1)) AS media_nacional_dias,
    CAST(e.media_dias_entrega - m.media_nacional_dias AS DECIMAL(5,1)) AS diferenca_media_nacional,
    CASE 
        WHEN e.media_dias_entrega <= m.media_nacional_dias THEN 'Acima da Média'
        ELSE 'Abaixo da Média'
    END AS performance
FROM entrega_stats e
CROSS JOIN media_nacional m
ORDER BY e.media_dias_entrega;


-- ============================================================================
-- 6. ANÁLISE DE CORRELAÇÃO PREÇO x AVALIAÇÃO
-- ============================================================================

-- 6.1 Relação entre faixa de preço e satisfação do cliente
WITH pedido_completo AS (
    SELECT 
        o.order_id,
        SUM(oi.price + oi.freight_value) AS valor_pedido,
        r.review_score
    FROM dbo.orders_clean o
    INNER JOIN dbo.order_items_clean oi ON o.order_id = oi.order_id
    INNER JOIN dbo.reviews_clean r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, r.review_score
),
faixa_preco AS (
    SELECT 
        order_id,
        valor_pedido,
        review_score,
        CASE 
            WHEN valor_pedido < 50 THEN '1. Até R$50'
            WHEN valor_pedido < 100 THEN '2. R$50-100'
            WHEN valor_pedido < 200 THEN '3. R$100-200'
            WHEN valor_pedido < 500 THEN '4. R$200-500'
            ELSE '5. Acima de R$500'
        END AS faixa
    FROM pedido_completo
)
SELECT 
    faixa AS faixa_preco,
    COUNT(*) AS qtd_pedidos,
    CAST(AVG(CAST(review_score AS FLOAT)) AS DECIMAL(3,2)) AS media_avaliacao,
    CAST(SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS pct_positivas,
    MIN(review_score) AS pior_avaliacao,
    MAX(review_score) AS melhor_avaliacao
FROM faixa_preco
GROUP BY faixa
ORDER BY faixa;


-- ============================================================================
-- 7. ANÁLISE DE SAZONALIDADE
-- ============================================================================

-- 7.1 Padrão de vendas por dia da semana e hora
WITH vendas_hora AS (
    SELECT 
        DATENAME(WEEKDAY, order_purchase_timestamp) AS dia_semana,
        DATEPART(WEEKDAY, order_purchase_timestamp) AS dia_semana_num,
        DATEPART(HOUR, order_purchase_timestamp) AS hora,
        COUNT(*) AS qtd_pedidos
    FROM dbo.orders_clean
    WHERE order_status = 'delivered'
    GROUP BY 
        DATENAME(WEEKDAY, order_purchase_timestamp),
        DATEPART(WEEKDAY, order_purchase_timestamp),
        DATEPART(HOUR, order_purchase_timestamp)
)
SELECT 
    dia_semana,
    hora,
    qtd_pedidos,
    RANK() OVER (PARTITION BY dia_semana ORDER BY qtd_pedidos DESC) AS rank_hora_no_dia,
    CAST(qtd_pedidos * 100.0 / SUM(qtd_pedidos) OVER (PARTITION BY dia_semana) AS DECIMAL(5,2)) AS pct_do_dia
FROM vendas_hora
ORDER BY dia_semana_num, hora;


-- ============================================================================
-- 8. SUBQUERY CORRELACIONADA - CLIENTES ACIMA DA MÉDIA
-- ============================================================================

-- 8.1 Identificar clientes com ticket médio acima da média de seu estado
SELECT 
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    AVG(oi.price + oi.freight_value) AS ticket_medio_cliente,
    (
        SELECT AVG(oi2.price + oi2.freight_value)
        FROM orders_clean o2
        INNER JOIN customers_clean c2 ON o2.customer_id = c2.customer_id
        INNER JOIN order_items_clean oi2 ON o2.order_id = oi2.order_id
        WHERE c2.customer_state = c.customer_state
          AND o2.order_status = 'delivered'
    ) AS ticket_medio_estado
FROM dbo.orders_clean o
INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id
INNER JOIN dbo.order_items_clean oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id, c.customer_state, c.customer_city
HAVING AVG(oi.price + oi.freight_value) > (
    SELECT AVG(oi2.price + oi2.freight_value)
    FROM orders_clean o2
    INNER JOIN customers_clean c2 ON o2.customer_id = c2.customer_id
    INNER JOIN order_items_clean oi2 ON o2.order_id = oi2.order_id
    WHERE c2.customer_state = c.customer_state
      AND o2.order_status = 'delivered'
)
ORDER BY c.customer_state, ticket_medio_cliente DESC;