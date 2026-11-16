import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../data/auth_repository.dart';
import '../../data/models.dart';
import '../painel/widgets/avatar_usuario.dart';
import '../painel/widgets/estados.dart';
import 'foto.dart';

/// Abre "Meu perfil" e devolve o usuário atualizado, ou `null` se nada foi salvo.
Future<Usuario?> abrirPerfil(BuildContext context, {required Usuario usuario, required AuthRepository repository, EscolherFoto escolherFoto = escolherFotoDoAparelho}) {
  return showDialog<Usuario>(
    context: context,
    builder: (_) => PerfilDialog(usuario: usuario, repository: repository, escolherFoto: escolherFoto),
  );
}

/// Meu perfil: o usuário logado troca o próprio nome, a foto e a senha (US13).
/// Papel e e-mail aparecem só para consulta; quem muda é o administrador.
class PerfilDialog extends StatefulWidget {
  const PerfilDialog({super.key, required this.usuario, required this.repository, this.escolherFoto = escolherFotoDoAparelho});

  final Usuario usuario;
  final AuthRepository repository;
  final EscolherFoto escolherFoto;

  @override
  State<PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<PerfilDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome = TextEditingController(text: widget.usuario.nome);
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmar = TextEditingController();

  /// Foto mostrada no formulário: começa com a atual e muda ao escolher ou remover.
  late String? _foto = widget.usuario.foto;
  bool _salvando = false;
  String? _erro;

  bool get _trocandoSenha => _novaSenha.text.isNotEmpty || _senhaAtual.text.isNotEmpty || _confirmar.text.isNotEmpty;

  @override
  void dispose() {
    _nome.dispose();
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    try {
      final nova = await widget.escolherFoto();
      if (nova != null && mounted) {
        setState(() {
          _foto = nova;
          _erro = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = e is FormatException ? e.message : 'Não foi possível abrir essa imagem.');
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final original = widget.usuario;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final atualizado = await widget.repository.atualizarPerfil(
        nome: _nome.text.trim() == original.nome ? null : _nome.text.trim(),
        senhaAtual: _trocandoSenha ? _senhaAtual.text : null,
        novaSenha: _trocandoSenha ? _novaSenha.text : null,
        foto: _foto == original.foto ? null : (_foto ?? ''),
      );
      if (mounted) Navigator.of(context).pop(atualizado);
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final u = widget.usuario;
    const borda = OutlineInputBorder();
    return AlertDialog(
      title: const Text('Meu perfil'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_erro != null) ...[MensagemErro(_erro!), const SizedBox(height: 14)],
              Row(children: [
                AvatarUsuario(iniciais: u.iniciais, foto: _foto, raio: 36, fundo: Cores.azulSuave, corTexto: Cores.azul),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.email, style: tema.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(u.papel.rotulo, style: tema.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(spacing: 4, children: [
                      TextButton.icon(
                        key: const Key('perfil-foto'),
                        onPressed: _salvando ? null : _escolherFoto,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(_foto == null ? 'Escolher foto' : 'Trocar foto'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
                      ),
                      if (_foto != null)
                        TextButton(
                          key: const Key('perfil-remover-foto'),
                          onPressed: _salvando ? null : () => setState(() => _foto = null),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8), foregroundColor: Cores.texto2),
                          child: const Text('Remover'),
                        ),
                    ]),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('perfil-nome'),
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline), border: borda),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 20),
              Text('Trocar a senha', style: tema.labelLarge),
              const SizedBox(height: 2),
              Text('Deixe os três campos em branco para manter a senha de hoje.', style: tema.bodySmall),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('perfil-senha-atual'),
                controller: _senhaAtual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual', prefixIcon: Icon(Icons.lock_outline), border: borda),
                validator: (v) => _trocandoSenha && (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('perfil-nova-senha'),
                controller: _novaSenha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha', prefixIcon: Icon(Icons.key_outlined), border: borda),
                validator: (v) => _trocandoSenha && (v == null || v.length < 6) ? 'Pelo menos 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('perfil-confirmar-senha'),
                controller: _confirmar,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Repita a nova senha', prefixIcon: Icon(Icons.key_outlined), border: borda),
                validator: (v) => _trocandoSenha && v != _novaSenha.text ? 'As senhas não são iguais' : null,
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('perfil-salvar'),
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
