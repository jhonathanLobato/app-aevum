import 'package:flutter/material.dart';

import 'system_clippers.dart';
import 'system_colors.dart';
import 'system_effects.dart';
import 'system_text_styles.dart';

/// Cor associada a cada rank, centralizada neste único local — nenhuma tela
/// deve decidir a cor de um rank com condicionais próprias (ex.:
/// `if (rank == 'S')`); qualquer mudança de paleta por rank se faz só aqui.
///
/// O `RankBadge.tsx` original sempre usa violeta, independente do rank
/// recebido (o mock do protótipo só exercita o rank "E"). Os 7 ranks do
/// CLAUDE.md (F–S) foram mapeados 1:1 para violeta para preservar fidelidade
/// total ao componente visto no ZIP. Se o sistema deve diferenciar ranks
/// mais altos visualmente (ex.: S em dourado), é uma decisão de design que
/// ainda não foi tomada — meramente ajustar esta tabela resolve, sem tocar
/// em nenhuma tela.
const Map<String, Color> _rankColors = {
  'F': SystemPalette.violet,
  'E': SystemPalette.violet,
  'D': SystemPalette.violet,
  'C': SystemPalette.violet,
  'B': SystemPalette.violet,
  'A': SystemPalette.violet,
  'S': SystemPalette.violet,
};

/// Cor do badge para um rank. Ranks desconhecidos caem no violeta padrão em
/// vez de lançar erro, já que o rank vem como `String` livre do banco
/// (coluna `rank` de `UserProfile`).
Color colorForRank(String rank) =>
    _rankColors[rank.toUpperCase()] ?? SystemPalette.violet;

/// Badge hexagonal de rank, direto de `RankBadge.tsx`. Reutilizável em
/// Sistema, Status, Perfil e, futuramente, em missões/conquistas
/// condicionadas a rank.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 56});

  /// Letra do rank (F, E, D, C, B, A, S) — mesmo formato `String` já usado
  /// em `UserProfile.rank`.
  final String rank;

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = colorForRank(rank);
    return SizedBox(
      width: size,
      height: size,
      child: ClipPath(
        clipper: const HexagonClipper(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: SystemShadows.coloredGlow(color),
          ),
          // O hexágono tem tamanho fixo (ao contrário da maioria dos
          // componentes do sistema, que crescem com o conteúdo); sem
          // limitar a escala de texto aqui, um text scaling grande do
          // sistema operacional estoura as duas linhas de texto pra fora
          // da caixa de 56px. `withClampedTextScaling` é o jeito
          // recomendado do próprio Flutter pra isso — continua escalando
          // um pouco (acessibilidade), só não deixa crescer sem limite.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Abaixo de ~40px o rótulo "RANK" não cabe junto da letra
                  // sem estourar o hexágono — nesse tamanho só a letra já
                  // comunica o rank.
                  if (size >= 40)
                    Text(
                      'RANK',
                      style: SystemTextStyles.label.copyWith(
                        fontSize: 7.2,
                        letterSpacing: 1.58, // tracking-[0.22em] de 7.2px
                        color: color,
                      ),
                    ),
                  Text(
                    rank,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: SystemFonts.display,
                      fontSize: size * 20 / 56,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: SystemPalette.foreground,
                      shadows: SystemTextStyles.glowViolet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
