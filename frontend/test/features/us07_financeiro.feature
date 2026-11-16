Funcionalidade: US07 Financeiro por período
  Como gestor, quero ver vendas, utilização e saldo de créditos de bilhetagem por período,
  para acompanhar o desempenho financeiro do sistema.

  Cenário: período com bilhetagem
    Dado que os relatórios de saldos de setembro foram importados
    Quando o gestor abre a tela Financeiro com o período de setembro
    Então os cartões mostram vendas, utilização, crédito circulante e saldo de créditos em reais
    E o crédito circulante é vendas menos utilização
    E cada cartão mostra a variação em relação ao período anterior

  Cenário: período antes do fim do Tarifa Zero
    Dado que a bilhetagem começou em 15/07/2026
    Quando o gestor escolhe um período que começa antes disso
    Então aparece o aviso explicando que antes não havia dado financeiro
    E os períodos sem bilhetagem aparecem como "Sem dados", nunca como zero

  Cenário: filtro de linha
    Quando o gestor filtra por uma linha na tela Financeiro
    Então os valores continuam sendo do sistema inteiro
    E aparece o aviso de que a bilhetagem não existe por linha
