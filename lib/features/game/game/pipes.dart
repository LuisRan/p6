/// Utilidades de bajo nivel para las losetas de "Circuito Guinda".
///
/// Cada loseta se representa con una máscara de 4 bits que indica por qué
/// lados tiene conexión: N=1, E=2, S=4, O=8.
library;

const int kN = 1;
const int kE = 2;
const int kS = 4;
const int kW = 8;

/// Gira la máscara 90° en sentido horario (N->E->S->O->N).
int rotateCw(int mask) => ((mask << 1) | (mask >> 3)) & 15;

/// Gira la máscara 90° en sentido antihorario (usado por "deshacer").
int rotateCcw(int mask) => ((mask >> 1) | (mask << 3)) & 15;

/// Cantidad de conexiones de la loseta.
int bitCount(int mask) {
  var c = 0;
  for (var m = mask; m != 0; m >>= 1) {
    c += m & 1;
  }
  return c;
}

/// Mínimo de giros horarios (0..3) para transformar [from] en [to],
/// o -1 si no son la misma forma. Tiene en cuenta simetrías
/// (una recta necesita a lo sumo 1 giro, una cruz ninguno).
int turnsBetween(int from, int to) {
  var m = from;
  for (var k = 0; k < 4; k++) {
    if (m == to) return k;
    m = rotateCw(m);
  }
  return -1;
}

/// Desplazamiento (dx, dy) de cada dirección.
const Map<int, List<int>> kDelta = {
  kN: [0, -1],
  kE: [1, 0],
  kS: [0, 1],
  kW: [-1, 0],
};

/// Dirección opuesta.
int opposite(int dir) => switch (dir) {
      kN => kS,
      kE => kW,
      kS => kN,
      _ => kE,
    };
