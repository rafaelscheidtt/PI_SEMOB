Funcionalidade: Passageiros por tipo

  Cenário: Exibir pagantes, gratuidades e total do dia
    Dado que em 01/08/2026 a bilhetagem registrou 5.168 passageiros na catraca, 676 antecipados e 10.700 não pagantes
    Quando o gestor seleciona a visão "Diária" em 01/08/2026
    Então o painel exibe 5.844 pagantes, 10.700 gratuidades e 16.544 no total

  Cenário: Período sem bilhetagem importada
    Dado que o Resumo Geral de julho de 2026 foi importado e o relatório de Passageiros não
    Quando o gestor seleciona o mês de julho de 2026
    Então os cartões de quilometragem e viagens exibem valores
    E os cartões de passageiros exibem "Sem dados"
