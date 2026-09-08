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
        tijuca = models.RegiaoMonitorada(
            nome="Tijuca, Rio de Janeiro",
            latitude=-22.9249,
            longitude=-43.2277,
            nivel_risco=models.NivelRisco.moderado,
            nivel_rio_metros=2.4,
            nivel_rio_maximo_metros=4.0,
            chance_chuva_percent=78,
        )
        db.add(tijuca)
        db.commit()
        db.refresh(tijuca)

        pontos_extra = [
            models.RegiaoMonitorada(
                nome="Rio Joana",
                latitude=-22.9235,
                longitude=-43.2310,
                nivel_risco=models.NivelRisco.alto,
                nivel_rio_metros=3.6,
                nivel_rio_maximo_metros=4.0,
                chance_chuva_percent=78,
            ),
            models.RegiaoMonitorada(
                nome="Praça Saens Peña",
                latitude=-22.9257,
                longitude=-43.2298,
                nivel_risco=models.NivelRisco.moderado,
                nivel_rio_metros=2.0,
                nivel_rio_maximo_metros=4.0,
                chance_chuva_percent=65,
            ),
            models.RegiaoMonitorada(
                nome="Grande Tijuca",
                latitude=-22.9270,
                longitude=-43.2250,
                nivel_risco=models.NivelRisco.baixo,
                nivel_rio_metros=1.1,
                nivel_rio_maximo_metros=4.0,
                chance_chuva_percent=30,
            ),
        ]
        db.add_all(pontos_extra)
        db.commit()

        alertas = [
            models.Alerta(
                titulo="Nível do rio subindo rapidamente",
                local="Rio Joana - Tijuca",
                nivel=models.NivelRisco.alto,
                regiao_id=tijuca.id,
            ),
            models.Alerta(
                titulo="Chuva forte prevista para as próximas horas",
                local="Zona Norte, Rio de Janeiro",
                nivel=models.NivelRisco.moderado,
                regiao_id=tijuca.id,
            ),
            models.Alerta(
                titulo="Bueiro entupido reportado por moradores",
                local="Praça Saens Peña",
                nivel=models.NivelRisco.moderado,
                regiao_id=tijuca.id,
            ),
            models.Alerta(
                titulo="Via interditada por acúmulo de água",
                local="Av. Maracanã",
                nivel=models.NivelRisco.alto,
                regiao_id=tijuca.id,
            ),
            models.Alerta(
                titulo="Nível normalizado após chuva de ontem",
                local="Grande Tijuca",
                nivel=models.NivelRisco.baixo,
                regiao_id=tijuca.id,
            ),
        ]
        db.add_all(alertas)
        db.commit()

        print("Seed concluído com sucesso.")
finally:
    db.close()