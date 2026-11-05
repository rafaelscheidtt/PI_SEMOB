Funcionalidade: Viagens por período

  Cenário: Exibir o total de viagens do mês
    Dado que existem registros de operação em agosto de 2026
    Quando o gestor seleciona a visão "Mensal" em agosto de 2026
    Então o cartão de viagens exibe a soma das viagens realizadas de todos os dias do mês
    E a quantidade de viagens programadas do mês

  Cenário: Exibir o cumprimento de viagens
    Dado que em agosto de 2026 foram programadas 35.050 viagens e realizadas 34.994
    Quando o gestor seleciona a visão "Mensal" em agosto de 2026
    Então o cartão de cumprimento de viagens exibe "99,84%"

  Cenário: Cumprimento por turno
    Dado que o relatório de FCV de agosto de 2026 foi importado
    Quando o gestor abre a tela "Cumprimento de viagens"
    Então o painel exibe as viagens programadas e realizadas da manhã, da tarde e da noite
    E os períodos com menor cumprimento, com a quantidade de viagens a menos
