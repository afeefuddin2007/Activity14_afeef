import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background isolate work only. Do not update Flutter widget state here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Autumn Product Manager',
    home: ProductPage(),
  ));
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _products = FirebaseFirestore.instance.collection('products');
  late final _productStream = _products.snapshots(includeMetadataChanges: true);

  Future<void> _createOrUpdate(
    [QueryDocumentSnapshot<Map<String, dynamic>>? document]
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => ProductEditor(
        products: _products,
        document: document,
      ),
    );
  }

  final _search = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _deleting = <String>{};
  final FcmService _fcmService = FcmService();
  String _notificationTitle = 'No FCM message yet';
  String _notificationBody = 'Firestore product tools remain available below.';
  String _notificationAsset = 'assets/default.png';
  String _lastHandler = 'Waiting for a message';
  String _payloadDiagnostic = 'Allowed: action=update_ui; asset=default or promo';
  String _notificationPermission = 'Checking…';
  String? _fcmToken;
  String _lastMessageId = '—';
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeFcm();
  }

  Future<void> _initializeFcm() async {
    try {
      _fcmService.listen(onMessage: _handleFcmMessage);
      final initialMessage = await _fcmService.getInitialMessage();
      if (initialMessage != null && mounted) {
        _handleFcmMessage(initialMessage, 'getInitialMessage');
      }
      final status = await _fcmService.requestPermission();
      final token = await _fcmService.getToken();
      if (!mounted) return;
      setState(() {
        _notificationPermission = status.name;
        _fcmToken = token;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _payloadDiagnostic = 'FCM initialization error: $error');
      }
    }
  }

  void _handleFcmMessage(RemoteMessage message, String handler) {
    if (!mounted) return;
    final action = message.data['action'];
    final asset = message.data['asset'];
    final allowedAsset = switch (asset) {
      'default' => 'assets/default.png',
      'promo' => 'assets/promo.png',
      _ => null,
    };
    final valid = action == 'update_ui' && allowedAsset != null;
    setState(() {
      _messageCount++;
      _lastHandler = handler;
      _lastMessageId = message.messageId ?? '(no message ID)';
      if (valid) {
        _notificationTitle = message.notification?.title ?? 'Cloud update received';
        _notificationBody = message.notification?.body ?? 'Custom data updated this panel.';
        _notificationAsset = allowedAsset!;
        _payloadDiagnostic = 'Accepted action=$action and asset=$asset';
      } else {
        _payloadDiagnostic = 'Rejected: expected action=update_ui and asset=default or promo. Previous title/image preserved.';
      }
    });
  }

  Future<void> _showFcmToken() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Current installation token'),
        content: SelectableText(_fcmToken ?? 'Token unavailable. Check permission and connection.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _messagePanel() => Card(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(_notificationAsset, width: 52, height: 52, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_notificationTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_notificationBody, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Handler: $_lastHandler • messages: $_messageCount', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
              Text(_payloadDiagnostic, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
              Text('Permission: $_notificationPermission • ID: $_lastMessageId', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
            ])),
          ]),
        ),
      );

  @override
  void dispose() {
    unawaited(_fcmService.dispose());
    _search.dispose(); _min.dispose(); _max.dispose();
    super.dispose();
  }

  String? get _rangeError {
    for (final field in [_min, _max]) {
      if (field.text.trim().isEmpty) continue;
      final value = double.tryParse(field.text.trim());
      if (value == null || !value.isFinite || value < 0) {
        return 'Bounds must be finite numbers of zero or more.';
      }
    }
    final min = double.tryParse(_min.text.trim());
    final max = double.tryParse(_max.text.trim());
    if (min != null && max != null && min > max) {
      return 'Minimum cannot exceed maximum.';
    }
    return null;
  }

  Future<void> _deleteProduct(String id) async {
    if (_deleting.contains(id)) return;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(title: const Text('Delete product?'),
        content: Text('Document ID: $id'), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ]));
    if (confirmed != true || !mounted) return;
    setState(() => _deleting.add(id));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Delete pending. Reconnect if offline.')));
    try {
      await _products.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed (${error.code}).')));
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autumn Product Manager'),
        actions: [IconButton(tooltip: 'Current FCM token', onPressed: _showFcmToken, icon: const Icon(Icons.notifications_active))],
      ),
      body: Column(children: [
        _messagePanel(),
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(controller: _search, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Search product name', prefixIcon: Icon(Icons.search))),
          Row(children: [
            Expanded(child: TextField(controller: _min, onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Minimum price'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _max, onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Maximum price'))),
            TextButton(onPressed: () => setState(() {
              _search.clear(); _min.clear(); _max.clear();
            }), child: const Text('Reset')),
          ]),
          if (_rangeError != null) Text(_rangeError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ])),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text(
              'Products could not load. Check connection and permissions.',
            ));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final documents = snapshot.data!.docs;
          if (documents.isEmpty) {
            return const Center(child: Text('No products yet. Add one to begin.'));
          }
          if (_rangeError != null) {
            return const Center(child: Text('Correct the price range to view results.'));
          }
          final query = _search.text.trim().toLowerCase();
          final min = double.tryParse(_min.text.trim());
          final max = double.tryParse(_max.text.trim());
          final invalid = documents.where((doc) {
            final data = doc.data(); final name = data['name']; final price = data['price'];
            return name is! String || name.trim().isEmpty || price is! num || !price.isFinite || price < 0;
          }).length;
          final filtered = documents.where((doc) {
            final data = doc.data(); final name = data['name']; final price = data['price'];
            if (name is! String || name.trim().isEmpty || price is! num || !price.isFinite || price < 0) return false;
            return name.trim().toLowerCase().contains(query) &&
              (min == null || price >= min) && (max == null || price <= max);
          }).toList();
          return Column(children: [
            Text('${filtered.length} products | ${snapshot.data!.metadata.isFromCache ? "Cache" : "Server"}'
              ' | ${snapshot.data!.metadata.hasPendingWrites ? "Pending writes" : "No pending writes"}'),
            if (invalid > 0) Text('$invalid invalid document(s) excluded. Check name/price types in Console.'),
            Expanded(child: filtered.isEmpty ? const Center(child: Text('No products found')) : ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final document = filtered[index];
              final data = document.data();
              final name = data['name'];
              final price = data['price'];
              if (name is! String || name.trim().isEmpty || price is! num ||
                  !price.isFinite || price < 0) {
                return ListTile(title: Text(
                  'Invalid product ${document.id}: check name/price types.',
                ));
              }
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('${price.toStringAsFixed(2)}\nID: ${document.id}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit product',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _createOrUpdate(document),
                      ),
                      IconButton(
                        tooltip: 'Delete product',
                        icon: const Icon(Icons.delete),
                        onPressed: _deleting.contains(document.id) ? null : () => _deleteProduct(document.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          )),
          ]);
        },
      )),
      ]),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create product',
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({
    super.key,
    required this.products,
    this.document,
  });

  final CollectionReference<Map<String, dynamic>> products;
  final QueryDocumentSnapshot<Map<String, dynamic>>? document;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.document?.data()['name'] as String? ?? '',
  );
  late final _price = TextEditingController(
    text: widget.document?.data()['price']?.toString() ?? '',
  );
  var _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _saveError = null; });
    final data = <String, Object>{
      'name': _name.text.trim(),
      'price': double.parse(_price.text.trim()),
    };
    try {
      final document = widget.document;
      if (document == null) {
        await widget.products.add(data);
      } else {
        await widget.products.doc(document.id).update(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      debugPrint('Product save failed (${error.code}): ${error.message}');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Save failed (${error.code}). '
            'Check your connection and permissions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.document == null ? 'Create product' : 'Edit product'),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a product name' : null,
                ),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || !amount.isFinite || amount < 0
                        ? 'Enter a finite price of zero or more' : null;
                  },
                ),
                if (_saveError != null)
                  Text(_saveError!, style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  )),
                if (_saving)
                  const Text(
                    'Awaiting server acknowledgement. If offline, reconnect. '
                    'This editor stays open until the write succeeds or fails.',
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}