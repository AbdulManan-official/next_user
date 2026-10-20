import 'package:flutter/material.dart';
import '../utils/app_theme_styles.dart';

/// Glass search bar. Same API as before.
/// No BackdropFilter of its own: sits on a glass header/card that already
/// blurs. Focus: gold border + soft glow (same as CustomTextField).
class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool autofocus;
  final double borderRadius;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 24.0,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  TextEditingController? _ownController;
  FocusNode? _ownNode;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void didUpdateWidget(covariant CustomSearchBar old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
    if (widget.focusNode != null && _ownNode != null) {
      _ownNode!.dispose();
      _ownNode = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose(); // never dispose parent's controller / node
    _ownNode?.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;

    // Only this widget rebuilds on focus change.
    return ListenableBuilder(
      listenable: node,
      builder: (context, _) {
        final focused = node.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Colors.white.withValues(alpha: focused ? 0.10 : 0.07),
            border: Border.all(
              color: focused
                  ? AppColors.gold.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.14),
              width: focused ? 1.3 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: 20,
                    ),
                  ]
                : const [],
          ),
          child: TextField(
            controller: _controller,
            focusNode: node,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            onSubmitted: (v) {
              node.unfocus();
              widget.onSubmitted?.call(v);
            },
            onTapOutside: (_) {
              if (node.hasFocus) node.unfocus();
            },
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
            maxLines: 1,
            cursorColor: AppColors.gold,
            cursorWidth: 1.8,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintMaxLines: 1,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search_rounded,
                    key: ValueKey(focused),
                    size: 20,
                    color: focused
                        ? AppColors.goldLight
                        : AppColors.gold.withValues(alpha: 0.75),
                  ),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 44, minHeight: 44),
              // Only the clear button rebuilds per keystroke.
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'Clear search',
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: EdgeInsets.zero,
                    onPressed: _handleClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        );
      },
    );
  }
}
