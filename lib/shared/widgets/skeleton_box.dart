import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 아직 값을 받지 못한 자리를 채우는 스켈레톤 블록입니다. (`feedbackSkeleton`)
///
/// 시안에는 정지된 블록만 있어서 반짝임(shimmer) 없이 은은하게 깜빡이는 정도로만 움직입니다.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.55,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.feedbackSkeleton,
          borderRadius: BorderRadius.circular(
            widget.radius ?? context.dimens.radiusSm,
          ),
        ),
      ),
    );
  }
}
