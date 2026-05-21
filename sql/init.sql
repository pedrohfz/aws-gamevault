-- ============================================================
-- GameVault — schema completo
-- 3 tabelas: developers (1) → games (N) ← reviews (N)
-- ============================================================

-- ------------------------------------------------------------
-- Tabela: developers (estúdios)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS developers (
    id           BIGSERIAL PRIMARY KEY,
    name         TEXT NOT NULL,
    country      TEXT NOT NULL,
    founded_year INTEGER NOT NULL
);

INSERT INTO developers (name, country, founded_year) VALUES
    ('CD Projekt Red',      'Polônia',          2002),
    ('Team Cherry',         'Austrália',        2014),
    ('FromSoftware',        'Japão',            1986),
    ('id Software',         'Estados Unidos',   1991),
    ('Santa Monica Studio', 'Estados Unidos',   1999),
    ('ConcernedApe',        'Estados Unidos',   2012),
    ('Larian Studios',      'Bélgica',          1996),
    ('343 Industries',      'Estados Unidos',   2007),
    ('Maddy Makes Games',   'Canadá',           2015);

-- ------------------------------------------------------------
-- Tabela: games
-- Coluna developer_id é NULLABLE para o backend continuar
-- funcionando sem precisar conhecer a FK.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS games (
    id           BIGSERIAL PRIMARY KEY,
    name         TEXT NOT NULL,
    genre        TEXT NOT NULL,
    platform     TEXT NOT NULL,
    rating       NUMERIC NOT NULL,
    release_year BIGINT NOT NULL,
    developer_id BIGINT NULL REFERENCES developers(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO games (name, genre, platform, rating, release_year, developer_id) VALUES
    -- CD Projekt Red (2 jogos)
    ('The Witcher 3: Wild Hunt',  'RPG',          'PC',          9.8, 2015, 1),
    ('Cyberpunk 2077',            'RPG',          'PlayStation', 7.5, 2020, 1),
    -- Team Cherry (1 jogo)
    ('Hollow Knight',             'Metroidvania', 'PC',          9.5, 2017, 2),
    -- FromSoftware (3 jogos)
    ('Elden Ring',                'RPG',          'PC',          9.7, 2022, 3),
    ('Dark Souls III',            'RPG',          'PC',          9.3, 2016, 3),
    ('Sekiro: Shadows Die Twice', 'Action',       'PC',          9.4, 2019, 3),
    -- id Software (2 jogos)
    ('Doom Eternal',              'FPS',          'PC',          8.9, 2020, 4),
    ('Doom (2016)',               'FPS',          'PC',          8.7, 2016, 4),
    -- Santa Monica Studio (2 jogos)
    ('God of War',                'Action',       'PlayStation', 9.4, 2018, 5),
    ('God of War Ragnarok',       'Action',       'PlayStation', 9.5, 2022, 5),
    -- ConcernedApe (1 jogo)
    ('Stardew Valley',            'Simulation',   'PC',          9.0, 2016, 6),
    -- Larian Studios (1 jogo)
    ('Baldurs Gate 3',            'RPG',          'PC',          9.6, 2023, 7),
    -- 343 Industries (1 jogo)
    ('Halo Infinite',             'FPS',          'Xbox',        8.0, 2021, 8),
    -- Maddy Makes Games (1 jogo)
    ('Celeste',                   'Platformer',   'PC',          9.2, 2018, 9);

-- ------------------------------------------------------------
-- Tabela: reviews (avaliações de usuários)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id            BIGSERIAL PRIMARY KEY,
    game_id       BIGINT NOT NULL REFERENCES games(id),
    reviewer_name TEXT NOT NULL,
    score         NUMERIC NOT NULL,
    comment       TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO reviews (game_id, reviewer_name, score, comment) VALUES
    -- The Witcher 3 (id=1)
    (1,  'João Silva',         9.5, 'Obra-prima dos RPGs, mundo aberto incrível.'),
    (1,  'Maria Souza',        10.0, 'Melhor jogo que já joguei.'),
    (1,  'Pedro Costa',         9.0, 'Quests secundárias surpreendentes.'),
    -- Cyberpunk 2077 (id=2)
    (2,  'Ana Lima',            6.0, 'Decepção no lançamento, melhorou com patches.'),
    (2,  'Carlos Mendes',       8.5, 'Após os patches ficou excelente.'),
    -- Hollow Knight (id=3)
    (3,  'Lucas Pereira',       9.5, 'Metroidvania perfeito.'),
    (3,  'Júlia Santos',        9.0, 'Combate satisfatório e exploração incrível.'),
    -- Elden Ring (id=4)
    (4,  'Rafael Almeida',     10.0, 'Soulslike no nível máximo.'),
    (4,  'Beatriz Rocha',       9.5, 'Mundo lindo e desafio justo.'),
    (4,  'Tiago Ferreira',      9.7, 'GOTY 2022 merecido.'),
    -- Dark Souls III (id=5)
    (5,  'Pedro Costa',         9.0, 'Encerramento épico da saga.'),
    (5,  'Camila Ribeiro',      9.5, 'Bosses memoráveis.'),
    -- Sekiro (id=6)
    (6,  'Carlos Mendes',       9.2, 'Combate técnico e desafiador.'),
    -- Doom Eternal (id=7)
    (7,  'Mateus Oliveira',     9.0, 'FPS frenético e divertido.'),
    (7,  'Lucas Pereira',       8.8, 'Trilha sonora bombástica.'),
    -- Doom 2016 (id=8)
    (8,  'João Silva',          8.7, 'Renascimento do clássico.'),
    -- God of War (id=9)
    (9,  'Camila Ribeiro',      9.5, 'Ação cinematográfica e história tocante.'),
    (9,  'Diego Martins',       9.0, 'God of War redefine o gênero.'),
    -- God of War Ragnarok (id=10)
    (10, 'Beatriz Rocha',       9.6, 'Sequência à altura do antecessor.'),
    (10, 'Fernanda Dias',       9.4, 'Mitologia nórdica brilhantemente explorada.'),
    -- Stardew Valley (id=11)
    (11, 'Larissa Gomes',       9.0, 'Relaxante e viciante.'),
    -- Baldurs Gate 3 (id=12)
    (12, 'Vinícius Cardoso',    9.5, 'CRPG moderno excepcional.'),
    (12, 'Fernanda Dias',      10.0, 'Liberdade de escolha incrível.'),
    (12, 'Maria Souza',         9.7, 'Cada partida é única.'),
    -- Halo Infinite (id=13)
    (13, 'Eduardo Barbosa',     7.5, 'Bom, mas sem inovação.'),
    -- Celeste (id=14)
    (14, 'Patrícia Lopes',      9.5, 'Plataforma desafiador e emocionante.'),
    (14, 'Renato Pinto',        9.0, 'Trilha sonora épica.');
