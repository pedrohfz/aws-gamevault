import json
import os
from collections import Counter
from urllib import request
from urllib.error import URLError, HTTPError


def lambda_handler(event, context):
    api_url = os.environ.get("API_URL", "").rstrip("/")
    if not api_url:
        return _response(500, {"error": "variável de ambiente API_URL não configurada"})

    try:
        games = _fetch_games(f"{api_url}/games")
    except (URLError, HTTPError) as e:
        return _response(502, {"error": f"falha ao consumir API: {e}"})
    except json.JSONDecodeError as e:
        return _response(502, {"error": f"resposta inválida da API: {e}"})

    return _response(200, _build_report(games))


def _fetch_games(url):
    req = request.Request(url, headers={"Accept": "application/json"})
    with request.urlopen(req, timeout=10) as resp:
        if resp.status != 200:
            raise URLError(f"status {resp.status}")
        return json.loads(resp.read().decode("utf-8"))


def _build_report(games):
    if not games:
        return {
            "total_games": 0,
            "average_rating": 0,
            "games_by_genre": {},
            "games_by_platform": {},
            "highest_rated": None,
            "lowest_rated": None,
        }

    total = len(games)
    avg = sum(g["rating"] for g in games) / total
    by_genre = Counter(g["genre"] for g in games)
    by_platform = Counter(g["platform"] for g in games)

    highest = max(games, key=lambda g: g["rating"])
    lowest = min(games, key=lambda g: g["rating"])

    return {
        "total_games": total,
        "average_rating": round(avg, 2),
        "games_by_genre": dict(by_genre),
        "games_by_platform": dict(by_platform),
        "highest_rated": {"name": highest["name"], "rating": highest["rating"]},
        "lowest_rated": {"name": lowest["name"], "rating": lowest["rating"]},
    }


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }
