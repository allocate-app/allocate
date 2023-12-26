import 'dart:io';
import 'dart:ui';

import 'package:allocate/ui/widgets/tiles.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

import '../../util/constants.dart';
import '../../util/interfaces/i_model.dart';
import '../../util/paginator.dart';
import 'flushbars.dart';

// TODO: Ignorepointer on list during animation.

class PaginatingListview<T extends IModel> extends StatefulWidget {
  const PaginatingListview(
      {Key? key,
      required this.listviewBuilder,
      required this.items,
      this.query,
      this.offset = 0,
      this.limit = Constants.minLimitPerQuery,
      this.paginateButton = false,
      this.pullToRefresh = true,
      this.allData = false,
      this.scrollController,
      this.onFetch,
      this.onRemove,
      this.getAnimationKey,
      this.rebuildNotifiers,
      this.rebuildCallback})
      : super(key: key);

  final List<T> items;
  final int offset;
  final int limit;
  final bool allData;
  final ScrollController? scrollController;

  final Future<List<T>> Function({int offset, int limit})? query;

  final Widget Function({
    Key? key,
    required BuildContext context,
    required List<T> items,
    Future<void> Function({T? item})? onRemove,
  }) listviewBuilder;

  final void Function({required List<T> items})? rebuildCallback;
  final ValueKey<int> Function()? getAnimationKey;

  final void Function({List<T>? items})? onFetch;
  final Future<void> Function({T? item})? onRemove;

  final bool paginateButton;
  final bool pullToRefresh;

  final List<ChangeNotifier>? rebuildNotifiers;

  @override
  State<PaginatingListview<T>> createState() => _PaginatingListview();
}

// Come back to this if it's needed.
class _PaginatingListview<T extends IModel>
    extends State<PaginatingListview<T>> {
  late final Paginator<T> paginator;
  late final ChangeNotifier? resetNotifier;
  late final ScrollController scrollController;
  late final ScrollPhysics scrollPhysics;
  late final ScrollPhysics refreshPhysics;

  late ValueKey<int> _animationKey;
  late ValueKey<int> Function() getAnimationKey;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    scrollController = widget.scrollController ?? ScrollController();

    paginator = Paginator<T>(
      items: widget.items,
      offset: widget.offset,
      limit: widget.limit,
      allData: widget.allData,
      query: widget.query,
      resetNotifiers: widget.rebuildNotifiers,
      onFetch: widget.onFetch,
    );

    paginator.addListener(repaint);

    if (!widget.paginateButton) {
      scrollController.addListener(() async {
        return await scrollListener();
      });
    }

    scrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    refreshPhysics = (widget.pullToRefresh)
        ? AlwaysScrollableScrollPhysics(parent: scrollPhysics)
        : NeverScrollableScrollPhysics(parent: scrollPhysics);

    initializeAnimation();
    super.initState();
  }

  void initializeAnimation() {
    getAnimationKey = widget.getAnimationKey ?? () => const ValueKey(0);
    _animationKey = getAnimationKey();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    paginator.removeListener(repaint);
    scrollController.dispose();
    paginator.dispose();
    super.dispose();
  }

  void repaint() {
    if (null != widget.rebuildCallback) {
      widget.rebuildCallback!(items: paginator.items!);
    }

    // Repaint & animate new items accordingly.
    if (mounted) {
      setState(() {
        print("key repaint");
        _animationKey = getAnimationKey();
      });
    }
  }

  void onError(dynamic e) {
    Flushbar? error;
    error = Flushbars.createError(
      message: e.cause ?? "Query Error",
      context: context,
      dismissCallback: () => error?.dismiss(),
    );

    error.show(context);
  }

  Future<void> scrollListener() async {
    if (paginator.loading) {
      return;
    }

    if (!(scrollController.offset >=
        scrollController.position.maxScrollExtent - Constants.loadOffset)) {
      return;
    }

    return await paginator.appendData().catchError(onError);
  }

  @override
  Widget build(context) {
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await paginator.resetPagination().catchError(onError);
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: Scrollbar(
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(
              shrinkWrap: true,
              controller: scrollController,
              physics: refreshPhysics,
              children: [
                // (!widget.pullToRefresh && (paginator.items?.length ?? 0) > 1)
                //     ? Tiles.resetTile(onTap: () {
                //         _refreshIndicatorKey.currentState?.show();
                //       })
                //     : const SizedBox.shrink(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: Constants.slideInTime),
                  reverseDuration:
                      const Duration(milliseconds: Constants.fadeOutTime),
                  switchInCurve: Curves.fastLinearToSlowEaseIn,
                  switchOutCurve: Curves.linear,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    if (child.key == getAnimationKey()) {
                      return SlideTransition(
                        position: Constants.offsetIn.animate(animation),
                        child: child,
                      );
                    }
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: widget.listviewBuilder(
                    key: _animationKey,
                    context: context,
                    items: paginator.items!,
                    onRemove: widget.onRemove,
                  ),
                ),
                (widget.paginateButton && !paginator.allData)
                    ? Tiles.fetchTile(onTap: () async {
                        return await paginator.appendData().catchError(onError);
                      })
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ));
  }
}
