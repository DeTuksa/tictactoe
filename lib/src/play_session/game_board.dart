import 'package:flutter/material.dart';
import 'package:flutter_game_sample/src/game_internals/board_setting.dart';
import 'package:flutter_game_sample/src/game_internals/tile.dart';
import 'package:flutter_game_sample/src/play_session/board_tile.dart';
import 'package:flutter_game_sample/src/style/rough/grid.dart';

class Board extends StatefulWidget {
  final VoidCallback? onPlayerWon;

  const Board({Key? key, required this.setting, this.onPlayerWon})
      : super(key: key);

  final BoardSetting setting;

  @override
  _BoardState createState() => _BoardState();
}

class _BoardState extends State<Board> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.setting.m / widget.setting.n,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RoughGrid(widget.setting.m, widget.setting.n),
          Column(
            children: [
              for (var y = 0; y < widget.setting.n; y++)
                Expanded(
                  child: Row(
                    children: [
                      for (var x = 0; x < widget.setting.m; x++)
                        Expanded(
                          child: BoardTile(Tile(x, y)),
                        ),
                    ],
                  ),
                )
            ],
          )
        ],
      ),
    );
  }
}
