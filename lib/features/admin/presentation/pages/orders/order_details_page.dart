import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundry_app/core/config/theme/app_theme.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final DateFormat _dateFormat = DateFormat('yMMMd • h:mm a');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en',
    symbol: 'SAR ',
    decimalDigits: 2,
  );

  bool _isUpdating = false;
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    final shortId =
        widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId;
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc('pending')
            .collection('pending')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Order not found'),
            );
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final status = (data['status'] ?? 'Unknown').toString();
          final totalAmount = _formatCurrency(
            data['totalPrice'] ?? data['totalAmount'] ?? data['total'] ?? 0,
          );
          final discountAmount = _formatCurrency(
            data['discountAmount'] ?? data['discount'] ?? 0,
          );
          final createdAt = _formatDate(data['createdAt']);
          final paymentStatus = (data['paymentStatus'] ?? 'Not set').toString();
          final paymentMethod = (data['paymentMethod'] ?? 'Not set').toString();
          final items = (data['items'] as List?) ?? <dynamic>[];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(status, totalAmount, createdAt),
                      if (_lastError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _lastError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'Customer',
                        children: [
                          _buildDetailRow(
                            'Name',
                            data['customerName'] ??
                                data['userName'] ??
                                data['name'] ??
                                'Not set',
                          ),
                          _buildDetailRow(
                            'Phone',
                            data['customerPhone'] ??
                                data['userPhone'] ??
                                data['phoneNumber'] ??
                                data['phone'] ??
                                'Not set',
                          ),
                          _buildDetailRow('User ID', data['userId'] ?? 'Not set'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'Addresses',
                        children: [
                          _buildDetailRow(
                            'Pickup',
                            data['pickupAddress'] ?? data['address'] ?? 'Not set',
                          ),
                          _buildDetailRow(
                            'Drop-off',
                            data['deliveryAddress'] ??
                                data['dropoffAddress'] ??
                                'Not set',
                          ),
                          _buildDetailRow(
                            'Notes',
                            data['notes'] ?? data['specialInstructions'] ?? 'None',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'Schedule',
                        children: [
                          _buildDetailRow('Created', createdAt),
                          _buildDetailRow(
                            'Pickup Time',
                            _formatDate(data['pickupTime'] ?? data['scheduledAt']),
                          ),
                          _buildDetailRow(
                            'Delivery Time',
                            _formatDate(data['deliveryTime'] ?? data['deliveryAt']),
                          ),
                          _buildDetailRow(
                            'Updated',
                            _formatDate(data['updatedAt']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'Payment',
                        children: [
                          _buildDetailRow('Method', paymentMethod),
                          _buildDetailRow('Status', paymentStatus),
                    _buildDetailRow('Total', totalAmount),
                          _buildDetailRow(
                      'Delivery Fee',
                      _formatCurrency(data['deliveryFee']),
                    ),
                    _buildDetailRow('Discount', discountAmount),
                          _buildDetailRow(
                            'Tax',
                            _formatCurrency(data['tax']),
                          ),
                          _buildDetailRow(
                            'Payment Ref',
                            data['paymentId'] ??
                                data['transactionId'] ??
                                'Not set',
                          ),
                        ],
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: 'Items',
                          children: [
                            for (final item in items)
                              _buildItemTile(item as Map<String, dynamic>?),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildSectionCard(
                        title: 'Assignment & Meta',
                        children: [
                          _buildDetailRow(
                            'Driver',
                            data['driverName'] ??
                                data['driverId'] ??
                                data['assignedDriver'] ??
                                'Not assigned',
                          ),
                          _buildDetailRow(
                            'Laundry',
                            data['laundryName'] ??
                                data['laundryId'] ??
                                data['laundry'] ??
                                'Not set',
                          ),
                          _buildDetailRow(
                            'Service',
                            data['serviceName'] ??
                                data['serviceId'] ??
                                data['service'] ??
                                'Not set',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildStatusActions(status, data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusActions(String status, Map<String, dynamic> data) {
    final steps = <String>[
      'accepted',
      'processing',
      'ready for pickup',
      'out for delivery',
      'complete',
    ];

    final currentIndex =
        steps.indexWhere((s) => s.toLowerCase() == status.toLowerCase());

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: steps.map((step) {
                final isCurrent = step.toLowerCase() == status.toLowerCase();
                final isNext = steps.indexOf(step) == currentIndex + 1;
                final isComplete = step == 'complete';
                final enabled =
                    !_isUpdating && (isCurrent || isNext || (currentIndex < 0));

                return ElevatedButton(
                  onPressed: enabled
                      ? () => _handleStatusChange(step, data, isComplete)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCurrent ? AppTheme.primaryBlue : Colors.grey.shade200,
                    foregroundColor:
                        isCurrent ? Colors.white : AppTheme.textPrimary,
                  ),
                  child: _isUpdating &&
                          step.toLowerCase() == status.toLowerCase()
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(step),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel order?'),
                          content: const Text(
                            'This will move the order to cancelled. Are you sure?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _handleCancel(data);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.cancel),
              label: _isUpdating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(
    String newStatus,
    Map<String, dynamic> data,
    bool isComplete,
  ) async {
    setState(() {
      _isUpdating = true;
      _lastError = null;
    });

    try {
      final pendingDoc = FirebaseFirestore.instance
          .collection('orders')
          .doc('pending')
          .collection('pending')
          .doc(widget.orderId);

      if (isComplete) {
        final completeDoc = FirebaseFirestore.instance
            .collection('orders')
            .doc('complete')
            .collection('complete')
            .doc(widget.orderId);

        await FirebaseFirestore.instance.runTransaction((txn) async {
          final pendingSnap = await txn.get(pendingDoc);
          if (!pendingSnap.exists) {
            throw Exception('Order not found in pending');
          }
          final pendingData = pendingSnap.data() ?? {};
          final updated = {
            ...pendingData,
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
          };
          txn.set(completeDoc, updated);
          txn.delete(pendingDoc);
        });
      } else {
        await pendingDoc.update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _handleCancel(Map<String, dynamic> data) async {
    setState(() {
      _isUpdating = true;
      _lastError = null;
    });

    try {
      final pendingDoc = FirebaseFirestore.instance
          .collection('orders')
          .doc('pending')
          .collection('pending')
          .doc(widget.orderId);

      final cancelDoc = FirebaseFirestore.instance
          .collection('orders')
          .doc('cancel')
          .collection('cancel')
          .doc(widget.orderId);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final pendingSnap = await txn.get(pendingDoc);
        if (!pendingSnap.exists) {
          throw Exception('Order not found in pending');
        }
        final pendingData = pendingSnap.data() ?? {};
        final updated = {
          ...pendingData,
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
          'cancelledAt': FieldValue.serverTimestamp(),
        };
        txn.set(cancelDoc, updated);
        txn.delete(pendingDoc);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildStatusCard(String status, String total, String createdAt) {
    return Card(
      color: AppTheme.primaryBlue.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(status),
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(
                    side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.4)),
                  ),
                  labelStyle: TextStyle(
                    color: AppTheme.primaryBlue.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Created', createdAt),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final text = (value?.toString().isNotEmpty ?? false) ? value.toString() : 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic>? item) {
    final name = item?['name'] ??
        item?['itemName'] ??
        item?['serviceName'] ??
        'Item';
    final quantity = item?['quantity'] ?? item?['qty'] ?? 1;
    final priceValue =
        item?['price'] ?? item?['unitPrice'] ?? item?['total'] ?? 0;
    final total = _formatCurrency(priceValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Qty: $quantity'),
              const Spacer(),
              Text(
                total,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    try {
      if (value == null) return 'Not set';
      DateTime dateTime;
      if (value is Timestamp) {
        dateTime = value.toDate();
      } else if (value is DateTime) {
        dateTime = value;
      } else {
        return value.toString();
      }
      return _dateFormat.format(dateTime.toLocal());
    } catch (_) {
      return 'Not set';
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'SAR 0.00';
    try {
      if (value is num) {
        return _currencyFormat.format(value);
      }
      return _currencyFormat.format(double.tryParse(value.toString()) ?? 0);
    } catch (_) {
      return 'SAR 0.00';
    }
  }
}

