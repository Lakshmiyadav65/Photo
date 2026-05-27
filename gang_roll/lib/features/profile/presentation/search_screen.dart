// Search tab — find rolls and gang members. Frontend: styled field + empty
// state; wiring to a real index lands with the data layer.

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Search', style: AppText.display(fontSize: 26)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: AppTheme.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        cursorColor: AppTheme.coral,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Rolls, gang, codes…',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.search_rounded, size: 40, color: AppTheme.muted),
                    const SizedBox(height: 12),
                    Text('Find a roll or a friend',
                        style: AppText.display(fontSize: 18)),
                    const SizedBox(height: 6),
                    Text(
                      'Search across every roll your gang has shot.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
