import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/filtros.dart';
import '../../../core/formatos.dart';
import '../../../core/layout.dart';
import '../../../core/periodo.dart';
import '../../../core/tema.dart';
import '../../../data/indicadores_repository.dart';
import '../../../data/models.dart';
import '../widgets/cartao.dart';
import '../widgets/estados.dart';
import '../widgets/grafico_colunas.dart';
import '../widgets/kpi_card.dart';
import '../widgets/tabela_linhas.dart';

/// Linhas: tabela de monitoramento de todas as linhas e o detalhamento de uma linha (US05).
class LinhasPage extends StatefulWidget {
  const LinhasPage({
    super.key,
    required this.filtros,
    required this.repository,
    this.linhaAberta,
    this.onAbrirLinha,
    this.onVoltar,
  });

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  /// Código da linha em detalhe; `null` mostra a lista.
  final String? linhaAberta;
  final ValueChanged<String>? onAbrirLinha;
  final VoidCallback? onVoltar;

  @override
  State<LinhasPage> createState() => _LinhasPageState();
}

class _LinhasPageState extends State<LinhasPage> {
  List<ResumoLinha> _linhas = const [];
  String? _erro;
  bool _carregando = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(LinhasPage anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.filtros != widget.filtros) _consultar();
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
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final l = await widget.repository.resumoPorLinha(inicio: f.inicio, fim: f.fim);
      if (!mounted || f != widget.filtros) return;
      setState(() => _linhas = l);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted && f == widget.filtros) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codigo = widget.linhaAberta ?? widget.filtros.linha;
    if (codigo != null) {
      return LinhaDetalhe(
        key: ValueKey('detalhe-$codigo'),
        codigo: codigo,
        filtros: widget.filtros,
        repository: widget.repository,
        resumoSistema: _linhas,
        onVoltar: widget.onVoltar,
      );
    }
    final f = widget.filtros;
    final filtradas = _busca.isEmpty
        ? _linhas
        : _linhas.where((l) => '${l.codigo} ${l.nome}'.toLowerCase().contains(_busca.toLowerCase())).toList();
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      return SingleChildScrollView(
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 14 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CabecalhoTela(
            titulo: 'Linhas',
            subtitulo: '${f.descricaoPeriodo}${_linhas.isEmpty ? '' : ' · ${_linhas.length} linhas'} · clique na linha para ver o detalhamento',
          ),
          const SizedBox(height: 18),
          if (_erro != null) MensagemErro(_erro!),
          if (_carregando) const Carregando(),
          if (!_carregando && _erro == null)
            Cartao(
              titulo: 'Monitoramento por linha',
              subtitulo: 'Km, viagens, participação na oferta e ocorrências de cada linha',
              acao: SizedBox(
                width: 200,
                child: TextField(
                  key: const Key('busca-linha'),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Buscar linha',
                    border: OutlineInputBorder(borderSide: BorderSide(color: Cores.linha)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _busca = v),
                ),
              ),
              child: _linhas.isEmpty
                  ? const AvisoSemDados(texto: 'Sem o resumo por linha no período')
                  : TabelaLinhas(linhas: filtradas, onSelecionar: widget.onAbrirLinha == null ? null : (l) => widget.onAbrirLinha!(l.codigo)),
            ),
        ]),
      );
    });
  }
}

/// Detalhamento de uma linha: indicadores, viagens por faixa horária e ocorrências de viagem.
class LinhaDetalhe extends StatefulWidget {
  const LinhaDetalhe({
    super.key,
    required this.codigo,
    required this.filtros,
    required this.repository,
    this.resumoSistema = const [],
    this.onVoltar,
  });

  final String codigo;
  final FiltrosPainel filtros;
  final IndicadoresRepository repository;

  /// Resumo de todas as linhas, para calcular a participação na oferta.
  final List<ResumoLinha> resumoSistema;
  final VoidCallback? onVoltar;

  @override
  State<LinhaDetalhe> createState() => _LinhaDetalheState();
}

class _LinhaDetalheState extends State<LinhaDetalhe> {
  Indicadores? _dados;
  DetalhesOperacao _detalhes = DetalhesOperacao.vazio;
  List<Ocorrencia> _ocorrencias = const [];
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void didUpdateWidget(LinhaDetalhe anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.filtros != widget.filtros || anterior.codigo != widget.codigo) _consultar();
  }

  Future<void> _consultar() async {
    final f = widget.filtros;
    final codigo = widget.codigo;
    final erroIntervalo = validarIntervalo(f.inicio, f.fim); // RN07
    if (erroIntervalo != null) {
      setState(() {
        _erro = erroIntervalo;
        _carregando = false;
      });
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait<Object>([
        widget.repository.obter(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, linha: codigo, comparar: true),
        widget.repository.detalhes(inicio: f.inicio, fim: f.fim, linha: codigo),
        widget.repository.ocorrencias(inicio: f.inicio, fim: f.fim, linha: codigo),
      ]);
      if (!mounted || f != widget.filtros || codigo != widget.codigo) return;
      setState(() {
        _dados = resultados[0] as Indicadores;
        _detalhes = resultados[1] as DetalhesOperacao;
        _ocorrencias = resultados[2] as List<Ocorrencia>;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted && f == widget.filtros && codigo == widget.codigo) setState(() => _carregando = false);
    }
  }

  ResumoLinha? get _resumo {
    for (final l in widget.resumoSistema) {
      if (l.codigo == widget.codigo) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filtros;
    final resumo = _resumo;
    final nome = resumo == null ? 'Linha ${widget.codigo}' : 'Linha ${widget.codigo} — ${resumo.nome}';
    final d = _dados;
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      return SingleChildScrollView(
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 14 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CodigoLinha(widget.codigo),
            const SizedBox(width: 10),
            Expanded(
              child: CabecalhoTela(
                titulo: nome,
                subtitulo: '${f.descricaoPeriodo}${d?.totais == null ? '' : ' · ${d!.totais!.diasComDados} dias com dados'}',
                acoes: [
                  if (d != null && !d.semDados) const Etiqueta('Em operação', tom: TomEtiqueta.ok),
                  if (widget.onVoltar != null)
                    OutlinedButton.icon(
                      key: const Key('botao-voltar-linhas'),
                      onPressed: widget.onVoltar,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Voltar às linhas'),
                      style: OutlinedButton.styleFrom(foregroundColor: Cores.tinta, side: BorderSide(color: Cores.linha), visualDensity: VisualDensity.compact),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          if (_erro != null) MensagemErro(_erro!),
          if (_carregando) const Carregando(),
          if (!_carregando && _erro == null && d != null) ..._corpo(faixa, d, resumo),
        ]),
      );
    });
  }

  List<Widget> _corpo(FaixaLargura faixa, Indicadores d, ResumoLinha? resumo) {
    if (d.semDados) return const [AvisoSemDados()];
    final t = d.totais!;
    final ant = d.anterior;
    final rotuloAnt = ant == null ? 'vs. anterior' : rotuloComparacao(ant.inicio, ant.fim);
    final viagensSistema = widget.resumoSistema.fold<int>(0, (a, l) => a + l.viagens);
    final kmSistema = widget.resumoSistema.fold<double>(0, (a, l) => a + l.kmTotal);
    final dias = t.diasComDados == 0 ? 1 : t.diasComDados;
    final ocorrencias = _ocorrencias.length;

    final cartoes = [
      KpiCard(
        titulo: 'Viagens realizadas',
        valor: fmtInteiro(t.viagens),
        detalhe: 'Média diária: ${fmtDecimal(t.viagens / dias)}',
        variacao: variacaoPercentual(t.viagens, ant?.totais.viagens),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.viagens.toDouble()],
      ),
      KpiCard(
        titulo: 'Quilometragem',
        valor: fmtInteiro(t.kmTotal.round()),
        unidade: 'km',
        detalhe: '${t.viagens == 0 ? '—' : fmtDecimal(t.kmTotal / t.viagens)} km por viagem',
        variacao: variacaoPercentual(t.kmTotal, ant?.totais.kmTotal),
        rotuloVariacao: rotuloAnt,
        serie: [for (final p in d.serie) p.kmTotal],
      ),
      KpiCard(
        titulo: 'Participação na oferta',
        valor: viagensSistema == 0 ? null : '${fmtDecimal(t.viagens / viagensSistema * 100)}%',
        detalhe: kmSistema == 0 ? null : '${fmtDecimal(t.kmTotal / kmSistema * 100)}% da quilometragem',
        etiqueta: viagensSistema == 0 ? null : const Etiqueta('das viagens do sistema', tom: TomEtiqueta.info),
        serie: const [],
        cor: Cores.verde,
      ),
      KpiCard(
        titulo: 'Ocorrências',
        valor: fmtInteiro(ocorrencias),
        detalhe: resumo == null
            ? 'viagens não realizadas, não iniciadas ou não terminadas'
            : '${fmtInteiro(resumo.naoRealizadas)} não realizadas · ${fmtInteiro(resumo.naoIniciadas)} não iniciadas · ${fmtInteiro(resumo.naoTerminadas)} não terminadas',
        etiqueta: ocorrencias == 0 ? const Etiqueta('nenhuma no período', tom: TomEtiqueta.ok) : null,
        serie: const [],
        cor: Cores.vermelho,
      ),
    ];

    final faixas = _detalhes.faixasHorarias;
    final pico = _detalhes.pico;

    return [
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunasDeCartoes(faixa),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 158,
        ),
        children: cartoes,
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Viagens por faixa horária — Linha ${widget.codigo}',
        subtitulo: '${widget.filtros.descricaoPeriodo} · soma das viagens do período por hora de início',
        acao: pico == null ? null : Etiqueta('Pico ${pico.faixa.toString().padLeft(2, '0')}h · ${fmtInteiro(pico.viagens)} viagens', tom: TomEtiqueta.info),
        child: faixas.isEmpty
            ? const AvisoSemDados(texto: 'Sem o relatório de partidas por faixa horária no período')
            : GraficoColunas(
                rotulos: [for (final x in faixas) '${x.faixa.toString().padLeft(2, '0')}h'],
                series: [SerieColunas(nome: 'Viagens', valores: [for (final x in faixas) x.viagens.toDouble()], cor: Cores.destaque)],
                altura: 200,
              ),
      ),
      const SizedBox(height: 18),
      Cartao(
        titulo: 'Ocorrências de viagem',
        subtitulo: '${widget.filtros.descricaoPeriodo} · ${fmtInteiro(ocorrencias)} registros · viagens programadas não realizadas, não iniciadas ou não terminadas',
        child: _ocorrencias.isEmpty
            ? const AvisoSemDados(texto: 'Nenhuma ocorrência no período')
            : TabelaOcorrencias(ocorrencias: _ocorrencias),
      ),
    ];
  }
}

/// Tabela das ocorrências de viagem de uma linha.
class TabelaOcorrencias extends StatelessWidget {
  const TabelaOcorrencias({super.key, required this.ocorrencias});

  final List<Ocorrencia> ocorrencias;

  static TextStyle get _cabecalho => TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Cores.texto2);
  static TextStyle get _celula => TextStyle(fontSize: 13, color: Cores.tinta);

  static String _hora(DateTime? d) => d == null ? '—' : DateFormat('HH:mm').format(d);

  static String _intervalo(DateTime? inicio, DateTime? fim) => inicio == null && fim == null ? '—' : '${_hora(inicio)} – ${_hora(fim)}';

  @override
  Widget build(BuildContext context) {
    final dia = DateFormat('dd/MM · EEE', 'pt_BR');
    DataColumn coluna(String t) => DataColumn(label: Text(t.toUpperCase(), style: _cabecalho));
    DataCell texto(String t) => DataCell(Text(t, style: _celula));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('tabela-ocorrencias'),
        columnSpacing: 20,
        horizontalMargin: 10,
        headingRowHeight: 36,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 46,
        dividerThickness: 0.6,
        columns: [
          coluna('Dia'),
          coluna('Tipo'),
          coluna('Atendimento'),
          coluna('Sentido'),
          coluna('Tabela'),
          coluna('Programado'),
          coluna('Realizado'),
        ],
        rows: [
          for (final o in ocorrencias)
            DataRow(cells: [
              texto(dia.format(o.data)),
              DataCell(Etiqueta(
                o.tipo.rotulo,
                tom: switch (o.tipo) {
                  TipoOcorrencia.naoRealizada => TomEtiqueta.negativo,
                  TipoOcorrencia.naoIniciada => TomEtiqueta.aviso,
                  TipoOcorrencia.naoTerminada => TomEtiqueta.aviso,
                },
              )),
              texto(o.atendimento ?? '—'),
              texto(o.sentido ?? '—'),
              texto(o.tabela ?? '—'),
              texto(_intervalo(o.inicioProgramado, o.fimProgramado)),
              texto(_intervalo(o.inicioRealizado, o.fimRealizado)),
            ]),
        ],
      ),
    );
  }
}
