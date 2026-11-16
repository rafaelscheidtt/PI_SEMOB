import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';

import '../../core/filtros.dart';
import '../../core/layout.dart';
import '../../core/tema.dart';
import '../../data/indicadores_repository.dart';
import '../../data/models.dart';
import '../painel/widgets/cartao.dart';
import '../painel/widgets/estados.dart';
import 'gerador_pdf.dart';

/// Entrega o PDF ao usuário: download no navegador, compartilhar no celular. Nos testes é substituída.
typedef SalvarPdf = Future<void> Function(Uint8List bytes, String nome);

Future<void> salvarPdfNoAparelho(Uint8List bytes, String nome) => Printing.sharePdf(bytes: bytes, filename: nome);

/// Lê o PNG do brasão dos assets para o cabeçalho do PDF; sem ele o relatório sai só com texto.
Future<Uint8List?> carregarBrasao() async {
  try {
    return (await rootBundle.load('assets/brasao.png')).buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Relatórios: exporta o painel do período em PDF, com as seções escolhidas.
class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key, required this.filtros, required this.repository, this.usuario, this.salvar = salvarPdfNoAparelho, this.brasao = carregarBrasao});

  final FiltrosPainel filtros;
  final IndicadoresRepository repository;
  final Usuario? usuario;
  final SalvarPdf salvar;
  final Future<Uint8List?> Function() brasao;

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

enum _Secao {
  indicadores('Indicadores do período', 'km, viagens, cumprimento e passageiros, com o comparativo do período anterior'),
  cumprimento('Cumprimento de viagens', 'viagens por turno e por faixa horária'),
  financeiro('Financeiro', 'vendas, utilização, crédito circulante e saldo de créditos'),
  alertas('Alertas', 'dias fora do padrão no período'),
  linhas('Monitoramento por linha', 'km, viagens e ocorrências de cada linha (só sem filtro de linha)');

  const _Secao(this.rotulo, this.descricao);
  final String rotulo;
  final String descricao;
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final _marcadas = {..._Secao.values};
  bool _gerando = false;
  String? _erro;
  String? _resultado;

  Future<void> _gerar() async {
    final f = widget.filtros;
    setState(() {
      _gerando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final conteudo = ConteudoRelatorio(
        filtros: f,
        geradoEm: DateTime.now(),
        geradoPor: widget.usuario?.nome,
        brasao: await widget.brasao(),
        indicadores: _marcadas.contains(_Secao.indicadores)
            ? await widget.repository.obter(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, linha: f.linha, comparar: true)
            : null,
        detalhes: _marcadas.contains(_Secao.cumprimento) ? await widget.repository.detalhes(inicio: f.inicio, fim: f.fim, linha: f.linha) : null,
        financeiro: _marcadas.contains(_Secao.financeiro) ? await widget.repository.financeiro(inicio: f.inicio, fim: f.fim, granularidade: f.granularidade, comparar: true) : null,
        alertas: _marcadas.contains(_Secao.alertas) ? await widget.repository.alertas(inicio: f.inicio, fim: f.fim, linha: f.linha) : null,
        linhas: _marcadas.contains(_Secao.linhas) && f.linha == null ? await widget.repository.resumoPorLinha(inicio: f.inicio, fim: f.fim) : null,
      );
      final bytes = await gerarRelatorioPdf(conteudo);
      final nome = nomeArquivoPdf(f);
      await widget.salvar(bytes, nome);
      if (mounted) setState(() => _resultado = '$nome · ${(bytes.length / 1024).toStringAsFixed(0)} KB');
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filtros;
    return LayoutBuilder(builder: (context, c) {
      final faixa = faixaDeLargura(c.maxWidth);
      return SingleChildScrollView(
        padding: EdgeInsets.all(faixa == FaixaLargura.compacto ? 14 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CabecalhoTela(
            titulo: 'Relatórios',
            subtitulo: '${f.descricaoPeriodo}${f.linha == null ? '' : ' · linha ${f.linha}'} · exporta o painel em PDF para compartilhar com outros gestores',
          ),
          const SizedBox(height: 18),
          Cartao(
            titulo: 'O que vai no PDF',
            subtitulo: 'O período e a linha são os da barra de filtros',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // o ListTile pinta no Material mais próximo; o cartão tem fundo próprio, então ganha o seu
              Material(
                color: Colors.transparent,
                child: Column(children: [
                  for (final s in _Secao.values)
                    CheckboxListTile(
                      key: Key('secao-${s.name}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(s.rotulo, style: Theme.of(context).textTheme.labelLarge),
                      subtitle: Text(s.descricao, style: Theme.of(context).textTheme.bodySmall),
                      value: _marcadas.contains(s),
                      onChanged: (v) => setState(() => v == true ? _marcadas.add(s) : _marcadas.remove(s)),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              if (_erro != null) ...[MensagemErro(_erro!), const SizedBox(height: 12)],
              if (_resultado != null) ...[
                Aviso('Relatório gerado: $_resultado. No navegador ele vai para a pasta de downloads; no celular abre a tela de compartilhar.', chave: const Key('pdf-resultado')),
                const SizedBox(height: 12),
              ],
              Row(children: [
                FilledButton.icon(
                  key: const Key('pdf-gerar'),
                  onPressed: _gerando || _marcadas.isEmpty ? null : _gerar,
                  icon: _gerando
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Cores.sobreDestaque))
                      : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(_gerando ? 'Gerando...' : 'Gerar PDF'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Arquivo: ${nomeArquivoPdf(f)}', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        ]),
      );
    });
  }
}
