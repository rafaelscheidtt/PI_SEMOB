Funcionalidade: Painel responsivo

  Cenário: Tela compacta
    Dado que o painel é aberto em uma tela com menos de 600 dp de largura
    Então os cartões de indicador ficam em uma coluna
    E os filtros ficam empilhados

  Cenário: Tela expandida
    Dado que o painel é aberto em uma tela com mais de 1024 dp de largura
    Então os cartões de indicador ficam em quatro colunas
    E os filtros ficam em uma linha
