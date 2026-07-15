// lib/features/owner/registration/owner_coworkers_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saloon_app/core/theme/app_colors.dart';
import 'package:saloon_app/core/theme/app_text_styles.dart';
import 'package:saloon_app/core/theme/theme_helper.dart';
import 'package:saloon_app/features/owner/registration/owner_documents_screen.dart';
import 'package:saloon_app/shared/widgets/app_button.dart';
import 'package:saloon_app/shared/widgets/progress_step_bar.dart';

class OwnerCoworkersScreen extends StatefulWidget {
  final Map<String, dynamic> salonData;
  const OwnerCoworkersScreen({super.key, required this.salonData});

  @override
  State<OwnerCoworkersScreen> createState() => _OwnerCoworkersScreenState();
}

class _OwnerCoworkersScreenState extends State<OwnerCoworkersScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _hasCoworkers = false;
  List<Map<String, dynamic>> _workers = [];

  void _addWorker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorkerForm(
        onSave: (worker) {
          setState(() {
            _workers.add(worker);
            _hasCoworkers = true;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editWorker(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WorkerForm(
        existingWorker: _workers[index],
        onSave: (worker) {
          setState(() {
            _workers[index] = worker;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteWorker(int index) {
    setState(() {
      _workers.removeAt(index);
      if (_workers.isEmpty) _hasCoworkers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.lightPinkColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('coworkers'.tr, style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressStepBar(totalSteps: 7, currentStep: 5),
              const SizedBox(height: 30),

              Text('your_team'.tr + ' 👥',
                style: AppTextStyles.displayLarge?.copyWith(fontSize: 25, color: theme.textColor),
              ),
              const SizedBox(height: 8),
              Text('do_you_have_workers'.tr,
                  style: AppTextStyles.tagline?.copyWith(color: theme.mutedTextColor)),

              const SizedBox(height: 30),

              // Toggle: Have co-workers or not
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  children: [
                    // No Co-workers option
                    GestureDetector(
                      onTap: () => setState(() {
                        _hasCoworkers = false;
                        _workers.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: !_hasCoworkers ? AppColors.lightPink : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_hasCoworkers ? AppColors.primaryPink : theme.borderColor,
                            width: !_hasCoworkers ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !_hasCoworkers ? Icons.check_circle : Icons.circle_outlined,
                              color: !_hasCoworkers ? AppColors.primaryPink : theme.mutedTextColor,
                            ),
                            const SizedBox(width: 12),
                             Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('work_alone'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text('no_coworkers'.tr, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Have Co-workers option
                    GestureDetector(
                      onTap: () => setState(() => _hasCoworkers = true),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _hasCoworkers ? AppColors.lightPink : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasCoworkers ? AppColors.primaryPink : theme.borderColor,
                            width: _hasCoworkers ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasCoworkers ? Icons.check_circle : Icons.circle_outlined,
                              color: _hasCoworkers ? AppColors.primaryPink : theme.mutedTextColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('have_coworkers'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text('ustad_shagird'.tr, style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Workers List
              if (_hasCoworkers) ...[
                const SizedBox(height: 24),

                ..._workers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final worker = entry.value;
                  return _buildWorkerCard(worker, index, theme);
                }),

                const SizedBox(height: 16),

                // Add Worker Button
                GestureDetector(
                  onTap: _addWorker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryPink, style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add_rounded, color: AppColors.primaryPink),
                        const SizedBox(width: 8),
                        Text('add_coworker'.tr, style: AppTextStyles.buttonText?.copyWith(color: AppColors.primaryPink)),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Save & Next Button
              AppButton(
                label: 'save_next'.tr,
                onTap: () {
                  final updatedSalonData = {
                    ...widget.salonData,
                    'hasCoworkers': _hasCoworkers,
                    'workers': _hasCoworkers ? _workers : [],
                  };
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => OwnerDocumentsScreen(salonData: updatedSalonData),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker, int index, ThemeHelper theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          // Worker Photo
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.lightPink,
              image: worker['profileImage'] != null
                  ? DecorationImage(image: FileImage(File(worker['profileImage'])), fit: BoxFit.cover)
                  : null,
            ),
            child: worker['profileImage'] == null
                ? const Icon(Icons.person, color: AppColors.primaryPink, size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          // Worker Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker['name'] ?? 'Unnamed', style: AppTextStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Father: ${worker['fatherName'] ?? 'N/A'}', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
                if (worker['cnic'] != null && worker['cnic'].toString().isNotEmpty)
                  Text('CNIC: ${worker['cnic']}', style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
              ],
            ),
          ),
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryPink),
            onPressed: () => _editWorker(index),
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
            onPressed: () => _deleteWorker(index),
          ),
        ],
      ),
    );
  }
}

// ==================== WORKER FORM BOTTOM SHEET ====================

class _WorkerForm extends StatefulWidget {
  final Map<String, dynamic>? existingWorker;
  final Function(Map<String, dynamic>) onSave;

  const _WorkerForm({this.existingWorker, required this.onSave});

  @override
  State<_WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends State<_WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    if (widget.existingWorker != null) {
      _nameController.text = widget.existingWorker!['name'] ?? '';
      _fatherNameController.text = widget.existingWorker!['fatherName'] ?? '';
      _cnicController.text = widget.existingWorker!['cnic'] ?? '';
      if (widget.existingWorker!['profileImage'] != null) {
        _profileImage = File(widget.existingWorker!['profileImage']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (image != null) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      // Ignore
    }
  }

  // In _WorkerForm build method, wrap the Column with SingleChildScrollView:

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      // ✅ WRAP IN SINGLECHILDSCROLLVIEW
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                widget.existingWorker != null ? 'edit_coworker'.tr : 'add_coworker'.tr,
                style: AppTextStyles.headingLarge?.copyWith(color: theme.textColor),
              ),
              const SizedBox(height: 16),  // Reduced from 24

              // Profile Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 70, height: 70,  // Reduced from 80
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(20),
                      image: _profileImage != null
                          ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, color: AppColors.primaryPink, size: 26)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),  // Reduced from 16

              // Name
              _buildField('full_name'.tr + ' *', 'e.g. Ahmed Khan', _nameController, theme),
              const SizedBox(height: 12),  // Reduced from 16

              // Father Name
              _buildField('father_name'.tr + ' *', 'e.g. Muhammad Khan', _fatherNameController, theme),
              const SizedBox(height: 12),  // Reduced from 16

              // CNIC (Optional)
              _buildField('cnic_optional'.tr, 'e.g. 17301-1234567-8', _cnicController, theme,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),  // Reduced from 24

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,  // Reduced from 52
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave({
                        'name': _nameController.text.trim(),
                        'fatherName': _fatherNameController.text.trim(),
                        'cnic': _cnicController.text.trim(),
                        'profileImage': _profileImage?.path,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.existingWorker != null ? 'update'.tr : 'add_worker'.tr,
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, ThemeHelper theme,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: theme.mutedTextColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.lightPinkColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: theme.textColor),
            validator: (value) {
              if (label.contains('*') && (value == null || value.trim().isEmpty)) {
                return 'field_required'.tr;
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}