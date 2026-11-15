Funcionalidade: US09 Visão executiva
  Como secretário, quero uma visão executiva com os principais indicadores e o comparativo
  com o período anterior, para apresentar ao prefeito.

  Cenário: resumo do período
    Dado que o período tem dados de operação, bilhetagem e alertas
    Quando o secretário abre a Visão executiva
    Então vê seis destaques: quilometragem, viagens, cumprimento, passageiros, vendas e alertas críticos
    E cada destaque mostra a variação em relação ao período anterior
    E a tabela compara os indicadores com o período anterior
    E os alertas críticos aparecem como pontos de atenção, com o botão para ver todos

  Cenário: executivo entra no painel
    Dado que a usuária tem o papel executivo
    Quando ela faz login
    Então cai direto na Visão executiva
    E o menu não mostra Linhas, Importação de relatórios nem Usuários

  Cenário: operação dentro do padrão
    Dado que não há alerta crítico no período
    Então os pontos de atenção dizem que a operação ficou dentro do padrão
