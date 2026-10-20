import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/animation_helper.dart';
import '../widgets/custom_search_bar.dart';
import '../models/move_model.dart';
import '../controllers/move_store.dart';
import '../widgets/concierge_call_sheet.dart';

enum ChatCategory { all, drivers, users, groups }

class ChatChannelItem {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final ChatCategory category;
  final IconData? icon;
  final Color? iconBgColor;
  final String? initial;
  final bool hasUnread;
  final bool isOnline;

  const ChatChannelItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.category,
    this.icon,
    this.iconBgColor,
    this.initial,
    this.hasUnread = false,
    this.isOnline = false,
  });
}

/// Chat List / Inbox Screen matching the Next Gen luxury design language.
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

  final List<ChatChannelItem> _channels = const [
    ChatChannelItem(
      id: 'driver_manan',
      name: 'manan driver',
      lastMessage: 'Declined call',
      time: '12:57 PM',
      category: ChatCategory.drivers,
      icon: Icons.local_shipping_rounded,
      iconBgColor: Color(0xFF1E5B99),
      isOnline: true,
    ),
    ChatChannelItem(
      id: 'mgmt',
      name: 'management',
      lastMessage: 'Admin, managers & leadership strate...',
      time: '20/08/2026',
      category: ChatCategory.groups,
      icon: Icons.groups_rounded,
      iconBgColor: Color(0xFF5A4486),
    ),
    ChatChannelItem(
      id: 'surveys_grp',
      name: 'surveys',
      lastMessage: 'On-site & video survey reports, surve..',
      time: '20/08/2026',
      category: ChatCategory.groups,
      icon: Icons.groups_rounded,
      iconBgColor: Color(0xFF5A4486),
    ),
    ChatChannelItem(
      id: 'dispatch_alpha',
      name: 'Dispatch Alpha Group',
      lastMessage: 'Special ops group chat for priority mo..',
      time: '20/08/2026',
      category: ChatCategory.groups,
      icon: Icons.groups_rounded,
      iconBgColor: Color(0xFF5A4486),
    ),
    ChatChannelItem(
      id: 'abdullah_user',
      name: 'abdullah',
      lastMessage: 'Available for survey queries',
      time: '10:45 AM',
      category: ChatCategory.users,
      initial: 'A',
      iconBgColor: Color(0xFF3E3120),
    ),
    ChatChannelItem(
      id: 'abdullah_test',
      name: 'abdullah test00',
      lastMessage: 'Available for survey queries',
      time: '10:45 AM',
      category: ChatCategory.users,
      initial: 'A',
      iconBgColor: Color(0xFF3E3120),
    ),
    ChatChannelItem(
      id: 'admin_user',
      name: 'Admin User',
      lastMessage: 'Available for survey queries',
      time: '10:45 AM',
      category: ChatCategory.users,
      icon: Icons.admin_panel_settings_rounded,
      iconBgColor: Color(0xFF5E3929),
    ),
    ChatChannelItem(
      id: 'anas_waheed',
      name: 'Anas Waheed',
      lastMessage: 'Available for survey queries',
      time: '10:45 AM',
      category: ChatCategory.users,
      initial: 'A',
      iconBgColor: Color(0xFF3E3120),
    ),
    ChatChannelItem(
      id: 'control_room',
      name: 'control',
      lastMessage: 'Available for survey queries',
      time: '10:45 AM',
      category: ChatCategory.users,
      initial: 'C',
      iconBgColor: Color(0xFF3E3120),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatChannelItem> get _filteredChannels {
    final query = _searchController.text.trim().toLowerCase();
    return _channels.where((c) {
      if (_selectedCategory == ChatCategory.drivers &&
          c.category != ChatCategory.drivers) {
        return false;
      }
      if (_selectedCategory == ChatCategory.users &&
          c.category != ChatCategory.users) {
        return false;
      }
      if (_selectedCategory == ChatCategory.groups &&
          c.category != ChatCategory.groups) {
        return false;
      }
      if (query.isNotEmpty) {
        return c.name.toLowerCase().contains(query) ||
            c.lastMessage.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  int _countFor(ChatCategory cat) {
    if (cat == ChatCategory.all) return _channels.length;
    return _channels.where((c) => c.category == cat).length;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final channels = _filteredChannels;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.gold,
            size: context.r(18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chats',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: context.sp(18),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Column(
                children: [
                  // Interactive Search Input Field
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(16),
                      context.h(4),
                      context.w(16),
                      context.h(12),
                    ),
                    child: CustomSearchBar(
                      controller: _searchController,
                      hintText: 'Search chats, staff, drivers, users...',
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),

                // Horizontal Filter Chips (All, Drivers, Users, Groups)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                  child: Row(
                    children: [
                      _buildPill(
                        category: ChatCategory.all,
                        label: 'All (${_countFor(ChatCategory.all)})',
                      ),
                      SizedBox(width: context.w(8)),
                      _buildPill(
                        category: ChatCategory.drivers,
                        label: 'Drivers (${_countFor(ChatCategory.drivers)})',
                      ),
                      SizedBox(width: context.w(8)),
                      _buildPill(
                        category: ChatCategory.users,
                        label: 'Users (${_countFor(ChatCategory.users)})',
                      ),
                      SizedBox(width: context.w(8)),
                      _buildPill(
                        category: ChatCategory.groups,
                        label: 'Groups (${_countFor(ChatCategory.groups)})',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(12)),

                // Channels List View
                Expanded(
                  child: channels.isEmpty
                      ? Center(
                          child: Text(
                            'No chats found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.symmetric(
                            vertical: context.h(4),
                          ),
                          itemCount: channels.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 0.8,
                            color: AppColors.border.withValues(alpha: 0.5),
                            indent: context.w(68),
                          ),
                          itemBuilder: (context, index) {
                            final item = channels[index];
                            return _buildChannelTile(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPill({
    required ChatCategory category,
    required String label,
  }) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      borderRadius: BorderRadius.circular(context.r(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(7),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(context.r(20)),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textOnGold : AppColors.textSecondary,
            fontSize: context.sp(11.5),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(ChatChannelItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          AnimationHelper.smoothRoute(
            page: ChatConversationScreen(channel: item),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(10),
        ),
        child: Row(
          children: [
            // Channel Avatar
            Container(
              width: context.r(46),
              height: context.r(46),
              decoration: BoxDecoration(
                color: item.iconBgColor ?? AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: item.icon != null
                    ? Icon(
                        item.icon,
                        color: Colors.white,
                        size: context.r(22),
                      )
                    : Text(
                        item.initial ?? 'A',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.gold,
                          fontSize: context.sp(17),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            SizedBox(width: context.w(12)),

            // Title & Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(3)),
                  Row(
                    children: [
                      if (item.category == ChatCategory.drivers) ...[
                        Icon(
                          Icons.call_missed_rounded,
                          color: AppColors.textMuted,
                          size: context.r(13),
                        ),
                        SizedBox(width: context.w(4)),
                      ] else ...[
                        Icon(
                          Icons.done_all_rounded,
                          color: AppColors.textMuted,
                          size: context.r(13),
                        ),
                        SizedBox(width: context.w(4)),
                      ],
                      Expanded(
                        child: Text(
                          item.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: context.sp(11.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(8)),

            // Timestamp
            Text(
              item.time,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: context.sp(10.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ChatType { concierge, crew }

/// Active chat thread / conversation screen.
class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.channel,
  });

  final ChatChannelItem channel;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MoveStore _store = MoveStore.instance;
  bool _isTyping = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    _store.addConciergeMessage(text.trim(), isUser: true);
    _scrollToBottom();

    setState(() => _isTyping = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isTyping = false);

      final reply =
          "Thanks for your message regarding ${widget.channel.name}. We've updated the log.";
      _store.addConciergeMessage(reply, isUser: false);
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.gold,
            size: context.r(18),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: context.r(16),
              backgroundColor:
                  widget.channel.iconBgColor ?? AppColors.surfaceElevated,
              child: widget.channel.icon != null
                  ? Icon(
                      widget.channel.icon,
                      color: Colors.white,
                      size: context.r(16),
                    )
                  : Text(
                      widget.channel.initial ?? 'A',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.channel.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Online · replies quickly',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: context.sp(10.5),
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.phone_rounded,
              color: AppColors.gold,
              size: context.r(18),
            ),
            onPressed: () {
              ConciergeCallSheet.show(
                context,
                name: widget.channel.name,
                role: 'Direct Line · Support & Dispatch',
                avatarInitials: widget.channel.initial ?? 'A',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: Column(
              children: [
                // Messages List
                Expanded(
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) {
                      final messages = _store.conciergeMessages;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(16),
                          vertical: context.h(14),
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _buildMessageBubble(msg);
                        },
                      );
                    },
                  ),
                ),

                if (_isTyping) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(18),
                      vertical: context.h(4),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Typing…',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold,
                          fontStyle: FontStyle.italic,
                          fontSize: context.sp(11),
                        ),
                      ),
                    ),
                  ),
                ],

                // Chat Input Box
                Container(
                  padding: EdgeInsets.all(context.r(12)),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(14),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(context.r(24)),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _textController,
                            onSubmitted: _sendMessage,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: context.sp(12.5),
                            ),
                            cursorColor: AppColors.gold,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: AppTextStyles.hint.copyWith(
                                fontSize: context.sp(12),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: context.h(11),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(8)),
                      InkWell(
                        onTap: () => _sendMessage(_textController.text),
                        borderRadius: BorderRadius.circular(context.r(24)),
                        child: Container(
                          padding: EdgeInsets.all(context.r(11)),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.goldGradient,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: AppColors.textOnGold,
                            size: context.r(17),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: context.h(10)),
        constraints: BoxConstraints(maxWidth: context.wp(75)),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(10),
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.gold : AppColors.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(context.r(18)),
            topRight: Radius.circular(context.r(18)),
            bottomLeft: Radius.circular(isUser ? context.r(18) : context.r(4)),
            bottomRight: Radius.circular(isUser ? context.r(4) : context.r(18)),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isUser ? AppColors.textOnGold : AppColors.textPrimary,
                fontSize: context.sp(12.5),
              ),
            ),
            SizedBox(height: context.h(4)),
            Text(
              msg.time,
              style: AppTextStyles.labelSmall.copyWith(
                color: isUser
                    ? AppColors.textOnGold.withValues(alpha: 0.75)
                    : AppColors.textMuted,
                fontSize: context.sp(9.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
