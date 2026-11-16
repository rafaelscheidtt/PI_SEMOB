import 'package:flutter/material.dart';

import '../../core/layout.dart';
import '../../core/tema.dart';
import '../../data/models.dart';
import '../legal/termo_page.dart';
import '../legal/termo_texto.dart';
import '../painel/widgets/cartao.dart';

const versaoDoApp = '0.1.0';

/// Sobre o DashMOB: o que é o painel, como os números são calculados, o que cada perfil
/// acessa, privacidade e quem desenvolveu. Reúne as explicações que antes ficavam espalhadas pelas telas.
class SobrePage extends StatelessWidget {
  const SobrePage({super.key});

  static const _calculos = <(String, String)>[
    ('Cumprimento de viagens', 'Viagens realizadas divididas pelas programadas no período, em percentual.'),
    ('Passageiros', 'Soma de pagantes e gratuidades registrados pela bilhetagem. O dado existe para o sistema inteiro, não por linha.'),
    ('Média de passageiros por viagem', 'Considera apenas os dias em que há dado de bilhetagem, para a média não ser puxada para baixo.'),
    ('Crédito circulante', 'Vendas de crédito menos a utilização no período.'),
    ('Períodos sem relatório', 'Ficam em branco ou como "Sem dados". O painel nunca mostra zero no lugar de um dado que não chegou.'),
    ('Comparação com o período anterior', 'A variação dos indicadores compara o período escolhido com o período de mesma duração imediatamente antes.'),
  ];

  static const _alertas = <(String, String)>[
    ('Cumprimento baixo', 'Dia com cumprimento abaixo de 95% gera aviso; abaixo de 90%, alerta crítico.'),
    ('Fora do padrão', 'Quilometragem, viagens e passageiros do dia são comparados com a média do mesmo dia da semana nas 8 semanas anteriores. Diferença a partir de 20% gera aviso; a partir de 35%, alerta crítico. É preciso haver pelo menos 3 semanas de histórico.'),
    ('Ocorrências', 'Dia com mais que o dobro da média diária de viagens não realizadas, não iniciadas ou não terminadas gera aviso, desde que sejam pelo menos 3 no dia; mais que o triplo, alerta crítico.'),
  ];

  static const _equipe = ['Guilherme Tomaz Gomes', 'Luigi Battistini', 'Mateo Vuolo Cortez', 'Matheus Anderson Moraes', 'Rafael Scheidt Reschke', 'Thales Xavier von Tein'];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    Widget item((String, String) i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.$1, style: tema.labelLarge),
            const SizedBox(height: 2),
            Text(i.$2, style: tema.bodyMedium?.copyWith(color: Cores.texto2)),
          ]),
        );
    Widget lista(List<(String, String)> itens) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [for (final i in itens) item(i)]);

    return LayoutBuilder(builder: (context, c) {
      final compacto = faixaDeLargura(c.maxWidth) == FaixaLargura.compacto;
      return SingleChildScrollView(
        padding: EdgeInsets.all(compacto ? 14 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const CabecalhoTela(
                titulo: 'Sobre o DashMOB',
                subtitulo: 'Painel de operação do transporte coletivo · SEMOB São Caetano do Sul · versão $versaoDoApp',
              ),
              const SizedBox(height: 18),
              Cartao(
                titulo: 'O que é',
                child: Text(
                  'O DashMOB reúne em um só lugar os indicadores da operação dos ônibus municipais: quilometragem, viagens, cumprimento, passageiros, bilhetagem e ocorrências. '
                  'Os números vêm dos relatórios do sistema de gestão da frota e podem ser vistos por dia, semana ou mês, para o sistema inteiro ou por linha.',
                  style: tema.bodyMedium,
                ),
              ),
              const SizedBox(height: 14),
              Cartao(titulo: 'Como os indicadores são calculados', child: lista(_calculos)),
              const SizedBox(height: 14),
              Cartao(titulo: 'Quando um alerta aparece', child: lista(_alertas)),
              const SizedBox(height: 14),
              Cartao(
                titulo: 'Perfis de acesso',
                subtitulo: 'O perfil de cada usuário é definido pelo administrador',
                child: lista([for (final p in Papel.values) (p.rotulo, p.descricao)]),
              ),
              const SizedBox(height: 14),
              Cartao(
                titulo: 'Privacidade',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'O painel guarda apenas os dados necessários para identificar quem o utiliza (nome, e-mail, perfil e, se a pessoa quiser, uma foto) e trata esses dados conforme a Lei Geral de Proteção de Dados. '
                    'Os indicadores são totais da operação e não identificam passageiros.',
                    style: tema.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('sobre-termo'),
                    onPressed: () => mostrarTermo(context),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Ler o termo de uso e aviso de privacidade (versão $versaoDoTermo)'),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Cartao(
                titulo: 'Desenvolvimento',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Desenvolvido em 2026 por alunos de Ciência da Computação do Instituto Mauá de Tecnologia, na disciplina de Projeto Integrador, em parceria com a Secretaria Municipal de Mobilidade Urbana de São Caetano do Sul.',
                    style: tema.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text('Equipe', style: tema.labelLarge),
                  const SizedBox(height: 2),
                  Text(_equipe.join(' · '), style: tema.bodyMedium?.copyWith(color: Cores.texto2)),
                  const SizedBox(height: 10),
                  Text('Tecnologia', style: tema.labelLarge),
                  const SizedBox(height: 2),
                  Text('Aplicativo em Flutter (web e celular), API em Python com FastAPI e banco de dados MongoDB.', style: tema.bodyMedium?.copyWith(color: Cores.texto2)),
                ]),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
