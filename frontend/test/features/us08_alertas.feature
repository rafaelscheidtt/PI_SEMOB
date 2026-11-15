Funcionalidade: US08 Alertas de desvio na operação
  Como gestor, quero que o painel destaque as viagens não realizadas, não iniciadas e não
  terminadas e os valores fora do padrão histórico, para identificar desvios rapidamente.

  Cenário: cumprimento baixo (RN09)
    Dado que em 08/09/2026 foram realizadas 88 das 100 viagens programadas
    Quando o gestor abre a tela Alertas com setembro
    Então aparece um alerta crítico de cumprimento de 88,0% nesse dia

  Cenário: desvio do padrão histórico (RN10)
    Dado que nas 8 segundas-feiras anteriores a quilometragem ficou em torno de 1.000 km
    E que na segunda 07/09/2026 foram rodados 700 km
    Quando o gestor abre a tela Alertas
    Então aparece um aviso de quilometragem 30% abaixo do normal de uma segunda

  Cenário: excesso de ocorrências (RN11)
    Dado que a média do período é 1,8 ocorrência por dia
    E que em 05/09/2026 houve 9 viagens com ocorrência
    Então aparece um alerta crítico de ocorrências nesse dia

  Cenário: destaque na Visão Geral
    Dado que o período tem 3 alertas, 1 deles crítico
    Quando o gestor abre a Visão Geral
    Então aparece a faixa "3 alertas no período (1 crítico)"
    E o botão Ver alertas abre a tela Alertas

  Cenário: operação dentro do padrão
    Dado que nenhum dia do período fugiu das regras
    Então a tela Alertas diz que a operação ficou dentro do padrão
    E a Visão Geral não mostra a faixa
