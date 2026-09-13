from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

import models
import schemas
from database import Base, engine, get_db
from security import criar_token, gerar_hash_senha, usuario_atual, verificar_senha

# Cria as tabelas no MySQL automaticamente se ainda não existirem.
# (Pra evoluir o schema depois de já ter dados em produção, o ideal é
# migrar para Alembic em vez de confiar só nisso — mas pra começar, resolve.)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="FloodAlert API")

# Libera o app Flutter (rodando em outra porta/origem) acessar a API.
# Em produção, troque "*" pelo domínio real do seu app.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def raiz():
    return {"status": "ok", "servico": "FloodAlert API"}


# ---------------------------------------------------------------------------
# Autenticação
# ---------------------------------------------------------------------------
@app.post(
    "/auth/registrar",
    response_model=schemas.TokenSaida,
    status_code=status.HTTP_201_CREATED,
    tags=["Autenticação"],
)
def registrar(dados: schemas.UsuarioCriar, db: Session = Depends(get_db)):
    ja_existe = db.query(models.Usuario).filter(models.Usuario.email == dados.email).first()
    if ja_existe:
        raise HTTPException(status_code=400, detail="E-mail já cadastrado")

    usuario = models.Usuario(
        nome=dados.nome,
        email=dados.email,
        senha_hash=gerar_hash_senha(dados.senha),
        bairro=dados.bairro,
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)

    token = criar_token(usuario.id)
    return schemas.TokenSaida(access_token=token, usuario=usuario)


@app.post("/auth/login", response_model=schemas.TokenSaida, tags=["Autenticação"])
def login(dados: schemas.UsuarioLogin, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.email == dados.email).first()
    if not usuario or not verificar_senha(dados.senha, usuario.senha_hash):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos")

    token = criar_token(usuario.id)
    return schemas.TokenSaida(access_token=token, usuario=usuario)


# ---------------------------------------------------------------------------
# Home
# ---------------------------------------------------------------------------
@app.get("/home/regiao", response_model=schemas.RegiaoSaida, tags=["Home"])
def regiao_do_usuario(
    usuario: models.Usuario = Depends(usuario_atual),
    db: Session = Depends(get_db),
):
    """
    Retorna os dados de risco da região do usuário logado (pelo bairro
    cadastrado no perfil). Se não achar uma correspondência exata,
    devolve a primeira região monitorada como fallback.

    TODO: quando tiver geolocalização de verdade, trocar essa busca por
    "região monitorada mais próxima das coordenadas do usuário".
    """
    query = db.query(models.RegiaoMonitorada)

    if usuario.bairro:
        regiao = query.filter(models.RegiaoMonitorada.nome == usuario.bairro).first()
        if regiao:
            return regiao

    regiao = query.first()
    if not regiao:
        raise HTTPException(status_code=404, detail="Nenhuma região monitorada cadastrada")
    return regiao


# ---------------------------------------------------------------------------
# Mapa
# ---------------------------------------------------------------------------
@app.get("/mapa/pontos", response_model=List[schemas.RegiaoSaida], tags=["Mapa"])
def pontos_do_mapa(db: Session = Depends(get_db)):
    return db.query(models.RegiaoMonitorada).all()


# ---------------------------------------------------------------------------
# Alertas
# ---------------------------------------------------------------------------
@app.get("/alertas", response_model=List[schemas.AlertaSaida], tags=["Alertas"])
def listar_alertas(
    nivel: Optional[models.NivelRisco] = None,
    db: Session = Depends(get_db),
):
    """O parâmetro ?nivel=baixo|moderado|alto espelha os chips de filtro
    da AlertsScreen no Flutter."""
    query = db.query(models.Alerta).order_by(models.Alerta.criado_em.desc())
    if nivel:
        query = query.filter(models.Alerta.nivel == nivel)
    return query.all()


# ---------------------------------------------------------------------------
# Reportar alagamento
# ---------------------------------------------------------------------------
@app.post(
    "/reportes",
    response_model=schemas.ReporteSaida,
    status_code=status.HTTP_201_CREATED,
    tags=["Reportes"],
)
def criar_reporte(
    dados: schemas.ReporteCriar,
    usuario: models.Usuario = Depends(usuario_atual),
    db: Session = Depends(get_db),
):
    reporte = models.Reporte(
        descricao=dados.descricao,
        latitude=dados.latitude,
        longitude=dados.longitude,
        usuario_id=usuario.id,
    )
    db.add(reporte)
    db.commit()
    db.refresh(reporte)
    return reporte