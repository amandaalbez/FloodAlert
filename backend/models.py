import datetime as dt
import enum

from sqlalchemy import Column, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from database import Base


class NivelRisco(str, enum.Enum):
    """Espelha exatamente o enum NivelRisco do Flutter (home_screen.dart)."""

    baixo = "baixo"
    moderado = "moderado"
    alto = "alto"


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(120), nullable=False)
    email = Column(String(160), unique=True, nullable=False, index=True)
    senha_hash = Column(String(255), nullable=False)
    bairro = Column(String(120), nullable=True)
    criado_em = Column(DateTime, default=dt.datetime.utcnow)

    reportes = relationship("Reporte", back_populates="usuario")


class RegiaoMonitorada(Base):
    """
    Representa tanto um ponto no mapa quanto a região do usuário na Home.
    Corresponde ao RiscoPonto do map_screen.dart + aos dados do card de
    risco da HomeScreen.
    """

    __tablename__ = "regioes_monitoradas"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(120), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    nivel_risco = Column(Enum(NivelRisco), nullable=False, default=NivelRisco.baixo)
    nivel_rio_metros = Column(Float, nullable=True)
    nivel_rio_maximo_metros = Column(Float, nullable=True)
    chance_chuva_percent = Column(Integer, nullable=True)
    atualizado_em = Column(
        DateTime, default=dt.datetime.utcnow, onupdate=dt.datetime.utcnow
    )

    alertas = relationship("Alerta", back_populates="regiao")


class Alerta(Base):
    """Corresponde ao AlertaItem do home_screen.dart / alerts_screen.dart."""

    __tablename__ = "alertas"

    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(200), nullable=False)
    local = Column(String(160), nullable=False)
    nivel = Column(Enum(NivelRisco), nullable=False)
    criado_em = Column(DateTime, default=dt.datetime.utcnow)
    regiao_id = Column(Integer, ForeignKey("regioes_monitoradas.id"), nullable=True)

    regiao = relationship("RegiaoMonitorada", back_populates="alertas")


class Reporte(Base):
    """Alagamento reportado por um usuário (botão "Reportar alagamento")."""

    __tablename__ = "reportes"

    id = Column(Integer, primary_key=True, index=True)
    descricao = Column(Text, nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    criado_em = Column(DateTime, default=dt.datetime.utcnow)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)

    usuario = relationship("Usuario", back_populates="reportes")