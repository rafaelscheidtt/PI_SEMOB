import 'package:flutter/material.dart';

import '../../data/models.dart';

/// Telas do menu lateral. As de gestão entram na Sprint 2 e aparecem desativadas.
enum Tela {
  visaoGeral('Visão Geral', Icons.dashboard_outlined),
  monitoramento('Monitoramento', Icons.tv_outlined),
  linhas('Linhas', Icons.route_outlined),
  cumprimento('Cumprimento de viagens', Icons.task_alt_outlined),
  passageiros('Passageiros', Icons.groups_outlined),
  importacao('Importação de relatórios', Icons.upload_file_outlined),
  financeiro('Financeiro', Icons.payments_outlined, gestao: true),
  alertas('Alertas', Icons.notifications_outlined, gestao: true, emConstrucao: true),
  relatorios('Relatórios', Icons.picture_as_pdf_outlined, gestao: true, emConstrucao: true),
  usuarios('Usuários', Icons.manage_accounts_outlined, administracao: true);

  const Tela(this.rotulo, this.icone, {this.gestao = false, this.administracao = false, this.emConstrucao = false});

  final String rotulo;
  final IconData icone;

  /// Grupo "Gestão" do menu (Sprint 2).
  final bool gestao;

  /// Ainda não implementada: aparece apagada no menu com a etiqueta "Sprint 2".
  final bool emConstrucao;

  /// Grupo "Administração" do menu, só para o administrador (US13).
  final bool administracao;

  bool get disponivel => !emConstrucao;

  /// O que cada papel enxerga no menu (US11). O executivo vê só a visão resumida.
  bool permitidaPara(Papel papel) {
    switch (papel) {
      case Papel.administrador:
        return true;
      case Papel.gestor:
        return !administracao;
      case Papel.executivo:
        return this == visaoGeral || this == monitoramento || this == cumprimento || this == passageiros;
    }
  }

  static List<Tela> permitidas(Papel papel) => values.where((t) => t.permitidaPara(papel)).toList();
}
