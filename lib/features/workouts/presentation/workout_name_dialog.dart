import 'package:flutter/material.dart';

Future<String?> showWorkoutNameDialog(
  BuildContext context, {
  String title = 'Novo treino',
  String? nomeInicial,
}) {
  final controller = TextEditingController(text: nomeInicial);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do treino'),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Informe um nome'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}
