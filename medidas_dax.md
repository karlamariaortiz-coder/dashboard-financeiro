# Medidas DAX — Painel Financeiro

> Modelo analítico desenvolvido para o projeto de portfólio **Painel Financeiro**.
> As medidas abaixo foram pensadas para a tabela `dados_financeiros_tratados`.

## 1. Medidas principais

### Receita Total

```DAX
Receita Total =
SUM(dados_financeiros_tratados[valor_receita])
```

### Despesa Total

```DAX
Despesa Total =
SUM(dados_financeiros_tratados[valor_despesa])
```

### Resultado

```DAX
Resultado =
[Receita Total] - [Despesa Total]
```

### Margem

```DAX
Margem % =
DIVIDE(
    [Resultado],
    [Receita Total],
    0
)
```

Formate como **percentual** no Power BI.

---

## 2. Contas em aberto

### Valor em Aberto

```DAX
Valor em Aberto =
CALCULATE(
    SUM(dados_financeiros_tratados[valor]),
    dados_financeiros_tratados[em_aberto] = TRUE()
)
```

### Valor Atrasado

```DAX
Valor Atrasado =
CALCULATE(
    SUM(dados_financeiros_tratados[valor]),
    dados_financeiros_tratados[atrasado] = TRUE()
)
```

### Quantidade de Contas em Aberto

```DAX
Qtd. Contas em Aberto =
CALCULATE(
    COUNTROWS(dados_financeiros_tratados),
    dados_financeiros_tratados[em_aberto] = TRUE()
)
```

### Quantidade de Contas Atrasadas

```DAX
Qtd. Contas Atrasadas =
CALCULATE(
    COUNTROWS(dados_financeiros_tratados),
    dados_financeiros_tratados[atrasado] = TRUE()
)
```

---

## 3. Indicadores operacionais

### Ticket Médio

```DAX
Ticket Médio =
AVERAGE(dados_financeiros_tratados[valor])
```

### Receita Média

```DAX
Receita Média =
AVERAGEX(
    FILTER(
        dados_financeiros_tratados,
        dados_financeiros_tratados[tipo] = "Receita"
    ),
    dados_financeiros_tratados[valor]
)
```

### Despesa Média

```DAX
Despesa Média =
AVERAGEX(
    FILTER(
        dados_financeiros_tratados,
        dados_financeiros_tratados[tipo] = "Despesa"
    ),
    dados_financeiros_tratados[valor]
)
```

### Média de Dias de Atraso

```DAX
Média Dias de Atraso =
AVERAGEX(
    FILTER(
        dados_financeiros_tratados,
        dados_financeiros_tratados[atrasado] = TRUE()
    ),
    dados_financeiros_tratados[dias_atraso]
)
```

---

## 4. Indicadores de composição

### Participação das Despesas

```DAX
Participação Despesa % =
DIVIDE(
    [Despesa Total],
    [Receita Total],
    0
)
```

### Resultado por Lançamento

```DAX
Resultado Médio por Lançamento =
AVERAGE(dados_financeiros_tratados[resultado])
```

---

## 5. Análise temporal

Para uma análise temporal mais robusta, recomenda-se criar uma tabela calendário no Power BI.

### Tabela Calendário

```DAX
Calendario =
ADDCOLUMNS(
    CALENDAR(
        MIN(dados_financeiros_tratados[data_lancamento]),
        MAX(dados_financeiros_tratados[data_lancamento])
    ),
    "Ano", YEAR([Date]),
    "Mês Número", MONTH([Date]),
    "Mês", FORMAT([Date], "MMMM"),
    "Ano Mês", FORMAT([Date], "YYYY-MM"),
    "Trimestre", "T" & FORMAT([Date], "Q")
)
```

Depois, criar relacionamento:

```text
Calendario[Date]
        ↓
dados_financeiros_tratados[data_lancamento]
```

### Receita no Período Anterior

```DAX
Receita Mês Anterior =
CALCULATE(
    [Receita Total],
    DATEADD(
        Calendario[Date],
        -1,
        MONTH
    )
)
```

### Variação da Receita

```DAX
Variação Receita % =
DIVIDE(
    [Receita Total] - [Receita Mês Anterior],
    [Receita Mês Anterior],
    0
)
```

### Resultado Acumulado

```DAX
Resultado Acumulado =
CALCULATE(
    [Resultado],
    FILTER(
        ALLSELECTED(Calendario[Date]),
        Calendario[Date] <= MAX(Calendario[Date])
    )
)
```

---

## 6. Indicadores executivos

### Quantidade de Lançamentos

```DAX
Qtd. Lançamentos =
COUNTROWS(dados_financeiros_tratados)
```

### Quantidade de Receitas

```DAX
Qtd. Receitas =
CALCULATE(
    COUNTROWS(dados_financeiros_tratados),
    dados_financeiros_tratados[tipo] = "Receita"
)
```

### Quantidade de Despesas

```DAX
Qtd. Despesas =
CALCULATE(
    COUNTROWS(dados_financeiros_tratados),
    dados_financeiros_tratados[tipo] = "Despesa"
)
```

### Percentual Atrasado

```DAX
% Atrasado =
DIVIDE(
    [Qtd. Contas Atrasadas],
    [Qtd. Lançamentos],
    0
)
```

---

## 7. KPIs recomendados para o dashboard

### Visão Executiva

Usar cartões para:

- Receita Total
- Despesa Total
- Resultado
- Margem %
- Valor em Aberto
- Valor Atrasado

### Gráficos

**Evolução financeira**
- Eixo: `Calendario[Ano Mês]`
- Valores: Receita, Despesa e Resultado

**Despesas por categoria**
- Categoria
- Despesa Total

**Despesas por centro de custo**
- Centro de Custo
- Despesa Total

**Receitas por cliente**
- Cliente/Fornecedor
- Receita Total

**Atrasos**
- Cliente/Fornecedor
- Valor
- Dias de atraso

---

## 8. Modelo conceitual

```text
                  ┌──────────────────────┐
                  │      Calendario      │
                  │──────────────────────│
                  │ Date                 │
                  │ Ano                  │
                  │ Mês                  │
                  │ Ano Mês              │
                  │ Trimestre            │
                  └──────────┬───────────┘
                             │
                             │ 1 : N
                             ▼
              ┌──────────────────────────────┐
              │ dados_financeiros_tratados  │
              │──────────────────────────────│
              │ data_lancamento              │
              │ tipo                         │
              │ categoria                    │
              │ subcategoria                 │
              │ cliente_fornecedor            │
              │ centro_custo                 │
              │ valor                        │
              │ valor_receita                │
              │ valor_despesa                │
              │ resultado                    │
              │ status                       │
              │ em_aberto                    │
              │ atrasado                     │
              │ dias_atraso                  │
              └──────────────────────────────┘
```

## Objetivo do modelo

A camada DAX transforma a base tratada em indicadores de **Controladoria, Finanças e Business Intelligence**, permitindo análise por período, categoria, centro de custo, cliente/fornecedor e situação financeira.

---

## Tecnologias

- Power BI
- DAX
- Python
- SQL
- Git/GitHub
- Inteligência Artificial
- Automação
