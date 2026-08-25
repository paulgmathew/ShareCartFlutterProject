import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_optimization_provider.dart';

class PriceLocationSettingsScreen extends StatefulWidget {
  const PriceLocationSettingsScreen({super.key});

  @override
  State<PriceLocationSettingsScreen> createState() =>
      _PriceLocationSettingsScreenState();
}

class _PriceLocationSettingsScreenState
    extends State<PriceLocationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());

    final provider = context.read<PriceOptimizationProvider>();
    await provider.saveLocation(
      latitude: latitude,
      longitude: longitude,
      address:
          _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
    );

    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      provider.clearError();
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _useCurrentLocation() async {
    final provider = context.read<PriceOptimizationProvider>();
    await provider.useCurrentLocation();

    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      provider.clearError();
      return;
    }

    final location = provider.savedLocation;
    if (location != null) {
      setState(() {
        _latitudeController.text = location.latitude.toString();
        _longitudeController.text = location.longitude.toString();
        _addressController.text = location.address ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceOptimizationProvider>();

    if (_latitudeController.text.isEmpty && provider.savedLocation != null) {
      final location = provider.savedLocation!;
      _latitudeController.text = location.latitude.toString();
      _longitudeController.text = location.longitude.toString();
      _addressController.text = location.address ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Location Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Save your current location so the app can compare nearby stores.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (double.tryParse((value ?? '').trim()) == null) {
                      return 'Enter a valid latitude';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (double.tryParse((value ?? '').trim()) == null) {
                      return 'Enter a valid longitude';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: provider.locationSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    provider.locationSaving ? 'Saving...' : 'Save Location',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      provider.locationSaving ? null : _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current GPS Location'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
