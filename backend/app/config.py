from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuração lida de variáveis de ambiente ou do arquivo .env."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db: str = "dashmob"
    cors_origins: str = "*"

    # login (US11): segredo que assina os tokens e validade da sessão em horas
    token_secret: str = "troque-este-segredo-no-.env"
    token_horas: int = 8
    # primeiro administrador: criado ao subir a API se a coleção `usuarios` estiver vazia
    admin_inicial_nome: str = "Administrador"
    admin_inicial_email: str = ""
    admin_inicial_senha: str = ""


settings = Settings()
