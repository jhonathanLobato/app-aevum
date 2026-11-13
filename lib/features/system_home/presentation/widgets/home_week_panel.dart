import 'package:flutter/material.dart';

import '../../../../design_system/system_panel.dart';
import '../../../daily/presentation/widgets/week_strip.dart';

class HomeWeekPanel extends StatelessWidget {
  const HomeWeekPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SystemPanel(title: 'SEMANA', child: WeekStrip());
  }
}
