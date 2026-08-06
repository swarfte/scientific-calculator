import 'package:flutter/material.dart';

class ResultDisplay extends StatelessWidget {
  const ResultDisplay({
    required this.result,
    required this.errorMessage,
    super.key,
  });

  final String? result;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.centerRight,
      child: Text(
        hasError ? errorMessage! : result ?? '0',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: hasError ? Theme.of(context).colorScheme.error : null,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
