import datetime as dt
import os

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

import models
from database import get_db

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "troque-esta-chave-em-producao")
ALGORITHM = "HS256"
EXPIRA_EM_MINUTOS = 60 * 24  # token válido por 1 dia

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# HTTPBearer faz o Swagger (/docs) pedir só "cole o token aqui" no botão
# Authorize, em vez do formulário usuário/senha do fluxo OAuth2 completo
# (que não faz sentido pra gente, já que nosso /auth/login recebe JSON).
bearer_scheme = HTTPBearer()


def gerar_hash_senha(senha: str) -> str:
    return pwd_context.hash(senha)


def verificar_senha(senha: str, senha_hash: str) -> bool:
    return pwd_context.verify(senha, senha_hash)


def criar_token(usuario_id: int) -> str:
    expira = dt.datetime.utcnow() + dt.timedelta(minutes=EXPIRA_EM_MINUTOS)
    payload = {"sub": str(usuario_id), "exp": expira}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def usuario_atual(
    credenciais: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> models.Usuario:
    """Dependência: injeta o usuário logado em qualquer rota protegida."""
    excecao = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
    token = credenciais.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        usuario_id = payload.get("sub")
        if usuario_id is None:
            raise excecao
    except JWTError:
        raise excecao

    usuario = db.query(models.Usuario).filter(models.Usuario.id == int(usuario_id)).first()
    if usuario is None:
        raise excecao
    return usuario