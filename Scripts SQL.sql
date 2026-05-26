------------
--Criação da Estrutura no HDFS

hdfs dfs -ls /

hdfs dfs -mkdir /user/gustavoqui/arquivos-projeto
hdfs dfs -mkdir /user/gustavoqui/arquivos-projeto/2023
hdfs dfs -mkdir /user/gustavoqui/arquivos-projeto/2024


hdfs dfs -put ~/arquivos-projeto/INFLUD23-26-06-2025.csv /user/gustavoqui/arquivos-projeto/2023/
hdfs dfs -put ~/arquivos-projeto/INFLUD24-26-06-2025.csv /user/gustavoqui/arquivos-projeto/2024/


hdfs dfs -ls -R /user/gustavoqui/arquivos-projeto


--Criação da database no HIVE
hive 

CREATE DATABASE IF NOT EXISTS tfc_infnet;
USE tfc_infnet;

--Criação da tabela do ano de 2023 e ingestão de dados.

DROP TABLE IF EXISTS ext_covid_2023;
CREATE EXTERNAL TABLE ext_covid_2023 (
  nu_notific   STRING,
  dt_notific   STRING,   
  sem_not      INT,
  dt_sin_pri   STRING,   
  sg_uf_not    STRING,
  co_regiona   STRING,
  id_municip   STRING,
  co_mun_not   STRING,
  cs_sexo      STRING,
  dt_nasc      STRING,  
  nu_idade_n   INT,
  tp_idade     INT,
  cod_idade    INT,
  sg_uf        STRING,
  id_mn_resi   STRING,
  co_mun_res   STRING,
  vacina       INT,      
  antiviral    INT,       
  hospital     INT,     
  dt_interna   STRING,   
  sg_uf_inte   STRING,
  id_mn_inte   STRING,
  co_mu_inte   STRING,
  nm_un_inte   STRING,
  uti          INT,      
  amostra      INT,      
  dt_coleta    STRING,   
  tp_amostra   INT,
  pcr_resul    INT,      
  classi_fin   INT,
  criterio     INT,
  evolucao     INT,
  dt_evoluca   STRING,   
  dt_encerra   STRING,  
  vacina_cov   INT,      
  dose_1_cov   INT,
  dose_2_cov   INT,
  dose_ref     INT,
  dose_2ref    INT,
  fab_cov_1    STRING,
  fab_cov_2    STRING,
  fab_covrf    STRING,
  fab_covrf2   STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE
LOCATION '/user/gustavoqui/arquivos-projeto/2023';

--Testes na tabela criada.

SELECT COUNT(*) AS linhas_2023 FROM ext_covid_2023;

SELECT dt_notific, dt_sin_pri, hospital, uti, classi_fin, evolucao, vacina_cov
FROM ext_covid_2023 LIMIT 10;

--Criação da tabela do ano de 2024 e ingestão de dados.


DROP TABLE IF EXISTS ext_covid_2024;
CREATE EXTERNAL TABLE ext_covid_2024 (
  nu_notific   STRING,
  dt_notific   STRING,
  sem_not      INT,
  dt_sin_pri   STRING,
  sg_uf_not    STRING,
  co_regiona   STRING,
  id_municip   STRING,
  co_mun_not   STRING,
  cs_sexo      STRING,
  dt_nasc      STRING,
  nu_idade_n   INT,
  tp_idade     INT,
  cod_idade    INT,
  sg_uf        STRING,
  id_mn_resi   STRING,
  co_mun_res   STRING,
  vacina       INT,
  antiviral    INT,
  hospital     INT,
  dt_interna   STRING,
  sg_uf_inte   STRING,
  id_mn_inte   STRING,
  co_mu_inte   STRING,
  nm_un_inte   STRING,
  uti          INT,
  amostra      INT,
  dt_coleta    STRING,
  tp_amostra   INT,
  pcr_resul    INT,
  classi_fin   INT,
  criterio     INT,
  evolucao     INT,
  dt_evoluca   STRING,
  dt_encerra   STRING,
  vacina_cov   INT,
  dose_1_cov   INT,
  dose_2_cov   INT,
  dose_ref     INT,
  dose_2ref    INT,
  fab_cov_1    STRING,
  fab_cov_2    STRING,
  fab_covrf    STRING,
  fab_covrf2   STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE
LOCATION '/user/gustavoqui/arquivos-projeto/2024';

Testes na tabela criada.

SELECT dt_notific, dt_sin_pri, hospital, uti, classi_fin, evolucao, vacina_cov
FROM ext_covid_2024 LIMIT 10;


Realização das consultas nos dados para analise exploratória.

-- BASE para todas as consultas

WITH base AS (
  SELECT 2023 AS ano, dt_notific, dt_sin_pri, hospital, uti, classi_fin, evolucao, vacina_cov
  FROM tfc_infnet.ext_covid_2023
  UNION ALL
  SELECT 2024 AS ano, dt_notific, dt_sin_pri, hospital, uti, classi_fin, evolucao, vacina_cov
  FROM tfc_infnet.ext_covid_2024
)

-- 1) CASOS CONFIRMADOS por ano (COVID = classi_fin = 5)

SELECT ano, COUNT(*) AS confirmados_covid
FROM base
WHERE classi_fin = 5
GROUP BY ano
ORDER BY ano;



-- 2) INTERNAÇÕES por ano (HOSPITAL = 1) e qual ano teve mais internações
WITH base AS (
  SELECT 2023 AS ano, dt_notific, dt_sin_pri, hospital, uti, classi_fin, evolucao, vacina_cov
  FROM tfc_infnet.ext_covid_2023
  UNION ALL
  SELECT 2024 AS ano, dt_notific, dt_sin_pri, hospital, uti, classi_fin, evolucao, vacina_cov
  FROM tfc_infnet.ext_covid_2024
)
SELECT ano,
       SUM(CASE WHEN hospital = 1 THEN 1 ELSE 0 END) AS internacoes
FROM base
GROUP BY ano
ORDER BY ano;


-- 3) % UTI entre VACINADOS x NÃO VACINADOS por ano
-- (considera valores conhecidos diferentes de vacina_cov in =(1) como não vacinados e uti in (1,2))
WWITH base AS (
  SELECT 2023 AS ano, CAST(uti AS INT) AS uti, CAST(vacina_cov AS INT) AS vacina_cov
  FROM tfc_infnet.ext_covid_2023
  UNION ALL
  SELECT 2024 AS ano, CAST(uti AS INT) AS uti, CAST(vacina_cov AS INT) AS vacina_cov
  FROM tfc_infnet.ext_covid_2024
)
SELECT
  ano,
  CASE WHEN vacina_cov = 1 THEN 'Vacinado' ELSE 'Não vacinado' END AS status_vacinacao,
  SUM(CASE WHEN uti = 1 THEN 1 ELSE 0 END) AS uti_sim,
  COUNT(*) AS total,
  ROUND(100.0 * SUM(CASE WHEN uti = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS perc_uti
FROM base
WHERE uti IN (1,2)          -- só UTI conhecida
GROUP BY ano, CASE WHEN vacina_cov = 1 THEN 'Vacinado' ELSE 'Não vacinado' END
ORDER BY ano, status_vacinacao;


-- 4) ÓBITOS por ano (EVOLUCAO = 2 normalmente indica óbito)
WITH base AS (
  SELECT 2023 AS ano, evolucao FROM tfc_infnet.ext_covid_2023
  UNION ALL
  SELECT 2024 AS ano, evolucao FROM tfc_infnet.ext_covid_2024
)
SELECT ano,
       SUM(CASE WHEN evolucao = 2 THEN 1 ELSE 0 END) AS obitos
FROM base
GROUP BY ano
ORDER BY ano;