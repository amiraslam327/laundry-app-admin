import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:laundry_app/features/auth/presentation/pages/login_page.dart';
import 'package:laundry_app/shared/presentation/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_app/features/admin/presentation/pages/dashboard/admin_dashboard_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/laundries/add_laundry_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/services/add_service_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/service_items/add_service_item_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/laundries/laundries_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/services/services_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/service_items/items_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/fragrances/fragrances_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/fragrances/add_fragrance_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/drivers/drivers_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/orders/orders_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/orders/order_details_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/settings/admin_settings_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/admins/add_admin_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/admins/admin_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/laundries/map_picker_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/service_categories/service_categories_list_page.dart';
import 'package:laundry_app/features/admin/presentation/pages/service_categories/add_service_category_page.dart';

// Note: Router redirect now handled by checking FirestoreAuthService
// Auto-login is handled by FirestoreAuthNotifier which restores state from SharedPreferences
final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    // Check if we're on login page and user is logged in
    if (state.matchedLocation == '/login') {
      // Let LoginPage handle the redirect after state is restored
      return null;
    }

    // For other routes, let pages handle their own auth checks
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/add-laundry',
      builder: (context, state) {
        final laundryId = state.uri.queryParameters['id'];
        return AddLaundryPage(laundryId: laundryId);
      },
    ),
    GoRoute(
      path: '/admin/map-picker',
      builder: (context, state) {
        final lat = state.uri.queryParameters['lat'];
        final lng = state.uri.queryParameters['lng'];
        final address = state.uri.queryParameters['address'];
        LatLng? initialLocation;
        if (lat != null && lng != null) {
          initialLocation = LatLng(double.parse(lat), double.parse(lng));
        }
        return MapPickerPage(
          initialLocation: initialLocation,
          initialAddress: address,
        );
      },
    ),
    GoRoute(
      path: '/admin/add-service',
      builder: (context, state) {
        final serviceId = state.uri.queryParameters['id'];
        return AddServicePage(serviceId: serviceId);
      },
    ),
    GoRoute(
      path: '/admin/add-service-item',
      builder: (context, state) {
        final itemId = state.uri.queryParameters['id'];
        final categoryId = state.uri.queryParameters['categoryId'];
        return AddServiceItemPage(itemId: itemId, categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/admin/laundries',
      builder: (context, state) => const LaundriesListPage(),
    ),
    GoRoute(
      path: '/admin/services',
      builder: (context, state) => const ServicesListPage(),
    ),
    GoRoute(
      path: '/admin/items',
      builder: (context, state) => const ItemsListPage(),
    ),
    GoRoute(
      path: '/admin/fragrances',
      builder: (context, state) => const FragrancesListPage(),
    ),
    GoRoute(
      path: '/admin/add-fragrance',
      builder: (context, state) {
        final fragranceId = state.uri.queryParameters['id'];
        return AddFragrancePage(fragranceId: fragranceId);
      },
    ),
    GoRoute(
      path: '/admin/drivers',
      builder: (context, state) => const DriversListPage(),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const OrdersListPage(),
    ),
    GoRoute(
      path: '/admin/orders/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderDetailsPage(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsPage(),
    ),
    GoRoute(
      path: '/admin/admin-list',
      builder: (context, state) => const AdminListPage(),
    ),
    GoRoute(
      path: '/admin/add-admin',
      builder: (context, state) => const AddAdminPage(),
    ),
    GoRoute(
      path: '/admin/service-categories',
      builder: (context, state) => const ServiceCategoriesListPage(),
    ),
    GoRoute(
      path: '/admin/add-service-category',
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['id'];
        return AddServiceCategoryPage(categoryId: categoryId);
      },
    ),
  ],
);

