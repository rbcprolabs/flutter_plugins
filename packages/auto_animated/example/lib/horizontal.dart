import 'package:flutter/material.dart';
import 'package:auto_animated/auto_animated.dart';

class HorizontalExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AutoAnimatedList(
        showItemInterval: Duration(milliseconds: 500),
        showItemDuration: Duration(seconds: 1),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        scrollDirection: Axis.horizontal,
        itemsCount: 10,
        itemBuilder: _buildAnimatedItem,
      );

  /// Wrap Ui item with animation & padding
  Widget _buildAnimatedItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) =>
      FadeTransition(
        opacity: Tween<double>(
          begin: 0,
          end: 1,
        ).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -0.1),
            end: Offset.zero,
          ).animate(animation),
          child: Padding(
            padding: EdgeInsets.only(right: 32),
            child: _buildCard(index.toString()),
          ),
        ),
      );

  /// UI item for showing
  Widget _buildCard(String text) => Builder(
        builder: (context) => Container(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Material(
              color: Theme.of(context).colorScheme.secondary,
              child: Center(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.display1.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary),
                ),
              ),
            ),
          ),
        ),
      );
}
