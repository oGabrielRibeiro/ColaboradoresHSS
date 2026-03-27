import 'package:flutter/material.dart';

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Colors.grey.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Secao de cabecalho
          Container(
            width: double.infinity,
            height: 24,
            color: skeletonColor,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 16,
            color: skeletonColor,
            margin: const EdgeInsets.only(bottom: 24),
          ),

          // Titulo da secao
          Container(
            width: 150,
            height: 20,
            color: skeletonColor,
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Itens da lista (ex: documentos ou vinculos)
          ...List.generate(3, (index) => _buildListItemSkeleton(skeletonColor)),

          const SizedBox(height: 24),

          // Outro titulo de secao
          Container(
            width: 180,
            height: 20,
            color: skeletonColor,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          ...List.generate(2, (index) => _buildListItemSkeleton(skeletonColor)),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton(Color color) {
    return Container(
      width: double.infinity,
      height: 60,
      color: color,
      margin: const EdgeInsets.only(bottom: 12),
    );
  }
}
