"""
Busca dados reais de previsão do tempo via Open-Meteo — gratuito,
sem necessidade de chave de API nem cadastro.
Documentação: https://open-meteo.com/en/docs
"""

from datetime import datetime, timezone
from typing import Optional

import requests


def obter_chance_chuva(latitude: float, longitude: float) -> Optional[int]:
    """
    Retorna a probabilidade de chuva (%) prevista para a hora atual,
    na coordenada informada. Retorna None se a chamada falhar (API fora
    do ar, sem internet, etc) — quem chamar decide o valor de fallback,
    em vez do endpoint quebrar por causa de um serviço externo.
    """
    try:
        resposta = requests.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": latitude,
                "longitude": longitude,
                "hourly": "precipitation_probability",
                "timezone": "UTC",
                "forecast_days": 1,
            },
            timeout=5,
        )
        resposta.raise_for_status()
        dados = resposta.json()

        horas = dados["hourly"]["time"]
        probabilidades = dados["hourly"]["precipitation_probability"]

        hora_atual = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:00")
        if hora_atual in horas:
            indice = horas.index(hora_atual)
            return int(probabilidades[indice])

        # Se por algum motivo a hora exata não estiver na lista,
        # usa a primeira previsão disponível como aproximação.
        return int(probabilidades[0]) if probabilidades else None
    except Exception:
        return None