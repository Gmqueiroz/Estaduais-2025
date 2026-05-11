WITH base AS (

    SELECT *
    
    FROM carioca.estaduais2025 - estaduais2025_csv(4)
    
    WHERE player_age < 22
      AND minutes_played > 400
      AND in_squad > 0

),

basecalculada AS (

    SELECT

        player_name,
        team_name,
        player_age,
        player_pos,

        CASE
            WHEN player_pos IN ('Centre-Back', 'Goalkeeper', 'Left-Back', 'Right-Back')
                THEN 'Defesa'

            WHEN player_pos IN ('Central Midfield', 'Left Midfield',
                                'Right Midfield', 'Defensive Midfield')
                THEN 'Meio'

            ELSE 'Ataque'
        END AS faixa,

        SUM(minutes_played) AS minutos_jogados,

        SUM(minutes_played) / SUM(appearances) AS MediaMinutos,

        SUM(appearances) - SUM(substitutions_on) AS Titularidade,

        SUM(goals) + SUM(assists) AS 'GA',

        ((SUM(goals) + SUM(assists)) / SUM(minutes_played) * 90) AS 'GA90',

        SUM(minutes_played) / MAX(SUM(minutes_played)) OVER() AS Minutos_normalizados,

        SUM(minutes_played) / SUM(appearances) /
            MAX(SUM(minutes_played) / SUM(appearances)) OVER() AS MM_Normalizado,

        (((SUM(goals) + SUM(assists)) / (SUM(minutes_played) * 90)) /
            MAX(((SUM(goals) + SUM(assists)) / (SUM(minutes_played) * 90))) OVER()) AS ga90_normalizado

    FROM base

    GROUP BY
        player_name,
        player_age,
        player_pos,
        team_name

)

SELECT

    player_name,
    team_name,
    player_age,
    player_pos,
    faixa,

    (0.6 * ga90_normalizado +
     0.1 * MM_Normalizado +
     0.3 * Minutos_normalizados) AS pontuacao,

    minutos_jogados,
    MediaMinutos,
    GA,
    GA90,

    RANK() OVER (
        PARTITION BY faixa

        ORDER BY CASE
            WHEN faixa = 'Ataque'
                THEN (0.6 * ga90_normalizado +
                      0.1 * MM_Normalizado +
                      0.3 * Minutos_normalizados)

            WHEN faixa = 'Defesa'
                THEN (0.2 * ga90_normalizado +
                      0.4 * MM_Normalizado +
                      0.4 * Minutos_normalizados)

            ELSE (0.33 * ga90_normalizado +
                  0.33 * MM_Normalizado +
                  0.33 * Minutos_normalizados)
        END DESC
    ) AS pos

FROM basecalculada

ORDER BY pos ASC
LIMIT 30;
