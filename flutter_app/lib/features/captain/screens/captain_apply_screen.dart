import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/providers.dart';

class CaptainApplyScreen extends ConsumerStatefulWidget {
  const CaptainApplyScreen({super.key});

  @override
  ConsumerState<CaptainApplyScreen> createState() => _CaptainApplyScreenState();
}

class _CaptainApplyScreenState extends ConsumerState<CaptainApplyScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _plateCtrl      = TextEditingController();

  String _vehicleType = AppConstants.vehicleCar;

  File? _selfieWithFrontId;
  File? _selfieWithBackId;
  File? _driverLicense;
  File? _carRegistration;
  File? _carWithPlate;

  bool _submitting = false;
  int  _currentStep = 0;

  final _picker = ImagePicker();

  Future<void> _pickImage(_DocSlot slot) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      switch (slot) {
        case _DocSlot.selfieWithFrontId: _selfieWithFrontId = file;
        case _DocSlot.selfieWithBackId:  _selfieWithBackId  = file;
        case _DocSlot.driverLicense:     _driverLicense     = file;
        case _DocSlot.carRegistration:   _carRegistration   = file;
        case _DocSlot.carWithPlate:      _carWithPlate      = file;
      }
    });
  }

  bool get _docsComplete =>
    _selfieWithFrontId != null && _selfieWithBackId  != null &&
    _driverLicense     != null && _carRegistration   != null &&
    _carWithPlate      != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_docsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and upload all documents')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = ref.read(currentUserProvider).value!;
      await ref.read(captainAppServiceProvider).submitApplication(
        uid:              user.uid,
        displayName:      _nameCtrl.text.trim(),
        phone:            _phoneCtrl.text.trim(),
        vehicleType:      _vehicleType,
        vehicleModel:     _vehicleModelCtrl.text.trim(),
        licensePlate:     _plateCtrl.text.trim(),
        selfieWithFrontId: _selfieWithFrontId!,
        selfieWithBackId:  _selfieWithBackId!,
        driverLicense:     _driverLicense!,
        carRegistration:   _carRegistration!,
        carWithPlate:      _carWithPlate!,
      );
      if (mounted) context.go(AppRoutes.captainPending);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _vehicleModelCtrl.dispose(); _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Become a Captain'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) setState(() => _currentStep++);
            else _submit();
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
            else context.pop();
          },
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : details.onStepContinue,
                    child: _submitting && _currentStep == 2
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentStep < 2 ? 'Continue' : 'Submit Application'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            // ── Step 1: Personal Info ───────────────────────────────────
            Step(
              title: const Text('Personal Information',
                style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600)),
              isActive: _currentStep >= 0,
              state:    _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _Field(ctrl: _nameCtrl,    label: 'Full Name',    hint: 'Mohamed Ahmed',
                    icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  _Field(ctrl: _phoneCtrl,   label: 'Phone Number', hint: '010XXXXXXXX',
                    icon: Icons.phone_outlined,  keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 11 ? 'Enter a valid number' : null),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Vehicle Type', style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _VehicleOption(label: '🚗 Car',   value: AppConstants.vehicleCar,
                        selected: _vehicleType == AppConstants.vehicleCar,
                        onTap: () => setState(() => _vehicleType = AppConstants.vehicleCar)),
                      const SizedBox(width: 8),
                      _VehicleOption(label: '🏍️ Moto', value: AppConstants.vehicleMoto,
                        selected: _vehicleType == AppConstants.vehicleMoto,
                        onTap: () => setState(() => _vehicleType = AppConstants.vehicleMoto)),
                      const SizedBox(width: 8),
                      _VehicleOption(label: '🚚 Truck', value: AppConstants.vehicleTruck,
                        selected: _vehicleType == AppConstants.vehicleTruck,
                        onTap: () => setState(() => _vehicleType = AppConstants.vehicleTruck)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field(ctrl: _vehicleModelCtrl, label: 'Vehicle Model', hint: 'e.g. Toyota Corolla 2020',
                    icon: Icons.directions_car_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  _Field(ctrl: _plateCtrl, label: 'License Plate', hint: 'e.g. ص ب ج 1234',
                    icon: Icons.numbers_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                ],
              ),
            ),

            // ── Step 2: Documents ───────────────────────────────────────
            Step(
              title: const Text('Upload Documents',
                style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600)),
              isActive: _currentStep >= 1,
              state:    _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  const _DocNote(),
                  const SizedBox(height: 14),
                  _DocUploader(
                    slot:     _DocSlot.selfieWithFrontId,
                    label:    'Selfie with Front ID',
                    hint:     'Hold your ID next to your face (front side)',
                    icon:     Icons.face_outlined,
                    file:     _selfieWithFrontId,
                    onTap:    () => _pickImage(_DocSlot.selfieWithFrontId),
                  ),
                  const SizedBox(height: 10),
                  _DocUploader(
                    slot:     _DocSlot.selfieWithBackId,
                    label:    'Selfie with Back ID',
                    hint:     'Hold your ID next to your face (back side)',
                    icon:     Icons.face_outlined,
                    file:     _selfieWithBackId,
                    onTap:    () => _pickImage(_DocSlot.selfieWithBackId),
                  ),
                  const SizedBox(height: 10),
                  _DocUploader(
                    slot:     _DocSlot.driverLicense,
                    label:    "Driver's License",
                    hint:     'Clear photo of your driver\'s license',
                    icon:     Icons.credit_card_outlined,
                    file:     _driverLicense,
                    onTap:    () => _pickImage(_DocSlot.driverLicense),
                  ),
                  const SizedBox(height: 10),
                  _DocUploader(
                    slot:     _DocSlot.carRegistration,
                    label:    'Car Registration',
                    hint:     'Official vehicle registration document',
                    icon:     Icons.description_outlined,
                    file:     _carRegistration,
                    onTap:    () => _pickImage(_DocSlot.carRegistration),
                  ),
                  const SizedBox(height: 10),
                  _DocUploader(
                    slot:     _DocSlot.carWithPlate,
                    label:    'Car with License Plate',
                    hint:     'Photo of your car showing the license plate',
                    icon:     Icons.directions_car_outlined,
                    file:     _carWithPlate,
                    onTap:    () => _pickImage(_DocSlot.carWithPlate),
                  ),
                ],
              ),
            ),

            // ── Step 3: Review & Submit ─────────────────────────────────
            Step(
              title: const Text('Review & Submit',
                style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w600)),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReviewRow(label: 'Name',    value: _nameCtrl.text),
                  _ReviewRow(label: 'Phone',   value: _phoneCtrl.text),
                  _ReviewRow(label: 'Vehicle', value: _vehicleModelCtrl.text),
                  _ReviewRow(label: 'Plate',   value: _plateCtrl.text),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Your application will be reviewed by our team within 24-48 hours. '
                      'You will receive a notification once it\'s approved.',
                      style: TextStyle(fontFamily: AppTheme.fontFamily,
                        fontSize: 13, color: AppTheme.primaryDark, height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DocSlot { selfieWithFrontId, selfieWithBackId, driverLicense, carRegistration, carWithPlate }

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({required this.ctrl, required this.label, required this.hint,
    required this.icon, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
    ),
  );
}

class _VehicleOption extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _VehicleOption({required this.label, required this.value,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border, width: 1.5),
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppTheme.fontFamily,
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primary : AppTheme.textSecondary)),
      ),
    ),
  );
}

class _DocUploader extends StatelessWidget {
  final _DocSlot slot;
  final String label, hint;
  final IconData icon;
  final File? file;
  final VoidCallback onTap;
  const _DocUploader({required this.slot, required this.label, required this.hint,
    required this.icon, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: file != null ? AppTheme.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null ? AppTheme.primary : AppTheme.border,
          width: file != null ? 1.5 : 0.5),
      ),
      child: Row(
        children: [
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(file!, width: 50, height: 50, fit: BoxFit.cover))
          else
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppTheme.textHint, size: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: file != null ? AppTheme.primaryDark : AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(file != null ? '✓ Photo captured' : hint,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily, fontSize: 11,
                    color: file != null ? AppTheme.primary : AppTheme.textHint)),
              ],
            ),
          ),
          Icon(
            file != null ? Icons.check_circle : Icons.camera_alt_outlined,
            color: file != null ? AppTheme.primary : AppTheme.textHint, size: 22),
        ],
      ),
    ),
  );
}

class _DocNote extends StatelessWidget {
  const _DocNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.warningLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.warning.withOpacity(0.4), width: 0.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.camera_alt, color: AppTheme.warning, size: 18),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Please use your camera to take clear, well-lit photos. '
            'All 5 documents are required. Photos will be securely stored.',
            style: TextStyle(fontFamily: AppTheme.fontFamily,
              fontSize: 12, color: Color(0xFF854F0B), height: 1.5)),
        ),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  final String label, value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(width: 70,
          child: Text(label, style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13, color: AppTheme.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
