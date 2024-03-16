part of '../spotify.dart';

class FavoriteAlbumState extends PaginatedState<AlbumSimple> {
  FavoriteAlbumState({
    required super.items,
    required super.offset,
    required super.limit,
    required super.hasMore,
  });

  @override
  FavoriteAlbumState copyWith({items, offset, limit, hasMore}) {
    return FavoriteAlbumState(
      items: items ?? this.items,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FavoriteAlbumNotifier
    extends PaginatedAsyncNotifier<AlbumSimple, FavoriteAlbumState> {
  @override
  Future<List<AlbumSimple>> fetch(int offset, int limit) {
    return spotify.me
        .savedAlbums()
        .getPage(limit, offset)
        .then((value) => value.items?.toList() ?? []);
  }

  @override
  build() async {
    ref.watch(spotifyProvider);
    final items = await fetch(0, 20);
    return FavoriteAlbumState(
      items: items,
      offset: 0,
      limit: 20,
      hasMore: items.length == 20,
    );
  }

  Future<void> addFavorites(List<String> ids) async {
    if (state.value == null) return;

    state = await AsyncValue.guard(() async {
      await spotify.me.saveAlbums(ids);
      final albums = await spotify.albums.list(ids);

      return state.value!.copyWith(
        items: [
          ...state.value!.items,
          ...albums,
        ],
      );
    });
  }

  Future<void> removeFavorites(List<String> ids) async {
    if (state.value == null) return;

    state = await AsyncValue.guard(() async {
      await spotify.me.removeAlbums(ids);

      return state.value!.copyWith(
        items: state.value!.items
            .where((element) => !ids.contains(element.id))
            .toList(),
      );
    });
  }
}

final favoriteAlbumsProvider =
    AsyncNotifierProvider<FavoriteAlbumNotifier, FavoriteAlbumState>(
  () => FavoriteAlbumNotifier(),
);
