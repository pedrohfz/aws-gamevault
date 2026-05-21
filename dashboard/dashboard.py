"""
Dashboard analítico do GameVault.

Conecta no banco PostgreSQL, executa 3 queries SQL com JOINs e gera
3 gráficos (PNG) com matplotlib usando o tema visual do GameVault
(Dark Vault — fundo escuro com destaques em dourado).

Uso:
    pip install -r requirements.txt
    python dashboard.py

Variáveis de ambiente suportadas (com defaults para o docker-compose):
    DB_HOST     (default: localhost)
    DB_PORT     (default: 5432)
    DB_USER     (default: gamevault)
    DB_PASSWORD (default: gamevault)
    DB_NAME     (default: gamevault)

Saída: 3 arquivos PNG em dashboards/output/
"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
import psycopg


DB_CONFIG = {
    "host":     os.getenv("DB_HOST",     "localhost"),
    "port":     os.getenv("DB_PORT",     "5433"),
    "user":     os.getenv("DB_USER",     "gamevault"),
    "password": os.getenv("DB_PASSWORD", "gamevault"),
    "dbname":   os.getenv("DB_NAME",     "gamevault"),
}

OUTPUT_DIR = Path(__file__).parent / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# Paleta Dark Vault
BG_PRIMARY = "#0e0e1a"
BG_CARD    = "#1a1a2e"
GOLD       = "#d4af37"
TEXT       = "#f0f0f0"
MUTED      = "#9b9bb0"

plt.rcParams.update({
    "figure.facecolor": BG_PRIMARY,
    "axes.facecolor":   BG_CARD,
    "axes.edgecolor":   MUTED,
    "axes.labelcolor":  TEXT,
    "axes.titlecolor":  GOLD,
    "xtick.color":      TEXT,
    "ytick.color":      TEXT,
    "text.color":       TEXT,
    "font.family":      ["DejaVu Sans"],
    "savefig.facecolor": BG_PRIMARY,
})


def run_query(sql: str) -> pd.DataFrame:
    """Executa SQL e retorna DataFrame."""
    with psycopg.connect(**DB_CONFIG, client_encoding="UTF8") as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            columns = [desc[0] for desc in cur.description]
            data    = cur.fetchall()
    return pd.DataFrame(data, columns=columns)


# ============================================================
# Gráfico 1 — Pizza: Distribuição de jogos por gênero
# ============================================================
def chart_jogos_por_genero():
    """JOIN com 2 tabelas: jogos + estúdios, agrupado por gênero."""
    sql = """
        SELECT g.genre AS genero, COUNT(*) AS total
        FROM games g
        JOIN developers d ON g.developer_id = d.id
        GROUP BY g.genre
        ORDER BY total DESC;
    """
    df = run_query(sql)

    fig, ax = plt.subplots(figsize=(10, 7))
    colors = ["#d4af37", "#e8c44c", "#bf9a30", "#9c7d27",
              "#8a6f22", "#6f5a1c", "#5a4717"]

    wedges, texts, autotexts = ax.pie(
        df["total"],
        labels=df["genero"],
        autopct="%1.1f%%",
        colors=colors[:len(df)],
        wedgeprops={"edgecolor": BG_PRIMARY, "linewidth": 2},
        textprops={"color": TEXT, "fontsize": 11, "fontweight": "bold"},
    )
    for autotext in autotexts:
        autotext.set_color(BG_PRIMARY)
        autotext.set_fontweight("bold")

    ax.set_title(
        "Distribuição de Jogos por Gênero",
        fontsize=16, fontweight="bold", pad=20,
    )
    plt.tight_layout()
    output = OUTPUT_DIR / "01_jogos_por_genero.png"
    plt.savefig(output, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Salvo: {output.name}  ({len(df)} gêneros)")


# ============================================================
# Gráfico 2 — Barras: Ranking de estúdios (GROUP BY + HAVING)
# ============================================================
def chart_ranking_estudios():
    """JOIN + GROUP BY + HAVING: estúdios com 2+ jogos."""
    sql = """
        SELECT
            d.name                            AS estudio,
            COUNT(g.id)                       AS total_jogos,
            ROUND(AVG(g.rating)::numeric, 2)  AS rating_medio
        FROM developers d
        JOIN games g ON g.developer_id = d.id
        GROUP BY d.name
        HAVING COUNT(g.id) >= 2
        ORDER BY rating_medio DESC;
    """
    df = run_query(sql)
    df["rating_medio"] = df["rating_medio"].astype(float)

    fig, ax = plt.subplots(figsize=(11, 6))
    bars = ax.barh(
        df["estudio"], df["rating_medio"],
        color=GOLD, edgecolor=BG_PRIMARY, linewidth=2,
    )

    for bar, valor, total in zip(bars, df["rating_medio"], df["total_jogos"]):
        ax.text(
            bar.get_width() + 0.08,
            bar.get_y() + bar.get_height() / 2,
            f"{valor:.2f}  ·  {total} jogos",
            va="center", color=TEXT, fontsize=10, fontweight="bold",
        )

    ax.set_xlabel("Rating médio", fontsize=12)
    ax.set_title(
        "Ranking de Estúdios com 2 ou Mais Jogos",
        fontsize=16, fontweight="bold", pad=20,
    )
    ax.set_xlim(0, 11)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.grid(axis="x", alpha=0.15, color=MUTED)
    ax.set_axisbelow(True)
    ax.invert_yaxis()

    plt.tight_layout()
    output = OUTPUT_DIR / "02_ranking_estudios.png"
    plt.savefig(output, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Salvo: {output.name}  ({len(df)} estúdios)")


# ============================================================
# Gráfico 3 — Dispersão: Rating oficial vs Reviews (sub-select)
# ============================================================
def chart_rating_vs_reviews():
    """JOIN com sub-select: rating oficial × média das reviews."""
    sql = """
        SELECT
            g.name             AS jogo,
            g.rating           AS rating_oficial,
            sub.media_reviews  AS media_reviews,
            sub.total_reviews  AS total_reviews
        FROM games g
        JOIN (
            SELECT
                game_id,
                ROUND(AVG(score)::numeric, 2) AS media_reviews,
                COUNT(*)                       AS total_reviews
            FROM reviews
            GROUP BY game_id
        ) sub ON sub.game_id = g.id
        ORDER BY sub.media_reviews DESC;
    """
    df = run_query(sql)
    df["rating_oficial"] = df["rating_oficial"].astype(float)
    df["media_reviews"]  = df["media_reviews"].astype(float)

    fig, ax = plt.subplots(figsize=(12, 7))

    sizes = df["total_reviews"] * 120
    ax.scatter(
        df["rating_oficial"], df["media_reviews"],
        s=sizes, c=GOLD, alpha=0.75,
        edgecolors=TEXT, linewidths=1.5,
    )

    for _, row in df.iterrows():
        ax.annotate(
            row["jogo"],
            (row["rating_oficial"], row["media_reviews"]),
            xytext=(8, 8), textcoords="offset points",
            color=TEXT, fontsize=9,
        )

    lo = min(df["rating_oficial"].min(), df["media_reviews"].min()) - 0.5
    hi = max(df["rating_oficial"].max(), df["media_reviews"].max()) + 0.5
    ax.plot(
        [lo, hi], [lo, hi],
        "--", color=MUTED, alpha=0.6,
        label="Rating oficial = Avaliação dos usuários",
    )

    ax.set_xlabel("Rating oficial", fontsize=12)
    ax.set_ylabel("Média das avaliações dos usuários", fontsize=12)
    ax.set_title(
        "Rating Oficial × Avaliação dos Usuários\n"
        "(tamanho do ponto proporcional ao número de reviews)",
        fontsize=14, fontweight="bold", pad=20,
    )
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.grid(alpha=0.15, color=MUTED)
    ax.set_axisbelow(True)
    ax.legend(facecolor=BG_CARD, edgecolor=MUTED, labelcolor=TEXT, loc="lower right")

    plt.tight_layout()
    output = OUTPUT_DIR / "03_rating_vs_reviews.png"
    plt.savefig(output, dpi=150, bbox_inches="tight")
    plt.close()
    print(f"  Salvo: {output.name}  ({len(df)} jogos)")


def main():
    print("=" * 60)
    print("GameVault — Dashboard analítico")
    print("=" * 60)
    print(f"Conectando em {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}")
    print()

    chart_jogos_por_genero()
    chart_ranking_estudios()
    chart_rating_vs_reviews()

    print()
    print(f"3 gráficos gerados em {OUTPUT_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
