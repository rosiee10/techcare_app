import 'package:flutter/material.dart';
import '../../../../../core/reusable_widgets/card_container.dart';
import '../../services/ipd_inventory_service.dart';

/// Dispensing Sheet Form Widget
/// Used when pharmacy is OPEN - sends request to pharmacist
class DispensingSheetForm extends StatefulWidget {
  final bool isSmallScreen;

  const DispensingSheetForm({
    super.key,
    required this.isSmallScreen,
  });

  @override
  State<DispensingSheetForm> createState() => _DispensingSheetFormState();
}

class _DispensingSheetFormState extends State<DispensingSheetForm> {
  final IpdInventoryService _inventoryService = IpdInventoryService();
  
  final TextEditingController _patientNameController = TextEditingController();

  final List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _pharmacyInventory = [];
  Map<String, dynamic>? _selectedPatient;
  int? _selectedPatientId;
  int? _selectedAdmissionId;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isPatientSelected = false;
  bool _isLoadingPharmacy = false;

  @override
  void initState() {
    super.initState();
    _loadPharmacyInventory();
    _addMedicineRow();
  }
  
  Future<void> _loadPharmacyInventory({String? query}) async {
    setState(() => _isLoadingPharmacy = true);
    try {
      final response = await _inventoryService.getPharmacyInventory(query: query);
      if (response['success'] == true) {
        setState(() {
          _pharmacyInventory = List<Map<String, dynamic>>.from(response['inventory'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading pharmacy inventory: $e');
    } finally {
      setState(() => _isLoadingPharmacy = false);
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

  Future<void> _selectDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _medicines[index]['date'].text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _addMedicineRow() {
    final now = DateTime.now();
    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    setState(() {
      _medicines.add({
        'date': TextEditingController(text: today),
        'name': TextEditingController(),
        'qty': TextEditingController(),
        'pharmacist': TextEditingController(),
      });
    });
  }

  void _removeMedicineRow(int index) {
    setState(() {
      _medicines[index]['date']?.dispose();
      _medicines[index]['name']?.dispose();
      _medicines[index]['qty']?.dispose();
      _medicines[index]['pharmacist']?.dispose();
      _medicines.removeAt(index);
    });
  }

  void _onPatientSelected(Map<String, dynamic> patient) {
    final admission = patient['admission'] as Map<String, dynamic>?;
    final fullName = '${patient['lastname'] ?? ''}, ${patient['firstname'] ?? ''}';

    setState(() {
      _isPatientSelected = true;
      _selectedPatient = patient;
      _selectedPatientId = patient['patient_id'];
      _selectedAdmissionId = admission?['admission_id'];

      _patientNameController.text = fullName;
    });
  }
  
  Future<void> _submitDispensingSheet() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first')),
      );
      return;
    }
    
    // Validate medicines
    final validMedicines = _medicines.where((med) {
      final name = med['name']?.text?.toString().trim() ?? '';
      final qty = med['qty']?.text?.toString().trim() ?? '';
      final date = med['date']?.text?.toString().trim() ?? '';
      return name.isNotEmpty && qty.isNotEmpty && date.isNotEmpty;
    }).toList();
    
    if (validMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine with a date and quantity')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final items = validMedicines.map((med) => {
        'date': med['date']?.text ?? '',
        'medicine_id': med['medicine_id'], // Pass the actual ID from search
        'dosage': '', 
        'qty': med['qty']?.text ?? '1',
      }).toList();
      
      // Note: requested_by and requested_by_name are now automatically 
      // handled by the backend using the authenticated user session.
      final response = await _inventoryService.createDispensingSheet(
        patientId: _selectedPatientId!,
        admissionId: _selectedAdmissionId,
        items: items,
        requestedByName: '', // Backend will override this with real user name
      );
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dispensing Sheet #${response['dispensing_id']} submitted successfully')),
        );
        
        // Reset form
        setState(() {
          _isPatientSelected = false;
          _selectedPatient = null;
          _selectedPatientId = null;
          _selectedAdmissionId = null;
          _medicines.clear();
          _addMedicineRow();
        });
        
        _patientNameController.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    for (var med in _medicines) {
      med['date']?.dispose();
      med['name']?.dispose();
      med['qty']?.dispose();
      med['pharmacist']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we have limited width and need to use compact layout
        final bool useCompactLayout = constraints.maxWidth < 700;
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search/Select Patient Section
              _buildPatientSelectionSection(),
              const SizedBox(height: 20),

              // Medicines Section
              if (_isPatientSelected) ...[
                _buildMedicinesSection(useCompactLayout),
                const SizedBox(height: 24),

                // Submit Button - aligned right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitDispensingSheet,
                      icon: _isSubmitting 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined, size: 18),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit to Pharmacist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
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
              Icon(Icons.search, color: const Color(0xFF2563EB), size: 20),
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
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              // Trigger async search
              _searchPatients(textEditingValue.text);
              
              // Filter current results to ensure only those starting with the query are shown
              final query = textEditingValue.text.toLowerCase();
              return _searchResults.where((option) {
                final lastName = (option['lastname'] ?? '').toString().toLowerCase();
                final firstName = (option['firstname'] ?? '').toString().toLowerCase();
                final hospitalId = (option['hospital_id'] ?? '').toString().toLowerCase();
                return lastName.startsWith(query) || 
                       firstName.startsWith(query) || 
                       hospitalId.startsWith(query);
              });
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
        ],
      ),
    );
  }

  Widget _buildMedicinesSection(bool useCompactLayout) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_outlined, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Medicines / Supplies',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Medicine Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: useCompactLayout
                ? Row(
                    children: [
                      Expanded(flex: 2, child: _buildTableHeader('DATE', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(flex: 5, child: _buildTableHeader('MEDICINE/SUPPLY', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      SizedBox(width: 60, child: _buildTableHeader('QTY', textColor: Colors.white)),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(width: 100, child: _buildTableHeader('DATE', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _buildTableHeader('MEDICINE/SUPPLY', textColor: Colors.white)),
                      const SizedBox(width: 8),
                      SizedBox(width: 80, child: _buildTableHeader('QTY', textColor: Colors.white)),
                      const SizedBox(width: 40),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          // Medicine Entry Rows
          ..._medicines.asMap().entries.map((entry) => _buildMedicineRow(entry.key, useCompactLayout)),
          const SizedBox(height: 12),
          // Add More Button
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            OutlinedButton.icon(
              onPressed: _addMedicineRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Medicine'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicineRow(int index, bool useCompactLayout) {
    final item = _medicines[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: useCompactLayout
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _selectDate(index),
                        child: IgnorePointer(
                          child: TextField(
                            controller: item['date'],
                            decoration: InputDecoration(
                              hintText: 'Date',
                              suffixIcon: const Icon(Icons.calendar_today, size: 16),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: item['qty'],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Qty',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => option['medicine_name'] ?? '',
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _pharmacyInventory;
                          }
                          return _pharmacyInventory.where((item) => 
                            item['medicine_name'].toLowerCase().contains(textEditingValue.text.toLowerCase())
                          );
                        },
                        onSelected: (selection) {
                          item['name'].text = selection['medicine_name'];
                          item['medicine_id'] = selection['medicine_id'];
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Sync initial text if any
                          if (controller.text != item['name'].text) {
                            controller.text = item['name'].text;
                          }
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search medicine...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (val) => item['name'].text = val,
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeMedicineRow(index),
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
                  child: InkWell(
                    onTap: () => _selectDate(index),
                    child: IgnorePointer(
                      child: TextField(
                        controller: item['date'],
                        decoration: InputDecoration(
                          hintText: 'Date',
                          suffixIcon: const Icon(Icons.calendar_today, size: 16),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (option) => option['medicine_name'] ?? '',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _pharmacyInventory;
                      }
                      return _pharmacyInventory.where((item) => 
                        item['medicine_name'].toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    onSelected: (selection) {
                      item['name'].text = selection['medicine_name'];
                      item['medicine_id'] = selection['medicine_id'];
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      // Sync initial text if any
                      if (controller.text != item['name'].text) {
                        controller.text = item['name'].text;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search medicine...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onChanged: (val) => item['name'].text = val,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: item['qty'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Qty',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeMedicineRow(index),
                  icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                ),
              ],
            ),
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
