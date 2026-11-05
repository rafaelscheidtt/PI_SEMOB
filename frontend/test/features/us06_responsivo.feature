Funcionalidade: Painel responsivo

  Cenário: Tela compacta
    Dado que o painel é aberto em uma tela com menos de 600 dp de largura
    Então os cartões de indicador ficam em uma coluna
    E os filtros ficam empilhados

  Cenário: Tela expandida
    Dado que o painel é aberto em uma tela com mais de 1024 dp de largura
    Então os cartões de indicador ficam em quatro colunas
    E os filtros ficam em uma linha

  Cenário: Menu lateral
    Dado que o painel é aberto em uma tela com mais de 1024 dp de largura
    Então o menu lateral fica fixo à esquerda, com as telas de operação e as de gestão marcadas como "Sprint 2"

  Cenário: Menu em gaveta
    Dado que o painel é aberto em uma tela com menos de 600 dp de largura
    Quando o gestor toca no ícone de menu
    Então o menu lateral abre como uma gaveta e fecha ao escolher uma tela
