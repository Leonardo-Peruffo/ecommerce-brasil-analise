-- ============================================================================
-- 1. FATO PEDIDOS (vw_fato_pedidos)
-- ============================================================================

CREATE OR ALTER VIEW vw_fato_pedidos AS
SELECT 
    o.order_id AS pk_pedido,
    c.customer_unique_id AS fk_cliente,
    CONVERT(INT, FORMAT(o.order_purchase_timestamp, 'yyyyMMdd')) AS fk_data,
    o.order_status AS status_original,
    CASE o.order_status
        WHEN 'delivered' THEN 'Entregue'
        WHEN 'shipped' THEN 'Enviado'
        WHEN 'canceled' THEN 'Cancelado'
        WHEN 'unavailable' THEN 'Indisponível'
        WHEN 'invoiced' THEN 'Faturado'
        WHEN 'processing' THEN 'Processando'
        WHEN 'created' THEN 'Criado'
        WHEN 'approved' THEN 'Aprovado'
        ELSE o.order_status
    END AS status_pedido,
    o.order_purchase_timestamp AS data_compra,
    o.order_approved_at AS data_aprovacao,
    o.order_delivered_carrier_date AS data_envio_transportadora,
    o.order_delivered_customer_date AS data_entrega_cliente,
    o.order_estimated_delivery_date AS data_entrega_estimada,
    o.dias_entrega,
    o.flag_atraso,
    o.dias_atraso,
    o.ano,
    o.mes,
    DATEPART(QUARTER, o.order_purchase_timestamp) AS trimestre,
    o.hora_pedido AS hora_compra
FROM dbo.orders_clean o
INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id;
GO


-- ============================================================================
-- 2. FATO ITENS DO PEDIDO (vw_fato_itens)
-- ============================================================================

CREATE OR ALTER VIEW vw_fato_itens AS
SELECT 
    CONCAT(oi.order_id, '-', oi.order_item_id) AS pk_item,
    oi.order_id AS fk_pedido,
    oi.product_id AS fk_produto,
    oi.seller_id AS fk_vendedor,
    CONVERT(INT, FORMAT(o.order_purchase_timestamp, 'yyyyMMdd')) AS fk_data,
    c.customer_unique_id AS fk_cliente,
    oi.order_item_id AS seq_item,
    oi.price AS preco,
    oi.freight_value AS frete,
    oi.valor_total_item AS valor_total,
    oi.shipping_limit_date AS data_limite_envio,
    1 AS quantidade
FROM dbo.order_items_clean oi
INNER JOIN dbo.orders_clean o ON oi.order_id = o.order_id
INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id;
GO


-- ============================================================================
-- 3. FATO PAGAMENTOS (vw_fato_pagamentos)
-- ============================================================================

CREATE OR ALTER VIEW vw_fato_pagamentos AS
SELECT 
    CONCAT(p.order_id, '-', p.payment_sequential) AS pk_pagamento,
    p.order_id AS fk_pedido,
    CONVERT(INT, FORMAT(o.order_purchase_timestamp, 'yyyyMMdd')) AS fk_data,
    c.customer_unique_id AS fk_cliente,
    p.payment_sequential AS seq_pagamento,
    p.payment_type AS tipo_pagamento_original,
    p.tipo_pagamento_pt AS tipo_pagamento,
    p.payment_installments AS parcelas,
    CASE 
        WHEN p.payment_installments = 1 THEN 'À Vista'
        WHEN p.payment_installments BETWEEN 2 AND 3 THEN '2-3x'
        WHEN p.payment_installments BETWEEN 4 AND 6 THEN '4-6x'
        WHEN p.payment_installments BETWEEN 7 AND 10 THEN '7-10x'
        ELSE 'Mais de 10x'
    END AS faixa_parcelamento,
    p.payment_value AS valor_pago,
    CASE 
        WHEN p.payment_installments > 0 
        THEN p.payment_value / p.payment_installments
        ELSE p.payment_value
    END AS valor_parcela
FROM dbo.payments_clean p
INNER JOIN dbo.orders_clean o ON p.order_id = o.order_id
INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id;
GO


-- ============================================================================
-- 4. FATO AVALIAÇÕES (vw_fato_avaliacoes)
-- ============================================================================

CREATE OR ALTER VIEW vw_fato_avaliacoes AS
SELECT 
    r.review_id AS pk_avaliacao,
    r.order_id AS fk_pedido,
    CONVERT(INT, FORMAT(r.review_creation_date, 'yyyyMMdd')) AS fk_data_avaliacao,
    c.customer_unique_id AS fk_cliente,
    r.review_score AS score,
    r.classificacao_review AS classificacao,
    r.flag_positivo,
    CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS flag_negativo,
    CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END AS flag_nota_maxima,
    CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END AS flag_nota_minima,
    r.review_comment_title AS titulo_comentario,
    r.review_comment_message AS mensagem_comentario,
    CASE 
        WHEN r.review_comment_message IS NOT NULL 
             AND LEN(r.review_comment_message) > 0 THEN 1 
        ELSE 0 
    END AS flag_tem_comentario,
    r.review_creation_date AS data_criacao,
    r.review_answer_timestamp AS data_resposta,
    CASE 
        WHEN r.review_answer_timestamp IS NOT NULL 
        THEN DATEDIFF(DAY, r.review_creation_date, r.review_answer_timestamp)
        ELSE NULL 
    END AS dias_ate_resposta
FROM dbo.reviews_clean r
INNER JOIN dbo.orders_clean o ON r.order_id = o.order_id
INNER JOIN dbo.customers_clean c ON o.customer_id = c.customer_id;
GO