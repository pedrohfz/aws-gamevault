CREATE TABLE IF NOT EXISTS games (
    id           BIGSERIAL PRIMARY KEY,
    name         TEXT NOT NULL,
    genre        TEXT NOT NULL,
    platform     TEXT NOT NULL,
    rating       NUMERIC NOT NULL,
    release_year BIGINT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO games (name, genre, platform, rating, release_year) VALUES
    ('The Witcher 3: Wild Hunt', 'RPG',          'PC',          9.8, 2015),
    ('Hollow Knight',            'Metroidvania', 'PC',          9.5, 2017),
    ('Cyberpunk 2077',           'RPG',          'PlayStation', 7.5, 2020),
    ('Elden Ring',               'RPG',          'PC',          9.7, 2022),
    ('Doom Eternal',             'FPS',          'PC',          8.9, 2020),
    ('God of War',               'Action',       'PlayStation', 9.4, 2018),
    ('Stardew Valley',           'Simulation',   'PC',          9.0, 2016),
    ('Baldurs Gate 3',           'RPG',          'PC',          9.6, 2023),
    ('Halo Infinite',            'FPS',          'Xbox',        8.0, 2021),
    ('Celeste',                  'Platformer',   'PC',          9.2, 2018);
