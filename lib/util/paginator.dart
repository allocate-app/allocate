import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';

// Component for self-pagination.
class Paginator<T> extends ChangeNotifier {
  bool _disposed = false;
  late List<T>? items;
  late int limit;
  late int initialLimit;
  late int offset;
  late bool allData;
  late bool loading;
  late Future<List<T>> Function({int limit, int offset})? query;

  // This is for listening to global stage changes.
  // ie. A change to a provider class.
  late List<ChangeNotifier>? resetNotifiers;

  // late ChangeNotifier? appendNotifier;

  Paginator({
    this.items,
    this.limit = Constants.minLimitPerQuery,
    this.offset = 0,
    this.allData = false,
    this.loading = false,
    this.query,
    this.resetNotifiers,
    // this.appendNotifier
  }) {
    this.initialLimit = this.limit;
    if (null != resetNotifiers) {
      for (ChangeNotifier notifier in resetNotifiers!) {
        notifier.addListener(resetPagination);
      }
    }

    if (offset < 1) {
      resetPagination();
    } else {
      appendData();
    }
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(items?.length ?? 0, limit);

    return await overwriteData();
  }

  Future<void> overwriteData() async {
    List<T> newItems = await fetchData();
    offset += newItems.length;
    items = newItems;
    loading = false;
    allData = (items?.length ?? 0) < limit;
    limit = initialLimit;

    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  Future<void> appendData() async {
    if (allData || loading) {
      return;
    }

    List<T> newItems = await fetchData();

    offset += newItems.length;
    items?.addAll(newItems);
    loading = false;
    allData = newItems.length < limit;
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // Catch this in the UI class.
  Future<List<T>> fetchData() async {
    loading = true;

    if (null == query) {
      return [];
    }
    return await query!(limit: limit, offset: offset);
  }

  @override
  void dispose() {
    _disposed = true;

    if (null != resetNotifiers) {
      for (ChangeNotifier notifier in resetNotifiers!) {
        notifier.removeListener(resetPagination);
      }
    }
    super.dispose();
  }
}
