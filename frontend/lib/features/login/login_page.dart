import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../core/tema_controle.dart';
import '../../data/auth_repository.dart';
import '../../data/models.dart';
import '../painel/widgets/estados.dart';

/// Tela de entrada do painel (US11): e-mail e senha, nada de cadastro por aqui —
/// quem cria usuário é o administrador, dentro do app.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.repository, required this.onEntrou, this.aviso, this.tema});

  final AuthRepository repository;
  final ValueChanged<Sessao> onEntrou;

  /// Mensagem mostrada ao abrir (por exemplo, "sessão expirada").
  final String? aviso;

  /// Modo claro/escuro; com ele aparece o botão de alternar no canto do cartão.
  final ControleTema? tema;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _entrando = false;
  bool _mostrarSenha = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      final sessao = await widget.repository.login(_email.text, _senha.text);
      if (mounted) widget.onEntrou(sessao);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Cores.navy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              decoration: BoxDecoration(color: Cores.superficie, borderRadius: BorderRadius.circular(14)),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.tema != null)
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          key: const Key('login-tema'),
                          tooltip: widget.tema!.escuro ? 'Modo claro' : 'Modo escuro',
                          onPressed: widget.tema!.alternar,
                          icon: Icon(widget.tema!.escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20, color: Cores.texto2),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Cores.fundo, borderRadius: BorderRadius.circular(12)),
                        child: Image.asset(
                          'assets/brasao_scs.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, erro, pilha) => const Icon(Icons.location_city, color: Cores.navy, size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('DashMOB', textAlign: TextAlign.center, style: tema.titleLarge),
                    const SizedBox(height: 4),
                    Text('Painel de operação · SEMOB São Caetano do Sul', textAlign: TextAlign.center, style: tema.bodySmall),
                    const SizedBox(height: 24),
                    if (widget.aviso != null && _erro == null) ...[Aviso(widget.aviso!, chave: const Key('login-aviso')), const SizedBox(height: 14)],
                    if (_erro != null) ...[MensagemErro(_erro!), const SizedBox(height: 14)],
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder()),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Informe o e-mail' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('login-senha'),
                      controller: _senha,
                      obscureText: !_mostrarSenha,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _mostrarSenha ? 'Esconder senha' : 'Mostrar senha',
                          icon: Icon(_mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const Key('login-entrar'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _entrando ? null : _entrar,
                      child: _entrando
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Cores.sobreDestaque))
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 16),
                    Text('Sem acesso? Peça ao administrador do painel.', textAlign: TextAlign.center, style: tema.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
