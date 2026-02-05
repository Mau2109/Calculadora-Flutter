import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _pantalla = '';
  int _parentesisAbiertos = 0;

  String _texto = '';
  int _indice = 0;

  void _limpiar() {
    _pantalla = '';
    _parentesisAbiertos = 0;
  }

  bool _esOperador(String c) {
    return c == '+' || c == '-' || c == '*' || c == '/';
  }

  bool _esDigito(String c) {
    return c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  }

  bool _esDigitoOPunto(String c) {
    return _esDigito(c) || c == '.';
  }

  bool _puedeAgregarOperador() {
    if (_pantalla.isEmpty) return false;
    final ultimo = _pantalla[_pantalla.length - 1];
    return _esDigito(ultimo) || ultimo == ')';
  }

  bool _puedeAgregarPunto() {
    if (_pantalla.isEmpty) return true;
    final ultimo = _pantalla[_pantalla.length - 1];
    if (ultimo == ')') return false;
    if (_esOperador(ultimo) || ultimo == '(') return true;
    if (!_esDigito(ultimo)) return false;

    for (int i = _pantalla.length - 1; i >= 0; i--) {
      final c = _pantalla[i];
      if (_esOperador(c) || c == '(' || c == ')') {
        break;
      }
      if (c == '.') return false;
    }
    return true;
  }

  bool _puedeAgregarParentesisDerecho() {
    if (_parentesisAbiertos == 0) return false;
    if (_pantalla.isEmpty) return false;
    final ultimo = _pantalla[_pantalla.length - 1];
    return _esDigito(ultimo) || ultimo == ')';
  }

  bool _expresionValida() {
    if (_pantalla.isEmpty) return false;
    if (_parentesisAbiertos != 0) return false;
    final ultimo = _pantalla[_pantalla.length - 1];
    if (_esOperador(ultimo) || ultimo == '(' || ultimo == '.') return false;
    return true;
  }

  void _alPresionarBoton(String valor) {
    setState(() {
      if (valor == 'C') {
        _limpiar();
        return;
      }

      if (valor == '=') {
        if (!_expresionValida()) {
          _pantalla = 'Error';
          _parentesisAbiertos = 0;
          return;
        }
        try {
          final resultado = _evaluarExpresion(_pantalla);
          _pantalla = _formatearResultado(resultado);
        } catch (_) {
          _pantalla = 'Error';
          _parentesisAbiertos = 0;
        }
        return;
      }

      if (valor == '(') {
        if (_pantalla.isEmpty ||
            _esOperador(_pantalla[_pantalla.length - 1]) ||
            _pantalla.endsWith('(')) {
          _pantalla += valor;
          _parentesisAbiertos++;
        } else {
          _pantalla += '*(';
          _parentesisAbiertos++;
        }
        return;
      }

      if (valor == ')') {
        if (_puedeAgregarParentesisDerecho()) {
          _pantalla += valor;
          _parentesisAbiertos--;
        }
        return;
      }

      if (_esOperador(valor)) {
        if (_puedeAgregarOperador()) {
          _pantalla += valor;
        }
        return;
      }

      if (valor == '.') {
        if (_puedeAgregarPunto()) {
          if (_pantalla.isEmpty ||
              _esOperador(_pantalla[_pantalla.length - 1]) ||
              _pantalla.endsWith('(')) {
            _pantalla += '0.';
          } else {
            _pantalla += '.';
          }
        }
        return;
      }

      if (_pantalla == 'Error') {
        _limpiar();
      }

      _pantalla += valor;
    });
  }

  String _formatearResultado(double valor) {
    if (valor % 1 == 0) {
      return valor.toInt().toString();
    }
    return valor.toString();
  }

  // -------------------------
  // Gramatica:
  // expresion -> termino (('+' | '-') termino)*
  // termino   -> factor (('*' | '/') factor)*
  // factor    -> numero | '(' expresion ')'
  // -------------------------
  double _evaluarExpresion(String texto) {
    _texto = texto;
    _indice = 0;
    final resultado = _leerExpresion();
    _saltarEspacios();
    if (_indice != _texto.length) {
      throw Exception('Caracter invalido');
    }
    return resultado;
  }

  void _saltarEspacios() {
    while (_indice < _texto.length && _texto[_indice] == ' ') {
      _indice++;
    }
  }

  double _leerNumero() {
    _saltarEspacios();
    final inicio = _indice;
    bool yaTienePunto = false;
    while (_indice < _texto.length && _esDigitoOPunto(_texto[_indice])) {
      if (_texto[_indice] == '.') {
        if (yaTienePunto) {
          break;
        }
        yaTienePunto = true;
      }
      _indice++;
    }
    if (inicio == _indice) {
      throw Exception('Numero esperado');
    }
    final parte = _texto.substring(inicio, _indice);
    return double.parse(parte);
  }

  double _leerFactor() {
    _saltarEspacios();
    if (_indice < _texto.length && _texto[_indice] == '(') {
      _indice++;
      final valor = _leerExpresion();
      _saltarEspacios();
      if (_indice >= _texto.length || _texto[_indice] != ')') {
        throw Exception('Parentesis no cerrado');
      }
      _indice++;
      return valor;
    }
    return _leerNumero();
  }

  double _leerTermino() {
    double valor = _leerFactor();
    while (true) {
      _saltarEspacios();
      if (_indice < _texto.length &&
          (_texto[_indice] == '*' || _texto[_indice] == '/')) {
        final op = _texto[_indice];
        _indice++;
        final siguiente = _leerFactor();
        if (op == '*') {
          valor *= siguiente;
        } else {
          if (siguiente == 0) {
            throw Exception('Division por cero');
          }
          valor /= siguiente;
        }
      } else {
        break;
      }
    }
    return valor;
  }

  double _leerExpresion() {
    double valor = _leerTermino();
    while (true) {
      _saltarEspacios();
      if (_indice < _texto.length &&
          (_texto[_indice] == '+' || _texto[_indice] == '-')) {
        final op = _texto[_indice];
        _indice++;
        final siguiente = _leerTermino();
        if (op == '+') {
          valor += siguiente;
        } else {
          valor -= siguiente;
        }
      } else {
        break;
      }
    }
    return valor;
  }

  Widget _buildButton(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => _alPresionarBoton(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRow(List<_KeySpec> keys) {
    // Construye una fila de teclas, cada una expandida según su flex.
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in keys)
            Expanded(
              flex: key.flex,
              child: _buildButton(key.text, color: key.color),
            ),
        ],
      ),
    );
  }

  Widget _buildKeypadPortrait() {
    // Teclado en vertical (retrato): layout clásico en 5 filas.
    return Column(
      children: [
        _buildRow([
          const _KeySpec('C', color: Color(0xFFD32F2F)),
          const _KeySpec('('),
          const _KeySpec(')'),
          const _KeySpec('/', color: Color(0xFFF57C00)),
        ]),
        _buildRow([
          const _KeySpec('7'),
          const _KeySpec('8'),
          const _KeySpec('9'),
          const _KeySpec('*', color: Color(0xFFF57C00)),
        ]),
        _buildRow([
          const _KeySpec('4'),
          const _KeySpec('5'),
          const _KeySpec('6'),
          const _KeySpec('-', color: Color(0xFFF57C00)),
        ]),
        _buildRow([
          const _KeySpec('1'),
          const _KeySpec('2'),
          const _KeySpec('3'),
          const _KeySpec('+', color: Color(0xFFF57C00)),
        ]),
        _buildRow([
          const _KeySpec('0'),
          const _KeySpec('.'),
          const _KeySpec('=', color: Color(0xFF388E3C), flex: 2),
        ]),
      ],
    );
  }

  Widget _buildKeypadLandscape() {
    // Teclado en horizontal: 2 filas, sin scroll.
    return Column(
      children: [
        _buildRow([
          const _KeySpec('0'),
          const _KeySpec('1'),
          const _KeySpec('2'),
          const _KeySpec('3'),
          const _KeySpec('4'),
          const _KeySpec('5'),
          const _KeySpec('6'),
          const _KeySpec('7'),
          const _KeySpec('8'),
          const _KeySpec('9'),
          const _KeySpec('.'),
        ]),
        _buildRow([
          const _KeySpec('C', color: Color(0xFFD32F2F)),
          const _KeySpec('('),
          const _KeySpec(')'),
          const _KeySpec('/', color: Color(0xFFF57C00)),
          const _KeySpec('*', color: Color(0xFFF57C00)),
          const _KeySpec('-', color: Color(0xFFF57C00)),
          const _KeySpec('+', color: Color(0xFFF57C00)),
          // El "=" ocupa 2+ espacios usando flex mayor.
          const _KeySpec('=', color: Color(0xFF388E3C), flex: 3),
        ]),
      ],
    );
  }

  Widget _buildDisplay() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      alignment: Alignment.centerRight,
      child: Text(
        _pantalla.isEmpty ? '0' : _pantalla,
        style: const TextStyle(fontSize: 42, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estructura general: display arriba y teclado abajo.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return Column(
                children: [
                  Expanded(flex: 2, child: _buildDisplay()),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _buildKeypadLandscape(),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(flex: 2, child: _buildDisplay()),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _buildKeypadPortrait(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KeySpec {
  final String text;
  final Color? color;
  final int flex;

  const _KeySpec(this.text, {this.color, this.flex = 1});
}
