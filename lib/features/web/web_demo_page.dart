import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Recorrido local reproducible del ejercicio web. El relay A/B y las
/// respuestas HTTPS son fixtures: aquí no hay una conexión Bluetooth real.
class WebDemoPage extends StatefulWidget {
  const WebDemoPage({super.key});

  @override
  State<WebDemoPage> createState() => _WebDemoPageState();
}

class _WebDemoPageState extends State<WebDemoPage> {
  static const _sampleUrl = 'https://jsonplaceholder.typicode.com/todos/1';
  static const _responses = <String, String>{
    _sampleUrl: '{\n  "userId": 1,\n  "id": 1,\n  "title": "delectus aut autem",\n  "completed": false\n}',
    'https://jsonplaceholder.typicode.com/posts/1': '{\n  "userId": 1,\n  "id": 1,\n  "title": "Prueba de consulta web",\n  "body": "Respuesta HTTPS de ejemplo entregada por el relay A simulado."\n}',
  };

  final _url = TextEditingController(text: _sampleUrl);
  final _cache = <String, ({String body, DateTime savedAt})>{};
  final _favorites = <String>{};
  final _history = <String>[];
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  int _historyIndex = -1;
  int _sequence = 0;
  bool _relayOnline = true;
  bool _loading = false;
  String? _body;
  String? _status;
  String? _source;
  String? _requestId;
  Duration? _elapsed;
  DateTime? _receivedAt;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  bool get _canGoBack => _historyIndex > 0;
  bool get _canGoForward =>
      _historyIndex >= 0 && _historyIndex < _history.length - 1;

  Future<void> _request({bool addHistory = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final raw = _url.text.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'jsonplaceholder.typicode.com') {
      setState(() {
        _status = 'Destino rechazado';
        _source = 'Sólo se permite HTTPS en jsonplaceholder.typicode.com.';
        _body = null;
      });
      return;
    }
    final body = _responses[uri.toString()];
    if (body == null) {
      setState(() {
        _status = 'Recurso no permitido';
        _source = 'La ruta no pertenece al conjunto de ejemplos autorizado.';
        _body = null;
      });
      return;
    }

    if (addHistory) {
      _history.removeRange(_historyIndex + 1, _history.length);
      if (_history.isEmpty || _history.last != uri.toString()) {
        _history.add(uri.toString());
      }
      _historyIndex = _history.length - 1;
    }

    final cached = _cache[uri.toString()];
    if (!_relayOnline) {
      if (cached == null) {
        setState(() {
          _status = 'Relay A sin conexión';
          _source = 'No hay copia en caché para este recurso.';
          _body = null;
          _loading = false;
        });
        return;
      }
      setState(() {
        _status = 'Copia de caché';
        _source = 'Guardada ${_dateFormat.format(cached.savedAt)}';
        _body = cached.body;
        _requestId = 'cache-${++_sequence}';
        _elapsed = Duration.zero;
        _receivedAt = DateTime.now();
        _loading = false;
      });
      return;
    }

    final requestId = 'web-${++_sequence}';
    final started = DateTime.now();
    setState(() {
      _loading = true;
      _status = 'Solicitando respuesta…';
      _source = null;
      _requestId = requestId;
      _body = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    final received = DateTime.now();
    _cache[uri.toString()] = (body: body, savedAt: received);
    setState(() {
      _loading = false;
      _status = '200 OK';
      _source = 'HTTPS de ejemplo · respuesta entregada por A simulado';
      _body = body;
      _elapsed = received.difference(started);
      _receivedAt = received;
    });
  }

  Future<void> _historyMove(int delta) async {
    final next = _historyIndex + delta;
    if (next < 0 || next >= _history.length) return;
    _historyIndex = next;
    _url.text = _history[next];
    await _request(addHistory: false);
  }

  void _toggleFavorite() {
    final value = _url.text.trim();
    setState(() {
      if (!_favorites.add(value)) _favorites.remove(value);
    });
  }

  void _toggleRelay() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _relayOnline = !_relayOnline);
  }

  void _selectFavorite(String value) {
    _url.text = value;
    _request();
  }

  @override
  Widget build(BuildContext context) {
    final favorite = _favorites.contains(_url.text.trim());
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta web')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Simulación B → relay A → HTTPS. Allowlist: dos rutas JSONPlaceholder; rechaza otros destinos. Respuestas locales; sin Bluetooth ni peticiones de red.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.phone_android),
                label: const Text('Cliente B simulado'),
              ),
              Chip(
                avatar: Icon(_relayOnline ? Icons.cloud_done : Icons.cloud_off),
                label: Text(
                  _relayOnline
                      ? 'Relay A · conectado'
                      : 'Relay A · sin Internet',
                ),
              ),
            ],
          ),
          TextField(
            key: const Key('web-url'),
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Recurso HTTPS permitido',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                tooltip: favorite ? 'Quitar favorito' : 'Guardar favorito',
                onPressed: _toggleFavorite,
                icon: Icon(favorite ? Icons.star : Icons.star_outline),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('web-request'),
                onPressed: _loading ? null : _request,
                icon: const Icon(Icons.travel_explore),
                label: const Text('Consultar'),
              ),
              OutlinedButton.icon(
                onPressed: _toggleRelay,
                icon: Icon(_relayOnline ? Icons.wifi_off : Icons.wifi),
                label: Text(_relayOnline ? 'Desconectar A' : 'Conectar A'),
              ),
            ],
          ),
          if (_favorites.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Favoritos',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final url in _favorites)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star),
                title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _selectFavorite(url),
              ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              IconButton(
                tooltip: 'Atrás',
                onPressed: _canGoBack ? () => _historyMove(-1) : null,
                icon: const Icon(Icons.arrow_back),
              ),
              IconButton(
                tooltip: 'Adelante',
                onPressed: _canGoForward ? () => _historyMove(1) : null,
                icon: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(width: 8),
              const Text('Historial local'),
              if (_history.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${_historyIndex + 1}/${_history.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 8),
                      Text(
                        _status ?? 'Sin solicitudes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_loading) ...[
                        const Spacer(),
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  if (_requestId != null) Text('ID: $_requestId'),
                  if (_elapsed != null)
                    Text('Tiempo: ${_elapsed!.inMilliseconds} ms'),
                  if (_receivedAt != null)
                    Text(
                      'Recibida: ${TimeOfDay.fromDateTime(_receivedAt!).format(context)}',
                    ),
                  if (_source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _source!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_body != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _body!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
