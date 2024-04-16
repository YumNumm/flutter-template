import 'package:cores_core/exception.dart';
import 'package:cores_core/extension.dart';
import 'package:cores_core/src/pagination/model/paging_data.dart';
import 'package:cores_core/src/pagination/provider/paging_async_notifier.dart';
import 'package:cores_core/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:visibility_detector/visibility_detector.dart';

/// A widget for pagination, supporting asynchronous data fetching.
///
/// Features:
/// 1. Displays widgets created by [_contentBuilder] with available data.
/// 2. Shows a [CircularProgressIndicator] while loading the first page.
/// 3. Presents an error widget for first page load failures.
/// 4. Loads the next page when the last item is displayed.
/// 5. Handles errors with an optional callback [_onError] for non-initial
///    loads.
/// 6. Enables pull-to-refresh, allowing manual data refresh.
class CommonPagingView<
    N extends PagingAsyncNotifier<D, I, U>,
    D extends PagingData<I, U>,
    I extends PagingDataItem<U>,
    U> extends ConsumerWidget {
  const CommonPagingView({
    required AutoDisposeAsyncNotifierProvider<N, D> provider,
    required Widget Function(D, Widget?) contentBuilder,
    required void Function(AppException e) onError,
    super.key,
  })  : _contentBuilder = contentBuilder,
        _provider = provider,
        _onError = onError;

  /// Specifies the provider for a [PagingAsyncNotifier] implemented class.
  final AutoDisposeAsyncNotifierProvider<N, D> _provider;

  /// Specifies a function to return a widget for displaying data. The function
  /// also receives an optional `endItem` widget.
  /// `endItem` serves as a marker to indicate the end of the list. When `endItem`
  /// is provided and non-null, it must be explicitly included in the list's layout
  /// by adding it as an additional item. This is typically used to detect when the
  /// last item becomes visible or to add a special widget at the end of the list.
  ///
  /// Example:
  /// ```dart
  /// contentBuilder: (data, endItem) => ListView.builder(
  ///     itemCount: data.items.length + (endItem != null ? 1 : 0),
  ///     itemBuilder: (context, index) {
  ///       if (index == data.items.length && endItem != null) {
  ///         // This is the end item
  ///         return endItem;
  ///       }
  ///       // This is a regular item
  ///       return ListTile(title: Text(data.items[index].name));
  ///     },
  /// ),
  /// ```
  final Widget Function(D data, Widget? endItem) _contentBuilder;

  final void Function(AppException e) _onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      _provider,
      (_, next) {
        if (!next.isLoading && next.hasError) {
          final error = next.error;
          if (error is AppException) {
            _onError(error);
            return;
          }
          // AppException is expected, so this should never be reached.
          logger.shout('Error: $error');
        }
      },
    );

    return ref.watch(_provider).whenPreservingDataOnError(
          data: (data, {required hasError}) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(_provider.future),
              child: _contentBuilder(
                data,
                // Displays EndItem to detect scroll end
                // if more data is available and no errors.
                data.hasMore && !hasError
                    ? _EndItem(
                        onScrollEnd: () async =>
                            ref.read(_provider.notifier).loadNext(),
                      )
                    : null,
              ),
            );
          },
          loading: () {
            // Shows loading indicator during initial page load.
            return const _LoadingItem();
          },
          error: (e, st) {
            // Displays error message for initial load failures.
            return _ErrorItem(
              errorMessage: e.toString(),
              onError: () => ref.read(_provider.notifier).forceRefresh(),
            );
          },
          // Continues showing data on subsequent load errors,
          // without hiding existing content.
          skipErrorOnHasValue: true,
        );
  }
}

class _EndItem extends StatelessWidget {
  const _EndItem({
    required void Function() onScrollEnd,
  }) : _onScrollEnd = onScrollEnd;
  final VoidCallback _onScrollEnd;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: key ?? const Key('EndItem'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1) {
          _onScrollEnd();
        }
      },
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorItem extends StatelessWidget {
  const _ErrorItem({
    required String errorMessage,
    required VoidCallback onError,
  })  : _errorMessage = errorMessage,
        _onError = onError;

  final String _errorMessage;
  final VoidCallback _onError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _onError,
            icon: const Icon(Icons.refresh),
          ),
          Text(_errorMessage),
        ],
      ),
    );
  }
}

class _LoadingItem extends StatelessWidget {
  const _LoadingItem();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}
