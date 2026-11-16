"""US11 (login e papéis) e US13 (cadastro de usuários pelo administrador)."""
from app import seguranca
from app.repositories import usuarios as repo
from app.usuarios_cli import main as cli
from tests.conftest import ADMIN, token_de


def _criar_gestor(client, email="gestor@semob.teste", senha="senha123", papel="gestor"):
    r = client.post("/usuarios", json={"nome": "Gil Gestor", "email": email, "senha": senha, "papel": papel})
    assert r.status_code == 201, r.text
    return r.json()


def test_senha_guardada_com_hash_e_conferida():
    guardado = seguranca.gerar_hash("minha senha")
    assert "minha senha" not in guardado
    assert seguranca.conferir_senha("minha senha", guardado)
    assert not seguranca.conferir_senha("outra", guardado)


def test_token_assinado_e_com_validade():
    usuario = {"email": "x@y", "papel": "gestor"}
    dados = seguranca.ler_token(seguranca.gerar_token(usuario))
    assert dados["sub"] == "x@y" and dados["papel"] == "gestor"
    assert seguranca.ler_token(seguranca.gerar_token(usuario, horas=-1)) is None  # vencido
    assert seguranca.ler_token(seguranca.gerar_token(usuario)[:-3] + "abc") is None  # assinatura adulterada
    assert seguranca.ler_token("lixo") is None


def test_us11_login_devolve_token_e_papel(anonimo, db):
    repo.criar(db, ADMIN["nome"], ADMIN["email"], ADMIN["senha"], ADMIN["papel"])
    r = anonimo.post("/login", json={"email": ADMIN["email"], "senha": ADMIN["senha"]})
    assert r.status_code == 200
    assert r.json()["usuario"]["papel"] == "administrador"
    assert "senha_hash" not in r.json()["usuario"]
    assert r.json()["token"].count(".") == 2


def test_us11_senha_errada_e_usuario_inexistente_sao_recusados(anonimo, db):
    repo.criar(db, ADMIN["nome"], ADMIN["email"], ADMIN["senha"], ADMIN["papel"])
    assert anonimo.post("/login", json={"email": ADMIN["email"], "senha": "errada"}).status_code == 401
    assert anonimo.post("/login", json={"email": "ninguem@semob.teste", "senha": "x"}).status_code == 401


def test_us11_rotas_de_dados_exigem_login(anonimo):
    assert anonimo.get("/health").status_code == 200
    assert anonimo.get("/linhas").status_code == 401
    assert anonimo.get("/importacoes").status_code == 401
    assert anonimo.get("/me", headers={"Authorization": "Bearer token-invalido"}).status_code == 401


def test_us11_me_devolve_o_usuario_logado(client):
    r = client.get("/me")
    assert r.status_code == 200 and r.json()["email"] == ADMIN["email"]


def test_us13_admin_cadastra_e_lista_usuarios(client):
    gestor = _criar_gestor(client)
    assert gestor["papel"] == "gestor" and gestor["ativo"] is True and "senha_hash" not in gestor
    emails = [u["email"] for u in client.get("/usuarios").json()]
    assert emails == [ADMIN["email"], "gestor@semob.teste"]


def test_us13_email_duplicado_papel_invalido_e_senha_curta(client):
    _criar_gestor(client)
    assert client.post("/usuarios", json={"nome": "Outro", "email": "GESTOR@semob.teste", "senha": "senha123", "papel": "gestor"}).status_code == 409
    assert client.post("/usuarios", json={"nome": "Outro", "email": "o@semob.teste", "senha": "senha123", "papel": "chefe"}).status_code == 422
    assert client.post("/usuarios", json={"nome": "Outro", "email": "o@semob.teste", "senha": "123", "papel": "gestor"}).status_code == 422


def test_us13_so_administrador_gerencia_usuarios(client, anonimo):
    _criar_gestor(client)
    anonimo.headers["Authorization"] = f"Bearer {token_de(anonimo, 'gestor@semob.teste', 'senha123')}"
    assert anonimo.get("/usuarios").status_code == 403
    assert anonimo.post("/usuarios", json={"nome": "X", "email": "x@semob.teste", "senha": "senha123", "papel": "gestor"}).status_code == 403
    assert anonimo.get("/linhas").status_code == 200  # mas continua usando o painel


def test_us11_executivo_nao_importa_relatorios(client, anonimo):
    _criar_gestor(client, email="exec@semob.teste", papel="executivo")
    anonimo.headers["Authorization"] = f"Bearer {token_de(anonimo, 'exec@semob.teste', 'senha123')}"
    r = anonimo.post("/importacoes", files=[("arquivos", ("x.html", b"<html></html>", "text/html"))])
    assert r.status_code == 403
    assert anonimo.get("/indicadores", params={"inicio": "2026-09-01", "fim": "2026-09-30"}).status_code == 200


def test_us13_desativar_usuario_derruba_o_acesso(client, anonimo):
    gestor = _criar_gestor(client)
    anonimo.headers["Authorization"] = f"Bearer {token_de(anonimo, 'gestor@semob.teste', 'senha123')}"
    assert client.put(f"/usuarios/{gestor['_id']}", json={"ativo": False}).json()["ativo"] is False
    assert anonimo.get("/linhas").status_code == 401
    assert anonimo.post("/login", json={"email": "gestor@semob.teste", "senha": "senha123"}).status_code == 401


def test_us13_editar_papel_e_senha(client, anonimo):
    gestor = _criar_gestor(client)
    r = client.put(f"/usuarios/{gestor['_id']}", json={"papel": "executivo", "senha": "novasenha"})
    assert r.status_code == 200 and r.json()["papel"] == "executivo"
    assert anonimo.post("/login", json={"email": "gestor@semob.teste", "senha": "senha123"}).status_code == 401
    assert anonimo.post("/login", json={"email": "gestor@semob.teste", "senha": "novasenha"}).json()["usuario"]["papel"] == "executivo"
    assert client.put("/usuarios/000000000000000000000000", json={"nome": "x"}).status_code == 404


def test_us13_admin_nao_se_desativa_nem_se_rebaixa(client):
    eu = client.get("/me").json()
    assert client.put(f"/usuarios/{eu['_id']}", json={"ativo": False}).status_code == 422
    assert client.put(f"/usuarios/{eu['_id']}", json={"papel": "gestor"}).status_code == 422


def test_us01_importacao_registra_quem_importou(client, pacote):
    client.post("/importacoes", files=[("arquivos", (nome, conteudo, "text/html")) for nome, conteudo in pacote[:1]])
    assert client.get("/importacoes").json()[0]["usuario"] == ADMIN["email"]


def test_cli_cria_o_primeiro_admin_uma_vez_so(db, monkeypatch, capsys):
    monkeypatch.setattr("app.usuarios_cli.get_db", lambda: db)
    assert cli(["cli", "criar-admin", "Ana", "ana@semob.teste", "segredo1"]) == 0
    assert db.usuarios.count_documents({}) == 1
    assert cli(["cli", "criar-admin", "Outro", "outro@semob.teste", "segredo1"]) == 1  # já existe usuário
    assert db.usuarios.count_documents({}) == 1
    assert cli(["cli"]) == 2


# 1 pixel em PNG, só para ter uma imagem de verdade nos testes do perfil
FOTO = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg=="


def test_us13_usuario_muda_o_proprio_nome_e_a_foto(client):
    r = client.put("/me", json={"nome": "  Ana Maria Admin ", "foto": FOTO})
    assert r.status_code == 200, r.text
    assert r.json()["nome"] == "Ana Maria Admin" and r.json()["foto"] == FOTO
    assert "senha_hash" not in r.json()
    assert client.get("/me").json()["foto"] == FOTO

    r = client.put("/me", json={"foto": ""})  # texto vazio apaga
    assert r.status_code == 200 and "foto" not in r.json()
    assert client.get("/me").json()["nome"] == "Ana Maria Admin"


def test_us13_perfil_recusa_foto_invalida_e_nome_vazio(client):
    assert client.put("/me", json={"foto": "data:text/html;base64,PGI+b2k8L2I+"}).status_code == 422
    assert client.put("/me", json={"foto": "data:image/png;base64,isto nao e base64!"}).status_code == 422
    assert client.put("/me", json={"foto": "data:image/png;base64," + "A" * 200_000}).status_code == 422
    assert client.put("/me", json={"nome": "   "}).status_code == 422
    assert "foto" not in client.get("/me").json()


def test_us13_trocar_a_propria_senha_exige_a_senha_atual(client, anonimo):
    r = client.put("/me", json={"senha_atual": "errada", "nova_senha": "novasenha1"})
    assert r.status_code == 422 and "senha atual" in r.json()["detail"]
    assert client.put("/me", json={"nova_senha": "novasenha1"}).status_code == 422
    assert client.put("/me", json={"senha_atual": ADMIN["senha"], "nova_senha": "123"}).status_code == 422  # curta

    assert client.put("/me", json={"senha_atual": ADMIN["senha"], "nova_senha": "novasenha1"}).status_code == 200
    assert anonimo.post("/login", json={"email": ADMIN["email"], "senha": ADMIN["senha"]}).status_code == 401
    assert anonimo.post("/login", json={"email": ADMIN["email"], "senha": "novasenha1"}).status_code == 200


def test_us13_perfil_nao_deixa_o_usuario_mudar_o_proprio_papel(client):
    _criar_gestor(client)
    cabecalho = {"Authorization": f"Bearer {token_de(client, 'gestor@semob.teste', 'senha123')}"}
    r = client.put("/me", json={"nome": "Gil G.", "papel": "administrador", "ativo": False}, headers=cabecalho)
    assert r.status_code == 200
    assert r.json()["nome"] == "Gil G." and r.json()["papel"] == "gestor" and r.json()["ativo"] is True


def test_us13_perfil_exige_login(anonimo):
    assert anonimo.put("/me", json={"nome": "X"}).status_code == 401


def test_lgpd_usuario_novo_precisa_aceitar_o_termo_e_o_aceite_fica_registrado(client, db):
    assert client.get("/me").json()["termo_pendente"] is True
    r = client.post("/me/termo")
    assert r.status_code == 200 and r.json()["termo_pendente"] is False
    assert r.json()["termo_versao"] == repo.TERMO_VERSAO and r.json()["termo_aceito_em"]
    assert client.get("/me").json()["termo_pendente"] is False
    # o login também avisa, para o app saber antes de abrir o painel
    r = client.post("/login", json={"email": ADMIN["email"], "senha": ADMIN["senha"]})
    assert r.json()["usuario"]["termo_pendente"] is False


def test_lgpd_termo_novo_pede_aceite_de_novo(client, db, monkeypatch):
    client.post("/me/termo")
    monkeypatch.setattr(repo, "TERMO_VERSAO", "2.0")
    assert client.get("/me").json()["termo_pendente"] is True
    assert client.post("/me/termo").json()["termo_versao"] == "2.0"


def test_lgpd_aceite_exige_login_e_aparece_para_o_administrador(client, anonimo):
    assert anonimo.post("/me/termo").status_code == 401
    _criar_gestor(client)
    gestor = next(u for u in client.get("/usuarios").json() if u["email"] == "gestor@semob.teste")
    assert gestor["termo_pendente"] is True
