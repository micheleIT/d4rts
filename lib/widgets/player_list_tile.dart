import 'package:flutter/material.dart';
import 'package:d4rts/models/player.dart';
import 'package:d4rts/utils/constants.dart';

class PlayerListTile extends StatelessWidget {
  final Player player;
  final int handicap;
  final bool showHandicap;
  final VoidCallback? onRemove;
  final ValueChanged<int>? onHandicapChanged;

  const PlayerListTile({
    super.key,
    required this.player,
    this.handicap = 0,
    this.showHandicap = true,
    this.onRemove,
    this.onHandicapChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        ),
      ),
      title: Text(player.name),
      subtitle: showHandicap && onHandicapChanged != null
          ? Row(
              children: [
                const Text('Handicap: '),
                DropdownButton<int>(
                  value: handicap,
                  isDense: true,
                  items: handicapOptions
                      .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text('$h'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onHandicapChanged!(v);
                  },
                ),
              ],
            )
          : null,
      trailing: onRemove != null
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onRemove,
              color: Colors.red,
            )
          : null,
    );
  }
}
