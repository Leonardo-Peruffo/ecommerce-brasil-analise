📊 Documentação das Medidas DAX

Este documento detalha todas as medidas DAX criadas para o dashboard de análise do E-commerce Brasileiro.

📈 Medidas de Vendas:

Faturamento = SUM(F_Itens[price]) + SUM(F_Itens[freight_value])


Qtd Pedidos = DISTINCTCOUNT(F_Pedidos[order_id])


Ticket Médio = DIVIDE([Faturamento], [Qtd Pedidos], 0)



🗺️ Medidas Geográficas:


% Faturamento SP = 

CALCULATE(

    [Faturamento],
    
    D_Clientes[customer_state] = "SP"

) / [Faturamento]


Qtd Cidades = DISTINCTCOUNT(D_Clientes[customer_city])


Qtd Estados = DISTINCTCOUNT(D_Clientes[customer_state])


⭐ Medidas de Satisfação:


Média Avaliação = AVERAGE('F_Avaliações'[review_score])


% Avaliações Positivas = 

VAR Positivas = CALCULATE(

    COUNT('F_Avaliações'[review_id]), 
    
    'F_Avaliações'[review_score] >= 4

)

VAR Total = COUNT('F_Avaliações'[review_id])

RETURN 

DIVIDE(Positivas, Total, 0)


🚚 Medidas de Entrega:


Dias Médios Entrega = AVERAGE(F_Pedidos[dias_entrega])
