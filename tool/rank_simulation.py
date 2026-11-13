"""Simulação de calibração do tempo até o rank S (docs: CLAUDE.md §30.9).

Uso: python tool/rank_simulation.py            (regras atuais: experiência)
     python tool/rank_simulation.py --meses    (regras antigas: tempo mínimo)

Modelo (esperança diária, sem aleatoriedade):
- XP: treino 100, PR 50 (PRs/treino com meia-vida 12 meses, piso 25%),
  missão diária 50, missão semanal por nº de treinos programados,
  atividade extra 30 (máx. 3/sem), penalidade 100/dia (máx. 300/sem).
- Folgas: 4 por mês, usadas nos dias em que a missão seria perdida.
- Exame inicia no dia da liberação; passa se as taxas atingem as metas.
"""
import sys

RANKS = ['F', 'E', 'D', 'C', 'B', 'A', 'S']
NIVEL_MIN = {'E': 10, 'D': 25, 'C': 45, 'B': 70, 'A': 100, 'S': 140}
# alvo: (prazo, %treinos, %missão)
EXAME = {'E': (35, .80, .75), 'D': (50, .80, .75), 'C': (70, .85, .80),
         'B': (90, .85, .80), 'A': (110, .90, .85), 'S': (140, .95, .90)}
MESES_ANTIGOS = {'F': 2, 'E': 3, 'D': 5, 'C': 7, 'B': 9, 'A': 10}
# Experiência mínima no rank ATUAL para liberar o exame do próximo.
EXP_MIN = {'F': 12, 'E': 40, 'D': 50, 'C': 70, 'B': 85, 'A': 100}
XP_SEMANAL = {0: 0, 1: 50, 2: 100, 3: 150, 4: 250, 5: 300, 6: 350, 7: 400}
FOLGAS_MES = 4 / 30.4
COMPLIANCE = 0.97  # fração dos treinos programados que ele cumpre

# nome: (treinos/sem, fração de dias com missão, atividades extras/sem)
PERFIS = {
    'Hardcore (6/sem, missão 100%)': (6, 1.00, 2.0),
    'Constante (4/sem, missão 90%)': (4, 0.90, 1.0),
    'Casual (3/sem), missão 80%': (3, 0.80, 0.5),
    'Casual (3/sem), missão 70%': (3, 0.70, 0.5),
}


def xp_para_nivel(n):
    return 480 + 10 * n


def nivel_de(xp):
    n = 1
    while xp >= xp_para_nivel(n):
        xp -= xp_para_nivel(n)
        n += 1
    return n


def simular(treinos, missao, extras, antigo=False, exp_min=EXP_MIN, anos_max=12):
    taxa_missao = min(1.0, missao / (1 - FOLGAS_MES))  # folgas cobrem as falhas
    c_semana = COMPLIANCE ** treinos
    falhas_sem = max(0.0, 7 * (1 - missao) - 7 * FOLGAS_MES)
    penal_sem = min(300, 100 * falhas_sem)
    xp = 0.0
    rank, entrou, exp = 'F', 0, 0.0
    exame_ini = None
    marcos = {}
    for dia in range(anos_max * 365):
        meses = dia / 30.4
        pr_por_treino = max(0.25, 0.5 ** (meses / 12))
        t_dia = treinos * COMPLIANCE / 7
        xp += t_dia * (100 + 50 * pr_por_treino)
        xp += missao * 50 / 1 - penal_sem / 7
        xp += XP_SEMANAL[treinos] * c_semana / 7
        xp += 30 * min(3, extras) / 7
        exp += t_dia + 0.5 * min(4, extras) / 7
        alvo = RANKS[RANKS.index(rank) + 1] if rank != 'S' else None
        if alvo is None:
            break
        nivel_ok = nivel_de(xp) >= NIVEL_MIN[alvo]
        if antigo:
            lib = nivel_ok and (dia - entrou) >= MESES_ANTIGOS[rank] * 30.4
        else:
            lib = nivel_ok and exp >= exp_min[rank]
        if exame_ini is None and lib:
            exame_ini = dia
        if exame_ini is not None:
            prazo, f_t, f_m = EXAME[alvo]
            if dia - exame_ini + 1 >= prazo:
                if COMPLIANCE >= f_t and taxa_missao >= f_m:
                    rank, entrou, exp, exame_ini = alvo, dia + 1, 0.0, None
                    marcos[alvo] = dia + 1
                else:
                    exame_ini = None  # reinicia (nova janela)
    return marcos, (marcos.get('S') or None)


if __name__ == '__main__':
    antigo = '--meses' in sys.argv
    for nome, (t, m, e) in PERFIS.items():
        marcos, s = simular(t, m, e, antigo=antigo)
        ult = max(marcos, key=lambda r: RANKS.index(r)) if marcos else 'F'
        res = f'{s / 365:.2f} anos' if s else f'não passa do {ult}'
        print(f'{nome:34s} {res:>18s}  ' +
              ' '.join(f'{r}:{d/365:.2f}' for r, d in marcos.items()))
