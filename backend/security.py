import datetime as dt
import os

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
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

# tokenUrl é só o endpoint mostrado na documentação /docs, não afeta a lógica.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def gerar_hash_senha(senha: str) -> str:
    return pwd_context.hash(senha)


def verificar_senha(senha: str, senha_hash: str) -> bool:
    return pwd_context.verify(senha, senha_hash)


def criar_token(usuario_id: int) -> str:
    expira = dt.datetime.utcnow() + dt.timedelta(minutes=EXPIRA_EM_MINUTOS)
    payload = {"sub": str(usuario_id), "exp": expira}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def usuario_atual(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> models.Usuario:
    """Dependência: injeta o usuário logado em qualquer rota protegida."""
    excecao = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
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