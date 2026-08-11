"""
Tratamento da base financeira
Projeto: Painel Financeiro

Objetivo:
- Ler a base financeira bruta;
- Validar estrutura e tipos;
- Tratar datas e valores;
- Criar indicadores auxiliares;
- Classificar situação financeira;
- Exportar uma base tratada para uso em SQL/Power BI.
"""

from pathlib import Path
import pandas as pd


# ---------------------------------------------------------------------
# 1. Configuração dos caminhos
# ---------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[1]

ARQUIVO_ENTRADA = BASE_DIR / "dados" / "dados_financeiros.csv"
ARQUIVO_SAIDA = BASE_DIR / "dados" / "dados_financeiros_tratados.csv"


# ---------------------------------------------------------------------
# 2. Leitura da base
# ---------------------------------------------------------------------

def carregar_dados(caminho: Path) -> pd.DataFrame:
    if not caminho.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {caminho}")

    df = pd.read_csv(caminho, encoding="utf-8-sig")

    if df.empty:
        raise ValueError("A base está vazia.")

    return df


# ---------------------------------------------------------------------
# 3. Validação da estrutura
# ---------------------------------------------------------------------

def validar_colunas(df: pd.DataFrame) -> None:
    colunas_obrigatorias = {
        "data_lancamento",
        "tipo",
        "categoria",
        "subcategoria",
        "descricao",
        "cliente_fornecedor",
        "centro_custo",
        "valor",
        "data_vencimento",
        "data_pagamento",
        "status",
        "conta",
    }

    colunas_faltantes = colunas_obrigatorias - set(df.columns)

    if colunas_faltantes:
        raise ValueError(
            f"Colunas obrigatórias ausentes: {sorted(colunas_faltantes)}"
        )


# ---------------------------------------------------------------------
# 4. Tratamento dos dados
# ---------------------------------------------------------------------

def tratar_dados(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Datas
    colunas_data = [
        "data_lancamento",
        "data_vencimento",
        "data_pagamento",
    ]

    for coluna in colunas_data:
        df[coluna] = pd.to_datetime(
            df[coluna],
            errors="coerce"
        )

    # Valores
    df["valor"] = pd.to_numeric(
        df["valor"],
        errors="coerce"
    )

    # Texto
    colunas_texto = [
        "tipo",
        "categoria",
        "subcategoria",
        "descricao",
        "cliente_fornecedor",
        "centro_custo",
        "status",
        "conta",
    ]

    for coluna in colunas_texto:
        df[coluna] = (
            df[coluna]
            .astype("string")
            .str.strip()
        )

    # Remover registros sem informações financeiras essenciais
    df = df.dropna(
        subset=[
            "data_lancamento",
            "tipo",
            "valor",
        ]
    )

    # Remover valores inválidos
    df = df[df["valor"] >= 0]

    # Padronizar tipo
    df["tipo"] = df["tipo"].str.title()

    # Padronizar status
    df["status"] = df["status"].str.title()

    # -----------------------------------------------------------------
    # Campos auxiliares
    # -----------------------------------------------------------------

    df["ano"] = df["data_lancamento"].dt.year
    df["mes"] = df["data_lancamento"].dt.month
    df["mes_nome"] = df["data_lancamento"].dt.strftime("%B")
    df["trimestre"] = (
        "T" + df["data_lancamento"].dt.quarter.astype(str)
    )

    # Valor de receita e despesa separados
    df["valor_receita"] = df["valor"].where(
        df["tipo"].eq("Receita"),
        0
    )

    df["valor_despesa"] = df["valor"].where(
        df["tipo"].eq("Despesa"),
        0
    )

    # Resultado financeiro
    df["resultado"] = (
        df["valor_receita"] - df["valor_despesa"]
    )

    # Situação financeira
    df["em_aberto"] = df["status"].isin(
        ["Em Aberto", "Atrasado"]
    )

    df["pago_recebido"] = df["status"].isin(
        ["Pago", "Recebido"]
    )

    df["atrasado"] = df["status"].eq("Atrasado")

    # Dias entre vencimento e pagamento
    df["dias_para_pagamento"] = (
        df["data_pagamento"] - df["data_vencimento"]
    ).dt.days

    # Indicador de atraso
    df["dias_atraso"] = (
        df["dias_para_pagamento"]
        .clip(lower=0)
        .fillna(0)
        .astype(int)
    )

    # Ordenação
    df = df.sort_values(
        by=["data_lancamento", "tipo", "categoria"]
    ).reset_index(drop=True)

    return df


# ---------------------------------------------------------------------
# 5. Exportação
# ---------------------------------------------------------------------

def salvar_dados(df: pd.DataFrame, caminho: Path) -> None:
    caminho.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    df.to_csv(
        caminho,
        index=False,
        encoding="utf-8-sig"
    )


# ---------------------------------------------------------------------
# 6. Execução principal
# ---------------------------------------------------------------------

def main() -> None:
    print("Iniciando tratamento da base financeira...")

    df = carregar_dados(ARQUIVO_ENTRADA)

    print(f"Registros carregados: {len(df):,}")

    validar_colunas(df)

    df_tratado = tratar_dados(df)

    salvar_dados(
        df_tratado,
        ARQUIVO_SAIDA
    )

    print(f"Registros após tratamento: {len(df_tratado):,}")
    print(f"Arquivo gerado: {ARQUIVO_SAIDA}")
    print("Tratamento concluído com sucesso.")


if __name__ == "__main__":
    main()
