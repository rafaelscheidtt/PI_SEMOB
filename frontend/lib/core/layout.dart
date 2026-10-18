/// Faixas de largura do layout responsivo (US06).
enum FaixaLargura { compacto, medio, expandido }

/// Compacto até 600 dp (celular), médio de 600 a 1024 dp (tablet),
/// expandido acima de 1024 dp (desktop e web).
FaixaLargura faixaDeLargura(double largura) {
  if (largura < 600) return FaixaLargura.compacto;
  if (largura < 1024) return FaixaLargura.medio;
  return FaixaLargura.expandido;
}

/// Quantidade de cartões de indicador por linha em cada faixa.
int colunasDeCartoes(FaixaLargura faixa) => switch (faixa) {
      FaixaLargura.compacto => 1,
      FaixaLargura.medio => 2,
      FaixaLargura.expandido => 4,
    };
