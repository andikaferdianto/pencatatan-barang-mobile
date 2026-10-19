import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatatan Barang',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StokBarangPage(),
    );
  }
}

class StokBarangPage extends StatefulWidget {
  const StokBarangPage({super.key});

  @override
  State<StokBarangPage> createState() => _StokBarangPageState();
}

class _StokBarangPageState extends State<StokBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _masukCtrl = TextEditingController();
  final _keluarCtrl = TextEditingController();
  final _kodeCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();

  bool _isSaving = false;

  // Inisial nama depan (Andika) dan 2 angka terakhir NIM genap (...94)
  static const String _inisial = 'A';
  static const String _akhirKode = '94';

  @override
  void dispose() {
    _namaCtrl.dispose();
    _masukCtrl.dispose();
    _keluarCtrl.dispose();
    _kodeCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  String? _wajibIsi(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  String? _validasiNama(String? v) {
    final err = _wajibIsi(v, 'Nama barang');
    if (err != null) return err;
    if (!v!.trim().toUpperCase().startsWith(_inisial)) {
      return 'Nama barang harus diawali inisial "$_inisial"';
    }
    return null;
  }

  String? _validasiKode(String? v) {
    final err = _wajibIsi(v, 'Kode barang');
    if (err != null) return err;
    final kode = v!.trim();
    if (!RegExp(r'^\d+$').hasMatch(kode)) return 'Kode barang harus angka';
    if (kode.length < 6) return 'Kode barang minimal 6 angka';
    if (!kode.endsWith(_akhirKode)) {
      return 'Kode barang harus berakhiran $_akhirKode';
    }
    return null;
  }

  String? _validasiStok(String? v) {
    final err = _wajibIsi(v, 'Jumlah stok');
    if (err != null) return err;
    final stok = int.tryParse(v!.trim());
    if (stok == null) return 'Jumlah stok harus berupa angka bulat';
    if (stok < 0) return 'Jumlah stok tidak boleh negatif';
    return null;
  }

  Future<void> _simpanBarang() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('stok_barang').add({
        'nama_barang': _namaCtrl.text.trim(),
        'tanggal_masuk': _masukCtrl.text.trim(),
        'tanggal_keluar': _keluarCtrl.text.trim(),
        'kode_barang': int.parse(_kodeCtrl.text.trim()),
        'jumlah_stok': int.parse(_stokCtrl.text.trim()),
        'waktu': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _formKey.currentState!.reset();
      _namaCtrl.clear();
      _masukCtrl.clear();
      _keluarCtrl.clear();
      _kodeCtrl.clear();
      _stokCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data barang berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencatatan Stok Barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                ),
                validator: _validasiNama,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _masukCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Masuk Barang',
                  hintText: 'contoh: 19-10-2026',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _wajibIsi(v, 'Tanggal masuk'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keluarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Keluar Barang',
                  hintText: 'contoh: 25-10-2026',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _wajibIsi(v, 'Tanggal keluar'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kodeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Kode Barang',
                  helperText: 'Min. 6 angka, berakhiran 94',
                  border: OutlineInputBorder(),
                ),
                validator: _validasiKode,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stokCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok',
                  border: OutlineInputBorder(),
                ),
                validator: _validasiStok,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _simpanBarang,
                  child: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Simpan Barang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}