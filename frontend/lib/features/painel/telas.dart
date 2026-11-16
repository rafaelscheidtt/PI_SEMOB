import 'package:flutter/material.dart';

import '../../data/models.dart';

/// Telas do menu lateral, nos grupos Operação, Gestão e Administração.
enum Tela {
  visaoGeral('Visão Geral', Icons.dashboard_outlined),
  monitoramento('Monitoramento', Icons.tv_outlined),
  linhas('Linhas', Icons.route_outlined),
  cumprimento('Cumprimento de viagens', Icons.task_alt_outlined),
  passageiros('Passageiros', Icons.groups_outlined),
  importacao('Importação de relatórios', Icons.upload_file_outlined),
  executiva('Visão executiva', Icons.insights_outlined, gestao: true),
  financeiro('Financeiro', Icons.payments_outlined, gestao: true),
  alertas('Alertas', Icons.notifications_outlined, gestao: true),
  relatorios('Relatórios', Icons.picture_as_pdf_outlined, gestao: true),
  usuarios('Usuários', Icons.manage_accounts_outlined, administracao: true),
  sobre('Sobre o DashMOB', Icons.info_outline, sistema: true);

  const Tela(this.rotulo, this.icone, {this.gestao = false, this.administracao = false, this.sistema = false});

  final String rotulo;
  final IconData icone;

  final bool gestao;

  final bool administracao;

  final bool sistema;

  bool permitidaPara(Papel papel) {
    if (sistema) return true;
    switch (papel) {
      case Papel.administrador:
        return true;
      case Papel.gestor:
        return !administracao;
      case Papel.executivo:
        return this != linhas && this != importacao && !administracao;
    }
  }

  String get grupo => sistema ? 'Sistema' : (administracao ? 'Administração' : (gestao ? 'Gestão' : 'Operação'));

  Color get cor => switch (this) {
        Tela.visaoGeral || Tela.executiva => _azul,
        Tela.monitoramento => _azulClaro,
        Tela.linhas => _amarelo,
        Tela.cumprimento || Tela.financeiro => _verde,
        Tela.passageiros => _ouro,
        Tela.alertas => _vermelho,
        Tela.importacao || Tela.relatorios || Tela.usuarios || Tela.sobre => _cinza,
      };

  static const _azul = Color(0xFF3F66C4); // azul do brasão, um tom mais claro para aparecer no menu
  static const _azulClaro = Color(0xFF4A86CF);
  static const _verde = Color(0xFF078944);
  static const _vermelho = Color(0xFFD42027);
  static const _amarelo = Color(0xFFF2C80F);
  static const _ouro = Color(0xFFA07C00);
  static const _cinza = Color(0xFF5F6673);

  static List<Tela> permitidas(Papel papel) => values.where((t) => !t.sistema && t.permitidaPara(papel)).toList();

  static Tela inicialPara(Papel papel) => papel == Papel.executivo ? executiva : visaoGeral;
}
