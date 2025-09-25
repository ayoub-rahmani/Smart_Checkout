import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/shared/widgets/custom_button.dart';
import '../../../presentation/shared/widgets/custom_text_field.dart';
import '../../../providers/product_provider.dart';
import '../../../data/models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _selectImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.clear();
          _selectedImages.addAll(images.take(5).map((x) => File(x.path)));
        });
        _showSnackBar('${_selectedImages.length} images selected', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error selecting images', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least one image', Colors.red);
      return;
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);

    final success = await provider.createProduct(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      stockQuantity: int.parse(_stockController.text),
      imageFiles: _selectedImages,
    );

    if (success) {
      _showSnackBar('Product created successfully!', Colors.green);
      Navigator.pop(context);
    } else {
      _showError(provider.error ?? 'Unknown error occurred');
    }
  }

  void _showError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 16),
            const Text('Try:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Check internet connection\n• Restart the app\n• Use smaller images'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveProduct();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images Section
                      const Text('Product Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Add button
                            GestureDetector(
                              onTap: provider.isLoading ? null : _selectImages,
                              child: Container(
                                width: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 32),
                                    Text('Add Photos'),
                                  ],
                                ),
                              ),
                            ),
                            // Selected images
                            ..._selectedImages.asMap().entries.map((entry) {
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(entry.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      if (_selectedImages.isNotEmpty)
                        Text('${_selectedImages.length} image(s) selected',
                            style: const TextStyle(color: Colors.grey)),

                      const SizedBox(height: 24),

                      // Form fields
                      CustomTextField(
                        controller: _titleController,
                        hintText: 'Product title',
                        validator: (v) => v?.trim().isEmpty == true ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'Description',
                        maxLines: 3,
                        validator: (v) => v?.trim().isEmpty == true ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _priceController,
                              hintText: 'Price (TND)',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final price = double.tryParse(v ?? '');
                                return price == null || price <= 0 ? 'Enter valid price' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _stockController,
                              hintText: 'Stock',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final stock = int.tryParse(v ?? '');
                                return stock == null || stock < 0 ? 'Enter valid stock' : null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: provider.isLoading ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: provider.isLoading ? 'Uploading...' : 'Save Product',
                              onPressed: provider.isLoading ? null : _saveProduct,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (provider.isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Creating product...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}