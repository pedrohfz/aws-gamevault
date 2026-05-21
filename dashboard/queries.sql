-- ============================================================
-- GameVault — Queries SQL para a disciplina de Tópicos em BD
-- ============================================================
--
-- 3 queries que atendem aos requisitos do trabalho:
--   1) JOIN com 2 tabelas
--   2) JOIN + GROUP BY + HAVING
--   3) JOIN com sub-select
--
-- Esquema: developers (1) -> games (N) <- reviews (N)
-- ============================================================


-- ------------------------------------------------------------
-- QUERY 1 — JOIN com 2 tabelas
-- ------------------------------------------------------------
-- Lista todos os jogos com o nome e país do estúdio que os
-- desenvolveu, ordenados pelo rating decrescente.
-- ------------------------------------------------------------

SELECT
    g.name        AS jogo,
    g.genre       AS genero,
    g.platform    AS plataforma,
    g.rating      AS rating,
    g.release_year AS ano,
    d.name        AS estudio,
    d.country     AS pais_estudio
FROM games g
JOIN developers d ON g.developer_id = d.id
ORDER BY g.rating DESC;


-- ------------------------------------------------------------
-- QUERY 2 — JOIN + GROUP BY + HAVING
-- ------------------------------------------------------------
-- Estúdios com 2 ou mais jogos no catálogo, mostrando o total
-- de jogos e o rating médio. Permite identificar quais estúdios
-- têm presença significativa e qual a qualidade média do
-- portfólio deles.
-- ------------------------------------------------------------

SELECT
    d.name                                AS estudio,
    d.country                             AS pais,
    COUNT(g.id)                           AS total_jogos,
    ROUND(AVG(g.rating)::numeric, 2)      AS rating_medio,
    MIN(g.release_year)                   AS primeiro_lancamento,
    MAX(g.release_year)                   AS ultimo_lancamento
FROM developers d
JOIN games g ON g.developer_id = d.id
GROUP BY d.name, d.country
HAVING COUNT(g.id) >= 2
ORDER BY rating_medio DESC;


-- ------------------------------------------------------------
-- QUERY 3 — JOIN com sub-select
-- ------------------------------------------------------------
-- Compara o rating oficial de cada jogo com a média das
-- avaliações dos usuários (reviews). A sub-query calcula a
-- média e o total de reviews por jogo, e o JOIN principal
-- traz essas informações para a tabela de jogos.
-- ------------------------------------------------------------

SELECT
    g.name                                              AS jogo,
    g.rating                                            AS rating_oficial,
    sub.media_reviews                                   AS media_reviews_usuarios,
    sub.total_reviews                                   AS total_reviews,
    ROUND((g.rating - sub.media_reviews)::numeric, 2)   AS diferenca
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
