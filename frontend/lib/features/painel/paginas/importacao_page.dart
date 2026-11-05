import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatos.dart';
import '../../../core/layout.dart';
import '../../../core/tema.dart';
import '../../../data/indicadores_repository.dart';
import '../../../data/models.dart';
import '../widgets/cartao.dart';
import '../widgets/estados.dart';

/// Função que deixa o gestor escolher os arquivos; nos testes é substituída por uma falsa.
typedef EscolherArquivos = Future<List<ArquivoEnvio>> Function();

/// Abre o seletor de arquivos do sistema (HTML do Smart Report ou o .zip do pacote).
Future<List<ArquivoEnvio>> escolherArquivosDoSistema() async {
  final r = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: FileType.custom,
    allowedExtensions: const ['html', 'htm', 'zip'],
  );
  if (r == null) return const [];
  return [
    for (final f in r.files)
      if (f.bytes != null) ArquivoEnvio(nome: f.name, bytes: f.bytes!),
  ];
}

/// Importação de relatórios: envio do pacote e histórico do que já entrou (US01).
class ImportacaoPage extends StatefulWidget {
  const ImportacaoPage({super.key, required this.repository, this.escolherArquivos = escolherArquivosDoSistema});

  final IndicadoresRepository repository;
  final EscolherArquivos escolherArquivos;

  @override
  State<ImportacaoPage> createState() => _ImportacaoPageState();
}

class _ImportacaoPageState extends State<ImportacaoPage> {
  List<Importacao> _historico = const [];
  ResultadoImportacao? _resultado;
  String? _erro;
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final h = await widget.repository.importacoes();
      if (mounted) setState(() => _historico = h);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _importar() async {
    final arquivos = await widget.escolherArquivos();
    if (arquivos.isEmpty || !mounted) return;
    setState(() {
      _enviando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final r = await widget.repository.importar(arquivos);
      if (!mounted) return;
      setState(() => _resultado = r);
      await _carregarHistorico();
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      final r = _resultado;
      return SingleChildScrollView(
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 14 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CabecalhoTela(
            titulo: 'Importação de relatórios',
            subtitulo: 'Pacote de relatórios do Smart Report (HTML) disponibilizado pela SEMOB — mensal ou quinzenal',
          ),
          const SizedBox(height: 18),
          Cartao(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7CBDA), width: 2),
              ),
              child: Column(children: [
                const Icon(Icons.upload_file_outlined, size: 32, color: Cores.texto2),
                const SizedBox(height: 10),
                Text('Escolha o .zip do pacote ou os arquivos HTML', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  'Cada arquivo é reconhecido pelo título do relatório: Resumo Geral, FCV, Linhas, Faixa Horária, Viagens, Passageiros e Saldos. '
                  'Reimportar o mesmo período atualiza os registros existentes sem duplicar.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('botao-escolher-arquivos'),
                  onPressed: _enviando ? null : _importar,
                  style: FilledButton.styleFrom(backgroundColor: Cores.navy),
                  icon: _enviando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.folder_open, size: 18),
                  label: Text(_enviando ? 'Importando...' : 'Escolher arquivos'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          if (_erro != null) ...[MensagemErro(_erro!), const SizedBox(height: 18)],
          if (r != null) ...[_ResultadoCartao(r), const SizedBox(height: 18)],
          Cartao(
            titulo: 'Histórico de importações',
            subtitulo: 'Relatórios já importados, do mais recente para o mais antigo',
            child: _carregando
                ? const Carregando()
                : _historico.isEmpty
                    ? const AvisoSemDados(texto: 'Nenhum relatório importado ainda')
                    : _TabelaHistorico(_historico),
          ),
        ]),
      );
    });
  }
}

Etiqueta etiquetaStatus(String status) => switch (status) {
      'concluida' => const Etiqueta('Concluída', tom: TomEtiqueta.ok),
      'parcial' => const Etiqueta('Parcial', tom: TomEtiqueta.aviso),
      'falha' => const Etiqueta('Falha', tom: TomEtiqueta.negativo),
      _ => Etiqueta(status),
    };

String _periodo(DateTime? inicio, DateTime? fim) => inicio == null || fim == null ? '—' : '${fmtData(inicio)} – ${fmtData(fim)}';

class _ResultadoCartao extends StatelessWidget {
  const _ResultadoCartao(this.r);

  final ResultadoImportacao r;

  @override
  Widget build(BuildContext context) {
    final resumo = [
      ('Arquivos', '${r.arquivos} arquivos importados'),
      ('Registros', '${fmtInteiro(r.importados)} importados, ${fmtInteiro(r.rejeitados)} rejeitados'),
      ('Período', _periodo(r.periodoInicio, r.periodoFim)),
      ('Reimportação', '${fmtInteiro(r.atualizados)} registros atualizados'),
    ];
    return Cartao(
      titulo: 'Última importação',
      subtitulo: r.status == 'parcial' ? 'Alguns registros ou arquivos foram rejeitados; os demais entraram' : null,
      acao: etiquetaStatus(r.status),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 24, runSpacing: 10, children: [
          for (final (rotulo, valor) in resumo)
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Rotulo(rotulo),
              const SizedBox(height: 2),
              Text(valor, key: Key('resultado-$rotulo'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
        ]),
        if (r.relatorios.isNotEmpty) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 10,
              headingRowHeight: 34,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 44,
              dividerThickness: 0.6,
              columns: const [
                DataColumn(label: Text('ARQUIVO', style: _TabelaHistorico.cabecalho)),
                DataColumn(label: Text('RELATÓRIO', style: _TabelaHistorico.cabecalho)),
                DataColumn(label: Text('REGISTROS', style: _TabelaHistorico.cabecalho), numeric: true),
                DataColumn(label: Text('STATUS', style: _TabelaHistorico.cabecalho)),
              ],
              rows: [
                for (final x in r.relatorios)
                  DataRow(cells: [
                    DataCell(Text(x.arquivo, style: _TabelaHistorico.celula)),
                    DataCell(Text(x.titulo ?? x.tipoRelatorio ?? 'não reconhecido', style: _TabelaHistorico.celula)),
                    DataCell(Text('${fmtInteiro(x.importados)} / ${fmtInteiro(x.totalRegistros)}', style: _TabelaHistorico.celula)),
                    DataCell(etiquetaStatus(x.status)),
                  ]),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

class _TabelaHistorico extends StatelessWidget {
  const _TabelaHistorico(this.historico);

  final List<Importacao> historico;

  static const cabecalho = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Cores.texto2);
  static const celula = TextStyle(fontSize: 13, color: Cores.tinta);

  @override
  Widget build(BuildContext context) {
    final dataHora = DateFormat('dd/MM/yyyy HH:mm');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('tabela-historico'),
        columnSpacing: 20,
        horizontalMargin: 10,
        headingRowHeight: 36,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 46,
        dividerThickness: 0.6,
        columns: const [
          DataColumn(label: Text('DATA', style: cabecalho)),
          DataColumn(label: Text('ARQUIVO', style: cabecalho)),
          DataColumn(label: Text('RELATÓRIO', style: cabecalho)),
          DataColumn(label: Text('PERÍODO', style: cabecalho)),
          DataColumn(label: Text('REGISTROS', style: cabecalho), numeric: true),
          DataColumn(label: Text('STATUS', style: cabecalho)),
        ],
        rows: [
          for (final i in historico)
            DataRow(cells: [
              DataCell(Text(i.importadoEm == null ? '—' : dataHora.format(i.importadoEm!), style: celula)),
              DataCell(Text(i.arquivo, style: celula)),
              DataCell(Text(i.titulo ?? i.tipoRelatorio ?? 'não reconhecido', style: celula)),
              DataCell(Text(_periodo(i.periodoInicio, i.periodoFim), style: celula)),
              DataCell(Text('${fmtInteiro(i.importados)} / ${fmtInteiro(i.totalRegistros)}', style: celula)),
              DataCell(etiquetaStatus(i.status)),
            ]),
        ],
      ),
    );
  }
}
