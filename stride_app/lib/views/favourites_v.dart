import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/main.dart';

class FavouritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favourites = appState.favourites.map((wordPair) {
      return ListTile(
        key: ValueKey(wordPair),
        title: Text(wordPair.asLowerCase),
        trailing: IconButton(
          onPressed: () => appState.toggleFavourite(wordPair),
          icon: Icon(Icons.delete),
        ),
      );
    }).toList();

    if (favourites.isEmpty) {
      favourites = [
        ListTile(
          title: Text('No favourites yet!'),
        ),
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            SizedBox(height: 100,),
            ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 100, // optional minimum width
              maxWidth: constraints.maxWidth * 0.8,
              maxHeight: constraints.maxHeight * 0.8,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  shrinkWrap: true, // important! makes ListView fit content
                  padding: EdgeInsets.zero,
                  children: favourites,
                ),
              ),
            ),
          )],
        );
      },
    );
  }
}
