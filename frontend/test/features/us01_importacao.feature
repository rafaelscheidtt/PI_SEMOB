Funcionalidade: Importação dos relatórios de operação
  Como gestor da SEMOB
  Quero importar o pacote de relatórios do Smart Report
  Para ter uma base consolidada sem depender de relatórios avulsos

  Cenário: Importar o pacote mensal
    Dado que o gestor está na tela de importação
    Quando ele seleciona os 11 relatórios HTML do pacote "Agosto_2026/Mensal"
    Então cada relatório é reconhecido pelo seu título
    E o sistema informa "11 arquivos importados"
    E a importação aparece no histórico com status "concluída"

  Cenário: Rejeitar registros inválidos sem descartar o restante
    Dado que o gestor está na tela de importação
    Quando ele seleciona um Resumo Geral com 6 dias válidos, 1 dia com quilometragem negativa e 1 data inválida
    Então o sistema informa "6 registros importados, 2 rejeitados"
    E a importação aparece no histórico com status "parcial"
    E os motivos de rejeição ficam disponíveis para consulta

  Cenário: Arquivo que não é um relatório Smart Report
    Dado que o gestor está na tela de importação
    Quando ele seleciona um arquivo HTML sem um título de relatório conhecido
    Então a importação aparece no histórico com status "falha"
    E nenhum registro de operação é alterado

  Cenário: Reimportar o mesmo período não duplica registros
    Dado que o pacote de agosto de 2026 já foi importado
    Quando o gestor importa novamente o mesmo pacote
    Então a quantidade de dias de operação de agosto permanece 31
    E a quantidade de ocorrências de viagem permanece a mesma
