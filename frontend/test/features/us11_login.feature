Funcionalidade: US11 Login e acesso por papel
  Como administrador, quero que o acesso ao painel exija login e que cada usuário
  caia direto na tela do seu papel, para proteger os dados de gestão.

  Cenário: entrar com e-mail e senha corretos
    Dado que existe o gestor "gestor@semob.teste" com a senha "senha123"
    Quando ele informa o e-mail e a senha e clica em Entrar
    Então o painel abre na Visão Geral
    E o nome dele aparece no menu lateral

  Cenário: senha errada
    Dado que existe o gestor "gestor@semob.teste"
    Quando ele informa a senha "errada"
    Então aparece a mensagem "E-mail ou senha incorretos"
    E ele continua na tela de login

  Cenário: menu de acordo com o papel
    Dado que a usuária "exec@semob.teste" tem o papel executivo
    Quando ela entra no painel
    Então o menu mostra só Visão Geral, Cumprimento de viagens e Passageiros
    E Linhas, Importação de relatórios e Usuários não aparecem

  Cenário: sessão expirada
    Dado que o gestor está no painel com um token vencido
    Quando a API responde 401
    Então o app volta para a tela de login com o aviso de sessão expirada

  Cenário: rota sem token
    Quando alguém chama GET /linhas sem o cabeçalho Authorization
    Então a API responde 401
