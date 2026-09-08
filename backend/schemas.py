import datetime as dt
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr

from models import NivelRisco


# ---------- Autenticação ----------
class UsuarioCriar(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    bairro: Optional[str] = None


class UsuarioLogin(BaseModel):
    email: EmailStr
    senha: str


class UsuarioSaida(BaseModel):
    id: int
    nome: str
    email: EmailStr
    bairro: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class TokenSaida(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioSaida


# ---------- Home / Mapa (mesma "forma" de dado nos dois) ----------
class RegiaoSaida(BaseModel):
    id: int
    nome: str
    latitude: float
    longitude: float
    nivel_risco: NivelRisco
    nivel_rio_metros: Optional[float] = None
    nivel_rio_maximo_metros: Optional[float] = None
    chance_chuva_percent: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


# ---------- Alertas ----------
class AlertaSaida(BaseModel):
    id: int
    titulo: str
    local: str
    nivel: NivelRisco
    criado_em: dt.datetime

    model_config = ConfigDict(from_attributes=True)


# ---------- Reportar alagamento ----------
class ReporteCriar(BaseModel):
    descricao: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class ReporteSaida(BaseModel):
    id: int
    descricao: str
    criado_em: dt.datetime

    model_config = ConfigDict(from_attributes=True)