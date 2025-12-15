import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';
import 'package:laundry_app/shared/presentation/providers/app_providers.dart';
import 'package:laundry_app/shared/domain/models/admin_model.dart';

class AdminListPage extends ConsumerStatefulWidget {
  const AdminListPage({super.key});

  @override
  ConsumerState<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends ConsumerState<AdminListPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter options
  String _sortBy = 'name'; // 'name', 'email', 'date'
  bool _showOnlyCurrentUser = false;
  bool _hasActiveFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.filter_list, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text('Filter & Sort'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Name'),
                value: 'name',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Email'),
                value: 'email',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Date Created'),
                value: 'date',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Show Only Current User'),
                value: _showOnlyCurrentUser,
                onChanged: (value) {
                  setDialogState(() {
                    _showOnlyCurrentUser = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _sortBy = 'name';
                  _showOnlyCurrentUser = false;
                  _hasActiveFilters = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasActiveFilters = _showOnlyCurrentUser || _sortBy != 'name';
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(allAdminsProvider);
    final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
    final currentUserId = firestoreAuthState.adminId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter & Sort',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/add-admin'),
            tooltip: 'Add New Admin',
          ),
        ],
      ),
      body: adminsAsync.when(
        data: (admins) {
          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No admins found'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/add-admin'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Admin'),
                  ),
                ],
              ),
            );
          }

          // Apply filters and sorting
          var filteredAdmins = List<AdminModel>.from(admins);
          
          // Filter: Show only current user if selected
          if (_showOnlyCurrentUser) {
            filteredAdmins = filteredAdmins.where((admin) => admin.id == currentUserId).toList();
          } else {
            // Sort: current user first, then others
            filteredAdmins.sort((a, b) {
              final aIsCurrent = a.id == currentUserId;
              final bIsCurrent = b.id == currentUserId;
              if (aIsCurrent && !bIsCurrent) return -1; // Current user first
              if (!aIsCurrent && bIsCurrent) return 1;  // Current user first
              return 0; // Keep original order for others
            });
          }
          
          // Apply sorting
          if (_sortBy == 'name') {
            filteredAdmins.sort((a, b) {
              final aName = a.fullName.isNotEmpty ? a.fullName.toLowerCase() : a.email.toLowerCase();
              final bName = b.fullName.isNotEmpty ? b.fullName.toLowerCase() : b.email.toLowerCase();
              return aName.compareTo(bName);
            });
            // Re-apply current user first after name sort
            if (!_showOnlyCurrentUser) {
              final currentUser = filteredAdmins.firstWhere(
                (admin) => admin.id == currentUserId,
                orElse: () => filteredAdmins.first,
              );
              if (currentUser.id == currentUserId) {
                filteredAdmins.remove(currentUser);
                filteredAdmins.insert(0, currentUser);
              }
            }
          } else if (_sortBy == 'email') {
            filteredAdmins.sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
            // Re-apply current user first after email sort
            if (!_showOnlyCurrentUser) {
              final currentUser = filteredAdmins.firstWhere(
                (admin) => admin.id == currentUserId,
                orElse: () => filteredAdmins.first,
              );
              if (currentUser.id == currentUserId) {
                filteredAdmins.remove(currentUser);
                filteredAdmins.insert(0, currentUser);
              }
            }
          } else if (_sortBy == 'date') {
            filteredAdmins.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
            // Re-apply current user first after date sort
            if (!_showOnlyCurrentUser) {
              final currentUser = filteredAdmins.firstWhere(
                (admin) => admin.id == currentUserId,
                orElse: () => filteredAdmins.first,
              );
              if (currentUser.id == currentUserId) {
                filteredAdmins.remove(currentUser);
                filteredAdmins.insert(0, currentUser);
              }
            }
          }
          
          final sortedAdmins = filteredAdmins;

          // Filter admins based on search query
          final searchQuery = _searchController.text.toLowerCase().trim();
          final finalFilteredAdmins = searchQuery.isEmpty
              ? sortedAdmins
              : sortedAdmins.where((admin) {
                  return admin.email.toLowerCase().contains(searchQuery) ||
                      (admin.fullName.isNotEmpty && 
                       admin.fullName.toLowerCase().contains(searchQuery));
                }).toList();

          // Separate current user from other admins
          AdminModel? currentUserAdmin;
          final otherAdmins = <AdminModel>[];
          
          for (final admin in finalFilteredAdmins) {
            if (admin.id == currentUserId) {
              currentUserAdmin = admin;
            } else {
              otherAdmins.add(admin);
            }
          }

          return Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email or name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to update filtered list
                  },
                ),
              ),
              // Current User Card (Fixed - Not Scrollable)
              if (currentUserAdmin != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    child: ListTile(
                      onTap: () => _showAdminDetails(context, currentUserAdmin!, true),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text(
                          currentUserAdmin!.fullName.isNotEmpty
                              ? currentUserAdmin!.fullName[0].toUpperCase()
                              : (currentUserAdmin!.email.isNotEmpty ? currentUserAdmin!.email[0].toUpperCase() : 'A'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentUserAdmin!.fullName.isNotEmpty ? currentUserAdmin!.fullName : currentUserAdmin!.email,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  currentUserAdmin!.email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (currentUserAdmin!.phoneNumber.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    currentUserAdmin!.phoneNumber,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.badge, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Role: ${currentUserAdmin!.role}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Current User',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Other Admins List (Scrollable)
              Expanded(
                child: otherAdmins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No other admins found'
                                  : 'No admins found matching "$searchQuery"',
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: otherAdmins.length,
                        itemBuilder: (context, index) {
                          final admin = otherAdmins[index];
              final isCurrentUser = false; // Always false for other admins
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _showAdminDetails(context, admin, isCurrentUser),
                  leading: CircleAvatar(
                    backgroundColor: isCurrentUser 
                        ? AppTheme.primaryBlue 
                        : Colors.grey[400],
                    child: Text(
                      admin.fullName.isNotEmpty 
                          ? admin.fullName[0].toUpperCase() 
                          : (admin.email.isNotEmpty ? admin.email[0].toUpperCase() : 'A'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          admin.fullName.isNotEmpty ? admin.fullName : admin.email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              admin.email,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (admin.phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                admin.phoneNumber,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.badge, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Role: ${admin.role}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: isCurrentUser
                      ? const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text(
                            'Current User',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAdmin(context, ref, admin),
                          tooltip: 'Delete Admin',
                        ),
                ),
              );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allAdminsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminDetails(BuildContext context, AdminModel admin, bool isCurrentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCurrentUser 
                  ? AppTheme.primaryBlue 
                  : Colors.grey[400],
              child: Text(
                admin.fullName.isNotEmpty 
                    ? admin.fullName[0].toUpperCase() 
                    : (admin.email.isNotEmpty ? admin.email[0].toUpperCase() : 'A'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.fullName.isNotEmpty ? admin.fullName : 'Admin',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isCurrentUser)
                    const Text(
                      'Current User',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.person, 'Full Name', admin.fullName.isNotEmpty ? admin.fullName : 'Not set'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.email, 'Email', admin.email),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.phone, 'Phone Number', admin.phoneNumber.isNotEmpty ? admin.phoneNumber : 'Not set'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_today, 'Created At', _formatDate(admin.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!isCurrentUser)
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close details dialog
                _deleteAdmin(context, ref, admin);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteAdmin(
    BuildContext context,
    WidgetRef ref,
    AdminModel admin,
  ) async {
    final firestoreAuthState = ref.watch(firestoreAuthServiceProvider);
    final currentUserId = firestoreAuthState.adminId;
    
    // Prevent deleting current user
    if (admin.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog with email
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this admin permanently?'),
            const SizedBox(height: 12),
            if (admin.fullName.isNotEmpty) ...[
              Text(
                'Name: ${admin.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Email: ${admin.email}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool authDeleted = false;
    try {
      final adminRepository = ref.read(adminRepositoryProvider);

      // Step 1: Delete Firestore document
      await adminRepository.deleteAdmin(admin.id);

      // Step 2: Delete Firebase Auth user via Cloud Function
      try {
        final functions = FirebaseFunctions.instance;
        final callable = functions.httpsCallable('deleteAdminAccount');
        await callable.call({'uid': admin.id});
        authDeleted = true;
      } catch (e) {
        // Check if it's a "not found" error (function not deployed)
        final errorString = e.toString();
        if (errorString.contains('not-found') || errorString.contains('NOT_FOUND')) {
          // Cloud Function not deployed yet
        } else {
          // Error calling deleteAdminAccount Cloud Function
        }
        // Still show success since Firestore deletion succeeded
        // The admin won't be able to login anyway since Firestore doc is deleted
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show appropriate message based on whether Auth was deleted
        final message = authDeleted
            ? 'Admin deleted successfully from Firestore and Authentication'
            : 'Admin deleted from Firestore. Note: Cloud Function not deployed - Auth account may still exist.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: authDeleted ? Colors.green : Colors.orange,
            duration: Duration(seconds: authDeleted ? 2 : 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

