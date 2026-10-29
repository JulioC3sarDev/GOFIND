import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

// Descobre para onde o celular está apontando, em graus
// (0 = norte, 90 = leste, 180 = sul, 270 = oeste).
//
// Usa o acelerômetro (para saber onde é "para cima") e o magnetômetro
// (para achar o norte). Funciona com o celular deitado ou em pé.
class Bussola {
  StreamSubscription<AccelerometerEvent>? _subAcel;
  StreamSubscription<MagnetometerEvent>? _subMag;

  // Últimas leituras suavizadas: [x, y, z]
  List<double>? _acel;
  List<double>? _mag;

  // Começa a medir. [aoMudar] recebe a direção a cada leitura.
  // [aoFalhar] é chamado se o aparelho não tiver os sensores.
  void iniciar(
    void Function(double graus) aoMudar, {
    void Function()? aoFalhar,
  }) {
    parar();

    _subAcel = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (e) => _acel = _suavizar(_acel, [e.x, e.y, e.z]),
      onError: (_) => aoFalhar?.call(),
      cancelOnError: true,
    );

    _subMag = magnetometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (e) {
        _mag = _suavizar(_mag, [e.x, e.y, e.z]);
        final graus = _calcular();
        if (graus != null) aoMudar(graus);
      },
      onError: (_) => aoFalhar?.call(),
      cancelOnError: true,
    );
  }

  void parar() {
    _subAcel?.cancel();
    _subMag?.cancel();
    _subAcel = null;
    _subMag = null;
    _acel = null;
    _mag = null;
  }

  // Filtro simples: cada leitura nova entra só um pouco, para não tremer
  static List<double> _suavizar(List<double>? anterior, List<double> novo) {
    if (anterior == null) return novo;
    const k = 0.22;
    return [
      for (var i = 0; i < 3; i++) anterior[i] + k * (novo[i] - anterior[i]),
    ];
  }

  static List<double> _cruz(List<double> a, List<double> b) => [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
      ];

  static double _tamanho(List<double> v) =>
      sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);

  static List<double> _unitario(List<double> v) {
    final t = _tamanho(v);
    return [v[0] / t, v[1] / t, v[2] / t];
  }

  double? _calcular() {
    final a = _acel;
    final m = _mag;
    if (a == null || m == null) return null;
    if (_tamanho(a) < 1 || _tamanho(m) < 5) return null; // leitura inválida

    // Direções do mundo (cima, leste, norte) vistas pelos eixos do celular
    final cima = _unitario(a);
    final leste0 = _cruz(m, cima);
    if (_tamanho(leste0) < 1) return null;
    final leste = _unitario(leste0);
    final norte = _cruz(cima, leste);

    // "Frente" do celular = topo (eixo Y) + costas (eixo -Z).
    // Vale para o celular deitado e para o celular em pé.
    final fe = leste[1] - leste[2];
    final fn = norte[1] - norte[2];

    final graus = atan2(fe, fn) * 180 / pi;
    return (graus + 360) % 360;
  }
}