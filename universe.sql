-- Create DB and connect (psql meta-commands)
DROP DATABASE IF EXISTS universe;
CREATE DATABASE universe;
\c universe

BEGIN;

-- Clean recreate in dependency order
DROP TABLE IF EXISTS moon       CASCADE;
DROP TABLE IF EXISTS planet     CASCADE;
DROP TABLE IF EXISTS star       CASCADE;
DROP TABLE IF EXISTS black_hole CASCADE;
DROP TABLE IF EXISTS galaxy     CASCADE;

-- ──────────────────────────────────────────────────────────────────────────────
-- GALAXY
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE galaxy (
  galaxy_id             SERIAL PRIMARY KEY,
  name                  VARCHAR(100) NOT NULL UNIQUE,
  group_name            TEXT,
  galaxy_type           TEXT        NOT NULL,
  star_count_estimate   BIGINT      CHECK (star_count_estimate IS NULL OR star_count_estimate > 0),
  age_gyr               NUMERIC(4,1) CHECK (age_gyr IS NULL OR age_gyr > 0),
  diameter_lightyears   INTEGER     CHECK (diameter_lightyears IS NULL OR diameter_lightyears > 0)
);

CREATE INDEX idx_galaxy_group_name ON galaxy (group_name);

INSERT INTO galaxy (name, group_name, galaxy_type, star_count_estimate, age_gyr, diameter_lightyears) VALUES
  ('Milky Way',          'Local Group',   'Barred spiral (SBbc)',          200000000000, 13.6, 110000),
  ('Andromeda (M31)',    'Local Group',   'Barred spiral (SA(s)b)',        1000000000000, 10.5, 220000),
  ('Triangulum (M33)',   'Local Group',   'Spiral (SA(s)cd)',                40000000000, 11.0,  60000),
  ('Messier 87 (M87)',   'Virgo Cluster', 'Giant elliptical (E0–E1)',      1500000000000, 12.5, 980000),
  ('NGC 253 (Sculptor)', 'Sculptor Group','Barred spiral (SAB(s)c)',        100000000000, 10.5,  90000),
  ('NGC 4889',           'Coma Cluster',  'Supergiant elliptical (E4)',    1000000000000, 12.5, 250000);

-- ──────────────────────────────────────────────────────────────────────────────
-- BLACK_HOLE  (5th table; includes name VARCHAR and UNIQUE)
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE black_hole (
  black_hole_id               SERIAL PRIMARY KEY,
  name                        VARCHAR(100) NOT NULL UNIQUE,
  galaxy_id                   INTEGER NOT NULL REFERENCES galaxy(galaxy_id) ON DELETE CASCADE,
  common_name                 TEXT,
  estimated_mass_solar_masses NUMERIC,
  accretion_state             TEXT NOT NULL,
  has_relativistic_jet        BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX ux_black_hole_one_per_galaxy ON black_hole (galaxy_id);

INSERT INTO black_hole
  (name, galaxy_id, common_name, estimated_mass_solar_masses, accretion_state, has_relativistic_jet)
VALUES
  ('Milky Way SMBH',          (SELECT galaxy_id FROM galaxy WHERE name='Milky Way'),           'Sagittarius A*', 4.1e6,  'quiescent / LLAGN', FALSE),
  ('Andromeda SMBH',          (SELECT galaxy_id FROM galaxy WHERE name='Andromeda (M31)'),     'M31*',           1.4e8,  'quiescent / LLAGN', FALSE),
  ('Triangulum Nuclear BH?',  (SELECT galaxy_id FROM galaxy WHERE name='Triangulum (M33)'),    NULL,             NULL,   'no confirmed SMBH (possible IMBH upper limit)', FALSE),
  ('M87 SMBH',                (SELECT galaxy_id FROM galaxy WHERE name='Messier 87 (M87)'),    'M87*',           6.5e9,  'active radio galaxy', TRUE),
  ('NGC 253 Nuclear BH',      (SELECT galaxy_id FROM galaxy WHERE name='NGC 253 (Sculptor)'),  NULL,             5.0e6,  'LLAGN / starburst nucleus candidate', FALSE),
  ('NGC 4889 SMBH',           (SELECT galaxy_id FROM galaxy WHERE name='NGC 4889'),            NULL,             2.1e10, 'dormant', FALSE);

-- ──────────────────────────────────────────────────────────────────────────────
-- STAR
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE star (
  star_id             SERIAL PRIMARY KEY,
  name                VARCHAR(120) NOT NULL UNIQUE,
  galaxy_id           INTEGER NOT NULL REFERENCES galaxy(galaxy_id) ON DELETE CASCADE,
  spectral_type       TEXT,
  color               TEXT,
  temperature_kelvin  INTEGER CHECK (temperature_kelvin IS NULL OR temperature_kelvin > 0)
);

CREATE INDEX idx_star_galaxy_id ON star (galaxy_id);

INSERT INTO star (name, galaxy_id, spectral_type, color, temperature_kelvin) VALUES
  -- Milky Way
  ('Sirius A', (SELECT galaxy_id FROM galaxy WHERE name='Milky Way'), 'A1V', 'White', 9940),
  ('Betelgeuse', (SELECT galaxy_id FROM galaxy WHERE name='Milky Way'), 'M1–M2 Ia–ab', 'Red-orange', 3500),

  -- Andromeda (M31)
  ('V1 (M31 Cepheid)', (SELECT galaxy_id FROM galaxy WHERE name='Andromeda (M31)'), 'F–G supergiant (Cepheid)', 'Yellow-white', 5800),
  ('J004244.1+411608', (SELECT galaxy_id FROM galaxy WHERE name='Andromeda (M31)'), 'B-type blue supergiant', 'Blue', 20000),

  -- Triangulum (M33)
  ('B416', (SELECT galaxy_id FROM galaxy WHERE name='Triangulum (M33)'), 'LBV candidate', 'Blue-white', 22000),

  -- M87
  ('M87 Nova 2006 (WD system)', (SELECT galaxy_id FROM galaxy WHERE name='Messier 87 (M87)'), 'White dwarf binary (nova)', 'White', 30000),

  -- NGC 253
  ('NGC 253 OB Star A', (SELECT galaxy_id FROM galaxy WHERE name='NGC 253 (Sculptor)'), 'O-type main sequence', 'Blue', 35000),

  -- NGC 4889
  ('NGC 4889 Star A', (SELECT galaxy_id FROM galaxy WHERE name='NGC 4889'), 'K-type red giant', 'Orange', 4500),
  ('NGC 4889 Blue Supergiant', (SELECT galaxy_id FROM galaxy WHERE name='NGC 4889'), 'B-type supergiant', 'Blue', 18000),

  -- Additional Milky Way example
  ('Rigel', (SELECT galaxy_id FROM galaxy WHERE name='Milky Way'), 'B8 Ia', 'Blue-white', 11000);

-- ──────────────────────────────────────────────────────────────────────────────
-- PLANET
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE planet (
  planet_id                     SERIAL PRIMARY KEY,
  name                          VARCHAR(120) NOT NULL UNIQUE,
  star_id                       INTEGER NOT NULL REFERENCES star(star_id) ON DELETE CASCADE,
  orbital_period_days           NUMERIC(8,2) CHECK (orbital_period_days IS NULL OR orbital_period_days > 0),
  daytime_temperature_kelvin    INTEGER CHECK (daytime_temperature_kelvin IS NULL OR daytime_temperature_kelvin > 0),
  nighttime_temperature_kelvin  INTEGER CHECK (nighttime_temperature_kelvin IS NULL OR nighttime_temperature_kelvin > 0),
  has_atmosphere                BOOLEAN NOT NULL DEFAULT FALSE,
  has_moon                      BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_planet_star_id ON planet (star_id);

-- 12 planets (order matters for moon planet_id references)
-- star_ids are in insert order: 1 Sirius A, 2 Betelgeuse, 3 V1, 4 J004244..., 5 B416, 6 M87 WD, 7 NGC253 OB A, 8 NGC4889 Star A, 9 NGC4889 BSG, 10 Rigel
INSERT INTO planet (name, star_id, orbital_period_days, daytime_temperature_kelvin, nighttime_temperature_kelvin, has_atmosphere, has_moon) VALUES
  ('Sirius b-I',         1, 180.00, 320, 260, TRUE,  TRUE),
  ('Betelgeuse Prime',   2, 800.00, 500, 300, TRUE,  FALSE),
  ('Andros-1',           3,  40.00, 280, 230, TRUE,  TRUE),
  ('Andros-2',           4, 400.00, 700, 500, FALSE, FALSE),
  ('Triangulon Alpha',   5,  90.00, 310, 260, TRUE,  TRUE),
  ('Triangulon Beta',    5,  25.00, 600, 350, TRUE,  FALSE),
  ('Virgon-1',           6,   0.50,1000, 800, FALSE, FALSE),
  ('Virgon-2',           6,  30.00, 200, 100, TRUE,  TRUE),
  ('Sculpta-1',          7,  50.00, 350, 280, TRUE,  TRUE),
  ('Sculpta-2',          7, 300.00, 260, 180, TRUE,  TRUE),
  ('Comara Major',       8, 600.00, 250, 200, TRUE,  TRUE),
  ('Comara Minor',       9,  70.00, 800, 500, FALSE, FALSE);

-- ──────────────────────────────────────────────────────────────────────────────
-- MOON
-- ──────────────────────────────────────────────────────────────────────────────
CREATE TABLE moon (
  moon_id                         SERIAL PRIMARY KEY,
  name                            VARCHAR(120) NOT NULL UNIQUE,
  planet_id                       INTEGER REFERENCES planet(planet_id) ON DELETE SET NULL,
  diameter_in_km                  INTEGER NOT NULL CHECK (diameter_in_km > 0),
  is_geologically_active          BOOLEAN NOT NULL DEFAULT FALSE,
  daytime_temperature_in_kelvin   INTEGER NOT NULL CHECK (daytime_temperature_in_kelvin > 0),
  nighttime_temperature_in_kelvin INTEGER NOT NULL CHECK (nighttime_temperature_in_kelvin > 0)
);

CREATE INDEX idx_moon_planet_id ON moon (planet_id);

INSERT INTO moon
  (name, planet_id, diameter_in_km, is_geologically_active, daytime_temperature_in_kelvin, nighttime_temperature_in_kelvin)
VALUES
  ('Selene Minor', 1, 1800, FALSE, 240, 120),

  ('Cryon A', 3, 600, FALSE, 180,  90),
  ('Cryon B', 3, 1200, TRUE, 210, 140),

  ('Lunara', 5, 3200, TRUE, 310, 200),

  ('Methara I', 8, 800,  FALSE, 160,  80),
  ('Methara II',8, 1400, TRUE, 190, 100),
  ('Methara III',8,700,  FALSE, 150,  70),

  ('Glacien', 9, 2600, TRUE, 250, 160),

  ('Rime I', 10, 1000, FALSE, 200, 120),
  ('Rime II',10, 1500, TRUE, 230, 150),

  ('Obris', 11, 2200, FALSE, 210, 140),

  -- Rogue (no parent planet)
  ('Driftor-1', NULL,  900, FALSE, 190, 120),
  ('Driftor-2', NULL, 1300, TRUE,  210, 140),
  ('Driftor-3', NULL,  600, FALSE, 160,  80),
  ('Driftor-4', NULL, 2000, TRUE,  260, 170),
  ('Driftor-5', NULL,  700, FALSE, 180,  90),
  ('Driftor-6', NULL, 1800, TRUE,  240, 150),
  ('Driftor-7', NULL, 1100, FALSE, 200, 110),
  ('Driftor-8', NULL, 2500, TRUE,  230, 150),
  ('Driftor-9', NULL, 3000, FALSE, 190, 120);

COMMIT;
