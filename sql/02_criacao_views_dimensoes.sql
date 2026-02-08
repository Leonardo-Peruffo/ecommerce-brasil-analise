-- ============================================================================
-- 1. DIMENSÃO CLIENTES (vw_dim_clientes)
-- ============================================================================

CREATE OR ALTER VIEW vw_dim_clientes AS
SELECT 
    c.customer_unique_id AS sk_cliente,
    c.customer_id,
    c.customer_zip_code_prefix AS cep,
    c.customer_city AS cidade,
    c.customer_state AS estado,
    c.cidade_estado,
    CASE c.customer_state
        WHEN 'SP' THEN 'Sudeste'
        WHEN 'RJ' THEN 'Sudeste'
        WHEN 'MG' THEN 'Sudeste'
        WHEN 'ES' THEN 'Sudeste'
        WHEN 'PR' THEN 'Sul'
        WHEN 'SC' THEN 'Sul'
        WHEN 'RS' THEN 'Sul'
        WHEN 'MS' THEN 'Centro-Oeste'
        WHEN 'MT' THEN 'Centro-Oeste'
        WHEN 'GO' THEN 'Centro-Oeste'
        WHEN 'DF' THEN 'Centro-Oeste'
        WHEN 'BA' THEN 'Nordeste'
        WHEN 'SE' THEN 'Nordeste'
        WHEN 'AL' THEN 'Nordeste'
        WHEN 'PE' THEN 'Nordeste'
        WHEN 'PB' THEN 'Nordeste'
        WHEN 'RN' THEN 'Nordeste'
        WHEN 'CE' THEN 'Nordeste'
        WHEN 'PI' THEN 'Nordeste'
        WHEN 'MA' THEN 'Nordeste'
        WHEN 'PA' THEN 'Norte'
        WHEN 'AM' THEN 'Norte'
        WHEN 'AP' THEN 'Norte'
        WHEN 'RR' THEN 'Norte'
        WHEN 'RO' THEN 'Norte'
        WHEN 'AC' THEN 'Norte'
        WHEN 'TO' THEN 'Norte'
        ELSE 'Não Identificado'
    END AS regiao
FROM dbo.customers_clean c;
GO


-- ============================================================================
-- 2. DIMENSÃO PRODUTOS (vw_dim_produtos)
-- ============================================================================
/*
Informações descritivas dos produtos para análise por categoria.
Granularidade: Um registro por produto.
Fonte: products_clean (tabela tratada)
*/

CREATE OR ALTER VIEW vw_dim_produtos AS
SELECT 
    p.product_id AS sk_produto,
    p.product_category_name AS categoria,
    CASE p.product_category_name
        WHEN 'beleza_saude' THEN 'Beleza e Saúde'
        WHEN 'informatica_acessorios' THEN 'Informática e Acessórios'
        WHEN 'automotivo' THEN 'Automotivo'
        WHEN 'cama_mesa_banho' THEN 'Cama, Mesa e Banho'
        WHEN 'moveis_decoracao' THEN 'Móveis e Decoração'
        WHEN 'esporte_lazer' THEN 'Esporte e Lazer'
        WHEN 'perfumaria' THEN 'Perfumaria'
        WHEN 'utilidades_domesticas' THEN 'Utilidades Domésticas'
        WHEN 'telefonia' THEN 'Telefonia'
        WHEN 'relogios_presentes' THEN 'Relógios e Presentes'
        WHEN 'alimentos_bebidas' THEN 'Alimentos e Bebidas'
        WHEN 'bebes' THEN 'Bebês'
        WHEN 'papelaria' THEN 'Papelaria'
        WHEN 'tablets_impressao_imagem' THEN 'Tablets e Impressão'
        WHEN 'brinquedos' THEN 'Brinquedos'
        WHEN 'telefonia_fixa' THEN 'Telefonia Fixa'
        WHEN 'ferramentas_jardim' THEN 'Ferramentas e Jardim'
        WHEN 'fashion_bolsas_e_acessorios' THEN 'Bolsas e Acessórios'
        WHEN 'eletroportateis' THEN 'Eletroportáteis'
        WHEN 'consoles_games' THEN 'Games e Consoles'
        WHEN 'audio' THEN 'Áudio'
        WHEN 'fashion_calcados' THEN 'Calçados'
        WHEN 'cool_stuff' THEN 'Diversos'
        WHEN 'malas_acessorios' THEN 'Malas e Acessórios'
        WHEN 'climatizacao' THEN 'Climatização'
        WHEN 'moveis_escritorio' THEN 'Móveis de Escritório'
        WHEN 'construcao_ferramentas_seguranca' THEN 'Construção e Segurança'
        WHEN 'eletronicos' THEN 'Eletrônicos'
        WHEN 'fashion_roupa_masculina' THEN 'Moda Masculina'
        WHEN 'fashion_underwear_e_moda_praia' THEN 'Moda Praia'
        WHEN 'livros_interesse_geral' THEN 'Livros'
        WHEN 'moveis_sala' THEN 'Móveis de Sala'
        WHEN 'eletrodomesticos' THEN 'Eletrodomésticos'
        WHEN 'sem_categoria' THEN 'Sem Categoria'
        ELSE p.product_category_name
    END AS categoria_pt,
    p.product_name_lenght AS tamanho_nome,
    p.product_description_lenght AS tamanho_descricao,
    p.product_photos_qty AS qtd_fotos,
    p.product_weight_g AS peso_g,
    p.product_length_cm AS comprimento_cm,
    p.product_height_cm AS altura_cm,
    p.product_width_cm AS largura_cm,
    p.volume_cm3,
    CASE 
        WHEN p.product_weight_g < 500 THEN 'Leve (< 500g)'
        WHEN p.product_weight_g < 2000 THEN 'Médio (500g - 2kg)'
        WHEN p.product_weight_g < 10000 THEN 'Pesado (2kg - 10kg)'
        ELSE 'Muito Pesado (> 10kg)'
    END AS faixa_peso
FROM dbo.products_clean p;
GO


-- ============================================================================
-- 3. DIMENSÃO VENDEDORES (vw_dim_vendedores)
-- ============================================================================
/*
Informações dos sellers para análise de performance por vendedor.
Granularidade: Um registro por vendedor.
Fonte: olist_sellers (tabela original - não há sellers_clean)
*/

CREATE OR ALTER VIEW vw_dim_vendedores AS
SELECT 
    s.seller_id AS sk_vendedor,
    s.seller_zip_code_prefix AS cep_vendedor,
    UPPER(LTRIM(RTRIM(s.seller_city))) AS cidade_vendedor,
    s.seller_state AS estado_vendedor,
    CONCAT(UPPER(LTRIM(RTRIM(s.seller_city))), ' - ', s.seller_state) AS cidade_estado_vendedor,
    CASE s.seller_state
        WHEN 'SP' THEN 'Sudeste'
        WHEN 'RJ' THEN 'Sudeste'
        WHEN 'MG' THEN 'Sudeste'
        WHEN 'ES' THEN 'Sudeste'
        WHEN 'PR' THEN 'Sul'
        WHEN 'SC' THEN 'Sul'
        WHEN 'RS' THEN 'Sul'
        WHEN 'MS' THEN 'Centro-Oeste'
        WHEN 'MT' THEN 'Centro-Oeste'
        WHEN 'GO' THEN 'Centro-Oeste'
        WHEN 'DF' THEN 'Centro-Oeste'
        WHEN 'BA' THEN 'Nordeste'
        WHEN 'SE' THEN 'Nordeste'
        WHEN 'AL' THEN 'Nordeste'
        WHEN 'PE' THEN 'Nordeste'
        WHEN 'PB' THEN 'Nordeste'
        WHEN 'RN' THEN 'Nordeste'
        WHEN 'CE' THEN 'Nordeste'
        WHEN 'PI' THEN 'Nordeste'
        WHEN 'MA' THEN 'Nordeste'
        WHEN 'PA' THEN 'Norte'
        WHEN 'AM' THEN 'Norte'
        WHEN 'AP' THEN 'Norte'
        WHEN 'RR' THEN 'Norte'
        WHEN 'RO' THEN 'Norte'
        WHEN 'AC' THEN 'Norte'
        WHEN 'TO' THEN 'Norte'
        ELSE 'Não Identificado'
    END AS regiao_vendedor
FROM dbo.olist_sellers_dataset s;
GO


-- ============================================================================
-- 4. DIMENSÃO CALENDÁRIO (vw_dim_calendario)
-- ============================================================================
/*
Tabela de datas para análise temporal (Time Intelligence).
Granularidade: Um registro por dia no período dos dados.
Período: 2016-09-04 a 2018-10-17 (período do dataset Olist)
*/

CREATE OR ALTER VIEW vw_dim_calendario AS
WITH DateRange AS (
    SELECT CAST('2016-09-01' AS DATE) AS data
    UNION ALL
    SELECT DATEADD(DAY, 1, data)
    FROM DateRange
    WHERE data < '2018-10-31'
)
SELECT 
    CONVERT(INT, FORMAT(data, 'yyyyMMdd')) AS sk_data,
    data AS data_completa,
    YEAR(data) AS ano,
    MONTH(data) AS mes,
    DAY(data) AS dia,
    DATEPART(QUARTER, data) AS trimestre,
    DATEPART(WEEK, data) AS semana_ano,
    DATEPART(DAYOFYEAR, data) AS dia_ano,
    DATENAME(MONTH, data) AS nome_mes,
    LEFT(DATENAME(MONTH, data), 3) AS nome_mes_abrev,
    DATENAME(WEEKDAY, data) AS nome_dia_semana,
    LEFT(DATENAME(WEEKDAY, data), 3) AS nome_dia_semana_abrev,
    CASE MONTH(data)
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END AS mes_pt,
    CASE DATEPART(WEEKDAY, data)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Segunda-feira'
        WHEN 3 THEN 'Terça-feira'
        WHEN 4 THEN 'Quarta-feira'
        WHEN 5 THEN 'Quinta-feira'
        WHEN 6 THEN 'Sexta-feira'
        WHEN 7 THEN 'Sábado'
    END AS dia_semana_pt,
    FORMAT(data, 'yyyy-MM') AS ano_mes,
    CONCAT('Q', DATEPART(QUARTER, data), ' ', YEAR(data)) AS trimestre_ano,
    CASE WHEN DATEPART(WEEKDAY, data) IN (1, 7) THEN 1 ELSE 0 END AS flag_fim_semana,
    CASE WHEN DAY(data) = 1 THEN 1 ELSE 0 END AS flag_primeiro_dia_mes,
    CASE WHEN data = EOMONTH(data) THEN 1 ELSE 0 END AS flag_ultimo_dia_mes,
    DATEPART(WEEKDAY, data) AS dia_semana_num
FROM DateRange;