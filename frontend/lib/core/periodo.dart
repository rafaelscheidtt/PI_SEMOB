/// Granularidades das visões do painel (RN01) e validação de intervalo (RN07).
enum Granularidade {
  dia('dia', 'Diária'),
  semana('semana', 'Semanal'),
  mes('mes', 'Mensal');

  const Granularidade(this.valorApi, this.rotulo);
  final String valorApi;
  final String rotulo;
}

/// Mensagem exibida ao usuário quando o intervalo é inválido (RN07).
const mensagemIntervaloInvalido = 'A data inicial deve ser anterior ou igual à final';

/// Devolve `null` se o intervalo é válido ou a mensagem de erro caso contrário.
String? validarIntervalo(DateTime inicio, DateTime fim) {
  final i = DateTime(inicio.year, inicio.month, inicio.day);
  final f = DateTime(fim.year, fim.month, fim.day);
  return i.isAfter(f) ? mensagemIntervaloInvalido : null;
}

/// Rótulo curto da chave de período (`2026-09-15`, `2026-W38`, `2026-09`).
/// Usa o formato da chave e não a granularidade selecionada, porque ao trocar
/// a visão a série antiga ainda aparece até a API responder.
String rotuloPeriodo(String chave, [Granularidade? g]) {
  if (chave.contains('-W')) return 'S${chave.split('-W').last}';
  final p = chave.split('-');
  if (p.length == 3) return '${p[2]}/${p[1]}';
  if (p.length == 2) return '${p[1]}/${p[0]}';
  return chave;
}
