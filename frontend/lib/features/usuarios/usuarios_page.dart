import 'package:flutter/material.dart';

import '../../core/layout.dart';
import '../../core/tema.dart';
import '../../data/auth_repository.dart';
import '../../data/models.dart';
import '../painel/widgets/cartao.dart';
import '../painel/widgets/estados.dart';

/// Cadastro de usuários pelo administrador (US13): lista, cria, edita e desativa.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key, required this.repository, required this.usuarioLogado});

  final AuthRepository repository;
  final Usuario usuarioLogado;

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<Usuario> _usuarios = const [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await widget.repository.usuarios();
      if (mounted) setState(() => _usuarios = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirFormulario({Usuario? existente}) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _FormularioUsuario(repository: widget.repository, existente: existente, souEu: existente?.id == widget.usuarioLogado.id),
    );
    if (salvo == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final compacto = faixaDeLargura(c.maxWidth) == FaixaLargura.compacto;
      return SingleChildScrollView(
        padding: EdgeInsets.all(compacto ? 14 : 24),
        child: Cartao(
          titulo: 'Usuários do painel',
          subtitulo: 'Quem pode entrar e o que cada um enxerga',
          acao: FilledButton.icon(
            key: const Key('usuarios-novo'),
            style: FilledButton.styleFrom(backgroundColor: Cores.navy),
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: const Text('Novo usuário'),
          ),
          child: _carregando
              ? const Carregando()
              : _erro != null
                  ? MensagemErro(_erro!)
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (final u in _usuarios) _LinhaUsuario(usuario: u, souEu: u.id == widget.usuarioLogado.id, onTap: () => _abrirFormulario(existente: u)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 16, runSpacing: 6, children: [
                        for (final p in Papel.values)
                          Text('${p.rotulo}: ${p.descricao}', style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ]),
        ),
      );
    });
  }
}

class _LinhaUsuario extends StatelessWidget {
  const _LinhaUsuario({required this.usuario, required this.souEu, required this.onTap});

  final Usuario usuario;
  final bool souEu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final cor = usuario.ativo ? Cores.tinta : Cores.texto2;
    return InkWell(
      key: Key('usuario-${usuario.email}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Cores.linha))),
        child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: usuario.ativo ? Cores.azulSuave : Cores.fundo, child: Icon(Icons.person, size: 18, color: usuario.ativo ? Cores.azul : Cores.texto2)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(souEu ? '${usuario.nome} (você)' : usuario.nome, style: tema.labelLarge?.copyWith(color: cor), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(usuario.email, style: tema.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          _Etiqueta(usuario.ativo ? usuario.papel.rotulo : 'Desativado', ativo: usuario.ativo),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Cores.texto2),
        ]),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {required this.ativo});

  final String texto;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: ativo ? Cores.azulSuave : Cores.fundo, borderRadius: BorderRadius.circular(999)),
      child: Text(texto, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: ativo ? Cores.azul : Cores.texto2)),
    );
  }
}

/// Diálogo de novo usuário ou de edição (papel, ativo e troca de senha).
class _FormularioUsuario extends StatefulWidget {
  const _FormularioUsuario({required this.repository, this.existente, this.souEu = false});

  final AuthRepository repository;
  final Usuario? existente;
  final bool souEu;

  @override
  State<_FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<_FormularioUsuario> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  final _senha = TextEditingController();
  late Papel _papel;
  late bool _ativo;
  bool _salvando = false;
  String? _erro;

  bool get _novo => widget.existente == null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.existente?.nome ?? '');
    _email = TextEditingController(text: widget.existente?.email ?? '');
    _papel = widget.existente?.papel ?? Papel.gestor;
    _ativo = widget.existente?.ativo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      if (_novo) {
        await widget.repository.criarUsuario(nome: _nome.text.trim(), email: _email.text.trim(), senha: _senha.text, papel: _papel);
      } else {
        await widget.repository.editarUsuario(widget.existente!.id, nome: _nome.text.trim(), papel: _papel, ativo: _ativo, senha: _senha.text);
      }
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: Text(_novo ? 'Novo usuário' : 'Editar usuário'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_erro != null) ...[MensagemErro(_erro!), const SizedBox(height: 12)],
              TextFormField(
                key: const Key('usuario-nome'),
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('usuario-email'),
                controller: _email,
                enabled: _novo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('usuario-senha'),
                controller: _senha,
                obscureText: true,
                decoration: InputDecoration(labelText: _novo ? 'Senha' : 'Nova senha (deixe em branco para manter)', border: const OutlineInputBorder()),
                validator: (v) => (_novo || (v != null && v.isNotEmpty)) && (v == null || v.length < 6) ? 'Pelo menos 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Papel', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Papel>(
                    key: const Key('usuario-papel'),
                    value: _papel,
                    isExpanded: true,
                    items: [for (final p in Papel.values) DropdownMenuItem(value: p, child: Text(p.rotulo))],
                    onChanged: widget.souEu ? null : (p) => setState(() => _papel = p ?? _papel),
                  ),
                ),
              ),
              if (!_novo && !widget.souEu) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  key: const Key('usuario-ativo'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativo'),
                  subtitle: const Text('Desativado não consegue entrar'),
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                ),
              ],
              if (widget.souEu) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Você não pode mudar o seu próprio papel nem se desativar.', style: Theme.of(context).textTheme.bodySmall)),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('usuario-salvar'),
          style: FilledButton.styleFrom(backgroundColor: Cores.navy),
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
