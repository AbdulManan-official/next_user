import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/move_store.dart';
import '../models/move_model.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/concierge_call_sheet.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/glass_kit.dart';
import '../widgets/image_preview_screen.dart';
import '../widgets/video_viewer_screen.dart';

enum ChatCategory { all, drivers, users, groups, admin, online }

class ChatChannelItem {
  final String id;
  final String name;
  final String role;
  final String lastMessage;
  final String time;
  final ChatCategory category;
  final IconData? icon;
  final Color? iconBgColor;
  final String? initial;
  final bool hasUnread;
  final int unreadCount;
  final bool isOnline;

  const ChatChannelItem({
    required this.id,
    required this.name,
    this.role = 'Concierge Specialist',
    required this.lastMessage,
    required this.time,
    required this.category,
    this.icon,
    this.iconBgColor,
    this.initial,
    this.hasUnread = false,
    this.unreadCount = 1,
    this.isOnline = false,
  });
}

enum ChatType { concierge, crew }

// ════════════════════════════════════════════════════════════════════════════
//  1. CHAT LIST / INBOX VIEW (WhatsApp-luxury Dark, Gold & Frosted-Glass)
// ════════════════════════════════════════════════════════════════════════════

/// Screen listing assigned Staff Members, Drivers, Concierge, Admin & Group Channels
/// for In-App Live Chat. Luxury dark, gold & frosted-glass design.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.chatType = ChatType.concierge,
    this.initialChannelId,
  });

  final ChatType chatType;
  final String? initialChannelId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  ChatCategory _selectedCategory = ChatCategory.all;

  static const Color _onlineColor = Color(0xFF25D366);

  final List<ChatChannelItem> _channels = const [
    ChatChannelItem(
      id: 'driver_manan',
      name: 'Manan Driver',
      role: 'Fleet Transport Lead · On Route',
      lastMessage: '📷 Cargo Photo Proof uploaded · Route on schedule',
      time: '12:57 PM',
      category: ChatCategory.drivers,
      icon: Icons.local_shipping_rounded,
      iconBgColor: Color(0xFF1E5B99),
      isOnline: true,
      hasUnread: true,
      unreadCount: 2,
    ),
    ChatChannelItem(
      id: 'mgmt',
      name: 'Platinum Concierge Management',
      role: 'VIP Relocation Director',
      lastMessage: '📹 Property Walkthrough Video verified and insured',
      time: '11:30 AM',
      category: ChatCategory.groups,
      icon: Icons.stars_rounded,
      iconBgColor: Color(0xFF352618),
      isOnline: true,
      hasUnread: false,
    ),
    ChatChannelItem(
      id: 'dispatch_alpha',
      name: 'Dispatch Operations Alpha',
      role: 'Fleet Control & Traffic HQ',
      lastMessage: 'Vehicle transit route verified and insured with tracking',
      time: '10:15 AM',
      category: ChatCategory.groups,
      icon: Icons.hub_rounded,
      iconBgColor: Color(0xFF2A2338),
      isOnline: false,
      hasUnread: false,
    ),
    ChatChannelItem(
      id: 'surveys_grp',
      name: 'Survey & Inventory Team',
      role: 'Digital Survey Specialists',
      lastMessage: 'Digital inventory survey report uploaded for approval',
      time: 'Yesterday',
      category: ChatCategory.groups,
      icon: Icons.inventory_2_rounded,
      iconBgColor: Color(0xFF1D3528),
      isOnline: false,
      hasUnread: false,
    ),
    ChatChannelItem(
      id: 'control_room',
      name: 'Central Control Concierge',
      role: '24/7 Priority Operations',
      lastMessage: 'Live vehicle tracking link active and authenticated',
      time: 'Yesterday',
      category: ChatCategory.admin,
      icon: Icons.admin_panel_settings_rounded,
      initial: 'C',
      iconBgColor: Color(0xFF3E3120),
      isOnline: true,
      hasUnread: false,
    ),
    ChatChannelItem(
      id: 'support_lead',
      name: 'Claims & White-Glove Support',
      role: 'Insurance & Claims Manager',
      lastMessage: '£100,000 Platinum Transit coverage certificate signed',
      time: '19/08/2026',
      category: ChatCategory.users,
      icon: Icons.verified_user_rounded,
      iconBgColor: Color(0xFF352618),
      isOnline: false,
      hasUnread: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // If an initial channel ID was specified, automatically handle route selection
    if (widget.initialChannelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final match = _channels.where((c) => c.id == widget.initialChannelId).firstOrNull;
        if (match != null && mounted) {
          _openChat(match);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(ChatChannelItem channel) {
    Navigator.push(
      context,
      AnimationHelper.smoothRoute(
        page: ChatConversationScreen(channel: channel),
      ),
    );
  }

  List<ChatChannelItem> get _filteredChannels {
    final query = _searchController.text.trim().toLowerCase();
    return _channels.where((c) {
      if (_selectedCategory == ChatCategory.drivers && c.category != ChatCategory.drivers) {
        return false;
      }
      if (_selectedCategory == ChatCategory.users && c.category != ChatCategory.users) {
        return false;
      }
      if (_selectedCategory == ChatCategory.groups && c.category != ChatCategory.groups) {
        return false;
      }
      if (_selectedCategory == ChatCategory.admin && c.category != ChatCategory.admin) {
        return false;
      }
      if (_selectedCategory == ChatCategory.online && !c.isOnline) {
        return false;
      }
      if (query.isNotEmpty) {
        return c.name.toLowerCase().contains(query) ||
            c.lastMessage.toLowerCase().contains(query) ||
            c.role.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  int _countFor(ChatCategory cat) {
    if (cat == ChatCategory.all) return _channels.length;
    if (cat == ChatCategory.online) return _channels.where((c) => c.isOnline).length;
    return _channels.where((c) => c.category == cat).length;
  }

  // ─── Header matching reference ContactStaffView ────────────────────────────
  Widget _buildHeader(ResponsiveHelper responsive) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.pagePadding,
        responsive.r(10),
        responsive.pagePadding,
        responsive.r(2),
      ),
      child: Row(
        children: [
          NxPressable(
            scale: 0.9,
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MESSAGES',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: responsive.sp(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chats',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: responsive.sp(26),
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _onlineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'ACTIVE',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter chip (luxury gold gradient when selected) ──────────────────────
  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
    ResponsiveHelper responsive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NxPressable(
        scale: 0.94,
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.14),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.textOnGold : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: responsive.sp(12),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Chat row (glass tile, butter-smooth 60/120fps) ────────────────────────
  Widget _buildChatItem(ChatChannelItem channel, ResponsiveHelper responsive) {
    final isAdmin = channel.category == ChatCategory.admin ||
        channel.role.toLowerCase().contains('admin');
    final isGroup = channel.category == ChatCategory.groups;
    final isDriver = channel.category == ChatCategory.drivers;
    final hasUnread = channel.hasUnread;

    // Avatar accent per contact type
    final Color avatarColor = isGroup
        ? Colors.purpleAccent
        : (isDriver ? Colors.lightBlueAccent : AppColors.gold);

    final lastMsgLower = channel.lastMessage.toLowerCase();
    IconData? mediaIcon;
    if (channel.lastMessage.contains('📷') || lastMsgLower.contains('photo')) {
      mediaIcon = Icons.camera_alt_rounded;
    } else if (channel.lastMessage.contains('📹') ||
        channel.lastMessage.contains('🎥') ||
        lastMsgLower.contains('video')) {
      mediaIcon = Icons.videocam_rounded;
    } else if (channel.lastMessage.contains('📄') || lastMsgLower.contains('document')) {
      mediaIcon = Icons.insert_drive_file_rounded;
    }

    return NxPressable(
      scale: 0.985,
      onTap: () => _openChat(channel),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.r(14),
          vertical: responsive.r(13),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasUnread
                ? [
                    AppColors.gold.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.04),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.09),
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          border: Border.all(
            color: hasUnread
                ? AppColors.gold.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.14),
            width: hasUnread ? 1.3 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with online indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: responsive.r(52),
                  height: responsive.r(52),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        avatarColor.withValues(alpha: 0.28),
                        avatarColor.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: hasUnread
                          ? AppColors.gold.withValues(alpha: 0.85)
                          : avatarColor.withValues(alpha: 0.40),
                      width: hasUnread ? 1.6 : 1.0,
                    ),
                    boxShadow: hasUnread
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isGroup
                        ? Icon(Icons.groups_rounded, color: avatarColor, size: 25)
                        : (isAdmin
                            ? const Icon(Icons.admin_panel_settings_rounded,
                                color: AppColors.gold, size: 24)
                            : (isDriver
                                ? Icon(Icons.local_shipping_rounded,
                                    color: avatarColor, size: 23)
                                : Text(
                                    channel.name.isNotEmpty
                                        ? channel.name[0].toUpperCase()
                                        : 'C',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w800,
                                      fontSize: responsive.sp(18),
                                    ),
                                  ))),
                  ),
                ),
                if (channel.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: responsive.r(13),
                      height: responsive.r(13),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _onlineColor,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _onlineColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Name, last message, time & badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                            fontSize: responsive.sp(15.5),
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        channel.time,
                        style: TextStyle(
                          color: hasUnread ? AppColors.gold : AppColors.textMuted,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                          fontSize: responsive.sp(11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (mediaIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(
                            mediaIcon,
                            size: 14,
                            color: hasUnread ? AppColors.gold : AppColors.textSecondary,
                          ),
                        )
                      else if (!hasUnread)
                        const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.done_all_rounded,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          channel.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            fontSize: responsive.sp(13),
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.goldGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.45),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${channel.unreadCount}',
                              style: const TextStyle(
                                color: AppColors.textOnGold,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(ResponsiveHelper responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: responsive.r(40),
            horizontal: responsive.r(24),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_unread_chat_alt_outlined,
                  size: 34,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _selectedCategory == ChatCategory.groups
                    ? 'No group channels found'
                    : 'No conversations found',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: responsive.sp(17),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Try adjusting your search criteria.'
                    : 'Active relocation conversations will appear here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: responsive.sp(12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final channels = _filteredChannels;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              const Positioned.fill(child: GlassAmbientBackground()),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(responsive),

                    // Search + Filter chips row
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.pagePadding,
                        responsive.r(12),
                        responsive.pagePadding,
                        responsive.r(12),
                      ),
                      child: Column(
                        children: [
                          CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Search chats, staff, drivers, users...',
                            onChanged: (_) => setState(() {}),
                            onClear: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                          SizedBox(height: responsive.r(14)),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  'All (${_countFor(ChatCategory.all)})',
                                  _selectedCategory == ChatCategory.all,
                                  () => setState(() => _selectedCategory = ChatCategory.all),
                                  responsive,
                                ),
                                _buildFilterChip(
                                  'Drivers (${_countFor(ChatCategory.drivers)})',
                                  _selectedCategory == ChatCategory.drivers,
                                  () => setState(() => _selectedCategory = ChatCategory.drivers),
                                  responsive,
                                ),
                                _buildFilterChip(
                                  'Users (${_countFor(ChatCategory.users)})',
                                  _selectedCategory == ChatCategory.users,
                                  () => setState(() => _selectedCategory = ChatCategory.users),
                                  responsive,
                                ),
                                _buildFilterChip(
                                  'Groups (${_countFor(ChatCategory.groups)})',
                                  _selectedCategory == ChatCategory.groups,
                                  () => setState(() => _selectedCategory = ChatCategory.groups),
                                  responsive,
                                ),
                                _buildFilterChip(
                                  'Admin HQ (${_countFor(ChatCategory.admin)})',
                                  _selectedCategory == ChatCategory.admin,
                                  () => setState(() => _selectedCategory = ChatCategory.admin),
                                  responsive,
                                ),
                                _buildFilterChip(
                                  'Online (${_countFor(ChatCategory.online)})',
                                  _selectedCategory == ChatCategory.online,
                                  () => setState(() => _selectedCategory = ChatCategory.online),
                                  responsive,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Channels List
                    Expanded(
                      child: channels.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) => SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: _buildEmptyState(responsive),
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: EdgeInsets.fromLTRB(
                                responsive.pagePadding,
                                responsive.r(4),
                                responsive.pagePadding,
                                responsive.r(24) + MediaQuery.paddingOf(context).bottom,
                              ),
                              itemCount: channels.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: responsive.r(10)),
                              itemBuilder: (context, index) {
                                final channel = channels[index];
                                return _buildChatItem(channel, responsive);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  2. CHAT DETAIL / CONVERSATION VIEW (WhatsApp-luxury In-App Chat)
// ════════════════════════════════════════════════════════════════════════════

/// WhatsApp-luxury In-App Chat View matching surveyor & driver side 1:1.
/// Features floating glass header, ambient aura background, gold-tinted attachment sheet,
/// curved gradient message bubbles, and multi-line expanding glass input pill.
class ChatConversationScreen extends StatefulWidget {
  final ChatChannelItem channel;

  const ChatConversationScreen({
    super.key,
    required this.channel,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final MoveStore _store = MoveStore.instance;

  bool _isOpeningMedia = false;
  bool _isSpecialistTyping = false;

  final List<String> _quickSuggestions = const [
    '👋 Arrived at property',
    '📍 Where is the vehicle now?',
    '📦 Need extra wardrobe boxes',
    '🔑 Keys left with concierge',
    '📞 Please call my mobile',
  ];

  @override
  void initState() {
    super.initState();
    // Warm up channel messages cache
    _store.getChannelMessages(widget.channel.id);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _scrollToLatest({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (force || _scrollController.position.pixels <= 40.0) {
          if (_scrollController.position.pixels > 0.0) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        }
      }
    });
  }

  void _openVideoSafely(String url, String id, String senderName) {
    if (_isOpeningMedia) return;
    _isOpeningMedia = true;
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();

    VideoViewerScreen.open(
      context,
      videoUrl: url,
      title: 'Relocation Video Walkthrough',
      subtitle: 'Channel #${widget.channel.id} • $senderName',
      albumName: 'NextGen_Chat_Videos',
      showDownloadButton: true,
    ).then((_) {
      if (mounted) {
        _focusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _isOpeningMedia = false;
      });
    });
  }

  void _openImageSafely(String url, String id, String senderName) {
    if (_isOpeningMedia) return;
    _isOpeningMedia = true;
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();

    ImagePreviewScreen.open(
      context,
      imageUrl: url,
      heroTag: 'chat_img_$id',
      title: 'Photo Attachment',
      subtitle: 'From $senderName',
      albumName: 'NextGen_Chat_Photos',
    ).then((_) {
      if (mounted) {
        _focusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _isOpeningMedia = false;
      });
    });
  }

  void _sendTextMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final userMsg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      time: timeStr,
      senderName: 'You',
    );

    _store.addMessageToChannel(widget.channel.id, userMsg);
    _msgController.clear();
    _scrollToLatest(force: true);

    // Simulate concierge/driver automated confirmation reply
    setState(() => _isSpecialistTyping = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isSpecialistTyping = false);

      final replyMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: 'Message confirmed regarding ${widget.channel.name}. Our lead is on standby.',
        isUser: false,
        time:
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        senderName: widget.channel.name,
      );
      _store.addMessageToChannel(widget.channel.id, replyMsg);
      _scrollToLatest(force: true);
    });
  }

  void _shareImage() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final msg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      text: '📷 Fragile Item & Inventory Proof',
      imagePath:
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      isUser: true,
      time: timeStr,
      senderName: 'You',
    );
    _store.addMessageToChannel(widget.channel.id, msg);
    _scrollToLatest(force: true);
  }

  void _shareVideo() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final msg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      text: '📹 Property Walkthrough Video',
      videoPath:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      isUser: true,
      time: timeStr,
      senderName: 'You',
    );
    _store.addMessageToChannel(widget.channel.id, msg);
    _scrollToLatest(force: true);
  }

  void _shareLocation() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final msg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      text: '📍 Current Location Shared',
      isLocation: true,
      latitude: 51.5074,
      longitude: -0.1278,
      isUser: true,
      time: timeStr,
      senderName: 'You',
    );
    _store.addMessageToChannel(widget.channel.id, msg);
    _scrollToLatest(force: true);
  }

  void _shareDocument() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final msg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      text: '📄 Parking Bay Suspension Permit.pdf',
      documentName: 'Parking_Permit_Central_London.pdf',
      isUser: true,
      time: timeStr,
      senderName: 'You',
    );
    _store.addMessageToChannel(widget.channel.id, msg);
    _scrollToLatest(force: true);
  }

  void _makeCall({bool isVideo = true}) {
    HapticFeedback.lightImpact();
    ConciergeCallSheet.show(
      context,
      name: widget.channel.name,
      role: isVideo ? 'Encrypted Video Line · Specialist' : 'Direct Line · Support & Dispatch',
      avatarInitials: widget.channel.initial ??
          (widget.channel.name.isNotEmpty ? widget.channel.name[0] : 'C'),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Share Attachment',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.photo_library_rounded,
                        color: Colors.purpleAccent,
                        label: 'Photo',
                        onTap: () {
                          Navigator.pop(ctx);
                          _shareImage();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.videocam_rounded,
                        color: Colors.amberAccent,
                        label: 'Video',
                        onTap: () {
                          Navigator.pop(ctx);
                          _shareVideo();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.location_on_rounded,
                        color: Colors.greenAccent,
                        label: 'Location',
                        onTap: () {
                          Navigator.pop(ctx);
                          _shareLocation();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.description_rounded,
                        color: Colors.lightBlueAccent,
                        label: 'Document',
                        onTap: () {
                          Navigator.pop(ctx);
                          _shareDocument();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return NxPressable(
      scale: 0.92,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
              border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 18),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header (Glass capsule matching reference chat) ───────────────────────
  Widget _buildHeader(ResponsiveHelper responsive) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.pagePadding,
        responsive.r(10),
        responsive.pagePadding,
        responsive.r(6),
      ),
      child: GlassCard(
        radius: 28,
        blur: 16,
        fillAlpha: 0.08,
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          children: [
            NxPressable(
              scale: 0.9,
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.gold,
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar with initial and gold rim
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.30),
                    AppColors.gold.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.75),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.channel.name.trim().isNotEmpty
                      ? widget.channel.name.trim()[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Channel ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: responsive.sp(14.5),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Channel #${widget.channel.id} • Active',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Call buttons
            _buildHeaderCallButton(
              icon: Icons.videocam_rounded,
              tooltip: 'Video Call',
              onTap: () => _makeCall(isVideo: true),
            ),
            const SizedBox(width: 8),
            _buildHeaderCallButton(
              icon: Icons.phone_rounded,
              tooltip: 'Voice Call',
              onTap: () => _makeCall(isVideo: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCallButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: NxPressable(
        scale: 0.88,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold.withValues(alpha: 0.14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.50), width: 1.1),
            boxShadow: [
              BoxShadow(color: AppColors.gold.withValues(alpha: 0.18), blurRadius: 12),
            ],
          ),
          child: Center(child: Icon(icon, color: AppColors.gold, size: 19)),
        ),
      ),
    );
  }

  // ─── Input Bar (Floating Glass Pill matching reference chat) ───────────────
  Widget _buildInputBar(ResponsiveHelper responsive) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.pagePadding,
        6,
        responsive.pagePadding,
        10,
      ),
      child: GlassCard(
        radius: 30,
        blur: 16,
        fillAlpha: 0.08,
        padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach Button
            NxPressable(
              scale: 0.88,
              onTap: _showAttachmentMenu,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.gold,
                  size: 21,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: TextField(
                focusNode: _focusNode,
                autofocus: false,
                controller: _msgController,
                cursorColor: AppColors.gold,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: responsive.sp(13.5),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Message #${widget.channel.id}...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: responsive.sp(13),
                  ),
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            const SizedBox(width: 8),

            // Send Button
            NxPressable(
              scale: 0.88,
              onTap: _sendTextMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.textOnGold,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(ResponsiveHelper responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: GlassCard(
        radius: 30,
        blur: 0,
        fillAlpha: 0.08,
        padding: EdgeInsets.symmetric(
          vertical: responsive.r(34),
          horizontal: responsive.r(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.10),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withValues(alpha: 0.18), blurRadius: 24),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 30, color: AppColors.gold),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: responsive.sp(16),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a message below to start the conversation.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: responsive.sp(12.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isVideoPath(String? path) {
    if (path == null || path.isEmpty) return false;
    final clean = path.split('?').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.avi') ||
        clean.endsWith('.mkv') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.3gp') ||
        clean.endsWith('.m4v');
  }

  // ─── Message bubbles (Curved luxury gradients matching reference) ─────────
  BoxDecoration _bubbleDecoration(bool isMe) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isMe ? 22 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 22),
    );

    if (isMe) {
      return BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: AppColors.goldGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
    }

    return BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ResponsiveHelper responsive) {
    final isMe = msg.isUser;
    final effectiveVideoPath = msg.videoPath ??
        (msg.imagePath != null && _isVideoPath(msg.imagePath) ? msg.imagePath : null);
    final effectiveImagePath =
        msg.imagePath != null && !_isVideoPath(msg.imagePath) ? msg.imagePath : null;

    final primaryTextColor = isMe ? AppColors.textOnGold : AppColors.textPrimary;
    final metaTextColor =
        isMe ? AppColors.textOnGold.withValues(alpha: 0.75) : AppColors.textSecondary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: responsive.wp(78)),
        decoration: _bubbleDecoration(isMe),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.senderName,
              style: AppTextStyles.bodySmall.copyWith(
                color: metaTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 5),

            // 1. Photo Attachment
            if (effectiveImagePath != null) ...[
              RepaintBoundary(
                child: GestureDetector(
                  onTap: () => _openImageSafely(effectiveImagePath, msg.id, msg.senderName),
                  child: Hero(
                    tag: 'chat_img_${msg.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: effectiveImagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: effectiveImagePath,
                              height: 155,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                height: 155,
                                color: Colors.black26,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (ctx, url, err) => Container(
                                height: 120,
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: AppColors.textMuted),
                                ),
                              ),
                            )
                          : Image.file(
                              File(effectiveImagePath),
                              height: 155,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 120,
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: AppColors.textMuted),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // 2. Video Attachment Card Preview
            if (effectiveVideoPath != null) ...[
              RepaintBoundary(
                child: GestureDetector(
                  onTap: () => _openVideoSafely(effectiveVideoPath, msg.id, msg.senderName),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe
                            ? AppColors.textOnGold.withValues(alpha: 0.3)
                            : Colors.white24,
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.textOnGold,
                            size: 32,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam_rounded, color: AppColors.gold, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'VIDEO',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tap to play video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.fullscreen_rounded,
                                color: AppColors.goldLight,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // 3. Document or Location or Text
            if (msg.documentName != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_rounded,
                      color: isMe ? AppColors.textOnGold : AppColors.gold,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.documentName!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified Relocation Document · 1.4 MB',
                            style: TextStyle(
                              color: metaTextColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (msg.isLocation) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.greenAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.greenAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Shared Coordinates (${msg.latitude?.toStringAsFixed(3)}, ${msg.longitude?.toStringAsFixed(3)})',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                msg.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: primaryTextColor,
                  fontSize: responsive.sp(13.5),
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],

            const SizedBox(height: 5),

            // 4. Timestamp & Read Status
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  msg.time,
                  style: TextStyle(
                    color: metaTextColor,
                    fontSize: responsive.sp(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: metaTextColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
          _focusNode.unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              const Positioned.fill(child: GlassAmbientBackground()),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(responsive),

                    // Date Header Badge
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: responsive.h(6)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Text(
                          'TODAY · ENCRYPTED LIVE CHANNEL',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // Messages Scroll Area
                    Expanded(
                      child: ListenableBuilder(
                        listenable: _store,
                        builder: (context, _) {
                          final messages = _store.getChannelMessages(widget.channel.id);

                          if (messages.isEmpty) {
                            return LayoutBuilder(
                              builder: (context, constraints) => SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: ClampingScrollPhysics(),
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Center(child: _buildEmptyState(responsive)),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            key: PageStorageKey('chat_${widget.channel.id}'),
                            controller: _scrollController,
                            reverse: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.pagePadding,
                              vertical: 10,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            ),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final reversedIndex = messages.length - 1 - index;
                              final msg = messages[reversedIndex];
                              return _buildMessageBubble(msg, responsive);
                            },
                          );
                        },
                      ),
                    ),

                    // Specialist Typing Indicator
                    if (_isSpecialistTyping)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          responsive.pagePadding,
                          0,
                          responsive.pagePadding,
                          6,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: AppColors.gold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.channel.name} is typing…',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.gold,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Quick suggestions row
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
                        itemCount: _quickSuggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final text = _quickSuggestions[index];
                          return NxPressable(
                            scale: 0.94,
                            onTap: () {
                              _msgController.text = text;
                              _sendTextMessage();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  text,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    _buildInputBar(responsive),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias so code or callers looking for ChatDetailScreen can use either name
typedef ChatDetailScreen = ChatConversationScreen;
