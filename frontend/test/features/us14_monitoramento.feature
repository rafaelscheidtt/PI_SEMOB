Funcionalidade: US14 Tela de monitoramento para TV
  Como gestor, quero uma tela só com os principais números da operação, grandes e legíveis
  de longe, para deixar aberta numa TV na SEMOB.

  Cenário: números grandes numa tela só
    Dado que o período tem dados de operação
    Quando o gestor abre o Monitoramento no computador
    Então vê seis painéis: quilometragem, viagens, cumprimento, passageiros, gratuidades e viagens não realizadas
    E cada painel mostra a variação em relação ao período anterior
    E o rodapé mostra o cumprimento por turno e os períodos com menor cumprimento, sem precisar rolar

  Cenário: atualização automática
    Dado que a tela Monitoramento está aberta
    Então ela consulta a API de novo a cada 5 minutos e mostra a hora da última atualização

  Cenário: celular
    Quando o Monitoramento é aberto num celular
    Então os painéis ficam em uma coluna e a tela rola

  Cenário: modo escuro
    Quando o usuário clica no botão de lua no rodapé do menu (ou na tela de login)
    Então o app inteiro passa para o modo escuro e a escolha fica guardada no aparelho
