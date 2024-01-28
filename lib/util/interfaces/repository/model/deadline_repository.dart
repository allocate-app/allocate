import 'package:flutter/foundation.dart';

import '../../../../model/task/deadline.dart';
import '../function/date_range.dart';
import '../function/local_notifications.dart';
import '../function/overdue.dart';
import '../function/repeatable.dart';
import '../function/repository.dart';
import '../function/search.dart';
import '../function/upcoming.dart';

abstract interface class DeadlineRepository extends ChangeNotifier
    implements
        Repository<Deadline>,
        Repeatable<Deadline>,
        Overdue<Deadline>,
        Upcoming<Deadline>,
        DateRange<Deadline>,
        LocalNotifications<Deadline>,
        Search<Deadline> {}
