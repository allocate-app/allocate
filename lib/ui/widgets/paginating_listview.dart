import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/application_service.dart';
import '../../util/constants.dart';
import '../../util/interfaces/i_model.dart';
import '../../util/paginator.dart';
import 'flushbars.dart';

class PaginatingListview<T extends IModel> extends StatefulWidget {
  const PaginatingListview(
      {super.key,
      required this.listviewBuilder,
      required this.items,
      this.query,
      this.offset = 0,
      this.limit = Constants.minLimitPerQuery,
      this.pullToRefresh = true,
      this.allData = false,
      this.indicatorDisplacement = 40.0,
      this.scrollController,
      this.onFetch,
      this.onAppend,
      this.onRemove,
      this.getAnimationKey,
      this.rebuildNotifiers,
      this.rebuildCallback});

  final List<T> items;
  final int offset;
  final int limit;
  final bool allData;
  final double indicatorDisplacement;
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
  final void Function({List<T>? items})? onAppend;
  final Future<void> Function({T? item})? onRemove;

  final bool pullToRefresh;

  final List<ChangeNotifier>? rebuildNotifiers;

  @override
  State<PaginatingListview<T>> createState() => _PaginatingListview();
}

// TODO: add support for alternative notify methods for pagination/reset.
// Nested scrollviews do not work well with with widget.

class _PaginatingListview<T extends IModel>
    extends State<PaginatingListview<T>> {
  late final Paginator<T> paginator;
  late final ChangeNotifier? resetNotifier;
  late final ScrollController scrollController;
  late final ScrollPhysics scrollPhysics;
  late ScrollPhysics refreshPhysics;

  late ApplicationService applicationService;

  late ValueKey<int> _animationKey;
  late ValueKey<int> Function() getAnimationKey;
  late bool animating;

  late final FocusNode _refreshFocusNode;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    scrollController = widget.scrollController ?? ScrollController();

    animating = false;

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

    scrollController.addListener(scrollListener);

    scrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    refreshPhysics = (widget.pullToRefresh)
        ? AlwaysScrollableScrollPhysics(parent: scrollPhysics)
        : NeverScrollableScrollPhysics(parent: scrollPhysics);

    _refreshFocusNode = FocusNode();

    if (widget.pullToRefresh) {
      applicationService = ApplicationService.instance;
      applicationService.addListener(scrollToTop);
    }

    initializeAnimation();
    super.initState();
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
  }

  void initializeAnimation() {
    getAnimationKey = widget.getAnimationKey ?? () => const ValueKey(0);
    _animationKey = getAnimationKey();
  }

  @override
  void dispose() {
    if (widget.pullToRefresh) {
      applicationService.removeListener(scrollToTop);
    }
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
        ValueKey<int> newKey = getAnimationKey();
        if (_animationKey != newKey) {
          pointerDelay();
        }
        _animationKey = newKey;
      });
    }
  }

  void pointerDelay() {
    if (mounted) {
      setState(() => animating = true);
    }

    Future.delayed(const Duration(milliseconds: Constants.hitDelay), () {
      if (mounted) {
        setState(() => animating = false);
      }
    });
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

    await paginator.appendData().catchError(onError);
  }

  // // This is a workaround - flutter has an ongoing issue with nested scroll competition.
  // // TBH, not sold - might just make inner listviews non-scrollable.
  // bool _handleNotification(ScrollNotification notification) {
  //   if (notification is OverscrollNotification) {
  //     double delta = notification.dragDetails?.delta.dy ?? 0;
  //     // Abstract this out to a constant.
  //     if (delta > 30) {
  //       return false;
  //     }
  //
  //     // Temporarily disable scrolling?
  //     // print("disabling");
  //     setState(() {
  //       refreshPhysics = NeverScrollableScrollPhysics(parent: scrollPhysics);
  //     });
  //   }
  //
  //   // TODO: implement a better solution.
  //   // Pass down state from the parent scrollbar and use that to turn scrolling back on
  //   // for refresh.
  //   if (notification is UserScrollNotification) {
  //     if (notification.direction == ScrollDirection.idle) {
  //       Future.delayed(const Duration(milliseconds: 3000)).whenComplete(() {
  //         // print("re-enabling");
  //         setState(() {
  //           refreshPhysics =
  //               AlwaysScrollableScrollPhysics(parent: scrollPhysics);
  //         });
  //       });
  //     }
  //   }
  //
  //   return false;
  // }

  @override
  Widget build(context) {
    // This is a workaround for Flutter's change to scrollbars.
    Widget list = NotificationListener<ScrollNotification>(
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        controller: scrollController,
        physics: refreshPhysics,
        children: [
          IgnorePointer(
            ignoring: animating,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: Constants.slideInTime),
              reverseDuration:
                  const Duration(milliseconds: Constants.fadeOutTime),
              switchInCurve: Curves.fastLinearToSlowEaseIn,
              switchOutCurve: Curves.linear,
              transitionBuilder: (Widget child, Animation<double> animation) {
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
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (PointerEvent details) {
        if (widget.pullToRefresh) {
          _refreshFocusNode.requestFocus();
        }
        // _refreshFocusNode.requestFocus();
      },
      onExit: (PointerEvent details) {
        _refreshFocusNode.unfocus();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          SingleActivator(LogicalKeyboardKey.keyR,
              control: !(Platform.isMacOS || Platform.isIOS),
              meta: !(Platform.isMacOS || Platform.isIOS),
              includeRepeats: false): () {
            if (widget.pullToRefresh) {
              _refreshIndicatorKey.currentState?.show();
            }
            // _refreshIndicatorKey.currentState?.show();
          }
        },
        child: Focus(
          autofocus: widget.pullToRefresh,
          focusNode: _refreshFocusNode,
          descendantsAreFocusable: true,
          child: RefreshIndicator(
              displacement: widget.indicatorDisplacement,
              key: _refreshIndicatorKey,
              onRefresh: () async {
                await paginator.resetPagination().catchError(onError);
              },
              child: (Platform.isIOS || Platform.isAndroid)
                  ? Scrollbar(controller: scrollController, child: list)
                  : list),
        ),
      ),
    );
  }
}
