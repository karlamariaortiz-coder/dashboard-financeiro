/*
===========================================================
PROJETO: Painel Financeiro
ARQUIVO: consultas.sql
DIALETO: PostgreSQL

Objetivo:
Criar consultas para análise financeira, controladoria,
fluxo de caixa e indicadores de desempenho.

Tabela utilizada:
dados_financeiros_tratados

Observação:
A tabela deve conter a base gerada pelo tratamento em Python.
===========================================================
*/


/* =========================================================
1. VISÃO GERAL DA BASE
========================================================= */

SELECT
    COUNT(*) AS total_lancamentos,
    COUNT(DISTINCT cliente_fornecedor) AS total_clientes_fornecedores,
    COUNT(DISTINCT categoria) AS total_categorias,
    MIN(data_lancamento) AS primeira_data,
    MAX(data_lancamento) AS ultima_data,
    SUM(valor) AS valor_total_movimentado
FROM dados_financeiros_tratados;


/* =========================================================
2. RECEITAS, DESPESAS E RESULTADO
========================================================= */

SELECT
    SUM(valor_receita) AS total_receitas,
    SUM(valor_despesa) AS total_despesas,
    SUM(resultado) AS resultado_financeiro
FROM dados_financeiros_tratados;


/* =========================================================
3. MARGEM FINANCEIRA
========================================================= */

SELECT
    SUM(valor_receita) AS receita_total,
    SUM(valor_despesa) AS despesa_total,
    SUM(resultado) AS resultado,
    ROUND(
        100.0 * SUM(resultado)
        / NULLIF(SUM(valor_receita), 0),
        2
    ) AS margem_percentual
FROM dados_financeiros_tratados;


/* =========================================================
4. RESULTADO POR MÊS
========================================================= */

SELECT
    ano,
    mes,
    mes_nome,
    SUM(valor_receita) AS receitas,
    SUM(valor_despesa) AS despesas,
    SUM(resultado) AS resultado
FROM dados_financeiros_tratados
GROUP BY
    ano,
    mes,
    mes_nome
ORDER BY
    ano,
    mes;


/* =========================================================
5. RECEITA POR CATEGORIA
========================================================= */

SELECT
    categoria,
    SUM(valor_receita) AS receita,
    ROUND(
        100.0 * SUM(valor_receita)
        / NULLIF(
            (SELECT SUM(valor_receita)
             FROM dados_financeiros_tratados),
            0
        ),
        2
    ) AS participacao_percentual
FROM dados_financeiros_tratados
WHERE tipo = 'Receita'
GROUP BY categoria
ORDER BY receita DESC;


/* =========================================================
6. DESPESAS POR CATEGORIA
========================================================= */

SELECT
    categoria,
    SUM(valor_despesa) AS despesa,
    ROUND(
        100.0 * SUM(valor_despesa)
        / NULLIF(
            (SELECT SUM(valor_despesa)
             FROM dados_financeiros_tratados),
            0
        ),
        2
    ) AS participacao_percentual
FROM dados_financeiros_tratados
WHERE tipo = 'Despesa'
GROUP BY categoria
ORDER BY despesa DESC;


/* =========================================================
7. DESPESAS POR CENTRO DE CUSTO
========================================================= */

SELECT
    centro_custo,
    SUM(valor_despesa) AS despesas,
    COUNT(*) AS quantidade_lancamentos
FROM dados_financeiros_tratados
WHERE tipo = 'Despesa'
GROUP BY centro_custo
ORDER BY despesas DESC;


/* =========================================================
8. CONTAS EM ABERTO
========================================================= */

SELECT
    tipo,
    status,
    COUNT(*) AS quantidade,
    SUM(valor) AS valor_total
FROM dados_financeiros_tratados
WHERE em_aberto = TRUE
GROUP BY tipo, status
ORDER BY valor_total DESC;


/* =========================================================
9. CONTAS ATRASADAS
========================================================= */

SELECT
    tipo,
    categoria,
    cliente_fornecedor,
    data_vencimento,
    valor,
    dias_atraso
FROM dados_financeiros_tratados
WHERE atrasado = TRUE
ORDER BY
    dias_atraso DESC,
    valor DESC;


/* =========================================================
10. VALOR TOTAL ATRASADO
========================================================= */

SELECT
    COUNT(*) AS quantidade_atrasados,
    SUM(valor) AS valor_atrasado,
    ROUND(AVG(valor), 2) AS valor_medio_atrasado,
    ROUND(AVG(dias_atraso), 2) AS media_dias_atraso
FROM dados_financeiros_tratados
WHERE atrasado = TRUE;


/* =========================================================
11. TOP 10 CLIENTES POR RECEITA
========================================================= */

SELECT
    cliente_fornecedor,
    SUM(valor_receita) AS receita_total,
    COUNT(*) AS quantidade_lancamentos
FROM dados_financeiros_tratados
WHERE tipo = 'Receita'
GROUP BY cliente_fornecedor
ORDER BY receita_total DESC
LIMIT 10;


/* =========================================================
12. TOP 10 FORNECEDORES POR DESPESA
========================================================= */

SELECT
    cliente_fornecedor AS fornecedor,
    SUM(valor_despesa) AS despesa_total,
    COUNT(*) AS quantidade_lancamentos
FROM dados_financeiros_tratados
WHERE tipo = 'Despesa'
GROUP BY cliente_fornecedor
ORDER BY despesa_total DESC
LIMIT 10;


/* =========================================================
13. EVOLUÇÃO TRIMESTRAL
========================================================= */

SELECT
    ano,
    trimestre,
    SUM(valor_receita) AS receitas,
    SUM(valor_despesa) AS despesas,
    SUM(resultado) AS resultado
FROM dados_financeiros_tratados
GROUP BY ano, trimestre
ORDER BY ano, trimestre;


/* =========================================================
14. STATUS DOS LANÇAMENTOS
========================================================= */

SELECT
    tipo,
    status,
    COUNT(*) AS quantidade,
    SUM(valor) AS valor_total
FROM dados_financeiros_tratados
GROUP BY tipo, status
ORDER BY tipo, valor_total DESC;


/* =========================================================
15. TICKET MÉDIO POR TIPO
========================================================= */

SELECT
    tipo,
    COUNT(*) AS quantidade,
    ROUND(AVG(valor), 2) AS ticket_medio,
    ROUND(MIN(valor), 2) AS menor_lancamento,
    ROUND(MAX(valor), 2) AS maior_lancamento
FROM dados_financeiros_tratados
GROUP BY tipo;


/* =========================================================
16. ANÁLISE DE PRAZO DE PAGAMENTO
========================================================= */

SELECT
    tipo,
    ROUND(AVG(dias_para_pagamento), 2) AS media_dias_pagamento,
    ROUND(AVG(dias_atraso), 2) AS media_dias_atraso
FROM dados_financeiros_tratados
WHERE pago_recebido = TRUE
GROUP BY tipo;


/* =========================================================
17. CONCENTRAÇÃO DE DESPESAS
========================================================= */

SELECT
    categoria,
    SUM(valor_despesa) AS despesa,
    ROUND(
        100.0 * SUM(valor_despesa)
        / NULLIF(
            (SELECT SUM(valor_despesa)
             FROM dados_financeiros_tratados),
            0
        ),
        2
    ) AS participacao
FROM dados_financeiros_tratados
WHERE tipo = 'Despesa'
GROUP BY categoria
ORDER BY participacao DESC;


/* =========================================================
18. RESULTADO POR CENTRO DE CUSTO
========================================================= */

SELECT
    centro_custo,
    SUM(valor_receita) AS receitas,
    SUM(valor_despesa) AS despesas,
    SUM(resultado) AS resultado
FROM dados_financeiros_tratados
GROUP BY centro_custo
ORDER BY resultado DESC;


/* =========================================================
19. CLIENTES COM RECEITA E VALORES EM ABERTO
========================================================= */

SELECT
    cliente_fornecedor,
    SUM(valor_receita) AS receita_total,
    SUM(
        CASE
            WHEN em_aberto = TRUE THEN valor
            ELSE 0
        END
    ) AS valor_em_aberto
FROM dados_financeiros_tratados
WHERE tipo = 'Receita'
GROUP BY cliente_fornecedor
ORDER BY valor_em_aberto DESC;


/* =========================================================
20. INDICADORES EXECUTIVOS
========================================================= */

SELECT
    SUM(valor_receita) AS receita_total,
    SUM(valor_despesa) AS despesa_total,
    SUM(resultado) AS resultado_total,

    ROUND(
        100.0 * SUM(resultado)
        / NULLIF(SUM(valor_receita), 0),
        2
    ) AS margem_percentual,

    SUM(
        CASE
            WHEN em_aberto = TRUE THEN valor
            ELSE 0
        END
    ) AS contas_em_aberto,

    SUM(
        CASE
            WHEN atrasado = TRUE THEN valor
            ELSE 0
        END
    ) AS contas_atrasadas

FROM dados_financeiros_tratados;


/*
===========================================================
INDICADORES DESENVOLVIDOS

Este conjunto de consultas permite alimentar uma camada
de Business Intelligence com indicadores de:

- Receita
- Despesas
- Resultado
- Margem
- Fluxo financeiro
- Contas em aberto
- Inadimplência
- Centros de custo
- Concentração de despesas
- Clientes e fornecedores
- Evolução mensal e trimestral
===========================================================
*/
