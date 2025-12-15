import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/widgets/app_button.dart';
import 'package:laundry_app/shared/presentation/widgets/app_text_field.dart';
import 'package:laundry_app/shared/domain/models/laundry_model.dart';
import 'package:laundry_app/features/admin/presentation/pages/laundries/map_picker_page.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AddLaundryPage extends ConsumerStatefulWidget {
  final String? laundryId;
  
  const AddLaundryPage({super.key, this.laundryId});

  @override
  ConsumerState<AddLaundryPage> createState() => _AddLaundryPageState();
}

class _AddLaundryPageState extends ConsumerState<AddLaundryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  bool _isSelectingLocation = false;
  bool _isLoadingData = false;
  String _countryCode = '+966';
  String _phoneNumber = '';
  LaundryModel? _editingLaundry;

  @override
  void initState() {
    super.initState();
    if (widget.laundryId != null) {
      _loadLaundryData();
    }
  }

  Future<void> _loadLaundryData() async {
    if (widget.laundryId == null) return;
    
    setState(() => _isLoadingData = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('laundries').doc(widget.laundryId).get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _editingLaundry = LaundryModel.fromMap(data);
        
        // Populate all fields
        _nameController.text = _editingLaundry!.name;
        _descriptionController.text = _editingLaundry!.description;
        _addressController.text = _editingLaundry!.address;
        _workingHoursController.text = _editingLaundry!.workingHours;
        
        // Parse phone number
        final phone = _editingLaundry!.phone;
        if (phone.isNotEmpty) {
          // Extract country code and number
          if (phone.startsWith('+')) {
            // Try common patterns: +966123456789 or +966 123456789
            final match = RegExp(r'^\+(\d{1,3})\s*(.+)$').firstMatch(phone);
            if (match != null) {
              _countryCode = '+${match.group(1)}';
              _phoneNumber = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
            } else {
              // Try without space: +966123456789
              final match2 = RegExp(r'^\+(\d{1,3})(\d+)$').firstMatch(phone);
              if (match2 != null) {
                _countryCode = '+${match2.group(1)}';
                _phoneNumber = match2.group(2)!;
              } else {
                // Default: assume +966 if starts with +, otherwise use stored value
                if (phone.startsWith('+966')) {
                  _countryCode = '+966';
                  _phoneNumber = phone.substring(4).replaceAll(RegExp(r'\s+'), '');
                } else {
                  _countryCode = '+966';
                  _phoneNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
                }
              }
            }
            _phoneController.text = _phoneNumber;
          } else {
            _phoneNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
            _phoneController.text = _phoneNumber;
          }
        }
        
        // Set location
        if (_editingLaundry!.lat != 0.0 && _editingLaundry!.lng != 0.0) {
          _selectedLocation = LatLng(_editingLaundry!.lat, _editingLaundry!.lng);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading laundry data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _openFullScreenMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(
          initialLocation: _selectedLocation,
          initialAddress: _addressController.text.trim().isNotEmpty 
              ? _addressController.text.trim() 
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      final location = result['location'] as LatLng?;
      final address = result['address'] as String?;

      if (location != null) {
        setState(() {
          _selectedLocation = location;
        });

        // Update address field
        if (address != null && address.isNotEmpty) {
          _addressController.text = address;
        }

        // Update map camera
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15),
          );
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isSelectingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          _addressController.text = 
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
        }
      } catch (e) {
        // Error getting address
      }

      if (_mapController != null && _selectedLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isSelectingLocation = false);
    }
  }

  Future<void> _saveLaundry() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final isEditing = widget.laundryId != null;
      final laundryId = widget.laundryId ?? const Uuid().v4();

      // Get existing data if editing
      Map<String, dynamic> laundryData = {
        'id': laundryId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneNumber.isNotEmpty 
            ? (_countryCode.isNotEmpty ? '$_countryCode$_phoneNumber' : _phoneNumber)
            : (_editingLaundry?.phone ?? ''),
        'address': _addressController.text.trim(),
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'workingHours': _workingHoursController.text.trim(),
      };

      if (isEditing) {
        // Preserve existing fields when editing
        final existingDoc = await firestore.collection('laundries').doc(laundryId).get();
        if (existingDoc.exists) {
          final existingData = existingDoc.data()!;
          laundryData['rating'] = existingData['rating'] ?? 0.0;
          laundryData['isOpen'] = existingData['isOpen'] ?? true;
          laundryData['logoUrl'] = existingData['logoUrl'];
          laundryData['isPreferred'] = existingData['isPreferred'] ?? false;
          laundryData['minOrderAmount'] = existingData['minOrderAmount'] ?? 0.0;
          laundryData['discountPercentage'] = existingData['discountPercentage'] ?? 0;
          laundryData['bannerImageUrl'] = existingData['bannerImageUrl'];
        }
        await firestore.collection('laundries').doc(laundryId).update(laundryData);
      } else {
        // New laundry - set default values
        laundryData['rating'] = 0.0;
        laundryData['isOpen'] = true;
        laundryData['logoUrl'] = null;
        laundryData['isPreferred'] = false;
        laundryData['minOrderAmount'] = 0.0;
        laundryData['discountPercentage'] = 0;
        laundryData['bannerImageUrl'] = null;
        await firestore.collection('laundries').doc(laundryId).set(laundryData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
                ? 'Laundry updated successfully!' 
                : 'Laundry added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving laundry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.laundryId != null;
    
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Laundry' : 'Add Laundry'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Laundry' : 'Add Laundry'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Laundry Name *',
                controller: _nameController,
                prefixIcon: const Icon(Icons.local_laundry_service),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter laundry name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description *',
                controller: _descriptionController,
                maxLines: 3,
                prefixIcon: const Icon(Icons.description),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  hintText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                initialCountryCode: 'SA', // Saudi Arabia
                onChanged: (phone) {
                  _countryCode = phone.countryCode;
                  _phoneNumber = phone.number;
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Address *',
                controller: _addressController,
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Working Hours *',
                controller: _workingHoursController,
                hint: 'e.g., Mon-Fri: 9AM-6PM',
                prefixIcon: const Icon(Icons.access_time),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter working hours';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Map Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Location *',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: _openFullScreenMap,
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Open Map'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isSelectingLocation ? null : _getCurrentLocation,
                                icon: _isSelectingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location, size: 18),
                                label: const Text('Current'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            height: 350,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryBlue, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation ?? 
                                (_editingLaundry != null && _editingLaundry!.lat != 0.0 && _editingLaundry!.lng != 0.0
                                  ? LatLng(_editingLaundry!.lat, _editingLaundry!.lng)
                                  : const LatLng(24.7136, 46.6753)), // Riyadh default
                              zoom: _selectedLocation != null || (_editingLaundry != null && _editingLaundry!.lat != 0.0) ? 15 : 12,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              // If editing and location is set, update map camera
                              if (_selectedLocation != null || 
                                  (_editingLaundry != null && _editingLaundry!.lat != 0.0 && _editingLaundry!.lng != 0.0)) {
                                final location = _selectedLocation ?? 
                                    LatLng(_editingLaundry!.lat, _editingLaundry!.lng);
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLngZoom(location, 15),
                                    );
                                  }
                                });
                              }
                            },
                            onTap: (LatLng location) async {
                              setState(() {
                                _selectedLocation = location;
                              });
                              
                              // Update map camera to tapped location
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(location, 15),
                                );
                              }
                              
                              // Get address from coordinates (reverse geocoding)
                              try {
                                List<Placemark> placemarks = await placemarkFromCoordinates(
                                  location.latitude,
                                  location.longitude,
                                );
                                if (placemarks.isNotEmpty && mounted) {
                                  final place = placemarks[0];
                                  final address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
                                  if (address.isNotEmpty) {
                                    setState(() {
                                      _addressController.text = address;
                                    });
                                  }
                                }
                              } catch (e) {
                                // Error getting address from coordinates
                              }
                            },
                            markers: (_selectedLocation != null || 
                                (_editingLaundry != null && _editingLaundry!.lat != 0.0 && _editingLaundry!.lng != 0.0))
                                ? {
                                    Marker(
                                      markerId: const MarkerId('selected'),
                                      position: _selectedLocation ?? LatLng(_editingLaundry!.lat, _editingLaundry!.lng),
                                      infoWindow: const InfoWindow(title: 'Selected Location'),
                                    ),
                                  }
                                : {},
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                            mapType: MapType.normal,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                      if (_selectedLocation != null || 
                          (_editingLaundry != null && _editingLaundry!.lat != 0.0 && _editingLaundry!.lng != 0.0)) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lat: ${(_selectedLocation?.latitude ?? _editingLaundry!.lat).toStringAsFixed(6)}, '
                                  'Lng: ${(_selectedLocation?.longitude ?? _editingLaundry!.lng).toStringAsFixed(6)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap on the map to select a location',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: isEditing ? 'Update Laundry' : 'Save Laundry',
                onPressed: _saveLaundry,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

