import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_constants.dart';
import '/models/freedom_session.dart';

class SessionList extends StatelessWidget {
  final List<FreedomSession> sessions;

  const SessionList({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final date = DateFormat('MMM dd, yyyy • hh:mm a').format(session.startTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: AppConstants.primaryOrange.withOpacity(0.1),
              child: Text(
                '${session.durationMinutes}',
                style: const TextStyle(
                  color: AppConstants.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '${session.durationMinutes} minutes',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              date,
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            trailing: session.usedParachute
                ? const Chip(
                    label: Text('Parachute used'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  )
                : null,
          ),
        );
      },
    );
  }
}