import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../painel/widgets/estados.dart';
import '../painel/widgets/marca.dart';
import 'termo_texto.dart';

/// O texto do termo, seção por seção. Usado na tela de aceite e no "Sobre".
class TextoDoTermo extends StatelessWidget {
  const TextoDoTermo({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Versão $versaoDoTermo · $dataDoTermo', style: tema.bodySmall),
      for (final s in secoesDoTermo) ...[
        const SizedBox(height: 16),
        Text(s.titulo, style: tema.labelLarge?.copyWith(fontSize: 14)),
        for (final p in s.paragrafos) Padding(padding: const EdgeInsets.only(top: 6), child: Text(p, style: tema.bodyMedium)),
      ],
    ]);
  }
}

/// Abre o termo para consulta (sem pedir aceite), a partir do "Sobre".
Future<void> mostrarTermo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Termo de uso e aviso de privacidade'),
      content: const SizedBox(width: 560, child: SingleChildScrollView(child: TextoDoTermo())),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar'))],
    ),
  );
}

/// Tela mostrada depois do login enquanto o usuário não aceita a versão atual do termo (LGPD).
/// Sem o aceite o painel não abre; a outra saída é sair da conta.
class TermoPage extends StatefulWidget {
  const TermoPage({super.key, required this.nome, required this.onAceitar, required this.onSair});

  final String nome;

  /// Registra o aceite; se lançar erro, a mensagem aparece na tela.
  final Future<void> Function() onAceitar;
  final VoidCallback onSair;

  @override
  State<TermoPage> createState() => _TermoPageState();
}

class _TermoPageState extends State<TermoPage> {
  bool _li = false;
  bool _enviando = false;
  String? _erro;

  Future<void> _aceitar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.onAceitar();
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final primeiroNome = widget.nome.trim().split(' ').first;
    return Scaffold(
      backgroundColor: Cores.navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                key: const Key('tela-termo'),
                decoration: BoxDecoration(color: Cores.superficie, borderRadius: BorderRadius.circular(14)),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      MarcaDashMob(tamanho: 20, cor: Cores.tinta, fio: Cores.paleta.escura ? const Color(0xFFFFEF0A) : const Color(0xFFF2C80F)),
                      const SizedBox(height: 16),
                      Text('Termo de uso e aviso de privacidade', style: tema.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        primeiroNome.isEmpty ? 'Antes de continuar, leia como o painel trata os seus dados.' : '$primeiroNome, antes de continuar, leia como o painel trata os seus dados.',
                        style: tema.bodySmall,
                      ),
                    ]),
                  ),
                  Divider(height: 1, color: Cores.linha),
                  const Flexible(
                    child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(28, 16, 28, 20), child: TextoDoTermo()),
                  ),
                  Divider(height: 1, color: Cores.linha),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (_erro != null) Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: MensagemErro(_erro!)),
                      // o Material próprio é o que deixa o efeito de toque aparecer em cima do cartão
                      Material(
                        type: MaterialType.transparency,
                        child: CheckboxListTile(
                          key: const Key('termo-li'),
                          value: _li,
                          onChanged: _enviando ? null : (v) => setState(() => _li = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('Li e estou de acordo com o termo de uso e o aviso de privacidade.', style: tema.bodyMedium),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 8, children: [
                        TextButton(key: const Key('termo-sair'), onPressed: _enviando ? null : widget.onSair, child: const Text('Sair')),
                        FilledButton(
                          key: const Key('termo-aceitar'),
                          onPressed: _li && !_enviando ? _aceitar : null,
                          child: Text(_enviando ? 'Registrando...' : 'Aceitar e continuar'),
                        ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
