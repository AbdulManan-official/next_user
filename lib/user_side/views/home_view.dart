import 'package:flutter/material.dart';
import '../../utils/app_theme_styles.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/animation_helper.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/logout_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../auth/views/login_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  void _onLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to log out of your account?',
      confirmText: 'Log Out',
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      AppSnackBar.showInfo(context, 'Signed out successfully.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              AppSnackBar.showInfo(context, 'No new notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsive.pagePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsive.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                AppFadeAnimation(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.r(20)),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'PREMIUM ACCESS',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.h(12)),
                        Text(
                          'Welcome to Next User',
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontSize: context.sp(22),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Explore our elite suite of services tailored just for you.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: context.sp(13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: context.h(20)),

                // Search Bar
                const AppFadeAnimation(
                  delay: Duration(milliseconds: 100),
                  child: CustomSearchBar(
                    hintText: 'Search services, bookings...',
                  ),
                ),

                SizedBox(height: context.h(24)),

                // Quick Services Grid Section
                AppFadeAnimation(
                  delay: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Services',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: context.sp(18),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.h(12)),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.responsive.gridColumns(
                      mobile: 2,
                      tablet: 4,
                      desktop: 4,
                    ),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final services = [
                      {'title': 'VIP Booking', 'icon': Icons.stars_rounded},
                      {'title': 'Chauffeur', 'icon': Icons.directions_car_rounded},
                      {'title': 'Concierge', 'icon': Icons.room_service_rounded},
                      {'title': 'Assistance', 'icon': Icons.support_agent_rounded},
                    ];
                    final item = services[index];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: AppColors.gold,
                            size: context.r(32),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'] as String,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: context.sp(14),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_sharp),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
