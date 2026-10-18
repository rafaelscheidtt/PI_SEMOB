#!/usr/bin/env python3
"""Gera o pacote de exemplo em dados/exemplo/ (dados fictícios, no formato do Smart Report).

Uso: python scripts/gera_exemplo.py
"""
import random
from datetime import date, datetime, timedelta
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1] / "dados" / "exemplo"
INICIO = date(2026, 9, 7)  # segunda-feira
DIAS = [INICIO + timedelta(days=i) for i in range(7)]
LINHAS = {"01": "CENTRO SENTIDO BAIRRO", "02": "CIRCULAR SENTIDO IDA", "03": "TERMINAL SENTIDO ESTACAO"}
SEM = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"]
rnd = random.Random(2026)


def br(v, casas=1):
    if isinstance(v, int):
        return f"{v:,}".replace(",", ".")
    s = f"{v:,.{casas}f}".replace(",", "X").replace(".", ",").replace("X", ".")
    return s.rstrip("0").rstrip(",") if casas == 1 else s


def pagina(titulo, tabelas, dominio="SmartDataSource.com", gerado="15/09/2026 08:00", obs=""):
    partes = [f"""<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>{titulo}</title>
    <meta http-equiv="content-type" content="text/html; charset=Cp1252">
    <style type="text/css">
      body {{ font-family: verdana, arial, helvetica, sans-serif; font-size: smaller; }}
      table {{ border: 1px solid #dddddd; border-collapse: collapse; }}
      th, td {{ border: 1px solid #11a8a5; padding: 2px; }}
      table.data {{ background: #28c6be; }}
      tr.even {{ background: #bbfffc; }}
      tr.odd {{ background: #a4dad2; }}
    </style>
  </head>
  <body>
    <table class="data">
      <tr>
        <th><a href="http://www.smartdatasource.com">{dominio}</a></th>
        <th>Hor&aacute;rio</th>
      </tr>
  <tr class="even">
    <td align="right">Gerado por &quot;Smart Report&quot;</td>
    <td align="right">{gerado}</td>
  </tr>
    </table>
    <p>Utilize [Ctrl +] ou [Ctrl -] para melhor ajuste de tela</p>"""]
    for h1, cabecalho, linhas, total in tabelas:
        partes.append(f"\n    <h1>{h1}</h1>\n    <p>{obs}</p>\n    <br>\n<table class='data'>\n")
        partes.append("".join(f"<th>{c}</th>\n" for c in cabecalho))
        for i, l in enumerate(linhas):
            partes.append(f"<tr class='{'even' if i % 2 == 0 else 'odd'}'>\n" + "".join(f"<td align='right'>{c}</td>\n" for c in l) + "</tr>\n")
        if total:
            partes.append("<tr class='total'>\n" + "".join(f"<td align='right'>{c}</td>\n" for c in total) + "</tr>\n")
        partes.append("</table>\n")
    partes.append("    <p>[SmartDataSource.com]</p>\n  </body>\n</html>\n")
    return "".join(partes).encode("cp1252")


def operacao():
    """Números diários coerentes entre os relatórios."""
    dias = {}
    for d in DIAS:
        fator = 1.0 if d.weekday() < 5 else (0.7 if d.weekday() == 5 else 0.55)
        por_linha = {}
        for cod in LINHAS:
            base = {"01": 120, "02": 220, "03": 160}[cod]
            prog = int(base * fator)
            real = prog - (1 if rnd.random() < 0.3 else 0)
            km = round(real * {"01": 6.6, "02": 8.1, "03": 7.7}[cod], 1)
            por_linha[cod] = {"prog": prog, "real": real, "km": km}
        dias[d] = por_linha
    return dias


def escrever(pasta: Path, sufixo: str, dados, com_erros=False):
    pasta.mkdir(parents=True, exist_ok=True)
    # Resumo Geral
    linhas, tp = [], [0, 0, 0, 0.0, 0.0, 0.0]
    for d, pl in dados.items():
        prog = sum(x["prog"] for x in pl.values()); real = sum(x["real"] for x in pl.values())
        kmp = round(sum(x["km"] for x in pl.values()), 1); kmi = round(kmp * 0.05, 1)
        if com_erros and d == DIAS[1]:
            kmp = -kmp  # quilometragem negativa: deve ser rejeitada (RN05)
        veic = 18 if d.weekday() < 5 else 12
        linhas.append([d.strftime("%d/%m/%Y"), SEM[d.weekday()], veic, veic - 2, prog, real, prog - real, br(kmp), br(kmi), br(round(kmp + kmi, 1))])
        tp[0] += prog; tp[1] += real; tp[3] += kmp; tp[4] += kmi
    if com_erros:
        linhas.append(["31/02/2026", "Seg", 18, 16, 500, 500, 0, "3.000", "150", "3.150"])  # data inválida
    total = ["Total Geral", "", "", "", tp[0], tp[1], tp[0] - tp[1], br(round(tp[3], 1)), br(round(tp[4], 1)), br(round(tp[3] + tp[4], 1))]
    (pasta / f"Mensal_{sufixo}.html").write_bytes(pagina("Mensal - Resumo Geral", [("Mensal - Resumo Geral",
        ["Data", "diaSem", "nrVeiculos", "nrMaxVeicFx", "nrViagensProgr", "nrViagensRealiz", "Dif Viagens", "kmProd", "kmImprod", "kmTotal"], linhas, total)]))
    if com_erros:
        return
    # FCV por turno
    linhas = []
    for d, pl in dados.items():
        prog = sum(x["prog"] for x in pl.values()); real = sum(x["real"] for x in pl.values())
        m_p, t_p = int(prog * 0.39), int(prog * 0.34); n_p = prog - m_p - t_p
        falta = prog - real
        linhas.append([d.strftime("%d/%m/%Y"), m_p, m_p - min(falta, 1), t_p, t_p - max(0, falta - 1), n_p, n_p, prog, real])
    (pasta / f"Mensal_FCV_{sufixo}.html").write_bytes(pagina("Mensal - Fator de Cumprimento de Viagem", [("Mensal - Fator de Cumprimento de Viagem",
        ["Data", "manha_p", "manha_r", "tarde_p", "tarde_r", "noite_p", "noite_r", "programadas", "realizadas"], linhas, None)]))
    # Resumo por Linha
    linhas = [[d.strftime("%d/%m/%Y"), cod, br(x["km"]), x["real"]] for d, pl in dados.items() for cod, x in pl.items()]
    (pasta / f"Mensal_Linhas_{sufixo}.html").write_bytes(pagina("Mensal - Resumo por Linha", [("Mensal - Resumo por Linha", ["Data", "Linha", "kmTotal", "nrViagens"], linhas, None)]))
    # Resumo por Faixa Horária
    linhas = []
    for fx in range(4, 24):
        for d, pl in dados.items():
            real = sum(x["real"] for x in pl.values())
            linhas.append([d.strftime("%d/%m/%Y"), f"{fx}hs", 6 if 6 <= fx <= 20 else 3, max(1, int(real / 20 * (1.3 if fx in (6, 7, 17, 18) else 0.9)))])
    (pasta / f"Mensal_Resumo_FxHr_{sufixo}.html").write_bytes(pagina("Mensal - Resumo por Faixa Hor&aacute;ria", [("Mensal - Resumo por Faixa Hor&aacute;ria", ["Data", "Fx_Hor", "Nr_Veiculos", "Nr_Viagens"], linhas, None)]))
    # Partidas por Faixa Horária
    linhas = []
    for cod in LINHAS:
        for fx in (6, 7, 8):
            for d, pl in dados.items():
                n = max(1, pl[cod]["real"] // 18)
                linhas.append([d.strftime("%d/%m/%Y"), cod, f"{fx}hs", 2, n, " > ".join(f"{(i * 60 // n):02d}" for i in range(n))])
    (pasta / f"Mensal_FxHr_{sufixo}.html").write_bytes(pagina("Mensal - Partidas por Faixa Hor&aacute;ria", [("Mensal - Partidas por Faixa Hor&aacute;ria", ["Data", "Linha", "Fx_Hor", "Nr_Veiculos", "Nr_Viagens", "Partidas"], linhas, None)]))
    # Viagens (uma amostra: duas viagens por linha e dia)
    linhas = []
    for d, pl in dados.items():
        for cod, x in pl.items():
            for i, sentido in enumerate(("I", "V")):
                ini = datetime.combine(d, datetime.min.time()) + timedelta(hours=6, minutes=i * 25)
                fim = ini + timedelta(minutes=22)
                linhas.append([d.strftime("%d/%m/%Y"), cod, 1500 + int(cod), "Viagem Normal", sentido, 6, ini.strftime("%Y-%m-%d %H:%M:%S"), fim.strftime("%Y-%m-%d %H:%M:%S"), br(round(x["km"] / x["real"], 1)), 0, br(round(x["km"] / x["real"], 1))])
    (pasta / f"Mensal_Viagens_{sufixo}.html").write_bytes(pagina("Mensal - Viagens", [("Mensal - Viagens", ["Data", "Linha", "Prefixo", "Atividade", "Sentido", "Fx_Hor", "inicioRealizado", "fimRealizado", "kmProd", "kmImprod", "kmTotal"], linhas, None)]))
    # Ocorrências: uma não realizada por viagem faltante; uma não terminada e uma não iniciada fixas
    cab = ["Data", "Linha", "Atendimento", "Prefixo", "Atividade", "Motorista", "Sentido", "Tabela", "statusSaida", "statusChegada", "inicioProgramado", "inicioRealizado", "fimProgramado", "fimRealizado", "kmProd"]
    nreal = []
    for d, pl in dados.items():
        for cod, x in pl.items():
            if x["prog"] > x["real"]:
                ini = datetime.combine(d, datetime.min.time()) + timedelta(hours=7, minutes=5)
                nreal.append([d.strftime("%d/%m/%Y"), cod, LINHAS[cod], "", "Viagem Normal", 100 + int(cod), "I", "2A", "", "", ini.strftime("%Y-%m-%d %H:%M:%S"), "", (ini + timedelta(minutes=30)).strftime("%Y-%m-%d %H:%M:%S"), "", 0])
    (pasta / f"Mensal_Viag_NRealiz_{sufixo}.html").write_bytes(pagina("Mensal - Viagens n&atilde;o Realizadas", [("Mensal - Viagens n&atilde;o Realizadas", cab, nreal, None)]))
    d0 = DIAS[2].strftime("%Y-%m-%d"); dd = DIAS[2].strftime("%d/%m/%Y")
    (pasta / f"Mensal_Viag_NTerm_{sufixo}.html").write_bytes(pagina("Mensal - Viagens n&atilde;o Terminadas", [("Mensal - Viagens n&atilde;o Terminadas", cab,
        [[dd, "02", LINHAS["02"], 1502, "Viagem Normal", 102, "V", "1B", "RG", "", f"{d0} 14:10:00", f"{d0} 14:10:06", f"{d0} 14:35:00", "", 0]], None)]))
    (pasta / f"Mensal_Viag_Ninic_{sufixo}.html").write_bytes(pagina("Mensal - Viagens n&atilde;o Iniciadas", [("Mensal - Viagens n&atilde;o Iniciadas", cab,
        [[dd, "02", LINHAS["02"], 1502, "Viagem Normal", 102, "I", "1B", "", "RG", f"{d0} 14:35:00", "", f"{d0} 15:00:00", f"{d0} 14:54:52", 0]], None)]))
    # Passageiros (bilhetagem, sistema inteiro)
    linhas, tot = [], [0, 0, 0, 0]
    for d, pl in dados.items():
        real = sum(x["real"] for x in pl.values())
        cat, ant, nao = int(real * 9.5), int(real * 2.5), int(real * 18)
        linhas.append([d.strftime("%Y-%m"), f"{d.day:02d}", br(cat), br(ant), br(nao), br(cat + ant + nao)])
        tot[0] += cat; tot[1] += ant; tot[2] += nao; tot[3] += cat + ant + nao
    linhas.append([DIAS[0].strftime("%Y-%m"), "Total M&ecirc;s", br(tot[0]), br(tot[1]), br(tot[2]), br(tot[3])])
    (pasta / "Passageiros_Mensal.html").write_bytes(pagina("S&atilde;o Caetano do Sul - Passageiros do Sistema", [("S&atilde;o Caetano do Sul - Passageiros do Sistema",
        ["M&ecirc;s", "Dia", "Catraca", "Antecipados", "N&atilde;o Pagantes", "Total Passageiros"], linhas, None)], dominio="SmartDataSource.com.br", gerado="15-Set 08:01",
        obs="Obs: A quantidade de passageiros &eacute; provis&oacute;ria, sendo atualizada diariamente de acordo com a atualiza&ccedil;&atilde;o do sistema de bilhetagem."))
    # Saldos (duas tabelas)
    saldo = 1_000_000.0; t1, t2 = [], []
    for d, pl in dados.items():
        real = sum(x["real"] for x in pl.values())
        transf = round(real * 12.5, 2); vendas = round(real * 13.0, 2) if d.weekday() < 5 else 0.0; util = round(real * 11.0, 2)
        saldo = round(saldo - transf, 2)
        t1.append([d.strftime("%Y-%m"), f"{d.day:02d}", 1, br(transf, 2), br(saldo, 2)])
        t2.append([d.strftime("%Y-%m"), f"{d.day:02d}", br(vendas, 2), br(util, 2), br(round(vendas - util, 2), 2)])
    (pasta / "Saldos_Mensal.html").write_bytes(pagina("S&atilde;o Caetano do Sul - Saldo de cr&eacute;ditos do sistema", [
        ("S&atilde;o Caetano do Sul - Saldo de cr&eacute;ditos do sistema", ["M&ecirc;s", "Dia", "S&eacute;rie", "Cr&eacute;ditos transferidos<br>para cart&otilde;es", "Saldo Final"], t1, None),
        ("S&atilde;o Caetano do Sul - Venda x Utiliza&ccedil;&atilde;o", ["M&ecirc;s", "Dia", "Total Vendas", "Total Utiliza&ccedil;&atilde;o", "Cr&eacute;dito Circulante"], t2, None),
    ], dominio="SmartDataSource.com.br", gerado="15-Set 08:01"))


if __name__ == "__main__":
    dados = operacao()
    escrever(RAIZ / "Setembro_2026" / "Mensal", "202609", dados)
    escrever(RAIZ / "com_erros", "202609", dados, com_erros=True)
    print("ok:", sorted(str(p.relative_to(RAIZ)) for p in RAIZ.rglob("*.html")))
