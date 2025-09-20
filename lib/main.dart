import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(CryptoAdapter());
  await Hive.openBox<Crypto>('cryptoPortfolio');
  runApp(CryptoPortfolioApp());
}

@HiveType(typeId: 0)
class Crypto {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  Crypto({required this.name, required this.amount});
}

class CryptoAdapter extends TypeAdapter<Crypto> {
  @override
  final typeId = 0;

  @override
  Crypto read(BinaryReader reader) {
    return Crypto(
      name: reader.readString(),
      amount: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Crypto obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.amount);
  }
}

class CryptoPortfolioApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      home: PortfolioScreen(),
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isEditing = false;
  Set<int> _selectedIndexes = {}; // For multi-selection
  String _currency = 'USD'; // Default currency
  bool _isSelecting = false; // For tracking selection mode

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _addCrypto() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isNotEmpty && amount != null) {
      final crypto = Crypto(name: name, amount: amount);
      Hive.box<Crypto>('cryptoPortfolio').add(crypto);

      _nameController.clear();
      _amountController.clear();
      Navigator.of(context).pop();
    }
  }

  void _showAddCryptoBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Cryptocurrency Name'),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addCrypto,
              child: Text('Add Cryptocurrency'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }

      // Exit selection mode if no items are selected
      if (_selectedIndexes.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  void _deleteSelectedItems(Box<Crypto> box) {
    setState(() {
      _selectedIndexes.toList().forEach((index) {
        box.deleteAt(index);
      });
      _selectedIndexes.clear();
      // If all items are deleted, reset the selection mode
      if (box.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  void _editSelectedItems(Box<Crypto> box) {
    if (_selectedIndexes.length == 1) {
      final index = _selectedIndexes.first;
      final crypto = box.getAt(index) as Crypto;

      _nameController.text = crypto.name;
      _amountController.text = crypto.amount.toString();

      showModalBottomSheet(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Cryptocurrency Name'),
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final editedCrypto = Crypto(
                    name: _nameController.text.trim(),
                    amount: double.tryParse(_amountController.text.trim()) ?? 0,
                  );

                  box.putAt(index, editedCrypto);

                  _nameController.clear();
                  _amountController.clear();
                  Navigator.of(context).pop();
                },
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('USD'),
              onTap: () {
                setState(() {
                  _currency = 'USD';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('EUR'),
              onTap: () {
                setState(() {
                  _currency = 'EUR';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('GBP'),
              onTap: () {
                setState(() {
                  _currency = 'GBP';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('AUD'),
              onTap: () {
                setState(() {
                  _currency = 'AUD';
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: Text('JPY'),
              onTap: () {
                setState(() {
                  _currency = 'JPY';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: _currency == 'USD'
          ? 'en_US'
          : _currency == 'EUR'
          ? 'de_DE'
          : _currency == 'GBP'
          ? 'en_GB'
          : _currency == 'AUD'
          ? 'en_AU'
          : _currency == 'JPY'
          ? 'ja_JP'
          : 'en_US',
      symbol: _currency == 'USD'
          ? '\$'
          : _currency == 'EUR'
          ? '€'
          : _currency == 'GBP'
          ? '£'
          : _currency == 'AUD'
          ? 'A\$'
          : _currency == 'JPY'
          ? '¥'
          : '\$',
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Pulse'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.attach_money),
            onPressed: _showCurrencyDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Crypto>>(
        valueListenable: Hive.box<Crypto>('cryptoPortfolio').listenable(),
        builder: (context, box, _) {
          final cryptos = box.values.toList();
          final totalAmount = cryptos.fold<double>(0, (sum, item) => sum + item.amount);

          Map<String, double> dataMap = {
            for (var crypto in cryptos) crypto.name: crypto.amount
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Portfolio Value: ${_formatCurrency(totalAmount)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              if (dataMap.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PieChart(
                    dataMap: dataMap,
                    chartType: ChartType.ring,
                    baseChartColor: Colors.grey[200]!,
                    chartValuesOptions: ChartValuesOptions(
                      showChartValuesInPercentage: true,
                    ),
                    colorList: [
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ],
                    animationDuration: Duration(milliseconds: 800),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: cryptos.length,
                  itemBuilder: (context, index) {
                    final crypto = cryptos[index];
                    bool isSelected = _selectedIndexes.contains(index);

                    return Dismissible(
                      key: Key(crypto.name),
                      onDismissed: (direction) {
                        box.deleteAt(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${crypto.name} dismissed')));
                      },
                      background: Container(color: Colors.red),
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: _isSelecting
                              ? IconButton(
                            icon: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => _toggleSelection(index),
                          )
                              : null,
                          title: Text(crypto.name),
                          subtitle: Text('Amount: ${_formatCurrency(crypto.amount)}'),
                          trailing: isSelected
                              ? IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              box.deleteAt(index);
                            },
                          )
                              : null,
                          onTap: _isSelecting
                              ? () => _toggleSelection(index)
                              : null,
                          onLongPress: () {
                            setState(() {
                              _isSelecting = true;
                              _selectedIndexes.add(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCryptoBottomSheet,
        child: Icon(Icons.add),
        backgroundColor: Colors.purple.shade100,
      ),
      bottomNavigationBar: _isSelecting
          ? BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                final box = Hive.box<Crypto>('cryptoPortfolio');
                _deleteSelectedItems(box);
              },
            ),
            // Show Edit button only when exactly one item is selected
            if (_selectedIndexes.length == 1)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  final box = Hive.box<Crypto>('cryptoPortfolio');
                  _editSelectedItems(box);
                },
              ),
          ],
        ),
      )
          : null,
    );
  }
}
