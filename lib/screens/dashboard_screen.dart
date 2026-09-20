import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Listas globales compartidas (Añadido el campo 'stock')
  List<Map<String, dynamic>> _productsList = [
    {'id': 'p1', 'name': 'Nutella Cookie', 'price': 260.0, 'cost': 95.0, 'stock': 15, 'description': 'Galleta artesanal rellena de abundante Nutella.'},
    {'id': 'p2', 'name': 'S´more brownie Cookie', 'price': 250.0, 'cost': 90.0, 'stock': 10, 'description': 'Combinación de brownie, galleta y marshmallows.'},
    {'id': 'p3', 'name': 'Red Velvet Cookie', 'price': 245.0, 'cost': 85.0, 'stock': 8, 'description': 'Galleta de terciopelo rojo con chispas de choc. blanco.'},
    {'id': 'p4', 'name': 'Biscoff Cookie', 'price': 215.0, 'cost': 75.0, 'stock': 12, 'description': 'Galleta infusionada con crema y galleta Lotus Biscoff.'},
    {'id': 'p5', 'name': 'Guava Cookie', 'price': 215.0, 'cost': 70.0, 'stock': 5, 'description': 'Galleta suave con relleno artesanal de guayaba.'},
    {'id': 'p6', 'name': 'Chocolate Chips Cookie', 'price': 205.0, 'cost': 65.0, 'stock': 20, 'description': 'La clásica galleta dorada cargada de chispas.'},
  ];

  List<Map<String, dynamic>> _salesList = [];
  List<Map<String, dynamic>> _expensesList = [];

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  // Cargar datos al abrir la App
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    final productsJson = prefs.getString('dl_products');
    if (productsJson != null) {
      final List decoded = jsonDecode(productsJson);
      _productsList = decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        // Compatibilidad: Si un producto viejo no tiene stock, le asignamos 0 por defecto
        if (!map.containsKey('stock')) {
          map['stock'] = 0;
        }
        return map;
      }).toList();
    }

    final salesJson = prefs.getString('dl_sales');
    if (salesJson != null) {
      final List decoded = jsonDecode(salesJson);
      _salesList = decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['fecha'] = DateTime.parse(map['fecha']);
        map['items'] = (map['items'] as List).map((i) => Map<String, dynamic>.from(i)).toList();
        return map;
      }).toList();
    }

    final expensesJson = prefs.getString('dl_expenses');
    if (expensesJson != null) {
      final List decoded = jsonDecode(expensesJson);
      _expensesList = decoded.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['fecha'] = DateTime.parse(map['fecha']);
        return map;
      }).toList();
    }

    setState(() {});
  }

  // Guardar datos
  Future<void> _saveStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('dl_products', jsonEncode(_productsList));

    final salesEncodable = _salesList.map((s) {
      final copy = Map<String, dynamic>.from(s);
      copy['fecha'] = (s['fecha'] as DateTime).toIso8601String();
      return copy;
    }).toList();
    await prefs.setString('dl_sales', jsonEncode(salesEncodable));

    final expensesEncodable = _expensesList.map((e) {
      final copy = Map<String, dynamic>.from(e);
      copy['fecha'] = (e['fecha'] as DateTime).toIso8601String();
      return copy;
    }).toList();
    await prefs.setString('dl_expenses', jsonEncode(expensesEncodable));
  }

  void _onDataChanged() {
    setState(() {});
    _saveStoredData();
  }
  
  // (Deja el resto del build y Scaffold igual) ...

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeTab(
        salesList: _salesList,
        expensesList: _expensesList,
        productsList: _productsList,
      ),
      VentasTab(
        salesList: _salesList,
        productsList: _productsList,
        onUpdate: _onDataChanged,
      ),
      GastosTab(
        expensesList: _expensesList,
        onUpdate: _onDataChanged,
      ),
      ProductosTab(
        productsList: _productsList,
        onUpdate: _onDataChanged,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A2A18),
        elevation: 0,
        title: Text(
          _getTitle(_currentIndex),
          style: const TextStyle(color: Color(0xFFE8DAD3), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE8DAD3),
                child: Icon(Icons.person, color: Color(0xFF4A2A18), size: 20),
              ),
              onSelected: (value) async {
                if (value == 'logout') {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);

                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF4A2A18),
        selectedItemColor: const Color(0xFFE8DAD3),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Ventas'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Gastos'),
          BottomNavigationBarItem(icon: Icon(Icons.cookie), label: 'Productos'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Panel Principal';
      case 1: return 'Gestión de Ventas';
      case 2: return 'Gastos Operativos';
      case 3: return 'Catálogo de Productos';
      default: return 'Dolce Legado';
    }
  }
}

// ---------------------------------------------------------
// PESTAÑA 1: INICIO (Dashboard Dinámico)
// ---------------------------------------------------------
class HomeTab extends StatefulWidget {
  final List<Map<String, dynamic>> salesList;
  final List<Map<String, dynamic>> expensesList;
  final List<Map<String, dynamic>> productsList;

  const HomeTab({
    super.key,
    required this.salesList,
    required this.expensesList,
    required this.productsList,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final completedSales = widget.salesList.where((s) => s['estado'] == 'Completada').toList();

    final double totalEarnings = completedSales.fold(0.0, (sum, s) => sum + (s['total'] as double));
    final double totalExpenses = widget.expensesList.fold(0.0, (sum, e) => sum + (e['monto'] as double));
    final int totalOrders = completedSales.length;

    // Conteo para Producto Estrella y PieChart
    final Map<String, int> productSalesCount = {};
    for (var sale in completedSales) {
      for (var item in (sale['items'] as List)) {
        final name = item['name'] as String;
        final qty = item['qty'] as int;
        productSalesCount[name] = (productSalesCount[name] ?? 0) + qty;
      }
    }

    String topProductName = 'Sin ventas registradas';
    int topProductQty = 0;
    double topProductPrice = 0.0;

    productSalesCount.forEach((name, qty) {
      if (qty > topProductQty) {
        topProductQty = qty;
        topProductName = name;
      }
    });

    if (topProductQty > 0) {
      final match = widget.productsList.firstWhere(
        (p) => p['name'] == topProductName,
        orElse: () => {'price': 0.0},
      );
      topProductPrice = (match['price'] as num).toDouble();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard('Cantidad de Ventas', '$totalOrders pedidos completados', const Color(0xFF4A2A18), isFullWidth: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Ganancias', '${totalEarnings.toStringAsFixed(2)} DOP\$', Colors.green[700]!)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Gastos', '${totalExpenses.toStringAsFixed(2)} DOP\$', Colors.red[700]!)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Producto Estrella',
            style: TextStyle(color: Color(0xFF4A2A18), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8DAD3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DAD3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cookie, color: Color(0xFF4A2A18), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topProductName, style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        topProductQty > 0 ? 'El más vendido con $topProductQty unidades.' : 'Registra ventas para ver el líder.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text('${topProductPrice.toStringAsFixed(2)} DOP\$', style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Flujo Financiero',
                style: TextStyle(color: Color(0xFF4A2A18), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ToggleButtons(
                isSelected: [_isWeekly, !_isWeekly],
                onPressed: (index) => setState(() => _isWeekly = index == 0),
                color: const Color(0xFF4A2A18),
                selectedColor: Colors.white,
                fillColor: const Color(0xFF4A2A18),
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 30, minWidth: 60),
                children: const [
                  Text('Semana', style: TextStyle(fontSize: 12)),
                  Text('Mes', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8DAD3)),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (_isWeekly) {
                          const titles = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
                          if (index >= 0 && index < titles.length) {
                            return Text(titles[index], style: const TextStyle(fontSize: 10, color: Colors.grey));
                          }
                        } else {
                          const titles = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                          if (index >= 0 && index < titles.length) {
                            return Text(titles[index], style: const TextStyle(fontSize: 9, color: Colors.grey));
                          }
                        }
                        return const Text('', style: TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _calculateRealBarGroups(completedSales, widget.expensesList),
              ),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Distribución de Productos Vendidos',
            style: TextStyle(color: Color(0xFF4A2A18), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8DAD3)),
            ),
            child: productSalesCount.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('No hay datos de ventas para mostrar la gráfica.', style: TextStyle(color: Colors.grey))),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: _buildPieSections(productSalesCount),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: _buildPieLegends(productSalesCount),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Agrupación de Ganancias y Gastos por Semana/Mes real
  List<BarChartGroupData> _calculateRealBarGroups(
    List<Map<String, dynamic>> sales,
    List<Map<String, dynamic>> expenses,
  ) {
    int slots = _isWeekly ? 7 : 12;
    List<double> ganancias = List.filled(slots, 0.0);
    List<double> gastos = List.filled(slots, 0.0);

    for (var s in sales) {
      final DateTime date = s['fecha'];
      final double total = s['total'] as double;
      if (_isWeekly) {
        int index = date.weekday - 1; // 0 (Lun) a 6 (Dom)
        if (index >= 0 && index < 7) ganancias[index] += total;
      } else {
        int index = date.month - 1; // 0 (Ene) a 11 (Dic)
        if (index >= 0 && index < 12) ganancias[index] += total;
      }
    }

    for (var e in expenses) {
      final DateTime date = e['fecha'];
      final double amount = e['monto'] as double;
      if (_isWeekly) {
        int index = date.weekday - 1;
        if (index >= 0 && index < 7) gastos[index] += amount;
      } else {
        int index = date.month - 1;
        if (index >= 0 && index < 12) gastos[index] += amount;
      }
    }

    return List.generate(slots, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: ganancias[i], color: Colors.green[700], width: 6, borderRadius: BorderRadius.circular(4)),
          BarChartRodData(toY: gastos[i], color: Colors.red[700], width: 6, borderRadius: BorderRadius.circular(4)),
        ],
      );
    });
  }

  // Paleta de colores para el gráfico circular
  final List<Color> _chartColors = [
    const Color(0xFF4A2A18),
    Colors.amber[800]!,
    Colors.orange[400]!,
    Colors.deepOrange[300]!,
    Colors.brown[300]!,
    Colors.grey[500]!,
  ];

  List<PieChartSectionData> _buildPieSections(Map<String, int> counts) {
    final int totalItems = counts.values.fold(0, (a, b) => a + b);
    int index = 0;

    return counts.entries.map((entry) {
      final color = _chartColors[index % _chartColors.length];
      final percentage = totalItems > 0 ? (entry.value / totalItems * 100).toStringAsFixed(0) : '0';
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: 45,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<Widget> _buildPieLegends(Map<String, int> counts) {
    int index = 0;
    return counts.entries.map((entry) {
      final color = _chartColors[index % _chartColors.length];
      index++;
      return _buildLegendItem(color, '${entry.key} (${entry.value} uds)');
    }).toList();
  }

  Widget _buildMetricCard(String title, String value, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DAD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Color(0xFF4A2A18), fontSize: 13)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// PESTAÑA 2: VENTAS (Sistema Completo de Registro y Control)
// ---------------------------------------------------------
class VentasTab extends StatefulWidget {
  final List<Map<String, dynamic>> salesList;
  final List<Map<String, dynamic>> productsList;
  final VoidCallback onUpdate;

  const VentasTab({
    super.key,
    required this.salesList,
    required this.productsList,
    required this.onUpdate,
  });

  @override
  State<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends State<VentasTab> {
  String _selectedFilter = 'Todas';

  double get _totalCobrado => widget.salesList
      .where((s) => s['estado'] == 'Completada')
      .fold(0.0, (sum, item) => sum + (item['total'] as double));

  double get _totalPendiente => widget.salesList
      .where((s) => s['estado'] == 'Pendiente')
      .fold(0.0, (sum, item) => sum + (item['total'] as double));

  List<Map<String, dynamic>> get _filteredSales {
    if (_selectedFilter == 'Pendientes') {
      return widget.salesList.where((s) => s['estado'] == 'Pendiente').toList();
    } else if (_selectedFilter == 'Completadas') {
      return widget.salesList.where((s) => s['estado'] == 'Completada').toList();
    }
    return widget.salesList;
  }

  // --- NUEVA FUNCIÓN: Alerta de Confirmación Genérica ---
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2A18)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF9F9F9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cobrado', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${_totalCobrado.toStringAsFixed(2)} DOP\$',
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: const Color(0xFFE8DAD3)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Por Cobrar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${_totalPendiente.toStringAsFixed(2)} DOP\$',
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['Todas', 'Pendientes', 'Completadas'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4A2A18),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A2A18)),
                    backgroundColor: const Color(0xFFF9F9F9),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay ventas registradas', style: TextStyle(color: Colors.grey)));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final saleMap = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    saleMap['id'] ??= docId;

                    final String cliente = saleMap['cliente']?.toString() ?? 'Cliente general';
                    final double total = (saleMap['total'] as num?)?.toDouble() ?? 0.0;
                    final String estado = saleMap['estado']?.toString() ?? 'Completado';
                    final String metodoPago = saleMap['metodoPago']?.toString() ?? 'Efectivo';
                    final items = saleMap['items'] as List<dynamic>? ?? [];

                    return Card(
                      color: const Color(0xFFF9F9F9),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE8DAD3), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cliente,
                              style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${total.toStringAsFixed(2)} DOP\$',
                              style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Método: $metodoPago • Estado: $estado', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Artículos: ${items.length}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showSaleModal(context, existingSale: saleMap, index: index);
                            } else if (value == 'delete') {
                              await FirebaseFirestore.instance.collection('ventas').doc(docId).delete();
                              widget.onUpdate();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4A2A18)),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Eliminar'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8DAD3),
        icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF4A2A18)),
        label: const Text('Nueva Venta', style: TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
        onPressed: () => _showSaleModal(context),
      ),
    );
  }

 void _confirmDelete(BuildContext context, int index) {
    _showConfirmDialog('¿Eliminar orden?', 'Esta acción quitará el registro y devolverá los productos al inventario.').then((confirm) {
      if (confirm == true) {
        // --- DEVOLVER STOCK AL INVENTARIO ---
        final sale = widget.salesList[index];
        for (var item in sale['items']) {
          final pIndex = widget.productsList.indexWhere((p) => p['name'] == item['name']);
          if (pIndex != -1) {
            widget.productsList[pIndex]['stock'] = (widget.productsList[pIndex]['stock'] ?? 0) + (item['qty'] as int);
          }
        }
        widget.salesList.removeAt(index);
        widget.onUpdate();
      }
    });
  }

  void _showSaleModal(BuildContext context, {Map<String, dynamic>? existingSale, int? index}) {
    final clientController = TextEditingController(text: existingSale?['cliente'] ?? '');
    // Inician en null para estar en blanco al crear, o cargan si se está editando
    String? selectedPayment = existingSale?['metodoPago'];
    String? selectedStatus = existingSale?['estado'];

    Map<String, int> selectedQuantities = {for (var item in widget.productsList) item['name']: 0};
    if (existingSale != null) {
      for (var item in existingSale['items']) {
        selectedQuantities[item['name']] = item['qty'];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double calculateTotal() {
              double total = 0.0;
              for (var item in widget.productsList) {
                final qty = selectedQuantities[item['name']] ?? 0;
                total += qty * (item['price'] as double);
              }
              return total;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingSale == null ? 'Registrar Nueva Venta' : 'Editar Venta',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2A18)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: clientController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Cliente',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Seleccionar Productos:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A2A18))),
                    const SizedBox(height: 8),
                    
                    // --- LISTA DE PRODUCTOS CON VALIDACIÓN DE STOCK ---
                    ...widget.productsList.map((product) {
                      final name = product['name'] as String;
                      final price = (product['price'] as num).toDouble();
                      final currentStock = (product['stock'] ?? 0) as int;
                      
                      int availableStock = currentStock;
                      if (existingSale != null) {
                        final oldItem = (existingSale['items'] as List).firstWhere((i) => i['name'] == name, orElse: () => <String, dynamic>{});
                        if (oldItem.isNotEmpty) availableStock += (oldItem['qty'] as int);
                      }
                      
                      final qty = selectedQuantities[name] ?? 0;
                      final isOutOfStock = availableStock <= 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$name (${price.toStringAsFixed(0)} DOP\$)'),
                                  Text(
                                    isOutOfStock ? 'Agotado' : 'Disponibles: $availableStock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isOutOfStock ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: qty > 0 ? () => setModalState(() => selectedQuantities[name] = qty - 1) : null,
                                ),
                                Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4A2A18)),
                                  onPressed: qty < availableStock ? () => setModalState(() => selectedQuantities[name] = qty + 1) : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPayment,
                            decoration: const InputDecoration(labelText: 'Pago', hintText: 'Seleccionar'),
                            items: ['Transferencia', 'Efectivo'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) => setModalState(() => selectedPayment = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: const InputDecoration(labelText: 'Estado', hintText: 'Seleccionar'),
                            items: ['Completada', 'Pendiente'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setModalState(() => selectedStatus = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${calculateTotal().toStringAsFixed(2)} DOP\$',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A2A18),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: calculateTotal() == 0 || 
                                   clientController.text.trim().isEmpty || 
                                   selectedPayment == null || 
                                   selectedStatus == null
                            ? null
                            : () async {
                                final totalVenta = calculateTotal();
                                final isEditing = existingSale != null;

                                List<TextSpan> desgloseSpans = [];
                                selectedQuantities.forEach((nombre, cantidad) {
                                  if (cantidad > 0) {
                                    final producto = widget.productsList.firstWhere((p) => p['name'] == nombre);
                                    final precio = (producto['price'] as num).toDouble();
                                    desgloseSpans.add(TextSpan(
                                      text: '$cantidad x $nombre = ${(cantidad * precio).toStringAsFixed(2)} DOP\$\n',
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ));
                                  }
                                });

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(isEditing ? 'Confirmar Actualización' : 'Confirmar Venta', style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
                                    content: SingleChildScrollView(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                                          children: [
                                            const TextSpan(text: 'Cliente: '),
                                            TextSpan(text: '${clientController.text.trim()}\n\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const TextSpan(text: 'Detalle de la orden:\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A2A18))),
                                            ...desgloseSpans,
                                            const TextSpan(text: '\nTotal a cobrar: '),
                                            TextSpan(text: '${totalVenta.toStringAsFixed(2)} DOP\$\n\n', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 18)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Revisar', style: TextStyle(color: Colors.grey))),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2A18)),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(isEditing ? 'Sí, actualizar' : 'Sí, registrar', style: const TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return; 

                                if (isEditing) {
                                  for (var oldItem in existingSale['items']) {
                                    final pIndex = widget.productsList.indexWhere((p) => p['name'] == oldItem['name']);
                                    if (pIndex != -1) {
                                      widget.productsList[pIndex]['stock'] = (widget.productsList[pIndex]['stock'] ?? 0) + (oldItem['qty'] as int);
                                    }
                                  }
                                }

                                final itemsList = <Map<String, dynamic>>[];
                                selectedQuantities.forEach((key, value) {
                                  if (value > 0) {
                                    final pIndex = widget.productsList.indexWhere((p) => p['name'] == key);
                                    if (pIndex != -1) {
                                      widget.productsList[pIndex]['stock'] = (widget.productsList[pIndex]['stock'] ?? 0) - value;
                                      itemsList.add({'name': key, 'qty': value, 'price': widget.productsList[pIndex]['price']});
                                    }
                                  }
                                });

                                // --- 1. INICIO DEL GUARDADO EN FIREBASE ---
                                    try {
                                      CollectionReference ventasDB = FirebaseFirestore.instance.collection('ventas');
                                      
                                      Map<String, dynamic> datosParaFirebase = {
                                        'cliente': clientController.text.trim(),
                                        'estado': selectedStatus!,
                                        'metodoPago': selectedPayment!,
                                        'items': itemsList,
                                        'total': totalVenta,
                                      };

                                      if (isEditing && existingSale['id'] != null) {
                                        // Si estás editando, actualiza el documento en Firebase
                                        await ventasDB.doc(existingSale['id'].toString()).set(datosParaFirebase, SetOptions(merge: true));
                                      } else {
                                        // Si es una nueva venta, incluye la hora exacta del servidor
                                        datosParaFirebase['fecha'] = FieldValue.serverTimestamp();
                                        await ventasDB.add(datosParaFirebase);
                                      }
                                    } catch (e) {
                                      print('Error al guardar en Firebase: $e');
                                    }
                                    // --- FIN DEL GUARDADO EN FIREBASE ---

                                    // --- 2. GUARDADO LOCAL (Mantiene tu interfaz funcionando sin recargar) ---
                                    final saleData = {
                                      'id': existingSale?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                      'cliente': clientController.text.trim(),
                                      'fecha': existingSale?['fecha'] ?? DateTime.now(),
                                      'estado': selectedStatus!,
                                      'metodoPago': selectedPayment!,
                                      'items': itemsList,
                                      'total': totalVenta,
                                    };

                                    // Ajuste fecha sintaxis segura:
                                    saleData['fecha'] = existingSale?['fecha'] ?? DateTime.now();

                                    if (isEditing && index != null) {
                                      widget.salesList[index] = saleData;
                                    } else {
                                      widget.salesList.insert(0, saleData);
                                    }
                                    
                                    widget.onUpdate();
                                    if (context.mounted) Navigator.pop(context);
                                  },
                            child: Text(existingSale == null ? 'GUARDAR VENTA' : 'ACTUALIZAR VENTA', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    } // <--- Faltaba esta llave de cierre para _VentasTabState

// ---------------------------------------------------------
// PESTAÑA 3: GASTOS (Registro Categorizado y Control Operativo)
// ---------------------------------------------------------

class GastosTab extends StatefulWidget {
  final List<Map<String, dynamic>> expensesList;
  final VoidCallback onUpdate;

  const GastosTab({
    super.key,
    required this.expensesList,
    required this.onUpdate,
  });

  @override
  State<GastosTab> createState() => _GastosTabState();
}

class _GastosTabState extends State<GastosTab> {
  String _selectedCategoryFilter = 'Todos';
  final List<String> _categories = ['Insumos', 'Servicios', 'Empaques', 'Otros'];

  double get _totalGastos => widget.expensesList.fold(
        0.0,
        (sum, item) => sum + ((item['monto'] as num?)?.toDouble() ?? 0.0),
      );

  List<Map<String, dynamic>> get _filteredExpenses {
    if (_selectedCategoryFilter != 'Todos') {
      return widget.expensesList.where((e) => e['categoria'] == _selectedCategoryFilter).toList();
    }
    return widget.expensesList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: const Color(0xFFF9F9F9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total de Gastos Registrados', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '${_totalGastos.toStringAsFixed(2)} DOP\$',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['Todos', ..._categories].map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4A2A18),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A2A18)),
                    backgroundColor: const Color(0xFFF9F9F9),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategoryFilter = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('gastos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay gastos registrados', style: TextStyle(color: Colors.grey)));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final expenseMap = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    expenseMap['id'] ??= docId;

                    final String concepto = expenseMap['concepto']?.toString() ?? 'Sin concepto';
                    final String categoria = expenseMap['categoria']?.toString() ?? 'General';
                    final double monto = (expenseMap['monto'] as num?)?.toDouble() ?? 0.0;
                    final String metodoPago = expenseMap['metodoPago']?.toString() ?? 'Efectivo';

                    return Card(
                      color: const Color(0xFFF9F9F9),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE8DAD3), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              concepto,
                              style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${monto.toStringAsFixed(2)} DOP\$',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Categoría: $categoria • Método: $metodoPago', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showExpenseModal(context, existingExpense: expenseMap, index: index);
                            } else if (value == 'delete') {
                              await FirebaseFirestore.instance.collection('gastos').doc(docId).delete();
                              widget.onUpdate();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4A2A18)),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Eliminar'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8DAD3),
        icon: const Icon(Icons.add, color: Color(0xFF4A2A18)),
        label: const Text('Registrar Gasto', style: TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
        onPressed: () => _showExpenseModal(context),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    if (index < 0 || index >= widget.expensesList.length) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar gasto?'),
        content: const Text('Esta acción descontará el registro del reporte financiero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              widget.expensesList.removeAt(index);
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExpenseModal(BuildContext context, {Map<String, dynamic>? existingExpense, int? index}) {
    final conceptController = TextEditingController(text: existingExpense?['concepto']?.toString() ?? '');
    final amountController = TextEditingController(
      text: existingExpense != null ? existingExpense['monto'].toString() : '',
    );
    String selectedCategory = existingExpense?['categoria']?.toString() ?? _categories.first;
    String selectedPayment = existingExpense?['metodoPago']?.toString() ?? 'Transferencia';
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingExpense == null ? 'Registrar Nuevo Gasto' : 'Editar Gasto',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2A18)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: conceptController,
                      decoration: InputDecoration(
                        labelText: 'Concepto (ej. Saco de Harina, Gas, Cajas)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto en DOP\$',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _categories.contains(selectedCategory) ? selectedCategory : _categories.first,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPayment,
                            decoration: const InputDecoration(labelText: 'Método de Pago'),
                            items: ['Transferencia', 'Efectivo'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedPayment = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A2A18),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final cleanedAmount = amountController.text.replaceAll(',', '.').trim();
                          final double? amount = double.tryParse(cleanedAmount);

                          if (conceptController.text.trim().isEmpty) {
                            setModalState(() => errorMessage = 'Por favor ingresa un concepto.');
                            return;
                          }
                          if (amount == null || amount <= 0) {
                            setModalState(() => errorMessage = 'Ingresa un monto válido mayor a 0.');
                            return;
                          }
                          // --- 1. INICIO DEL GUARDADO EN FIREBASE ---
                                    try {
                                      CollectionReference gastosDB = FirebaseFirestore.instance.collection('gastos');
                                      
                                      Map<String, dynamic> datosParaFirebase = {
                                        'concepto': conceptController.text.trim(),
                                        'categoria': selectedCategory,
                                        'monto': amount,
                                        'metodoPago': selectedPayment,
                                      };

                                      if (existingExpense != null && existingExpense['id'] != null) {
                                        // Si estás editando, actualiza el documento en Firebase
                                        await gastosDB.doc(existingExpense['id'].toString()).set(datosParaFirebase, SetOptions(merge: true));
                                      } else {
                                        // Si es un nuevo gasto, incluye la hora exacta del servidor
                                        datosParaFirebase['fecha'] = FieldValue.serverTimestamp();
                                        await gastosDB.add(datosParaFirebase);
                                      }
                                    } catch (e) {
                                      print('Error al guardar gasto en Firebase: $e');
                                    }
                                    // --- FIN DEL GUARDADO EN FIREBASE ---

                                    // --- 2. GUARDADO LOCAL (Mantiene tu interfaz funcionando sin recargar) ---
                                    final expenseData = {
                                      'id': existingExpense?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                      'concepto': conceptController.text.trim(),
                                      'categoria': selectedCategory,
                                      'monto': amount,
                                      'fecha': existingExpense?['fecha'] ?? DateTime.now(),
                                      'metodoPago': selectedPayment,
                                    };

                                    if (existingExpense != null && index != null && index >= 0 && index < widget.expensesList.length) {
                                      widget.expensesList[index] = expenseData;
                                    } else {
                                      widget.expensesList.insert(0, expenseData);
                                    }
                                    
                                    widget.onUpdate();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    existingExpense == null ? 'GUARDAR GASTO' : 'ACTUALIZAR GASTO',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }
          }

// ---------------------------------------------------------
// PESTAÑA 4: PRODUCTOS (Gestión Dinámica y Expansión)
// ---------------------------------------------------------

class ProductosTab extends StatefulWidget {
  final List<Map<String, dynamic>> productsList;
  final VoidCallback onUpdate;

  const ProductosTab({
    super.key,
    required this.productsList,
    required this.onUpdate,
  });

  @override
  State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: const Color(0xFFF9F9F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Catálogo Activo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('productos').snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Text(
                          '$count Productos',
                          style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 18),
                        );
                      },
                    ),
                  ],
                ),
                const Icon(Icons.cookie_outlined, color: Color(0xFF4A2A18), size: 28),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('productos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay productos en el catálogo', style: TextStyle(color: Colors.grey)));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    // SOLUCIÓN: Crear una copia del mapa para evitar el error de solo lectura
                    final rawData = docs[index].data() as Map<String, dynamic>? ?? {};
                    final productDataMap = Map<String, dynamic>.from(rawData);
                    
                    final docId = docs[index].id;
                    productDataMap['id'] = docId;

                    final double itemPrice = (productDataMap['price'] as num?)?.toDouble() ?? 0.0;
                    final double itemCost = (productDataMap['cost'] as num?)?.toDouble() ?? 0.0;
                    final int itemStock = (productDataMap['stock'] as num?)?.toInt() ?? 0;
                    final double itemMargin = itemPrice - itemCost;

                    return Card(
                      color: const Color(0xFFF9F9F9),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE8DAD3), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              productDataMap['name']?.toString() ?? 'Sin nombre',
                              style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              itemStock > 0 ? 'Stock: $itemStock' : 'Agotado',
                              style: TextStyle(
                                color: itemStock > 0 ? Colors.blue[700] : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(productDataMap['description']?.toString() ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(
                              'Costo est.: ${itemCost.toStringAsFixed(2)} DOP\$ • Margen: ${itemMargin.toStringAsFixed(2)} DOP\$',
                              style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${itemPrice.toStringAsFixed(2)} DOP\$',
                              style: const TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showProductModal(context, existingProduct: productDataMap, index: index);
                                } else if (value == 'delete') {
                                  await FirebaseFirestore.instance.collection('productos').doc(docId).delete();
                                  widget.onUpdate();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: Color(0xFF4A2A18)),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text('Eliminar'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8DAD3),
        icon: const Icon(Icons.add, color: Color(0xFF4A2A18)),
        label: const Text('Nuevo Producto', style: TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
        onPressed: () => _showProductModal(context),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, int index) {
    if (index < 0 || index >= widget.productsList.length) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?', style: TextStyle(color: Color(0xFF4A2A18), fontWeight: FontWeight.bold)),
        content: const Text('Esta acción eliminará el producto del catálogo de forma permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2A18)),
            onPressed: () {
              widget.productsList.removeAt(index);
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductModal(BuildContext context, {Map<String, dynamic>? existingProduct, int? index}) {
    final nameController = TextEditingController(text: existingProduct?['name']?.toString() ?? '');
    final descController = TextEditingController(text: existingProduct?['description']?.toString() ?? '');
    final priceController = TextEditingController(
      text: existingProduct != null ? existingProduct['price'].toString() : '',
    );
    final costController = TextEditingController(
      text: existingProduct != null ? existingProduct['cost'].toString() : '',
    );
    final stockController = TextEditingController(
      text: existingProduct != null ? existingProduct['stock'].toString() : '0',
    );
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingProduct == null ? 'Nuevo Producto' : 'Editar Producto',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2A18)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Producto',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Costo (DOP\$)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Precio (DOP\$)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock Inicial',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A2A18),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final localCost = double.tryParse(costController.text.replaceAll(',', '.')) ?? 0.0;
                            final localPrice = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
                            final int localStock = int.tryParse(stockController.text) ?? 0;

                            if (nameController.text.trim().isEmpty) {
                              setModalState(() => errorMessage = 'El nombre es obligatorio.');
                              return;
                            }
                            if (localPrice <= 0) {
                              setModalState(() => errorMessage = 'El precio debe ser mayor a 0.');
                              return;
                            }

                            final productData = {
                              'id': existingProduct?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              'name': nameController.text.trim(),
                              'description': descController.text.trim(),
                              'cost': localCost,
                              'price': localPrice,
                              'stock': localStock,
                            };

                            try {
                              CollectionReference productosDB = FirebaseFirestore.instance.collection('productos');
                              if (existingProduct != null && existingProduct['id'] != null) {
                                await productosDB.doc(existingProduct['id'].toString()).set(productData, SetOptions(merge: true));
                              } else {
                                await productosDB.add(productData);
                              }
                            } catch (e) {
                              print('Error al guardar producto en Firebase: $e');
                            }

                            if (existingProduct != null && index != null && index >= 0 && index < widget.productsList.length) {
                              widget.productsList[index] = productData;
                            } else {
                              widget.productsList.insert(0, productData);
                            }
                            widget.onUpdate();
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(
                            existingProduct == null ? 'GUARDAR PRODUCTO' : 'ACTUALIZAR PRODUCTO',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ], // Cierra Column children
                  ), // Cierra Column
                ), // Cierra SingleChildScrollView
              ); // Cierra Padding
            }, // Cierra builder de StatefulBuilder
          ); // Cierra StatefulBuilder
        }, // Cierra builder de showModalBottomSheet
      ); // Cierra showModalBottomSheet
    } // Cierra _showProductModal
  } // Cierra _ProductosTabState