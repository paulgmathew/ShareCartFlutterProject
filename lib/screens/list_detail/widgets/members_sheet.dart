import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/list_detail_provider.dart';

class MembersSheet extends StatelessWidget {
  const MembersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final members =
        context.watch<ListDetailProvider>().shoppingList?.members ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members (${members.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No members yet')),
            )
          else
            ...members.map(
              (member) => ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (member.name ?? member.email).substring(0, 1).toUpperCase(),
                  ),
                ),
                title: Text(member.name ?? member.email),
                subtitle: Text(member.email),
                trailing: Chip(
                  label: Text(
                    member.role,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
