import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_booking/app/theme/app_colors.dart';
import 'package:turf_booking/features/owner/providers/application_controller.dart';
import 'package:turf_booking/shared/exceptions/app_exceptions.dart';
import 'dart:typed_data';

class OwnerApplicationScreen extends ConsumerStatefulWidget {
  const OwnerApplicationScreen({super.key});

  @override
  ConsumerState<OwnerApplicationScreen> createState() => _OwnerApplicationScreenState();
}

class _OwnerApplicationScreenState extends ConsumerState<OwnerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Crucial: Loads bytes into memory
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      setState(() {
        _selectedFileBytes = file.bytes;
        _selectedFileName = file.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a PDF document verifying ownership.', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(applicationControllerProvider.notifier).submit(
      businessName: _businessNameController.text.trim(),
      phone: _phoneController.text.trim(),
      message: _messageController.text.trim(),
      documentBytes: _selectedFileBytes!,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold UI listen state for successful submission & error presentation
    ref.listen(applicationControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        final message = error is AppException ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next.valueOrNull != null || (!next.isLoading && !next.hasError && previous?.isLoading == true)) {
         // Submission success lock jump to pending mode
         context.go('/owner/pending-approval');
      }
    });

    final isLoading = ref.watch(applicationControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Partner Application'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join Courtly',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit your stadium or turf ownership details below. Our team reviews all documents within 48 hours.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Registered Business / Stadium Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message to Admin (Optional)'),
                enabled: !isLoading,
              ),
              const SizedBox(height: 32),
              
              // PDF Upload Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 40,
                      color: _selectedFileBytes != null ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFileName ?? 'Upload Proof of Ownership',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: _selectedFileBytes != null ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PDF format only (Lease Agreement, GST Certificate, or Tax ID)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _pickPdf,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFileBytes != null ? 'Change Document' : 'Select File'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Text('Submit Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
