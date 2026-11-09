import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/filtros.dart';
import '../../../core/formatos.dart';
import '../../../core/layout.dart';
import '../../../core/periodo.dart';
import '../../../core/tema.dart';
import '../../../data/indicadores_repository.dart';
import '../../../data/models.dart';
import '../widgets/estados.dart';

/// Cores da tela de monitoramento: seguem o modo claro/escuro do app, com os sinais
/// (verde, âmbar, vermelho) mais vivos no escuro para ler de longe.
class _Tons {
  _Tons._();

  static bool get escuro => Cores.paleta.escura;
  static Color get painel => Cores.superficie;
  static Color get borda => Cores.linha;
  static Color get rotulo => Cores.texto2;
  static Color get texto => Cores.tinta;
  static Color get verde => escuro ? const Color(0xFF3DDC97) : Cores.verde;
  static Color get vermelho => escuro ? const Color(0xFFFF7A7A) : Cores.vermelho;
  static Color get ambar => escuro ? const Color(0xFFFFC95C) : Cores.ambar;
}

/// Monitoramento (US14): uma tela só, pensada para ficar aberta numa TV na sala da SEMOB.
/// Números grandes, poucos elementos e contraste alto, para quem passa longe conseguir ler.
/// Atualiza sozinha de tempos em tempos. (Os alertas entram aqui quando a US08 chegar.)
class MonitoramentoPage extends StatefulWidget {
  const MonitoramentoPage({super.key, required this.filtros, required this.repository, this.intervaloAtualizacao = const Duration(minutes: 5)});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  /// De quanto em quanto tempo a tela consulta a API de novo; `null` desliga.
  final Duration? intervaloAtualizacao;

  @override
  State<MonitoramentoPage> createState() => _MonitoramentoPageState();
}

class _MonitoramentoPageState extends State<MonitoramentoPage> {
  Indicadores? _dados;
  DetalhesOperacao _detalhes = DetalhesOperacao.vazio;
  DateTime? _atualizadoEm;
  String? _erro;
  bool _carregando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _consultar();
    final intervalo = widget.intervaloAtualizacao;
    if (intervalo != null) _timer = Timer.periodic(intervalo, (_) => _consultar());
  }

  @override
  void didUpdateWidget(MonitoramentoPage anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.filtros != widget.filtros) _consultar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _consultar() async {
    final f = widget.filtros;
    final erroIntervalo = validarIntervalo(f.inicio, f.fim); // RN07
    if (erroIntervalo != null) {
      setState(() {
        _erro = erroIntervalo;
        _carregando = false;
      });
      return;
    }
    if (_dados == null) setState(() => _carregando = true);
    try {
      final resultados = await Future.wait<Object>([
        widget.repository.obter(inicio: f.inicio, fim: f.fim, granularidade: Granularidade.dia, linha: f.linha, comparar: true),
        widget.repository.detalhes(inicio: f.inicio, fim: f.fim, linha: f.linha),
      ]);
      if (!mounted || f != widget.filtros) return;
      setState(() {
        _dados = resultados[0] as Indicadores;
        _detalhes = resultados[1] as DetalhesOperacao;
        _atualizadoEm = DateTime.now();
        _erro = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted && f == widget.filtros) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      final d = _dados;
      final cabecalho = _Cabecalho(filtros: widget.filtros, atualizadoEm: _atualizadoEm, compacto: faixa == FaixaLargura.compacto);
      Widget corpo;
      if (_erro != null && d == null) {
        corpo = MensagemErro(_erro!);
      } else if (_carregando || d == null) {
        corpo = const Center(child: CircularProgressIndicator());
      } else if (d.semDados) {
        corpo = const Center(child: _SemDados());
      } else {
        corpo = _Paineis(dados: d, detalhes: _detalhes, faixa: faixa);
      }
      return Container(
        color: Cores.fundo,
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 16 : 28),
        child: faixa == FaixaLargura.expandido && d != null && !d.semDados
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cabecalho, const SizedBox(height: 18), Expanded(child: corpo)])
            : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cabecalho, const SizedBox(height: 18), corpo])),
      );
    });
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.filtros, required this.atualizadoEm, required this.compacto});

  final FiltrosPainel filtros;
  final DateTime? atualizadoEm;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final titulo = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MONITORAMENTO · SEMOB SÃO CAETANO DO SUL', style: TextStyle(color: _Tons.rotulo, fontSize: compacto ? 12 : 14, letterSpacing: 2, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(
        filtros.linha == null ? 'Operação do transporte coletivo' : 'Linha ${filtros.linha}',
        style: TextStyle(color: _Tons.texto, fontSize: compacto ? 22 : 32, fontWeight: FontWeight.w700),
      ),
    ]);
    final periodo = Column(crossAxisAlignment: compacto ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
      Text(filtros.descricaoPeriodo, style: TextStyle(color: _Tons.texto, fontSize: compacto ? 16 : 22, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(
        atualizadoEm == null ? 'carregando...' : 'atualizado às ${atualizadoEm!.hour.toString().padLeft(2, '0')}:${atualizadoEm!.minute.toString().padLeft(2, '0')}',
        key: const Key('monitor-atualizado'),
        style: TextStyle(color: _Tons.rotulo, fontSize: compacto ? 13 : 15),
      ),
    ]);
    if (compacto) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titulo, const SizedBox(height: 10), periodo]);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: titulo), periodo]);
  }
}

class _SemDados extends StatelessWidget {
  const _SemDados();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 56, color: _Tons.rotulo),
        const SizedBox(height: 14),
        Text('Sem dados para o período', key: const Key('aviso-sem-dados'), style: TextStyle(color: _Tons.texto, fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Escolha outro intervalo na barra de filtros.', style: TextStyle(color: _Tons.rotulo, fontSize: 16)),
      ]),
    );
  }
}

/// Os seis painéis grandes mais a faixa de rodapé. No desktop ocupam a altura toda; no celular rolam.
class _Paineis extends StatelessWidget {
  const _Paineis({required this.dados, required this.detalhes, required this.faixa});

  final Indicadores dados;
  final DetalhesOperacao detalhes;
  final FaixaLargura faixa;

  @override
  Widget build(BuildContext context) {
    final t = dados.totais!;
    final ant = dados.anterior?.totais;
    final gratuidades = t.total == null || t.naoPagantes == null || t.total == 0 ? null : t.naoPagantes! / t.total! * 100;
    final gratuidadesAnt = ant == null || ant.total == null || ant.naoPagantes == null || ant.total == 0 ? null : ant.naoPagantes! / ant.total! * 100;
    final fcvOk = t.fcv == null || t.fcv! >= 95;
    final naoRealizadas = t.viagensNaoRealizadas;

    final paineis = <_Painel>[
      _Painel(titulo: 'Quilometragem', valor: fmtInteiro(t.kmTotal.round()), unidade: 'km', variacao: variacaoPercentual(t.kmTotal, ant?.kmTotal)),
      _Painel(titulo: 'Viagens realizadas', valor: fmtInteiro(t.viagens), detalhe: t.viagensProgramadas == null ? null : 'de ${fmtInteiro(t.viagensProgramadas!)} programadas', variacao: variacaoPercentual(t.viagens, ant?.viagens)),
      _Painel(titulo: 'Cumprimento de viagens', valor: t.fcv == null ? null : fmtDecimal(t.fcv!), unidade: t.fcv == null ? null : '%', detalhe: t.fcv == null ? null : (fcvOk ? 'dentro da meta de 95%' : 'abaixo da meta de 95%'), cor: fcvOk ? _Tons.verde : _Tons.vermelho, variacao: variacaoPercentual(t.fcv, ant?.fcv)),
      _Painel(titulo: 'Passageiros', valor: t.total == null ? null : fmtInteiro(t.total!), detalhe: t.total == null ? 'sem bilhetagem no período' : null, variacao: variacaoPercentual(t.total, ant?.total)),
      _Painel(titulo: 'Gratuidades', valor: gratuidades == null ? null : fmtDecimal(gratuidades), unidade: gratuidades == null ? null : '%', detalhe: t.naoPagantes == null ? null : '${fmtInteiro(t.naoPagantes!)} passageiros', variacao: variacaoPercentual(gratuidades, gratuidadesAnt), cor: _Tons.ambar),
      _Painel(
        titulo: 'Viagens não realizadas',
        valor: naoRealizadas == null ? null : fmtInteiro(naoRealizadas),
        detalhe: naoRealizadas == null ? 'sem o relatório de FCV' : (naoRealizadas == 0 ? 'todas as viagens programadas saíram' : 'programadas que não saíram'),
        variacao: variacaoPercentual(naoRealizadas, ant?.viagensNaoRealizadas),
        quedaEBoa: true,
        cor: naoRealizadas == null || naoRealizadas == 0 ? _Tons.verde : _Tons.vermelho,
      ),
    ];

    final piores = [...dados.serie.where((p) => p.fcv != null)]..sort((a, b) => a.fcv!.compareTo(b.fcv!));
    final rodape = _Rodape(turnos: detalhes.turnos, piores: piores.take(3).toList(), fcvOk: fcvOk, compacto: faixa == FaixaLargura.compacto);

    if (faixa == FaixaLargura.expandido) {
      // três colunas por duas linhas, preenchendo a altura disponível
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: _linha(paineis.sublist(0, 3))),
        const SizedBox(height: 16),
        Expanded(child: _linha(paineis.sublist(3, 6))),
        const SizedBox(height: 16),
        rodape,
      ]);
    }
    final colunas = faixa == FaixaLargura.medio ? 2 : 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: colunas, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 170),
        children: paineis,
      ),
      const SizedBox(height: 16),
      rodape,
    ]);
  }

  Widget _linha(List<Widget> itens) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < itens.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: itens[i]),
        ],
      ]);
}

/// Um painel grande: rótulo, número enorme (que encolhe para caber) e uma linha de apoio.
class _Painel extends StatelessWidget {
  const _Painel({required this.titulo, required this.valor, this.unidade, this.detalhe, this.variacao, this.cor, this.quedaEBoa = false});

  final String titulo;
  final String? valor;
  final String? unidade;
  final String? detalhe;
  final double? variacao;

  /// Cor do número; sem ela, a cor de texto do tema.
  final Color? cor;

  /// Para indicadores em que cair é bom (viagens não realizadas), inverte as cores da variação.
  final bool quedaEBoa;

  @override
  Widget build(BuildContext context) {
    final v = variacao;
    final subiu = v != null && v > 0;
    final bom = quedaEBoa ? !subiu : subiu;
    final corValor = cor ?? _Tons.texto;
    final textoVariacao = v == null ? null : '${subiu ? '▲' : (v < 0 ? '▼' : '●')} ${fmtDecimal(v.abs())}% vs. período anterior';
    final corVariacao = v == null || v.abs() < 0.05 ? _Tons.rotulo : (bom ? _Tons.verde : _Tons.vermelho);
    return LayoutBuilder(builder: (context, c) {
      // tipografia cresce com o painel: numa TV os rótulos também precisam ser lidos de longe
      final rotulo = (c.maxWidth / 24).clamp(13.0, 22.0);
      final apoio = (c.maxWidth / 22).clamp(14.0, 24.0);
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(color: _Tons.painel, border: Border.all(color: _Tons.borda), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo.toUpperCase(), style: TextStyle(color: _Tons.rotulo, fontSize: rotulo, letterSpacing: 1.6, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: valor == null
                    ? Text('Sem dados', key: Key('monitor-$titulo'), style: TextStyle(color: _Tons.rotulo, fontSize: 44, fontWeight: FontWeight.w600))
                    : Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text(valor!, key: Key('monitor-$titulo'), style: TextStyle(color: corValor, fontSize: 96, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1)),
                        if (unidade != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(unidade!, style: TextStyle(color: corValor.withValues(alpha: 0.8), fontSize: 34, fontWeight: FontWeight.w600))),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(textoVariacao ?? detalhe ?? '', style: TextStyle(color: corVariacao, fontSize: apoio, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (textoVariacao != null && detalhe != null)
            Text(detalhe!, style: TextStyle(color: _Tons.rotulo, fontSize: apoio - 2), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
    });
  }
}

/// Rodapé: cumprimento por turno e os períodos com menor cumprimento.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.turnos, required this.piores, required this.fcvOk, required this.compacto});

  final List<Turno> turnos;
  final List<PontoIndicador> piores;
  final bool fcvOk;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final resumo = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(fcvOk ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: fcvOk ? _Tons.verde : _Tons.vermelho, size: 32),
      const SizedBox(width: 14),
      Expanded(
        child: piores.isEmpty
            ? Text('Sem o relatório de cumprimento no período', key: const Key('monitor-ok'), style: TextStyle(color: _Tons.texto, fontSize: 22, fontWeight: FontWeight.w600))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fcvOk ? 'Cumprimento dentro da meta de 95% no período' : 'Cumprimento abaixo da meta de 95% no período',
                    key: const Key('monitor-ok'), style: TextStyle(color: _Tons.texto, fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Menor cumprimento: ${piores.map((p) => '${rotuloPeriodo(p.periodo)} (${fmtPercentual(p.fcv!)})').join(' · ')}',
                  key: const Key('monitor-piores'),
                  style: TextStyle(color: _Tons.rotulo, fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
      ),
    ]);
    final porTurno = turnos.isEmpty
        ? null
        : Wrap(spacing: 18, runSpacing: 6, children: [
            for (final tr in turnos)
              Text('${tr.rotulo} ${tr.fcv == null ? '—' : fmtPercentual(tr.fcv!)}', style: TextStyle(color: _Tons.texto, fontSize: 18, fontWeight: FontWeight.w600)),
          ]);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      decoration: BoxDecoration(color: _Tons.painel, border: Border.all(color: _Tons.borda), borderRadius: BorderRadius.circular(16)),
      child: compacto || porTurno == null
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [resumo, if (porTurno != null) ...[const SizedBox(height: 12), porTurno]])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: resumo), const SizedBox(width: 24), porTurno]),
    );
  }
}
