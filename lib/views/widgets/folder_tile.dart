import 'package:flutter/material.dart';

class FolderTile extends StatelessWidget {
  const FolderTile({required this.name, required this.onTap, super.key});

  final String name;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Expanded(child: Image.asset("")), //TODO
            Expanded(
              child: Center(
                child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
              ),
            )
          ],
        ),
      ),
    );
  }
}
