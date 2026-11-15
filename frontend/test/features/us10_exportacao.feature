Funcionalidade: US10 Exportação do painel em PDF
  Como gestor, quero exportar o painel em PDF ou imagem, para compartilhar com outros gestores.

  Cenário: gerar o PDF do período
    Dado que o gestor está na tela Relatórios com setembro na barra de filtros
    Quando ele marca as seções que quer e clica em Gerar PDF
    Então o app consulta só as seções marcadas
    E o arquivo dashmob_2026-09-01_2026-09-30.pdf é baixado (ou compartilhado, no celular)
    E o PDF traz o cabeçalho da SEMOB, o período, quem gerou e a numeração das páginas

  Cenário: período sem dados
    Dado que o período escolhido não tem relatório importado
    Quando o gestor gera o PDF
    Então as tabelas mostram "Sem dados" no lugar dos valores, nunca zero

  Cenário: nenhuma seção marcada
    Quando o gestor desmarca todas as seções
    Então o botão Gerar PDF fica desativado
