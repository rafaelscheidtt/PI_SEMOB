Funcionalidade: US13 Cadastro de usuários pelo administrador
  Como administrador, quero cadastrar, editar e desativar usuários e definir o
  papel de cada um, para controlar quem acessa o painel.

  Cenário: cadastrar um gestor
    Dado que a administradora está na tela Usuários
    Quando ela clica em Novo usuário, preenche nome, e-mail, senha e papel e salva
    Então o usuário aparece na lista com o papel escolhido
    E consegue entrar no painel com a senha informada

  Cenário: e-mail repetido
    Dado que já existe "gestor@semob.teste"
    Quando a administradora tenta cadastrar outro usuário com o mesmo e-mail
    Então aparece a mensagem "já existe um usuário com este e-mail"

  Cenário: desativar um usuário
    Dado que o executivo "exec@semob.teste" está ativo
    Quando a administradora desmarca Ativo e salva
    Então ele aparece como Desativado
    E não consegue mais entrar nem usar um token antigo

  Cenário: quem não é administrador
    Dado que um gestor está logado
    Quando ele chama GET /usuarios
    Então a API responde 403
    E a tela Usuários não aparece no menu dele
