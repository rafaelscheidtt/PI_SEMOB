Funcionalidade: Filtros do painel

  Cenário: Filtrar por intervalo de datas
    Dado que o gestor está no painel
    Quando ele informa o intervalo de 01/08/2026 a 14/08/2026
    Então todos os indicadores passam a considerar apenas esse intervalo

  Cenário: Filtrar por linha
    Dado que o gestor está no painel
    Quando ele seleciona a linha "02"
    Então quilometragem e viagens passam a considerar apenas a linha "02"
    E os cartões de passageiros exibem "Sem dados", porque a bilhetagem não é detalhada por linha

  Cenário: Intervalo inválido
    Dado que o gestor está no painel
    Quando ele informa a data inicial 20/08/2026 e a data final 10/08/2026
    Então o painel exibe a mensagem "A data inicial deve ser anterior ou igual à final"
    E os indicadores não são atualizados
