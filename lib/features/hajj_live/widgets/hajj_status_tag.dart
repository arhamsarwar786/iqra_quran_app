import 'package:flutter/material.dart';
import '../models/hajj_stream_model.dart';
import 'package:shimmer/shimmer.dart';

class HajjStatusTag extends StatefulWidget {
  final StreamStatus status;
  final bool isLoading;

  const HajjStatusTag({
    Key? key,
    required this.status,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<HajjStatusTag> createState() => _HajjStatusTagState();
}

class _HajjStatusTagState extends State<HajjStatusTag> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.status == StreamStatus.live) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(HajjStatusTag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == StreamStatus.live) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    String text;
    Color bgColor;
    Widget? icon;

    switch (widget.status) {
      case StreamStatus.live:
        text = "LIVE";
        bgColor = Colors.red;
        icon = FadeTransition(
          opacity: _pulseController,
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
        break;
      case StreamStatus.coming_soon:
        text = "COMING SOON";
        bgColor = Colors.red;
        break;
      case StreamStatus.ended:
        text = "ENDED";
        bgColor = Colors.grey;
        break;
      case StreamStatus.error:
        text = "UNAVAILABLE";
        bgColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: widget.status == StreamStatus.live 
            ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon,
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
