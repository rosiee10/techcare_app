import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/card_container.dart';
import '../../../../../core/services/auth_service.dart';
import '../../services/ipd_inventory_service.dart';

/// Cart Form Widget
/// Used when pharmacy is CLOSED - records medicines taken from cart
class CartForm extends StatefulWidget {
  final bool isSmallScreen;

  const CartForm({
    super.key,
    required this.isSmallScreen,
  });

  @override
  State<CartForm> createState() => _CartFormState();
}

class _CartFormState extends State<CartForm> {
  final IpdInventoryService _inventoryService = IpdInventoryService();
  
  final List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  int? _selectedPatientId;
  int? _selectedAdmissionId;
  
  bool _isPatientSelected = false;
  bool _isLoadingInventory = false;
  bool _isLoadingPatients = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String _currentUserFullName = '';
  List<Map<String, dynamic>> _cartInventory = [];
  List<Map<String, dynamic>> _inpatients = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCartInventory();
    _loadInpatients();
    // Add initial empty row
    _addCartItemRow();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserFullName = "${user['firstname'] ?? ''} ${user['lastname'] ?? ''}".trim();
        if (_currentUserFullName.isEmpty) {
          _currentUserFullName = user['username'] ?? 'RN';
        }
        
        // Update any existing empty administered_by controllers
        for (var item in _cartItems) {
          if (item['administered_by_controller']?.text.isEmpty ?? true) {
            item['administered_by_controller']?.text = _currentUserFullName;
          }
        }
      });
    }
  }

  Future<void> _loadCartInventory() async {
    setState(() => _isLoadingInventory = true);
    try {
      final response = await _inventoryService.getInventory();
      if (response['success'] == true) {
        setState(() {
          _cartInventory = List<Map<String, dynamic>>.from(response['inventory'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading cart inventory: $e');
    } finally {
      setState(() => _isLoadingInventory = false);
    }
  }

  Future<void> _loadInpatients({String? query}) async {
    setState(() => _isLoadingPatients = true);
    try {
      // Use the existing searchPatients method which filters for INPATIENT by default on backend
      final response = await _inventoryService.searchPatients(query ?? '');
      if (response['success'] == true) {
        setState(() {
          _inpatients = List<Map<String, dynamic>>.from(response['patients'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading inpatients: $e');
    } finally {
      setState(() => _isLoadingPatients = false);
    }
  }
  
  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _inventoryService.searchPatients(query);
      if (response['success'] == true) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response['patients'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error searching patients: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _onPatientSelected(Map<String, dynamic> patient) {
    final admission = patient['admission'] as Map<String, dynamic>?;
    
    setState(() {
      _selectedPatient = patient;
      _selectedPatientId = patient['patient_id'];
      _selectedAdmissionId = admission?['admission_id'];
    });
    
    // Auto-fill patient name in cart items
    final patientName = '${patient['lastname'] ?? ''}, ${patient['firstname'] ?? ''}';
    for (var item in _cartItems) {
      if (item['patient_controller']?.text?.isEmpty ?? true) {
        item['patient_controller']?.text = patientName;
      }
    }
  }
  
  Future<void> _submitCartForm() async {
    // Validate items
    final validItems = _cartItems.where((item) {
      final drug = item['drug_controller']?.text?.toString().trim() ?? '';
      final qty = item['qty_controller']?.text?.toString().trim() ?? '';
      final patientName = item['patient_controller']?.text?.toString().trim() ?? '';
      final administeredBy = item['administered_by_controller']?.text?.toString().trim() ?? '';
      final date = item['date_controller']?.text?.toString().trim() ?? '';
      final patientId = item['patient_id']; // Row-level patient ID
      
      return drug.isNotEmpty && qty.isNotEmpty && patientName.isNotEmpty && 
             administeredBy.isNotEmpty && date.isNotEmpty && patientId != null;
    }).toList();
    
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields (Date, Drug, Qty, Administered By) and select a valid patient from the dropdown for at least one item')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final items = validItems.map((item) {
        return {
          'date_taken': item['date_controller']?.text ?? '',
          'medicine_id': item['medicine_id'],
          'drug_name': item['drug_controller']?.text ?? '',
          'quantity': int.tryParse(item['qty_controller']?.text ?? '1') ?? 1,
          'administered_by': item['administered_by_controller']?.text ?? '',
        };
      }).toList();
      
      final firstItem = validItems.first;
      
      // Update the audit trail metadata
      final timestamp = DateTime.now().toIso8601String();
      final trail = "RN|$_currentUserFullName|CREATED|$timestamp";

      final response = await _inventoryService.createCartForm(
        patientId: firstItem['patient_id'],
        admissionId: firstItem['admission_id'],
        items: items,
        requestedByName: _currentUserFullName,
        trail: trail,
      );
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cart Form #${response['cart_form_id']} recorded successfully')),
        );
        
        // Reset form
        setState(() {
          _selectedPatient = null;
          _selectedPatientId = null;
          _selectedAdmissionId = null;
          _cartItems.clear();
          _addCartItemRow();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _addCartItemRow() {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    setState(() {
      _cartItems.add({
        'date_controller': TextEditingController(text: today),
        'drug_controller': TextEditingController(),
        'qty_controller': TextEditingController(),
        'patient_controller': TextEditingController(),
        'administered_by_controller': TextEditingController(text: _currentUserFullName),
        'medicine_id': null,
      });
    });
  }

  void _removeCartItemRow(int index) {
    setState(() {
      _cartItems[index]['date_controller']?.dispose();
      _cartItems[index]['drug_controller']?.dispose();
      _cartItems[index]['qty_controller']?.dispose();
      _cartItems[index]['patient_controller']?.dispose();
      _cartItems[index]['administered_by_controller']?.dispose();
      _cartItems.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var item in _cartItems) {
      item['date_controller']?.dispose();
      item['drug_controller']?.dispose();
      item['qty_controller']?.dispose();
      item['patient_controller']?.dispose();
      item['administered_by_controller']?.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useCompactLayout = constraints.maxWidth < 900;
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cart Items Table
              _buildCartItemsSection(useCompactLayout),
              const SizedBox(height: 24),

              // Record Button - aligned right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitCartForm,
                    icon: _isSubmitting 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_isSubmitting ? 'Recording...' : 'Record Cart Items'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPatientSelectionSection() {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: const Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Select Patient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (option) => option['full_name'] ?? '${option['lastname']}, ${option['firstname']}',
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.length < 2) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              _searchPatients(textEditingValue.text);
              return _searchResults;
            },
            onSelected: (Map<String, dynamic> selection) {
              _onPatientSelected(selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Search patient by name...',
                  prefixIcon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_search_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              );
            },
          ),
          if (_selectedPatient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedPatient!['full_name'] ?? '${_selectedPatient!['lastname']}, ${_selectedPatient!['firstname']}'}',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItemsSection(bool useCompactLayout) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: const Color(0xFF059669), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Cart Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF059669),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: useCompactLayout
                ? Row(
                    children: [
                      SizedBox(width: 100, child: _buildTableHeader('Date', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      SizedBox(width: 60, child: _buildTableHeader('Qty', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTableHeader('Patient', textColor: Colors.white)),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(width: 100, child: _buildTableHeader('Date', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _buildTableHeader('DRUG (Invoice-Dosage-Strength-Manufacturer)', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      SizedBox(width: 60, child: _buildTableHeader('Qty', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildTableHeader('Name of Patient', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: _buildTableHeader('Administered by (RN/Entity)', textColor: Colors.white)),
                    ],
                  ),
          ),
          // Cart Item Rows
          ..._cartItems.asMap().entries.map((entry) => _buildCartItemRow(entry.key, useCompactLayout)),
          const SizedBox(height: 12),
          // Add More Button
          OutlinedButton.icon(
            onPressed: _addCartItemRow,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              side: const BorderSide(color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(int index, bool useCompactLayout) {
    final item = _cartItems[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
          left: BorderSide(color: Colors.grey[200]!),
          right: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: useCompactLayout
          ? Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: item['date_controller'],
                        readOnly: true,
                        onTap: () => _selectDate(item['date_controller']),
                        decoration: _inputDecoration('mm/dd/yyyy', isDate: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: item['qty_controller'],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: _inputDecoration('Qty'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => option['full_name'] ?? '',
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return _inpatients.where((p) {
                            final lastName = (p['lastname'] ?? '').toString().toLowerCase();
                            final firstName = (p['firstname'] ?? '').toString().toLowerCase();
                            final hospitalId = (p['hospital_id'] ?? '').toString().toLowerCase();
                            return lastName.startsWith(query) || 
                                   firstName.startsWith(query) || 
                                   hospitalId.startsWith(query);
                          });
                        },
                        onSelected: (selection) {
                          item['patient_controller'].text = selection['full_name'] ?? '';
                          item['patient_id'] = selection['patient_id'];
                          item['admission_id'] = selection['admission']?['admission_id'];
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text != item['patient_controller'].text) {
                            controller.text = item['patient_controller'].text;
                          }
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: _inputDecoration('Search patient...'),
                            onChanged: (val) => item['patient_controller'].text = val,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => option['medicine_name'] ?? '',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _cartInventory;
                    }
                    return _cartInventory.where((item) => 
                      item['medicine_name'].toLowerCase().contains(textEditingValue.text.toLowerCase())
                    );
                  },
                  onSelected: (selection) {
                    item['drug_controller'].text = selection['medicine_name'];
                    item['medicine_id'] = selection['medicine_id'];
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    if (controller.text != item['drug_controller'].text) {
                      controller.text = item['drug_controller'].text;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _inputDecoration('Search medicine from cart...'),
                      onChanged: (val) => item['drug_controller'].text = val,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: item['administered_by_controller'],
                        decoration: _inputDecoration('Administered by (Name of RN/Entity)'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeCartItemRow(index),
                      icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: item['date_controller'],
                    readOnly: true,
                    onTap: () => _selectDate(item['date_controller']),
                    decoration: _inputDecoration('mm/dd/yyyy', isDate: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => option['medicine_name'] ?? '',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _cartInventory;
                      }
                      return _cartInventory.where((item) => 
                        item['medicine_name'].toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    onSelected: (selection) {
                      item['drug_controller'].text = selection['medicine_name'];
                      item['medicine_id'] = selection['medicine_id'];
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text != item['drug_controller'].text) {
                        controller.text = item['drug_controller'].text;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: _inputDecoration('Search medicine from cart...'),
                        onChanged: (val) => item['drug_controller'].text = val,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: item['qty_controller'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: _inputDecoration('Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => option['full_name'] ?? '',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return _inpatients.where((p) {
                        final lastName = (p['lastname'] ?? '').toString().toLowerCase();
                        final firstName = (p['firstname'] ?? '').toString().toLowerCase();
                        final hospitalId = (p['hospital_id'] ?? '').toString().toLowerCase();
                        return lastName.startsWith(query) || 
                               firstName.startsWith(query) || 
                               hospitalId.startsWith(query);
                      });
                    },
                    onSelected: (selection) {
                      item['patient_controller'].text = selection['full_name'] ?? '';
                      item['patient_id'] = selection['patient_id'];
                      item['admission_id'] = selection['admission']?['admission_id'];
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (controller.text != item['patient_controller'].text) {
                        controller.text = item['patient_controller'].text;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: _inputDecoration('Search patient...'),
                        onChanged: (val) => item['patient_controller'].text = val,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item['administered_by_controller'],
                    decoration: _inputDecoration('Administered by (RN/Entity)'),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: () => _removeCartItemRow(index),
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration(String hint, {bool isDate = false}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      suffixIcon: isDate ? Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]) : null,
    );
  }

  Widget _buildTableHeader(String title, {Color? textColor}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor ?? Colors.grey[600],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
