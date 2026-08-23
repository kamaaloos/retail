import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'auth/role_permissions.dart';
import 'data/database.dart';
import 'l10n/app_strings.dart';
import 'providers/retail_store.dart';
import 'ui/login_page.dart';
import 'ui/pages.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US');
  await initializeDateFormatting('en_GB');
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('ar');
  await initializeDateFormatting('ar_SA');
  await AppDatabase.instance.init();

  final store = RetailStore();
  await store.load();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const ShopXApp(),
    ),
  );
}

class ShopXApp extends StatelessWidget {
  const ShopXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final strings = AppStrings.of(store.language);

    return MaterialApp(
      title: strings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildRetailTheme(dark: store.darkMode),
      locale: strings.materialLocale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('fr', 'FR'),
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    if (store.loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    if (!store.isLoggedIn) {
      return const LoginPage();
    }
    return const AppShell();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage _page = AppPage.dashboard;

  String _pageLabel(AppPage page, AppStrings s) {
    return switch (page) {
      AppPage.dashboard => s.dashboard,
      AppPage.pos => s.pos,
      AppPage.products => s.products,
      AppPage.categories => s.categories,
      AppPage.salesHistory => s.salesHistory,
      AppPage.inventory => s.inventory,
      AppPage.staff => s.staff,
      AppPage.shifts => s.shifts,
      AppPage.reports => s.reports,
      AppPage.settings => s.settings,
    };
  }

  void _goTo(AppPage page, String role) {
    if (!RolePermissions.canAccess(role, page)) return;
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final strings = AppStrings.of(store.language);
    final role = store.loggedInEmployee?.role ?? 'cashier';
    final allowed = RolePermissions.allowedPages(role);
    final activePage = allowed.contains(_page) ? _page : RolePermissions.defaultPage(role);
    if (activePage != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = activePage);
      });
    }
    final session = store.loggedInEmployee;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppColors.panel,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AppLogo(size: 36, radius: 10, storeLogoPath: store.storeLogoPath),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.appName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: allowed.length,
                    itemBuilder: (context, i) {
                      final page = allowed[i];
                      final selected = activePage == page;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () => _goTo(page, role),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? page.iconFilled : page.iconOutlined,
                                  size: 20,
                                  color: selected ? AppColors.accent : AppColors.muted,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _pageLabel(page, strings),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected ? AppColors.text : AppColors.muted,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          (session?.name ?? 'A').characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session?.name ?? strings.adminFallback,
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                            Text(
                              strings.roleLabel(session?.role ?? 'owner').toUpperCase(),
                              style: TextStyle(color: AppColors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => context.read<RetailStore>().logout(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.logout, size: 18, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.bg,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(activePage.navIndex),
                  child: _buildPage(activePage, role, strings),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(AppPage page, String role, AppStrings strings) {
    if (!RolePermissions.canAccess(role, page)) {
      return Center(
        child: Text(strings.accessDenied, style: TextStyle(color: AppColors.muted)),
      );
    }

    switch (page) {
      case AppPage.pos:
        return const PosPage();
      case AppPage.products:
        return const ProductsPage();
      case AppPage.categories:
        return const CategoriesPage();
      case AppPage.salesHistory:
        return const SalesHistoryPage();
      case AppPage.inventory:
        return const InventoryPage();
      case AppPage.staff:
        return const StaffPage();
      case AppPage.shifts:
        return const ShiftsPage();
      case AppPage.reports:
        return const ReportsPage();
      case AppPage.settings:
        return const SettingsPage();
      case AppPage.dashboard:
        return DashboardHome(onOpenPos: () => _goTo(AppPage.pos, role));
    }
  }
}
