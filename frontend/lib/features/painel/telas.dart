import 'package:flutter/material.dart';

/// Telas do menu lateral. As de gestão entram na Sprint 2 e aparecem desativadas.
enum Tela {
  visaoGeral('Visão Geral', Icons.dashboard_outlined),
  linhas('Linhas', Icons.route_outlined),
  cumprimento('Cumprimento de viagens', Icons.task_alt_outlined),
  passageiros('Passageiros', Icons.groups_outlined),
  importacao('Importação de relatórios', Icons.upload_file_outlined),
  financeiro('Financeiro', Icons.payments_outlined, gestao: true),
  alertas('Alertas', Icons.notifications_outlined, gestao: true),
  relatorios('Relatórios', Icons.picture_as_pdf_outlined, gestao: true);

  const Tela(this.rotulo, this.icone, {this.gestao = false});

  final String rotulo;
  final IconData icone;

  /// Grupo "Gestão" do menu, previsto para a Sprint 2.
  final bool gestao;

  bool get disponivel => !gestao;
}
