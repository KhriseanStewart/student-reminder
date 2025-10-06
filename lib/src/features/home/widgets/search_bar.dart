import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SearchBarX extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final String hint;
  final TextEditingController? controller;
  final Duration debounceDuration;

  const SearchBarX({
    super.key,
    this.onChanged,
    this.onSearchTap,
    this.hint = 'Search students...',
    this.controller,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SearchBarX> createState() => _SearchBarXState();
}

class _SearchBarXState extends State<SearchBarX> {
  Timer? _debounce;
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    // If a controller is passed from outside, use it. Otherwise create our own.
    _internalController = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Only dispose our own controller (not the one passed in)
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _onChanged(String val) {
    // cancel any active timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // start a new debounce timer
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(val);
    });

    // Only rebuild the search bar (not the whole page)
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const double barHeight = 52;
    const double circleSize = 48;
    const double circleInset = 4;
    const double circleOver = -10;

    return SizedBox(
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 🔹 Search Input Field
          Positioned.fill(
            right: circleSize + circleInset,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _internalController,
                    onChanged: _onChanged,
                    textAlignVertical:
                        TextAlignVertical.center, // ✅ vertically center text
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: widget.hint,
                      hintStyle: const TextStyle(color: Colors.white60),
                      contentPadding: EdgeInsets.zero, // ✅ remove extra padding
                      // ✅ Safe null-check for text
                      suffixIcon: (_internalController.text.isNotEmpty)
                          ? GestureDetector(
                              onTap: () {
                                _internalController.clear();
                                widget.onChanged?.call('');
                                if (mounted) setState(() {});
                              },
                              child: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Floating Search Button
          Positioned(
            right: circleOver,
            top: (barHeight - circleSize) / 2,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              shadowColor: Colors.black45,
              child: InkWell(
                onTap: () {
                  FocusScope.of(context).unfocus(); // hide keyboard
                  widget.onSearchTap?.call();
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
