Funcionalidade: Quilometragem por período

  Cenário: Exibir a quilometragem semanal
    Dado que existem registros de operação de 01/08/2026 a 31/08/2026
    Quando o gestor seleciona a visão "Semanal"
    Então o painel exibe uma barra para cada semana de segunda a domingo
    E o valor de cada semana é a soma da quilometragem total dos seus dias

  Cenário: Período sem dados
    Dado que não existem registros de operação em outubro de 2026
    Quando o gestor seleciona o mês de outubro de 2026
    Então o cartão de quilometragem exibe "Sem dados"
    E nenhum valor zero é exibido
