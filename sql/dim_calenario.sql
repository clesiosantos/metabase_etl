USE dw_glpi;

CREATE TABLE IF NOT EXISTS dim_calendario (
    data DATE NOT NULL,
    ano INT NOT NULL,
    mes INT NOT NULL,
    dia INT NOT NULL,
    trimestre INT NOT NULL,
    semana_do_ano INT NOT NULL,
    dia_da_semana_num INT NOT NULL,
    dia_da_semana_nome VARCHAR(20) NOT NULL,
    mes_nome VARCHAR(20) NOT NULL,
    ano_mes VARCHAR(7) NOT NULL, -- YYYY-MM
    eh_fim_de_semana TINYINT(1) NOT NULL,
    PRIMARY KEY (data),
    INDEX idx_cal_ano_mes (ano, mes),
    INDEX idx_cal_ano_trimestre (ano, trimestre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

USE `dw_glpi`;
DROP procedure IF EXISTS `PopulateCalendar`;

DELIMITER $$
USE `dw_glpi`$$
CREATE PROCEDURE PopulateCalendar(IN start_date DATE, IN end_date DATE)
BEGIN
    DECLARE current_date DATE;
    SET current_date = start_date;
    WHILE current_date <= end_date DO
        INSERT INTO dim_calendario (
            data,
            ano,
            mes,
            dia,
            trimestre,
            semana_do_ano,
            dia_da_semana_num,
            dia_da_semana_nome,
            mes_nome,
            ano_mes,
            eh_fim_de_semana
        ) VALUES (
            current_date,
            YEAR(current_date),
            MONTH(current_date),
            DAY(current_date),
            QUARTER(current_date),
            WEEKOFYEAR(current_date),
            DAYOFWEEK(current_date),
            CASE DAYOFWEEK(current_date)
                WHEN 1 THEN 'Domingo'
                WHEN 2 THEN 'Segunda-feira'
                WHEN 3 THEN 'Terça-feira'
                WHEN 4 THEN 'Quarta-feira'
                WHEN 5 THEN 'Quinta-feira'
                WHEN 6 THEN 'Sexta-feira'
                WHEN 7 THEN 'Sábado'
            END,
            CASE MONTH(current_date)
                WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro' WHEN 3 THEN 'Março'
                WHEN 4 THEN 'Abril' WHEN 5 THEN 'Maio' WHEN 6 THEN 'Junho'
                WHEN 7 THEN 'Julho' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Setembro'
                WHEN 10 THEN 'Outubro' WHEN 11 THEN 'Novembro' WHEN 12 THEN 'Dezembro'
            END,
            DATE_FORMAT(current_date, '%Y-%m'),
            IF(DAYOFWEEK(current_date) IN (1, 7), 1, 0)
        );
        SET current_date = ADDDATE(current_date, INTERVAL 1 DAY);
    END WHILE;
END$$

DELIMITER ;

