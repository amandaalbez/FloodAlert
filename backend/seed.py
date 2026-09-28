"""
Popula o banco com os mesmos dados mockados que já existiam no Flutter,
pra você ver a API respondendo com algo familiar assim que ligar tudo.

Rode uma vez com: python seed.py
"""

import models
from database import Base, SessionLocal, engine

Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    if db.query(models.RegiaoMonitorada).first():
        print("Já existem dados no banco — nada foi alterado.")
    else:

        db.commit()

        print("Seed concluído com sucesso.")
finally:
    db.close()