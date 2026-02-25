import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Royal Stock Pro',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- شاشة تسجيل الدخول ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();

  void _login() {
    if (_user.text.trim() == "admin" && _pass.text.trim() == "1234") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("بيانات الدخول خاطئة! (admin / 1234)"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 60,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "STOCK MASTER",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInput(_user, "اسم المستخدم", Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildInput(
                        _pass,
                        "كلمة المرور",
                        Icons.lock_outline,
                        isPass: true,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _login,
                          child: const Text(
                            "دخول للنظام",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPass = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withAlpha(15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- الشاشة الرئيسية ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  final _pages = [const InventoryApp(), const ReportsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: Colors.cyanAccent,
        backgroundColor: const Color(0xFF0A0E21),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: "المخزن",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: "التقارير",
          ),
        ],
      ),
    );
  }
}

// --- صفحة المخزن ---
class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key});
  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  List all = [];
  List filtered = [];
  bool loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products'),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          all = json.decode(res.body);
          filtered = all;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onSearch(String val) {
    setState(() {
      filtered = all
          .where(
            (p) =>
                p['name'].toString().toLowerCase().contains(
                  val.toLowerCase(),
                ) ||
                p['barcode'].toString().contains(val),
          )
          .toList();
    });
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String code = barcodes.first.rawValue ?? "";
              Navigator.pop(ctx);
              _showProductDialog(barcode: code);
            }
          },
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final res = await http.delete(
      Uri.parse('http://10.0.2.2:5000/api/products/$id'),
    );
    if (res.statusCode == 200) _fetch();
  }

  void _showProductDialog({Map? product, String? barcode}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product['name'] : '');
    final priceCtrl = TextEditingController(
      text: isEdit ? product['price'].toString() : '',
    );
    final stockCtrl = TextEditingController(
      text: isEdit ? product['stock'].toString() : '',
    );
    final bCode = barcode ?? (isEdit ? product['barcode'] : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title: Text(isEdit ? "تعديل منتج" : "إضافة منتج جديد"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bCode != null && bCode.isNotEmpty)
              Text(
                "الباركود: $bCode",
                style: const TextStyle(color: Colors.cyanAccent),
              ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "الاسم"),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "السعر"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(labelText: "الكمية"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                "name": nameCtrl.text,
                "price": double.parse(priceCtrl.text),
                "stock": int.parse(stockCtrl.text),
                "barcode":
                    bCode ?? DateTime.now().millisecondsSinceEpoch.toString(),
              };
              final url = isEdit
                  ? 'http://10.0.2.2:5000/api/products/${product['id']}'
                  : 'http://10.0.2.2:5000/api/products';
              isEdit
                  ? await http.put(
                      Uri.parse(url),
                      headers: {"Content-Type": "application/json"},
                      body: json.encode(data),
                    )
                  : await http.post(
                      Uri.parse(url),
                      headers: {"Content-Type": "application/json"},
                      body: json.encode(data),
                    );
              _fetch();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المخزن الملكي 💎"),
        actions: [
          IconButton(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "بحث بالاسم أو الباركود...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withAlpha(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                return Card(
                  color: Colors.white.withAlpha(10),
                  child: ListTile(
                    onTap: () => _showProductDialog(product: p),
                    title: Text(
                      p['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${p['price']} ج.م | باركود: ${p['barcode']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${p['stock']}",
                          style: TextStyle(
                            color: (p['stock'] < 5)
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _delete(p['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// --- صفحة التقارير الحديثة والممتازة ---
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/products'),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() {
          products = json.decode(res.body);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalValue = 0;
    int lowStock = 0;
    for (var p in products) {
      totalValue += (p['price'] * p['stock']);
      if (p['stock'] < 5) lowStock++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة التقارير الذكية 📊"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatCard(
                    "إجمالي قيمة المخزن",
                    "${totalValue.toStringAsFixed(2)} ج.م",
                    Icons.account_balance_wallet_rounded,
                    Colors.greenAccent,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "الأصناف",
                          "${products.length}",
                          Icons.category_rounded,
                          Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          "نواقص",
                          "$lowStock",
                          Icons.warning_amber_rounded,
                          Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "حالة المخزون الحالية",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: products
                          .take(5)
                          .map(
                            (p) => ListTile(
                              leading: Icon(
                                Icons.circle,
                                size: 12,
                                color: p['stock'] < 5
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                              ),
                              title: Text(p['name']),
                              trailing: Text("${p['stock']} قطعة"),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withAlpha(50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            val,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
