🛒 Análise de E-commerce Brasileiro

📋 Sobre o Projeto
Análise completa de dados de e-commerce brasileiro utilizando o dataset público da Olist (Kaggle). O projeto demonstra habilidades em ETL, modelagem dimensional, SQL avançado e visualização de dados com Power BI.

🎯 Objetivos
Construir um pipeline de dados completo (ETL)
Implementar modelagem Star Schema
Criar dashboard interativo com insights acionáveis
Demonstrar proficiência técnica para posição de Analista de BI Pleno


🏗️ Arquitetura do Projeto
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Kaggle    │───▶│ SQL Server  │───▶│ Star Schema │───▶│  Power BI   │
│   (Olist)   │    │    ETL      │    │   (Views)   │    │  Dashboard  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘


📊 Modelagem Star Schema
Tabelas Fato
Tabela	Descrição	Grain
F_Pedidos	Pedidos realizados	1 linha por pedido
F_Itens	Itens dos pedidos	1 linha por item
F_Pagamentos	Pagamentos dos pedidos	1 linha por pagamento
F_Avaliações	Reviews dos clientes	1 linha por avaliação
Tabelas Dimensão
Tabela	Descrição
D_Clientes	Dados demográficos dos clientes
D_Produtos	Catálogo de produtos e categorias
D_Vendedores	Informações dos sellers
D_Calendario	Dimensão de tempo


📈 Dashboard
O dashboard possui 3 páginas com foco em diferentes perspectivas de análise:

Página 1: Overview Executivo

KPIs principais (Faturamento, Pedidos, Ticket Médio)
Evolução temporal de vendas
Distribuição por forma de pagamento
Status dos pedidos

Página 2: Análise Geográfica

Mapa de calor por estado
Ranking de faturamento por UF
Concentração de clientes por região

Página 3: Satisfação do Cliente

Média de avaliações e % positivas
Análise de tempo de entrega
Top/Bottom 10 categorias por avaliação

🔧 Tecnologias Utilizadas

Tecnologia	Uso

SQL Server - Armazenamento e ETL

T-SQL	Queries avançadas (CTEs, Window Functions)

Power BI Desktop	Visualização e Dashboard

DAX	Medidas e cálculos


📁 Estrutura do Repositório
ecommerce-brasil-analise/
├── README.md
├── assets/
│   ├── dashboard-overview.png
│   ├── dashboard-geografia.png
│   └── dashboard-satisfacao.png
├── sql/
│   ├── 01_limpeza_dados.sql
│   ├── 02_criacao_views_dimensoes.sql
│   ├── 03_criacao_views_fatos.sql
│   └── 04_queries_avancadas.sql
├── dax/
│   └── medidas.md
└── docs/
    └── modelagem_star_schema.png


💡 Principais Insights
Concentração Geográfica: São Paulo representa a maior parte do faturamento
Forma de Pagamento: Cartão de crédito é predominante
Satisfação: Correlação entre tempo de entrega e nota de avaliação
Sazonalidade: Picos de vendas identificados em períodos específicos
