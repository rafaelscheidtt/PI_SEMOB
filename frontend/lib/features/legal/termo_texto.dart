/// Texto do termo de uso e aviso de privacidade. Se mudar o texto, trocar também TERMO_VERSAO em backend/app/repositories/usuarios.py.
library;

const versaoDoTermo = '1.0';
const dataDoTermo = 'novembro de 2026';

class SecaoDoTermo {
  const SecaoDoTermo(this.titulo, this.paragrafos);

  final String titulo;
  final List<String> paragrafos;
}

const secoesDoTermo = <SecaoDoTermo>[
  SecaoDoTermo('1. Sobre este termo', [
    'O DashMOB é o painel de acompanhamento da operação do transporte coletivo de São Caetano do Sul, de uso interno da Secretaria Municipal de Mobilidade Urbana (SEMOB). Este termo explica quais dados pessoais o painel guarda sobre quem o utiliza, para que servem e quais são os seus direitos, conforme a Lei Geral de Proteção de Dados (Lei nº 13.709/2018).',
    'Para usar o painel é preciso ler e aceitar este termo. O aceite fica registrado com a data.',
  ]),
  SecaoDoTermo('2. Dados pessoais tratados', [
    'Do usuário do painel são guardados: nome, e-mail, perfil de acesso (administrador, gestor ou executivo), situação da conta (ativa ou desativada), data de criação da conta, data do aceite deste termo e, se você quiser, uma foto de perfil.',
    'A senha não é guardada em texto: fica apenas um código embaralhado, que não permite descobrir a senha original.',
    'No seu aparelho ficam somente o código da sessão, para você não precisar entrar de novo a cada acesso, e a sua preferência de modo claro ou escuro. O painel não usa cookies de publicidade nem coleta a sua localização.',
  ]),
  SecaoDoTermo('3. Para que os dados são usados', [
    'Nome, e-mail, senha e perfil servem para identificar quem acessa o painel e liberar apenas o que cada perfil pode ver. Esse tratamento é necessário para a execução das atividades da administração pública (arts. 7º, III, e 23 da LGPD).',
    'A foto é opcional e depende do seu consentimento (art. 7º, I). Ela só existe se você a enviar em "Meu perfil" e pode ser removida por você a qualquer momento, no mesmo lugar.',
  ]),
  SecaoDoTermo('4. Dados da operação', [
    'Os indicadores do painel (quilometragem, viagens, passageiros, valores de bilhetagem e ocorrências) vêm dos relatórios do sistema de gestão da frota e são totais por dia e por linha. O painel não identifica passageiros e não guarda o código do motorista que aparece nos relatórios de ocorrência.',
  ]),
  SecaoDoTermo('5. Quem tem acesso', [
    'Os administradores do painel veem o nome, o e-mail, o perfil, a situação e a foto de todos os usuários, para fazer o cadastro e o controle de acesso. Os demais usuários veem apenas os próprios dados.',
    'Os dados não são vendidos nem cedidos a terceiros. Eles ficam em serviço de banco de dados em nuvem contratado para o painel, que os armazena em nome da SEMOB.',
  ]),
  SecaoDoTermo('6. Guarda e segurança', [
    'O acesso exige e-mail e senha, a sessão vence sozinha depois de algumas horas e cada perfil só alcança as funções que lhe cabem. Os dados da conta são mantidos enquanto ela existir; uma conta desativada deixa de entrar no painel.',
  ]),
  SecaoDoTermo('7. Seus direitos', [
    'Você pode, a qualquer momento: conferir e corrigir o seu nome e trocar a sua senha em "Meu perfil"; remover a sua foto; e pedir ao administrador do painel a correção de outros dados ou a desativação e a exclusão da sua conta.',
    'Os demais direitos previstos no art. 18 da LGPD, como a confirmação e o acesso aos dados tratados, podem ser exercidos junto ao encarregado pelo tratamento de dados pessoais da Prefeitura de São Caetano do Sul, pelos canais oficiais de atendimento.',
  ]),
  SecaoDoTermo('8. Suas responsabilidades', [
    'A conta é pessoal e não deve ser emprestada. Guarde a sua senha, saia do painel em computadores compartilhados e avise o administrador se suspeitar de uso indevido.',
    'As informações do painel são de uso da SEMOB e devem ser utilizadas apenas para as atividades de trabalho.',
  ]),
  SecaoDoTermo('9. Mudanças neste termo', [
    'Se este termo mudar, a nova versão será apresentada no seu próximo acesso, para nova leitura e aceite. A versão em vigor fica sempre disponível em "Sobre o DashMOB".',
  ]),
];
