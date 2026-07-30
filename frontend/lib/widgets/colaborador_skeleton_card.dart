import 'package:flutter/material.dart';

class ColaboradorSkeletonCard extends StatelessWidget {
  const ColaboradorSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Colors.grey.withAlpha(50);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(backgroundColor: skeletonColor),
        title: Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 8),
          width: 150,
          height: 12,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: skeletonColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
