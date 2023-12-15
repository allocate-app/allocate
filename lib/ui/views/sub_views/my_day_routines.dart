//TODO: Refactor using Custom tiles -> Expansion + Search.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/routine_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/tiles.dart';

class MyDayRoutines extends StatefulWidget {
  const MyDayRoutines({Key? key}) : super(key: key);

  @override
  State<MyDayRoutines> createState() => _MyDayRoutines();
}

class _MyDayRoutines extends State<MyDayRoutines> {
  late RoutineProvider routineProvider;
  late UserProvider userProvider;

  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  @override
  void initState() {
    initializeProviders();
    initializeControllers();
    super.initState();
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics = const ScrollPhysics();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      buildRoutineCards(),
    ]);
  }

  Widget buildRoutineCards() {
    return Consumer<RoutineProvider>(
        builder: (BuildContext context, RoutineProvider value, Widget? child) {
      return Expanded(
        child: ListView(
            controller: mainScrollController,
            physics: scrollPhysics,
            shrinkWrap: true,
            children: [
              (null != value.curMorning)
                  ? Tiles.filledRoutineTile(
                      context: context,
                      routine: value.curMorning!,
                      times: 1,
                    )
                  : Tiles.emptyRoutineTile(
                      context: context,
                      times: 1,
                    ),
              (null != value.curAfternoon)
                  ? Tiles.filledRoutineTile(
                      context: context,
                      routine: value.curAfternoon!,
                      times: 2,
                    )
                  : Tiles.emptyRoutineTile(
                      context: context,
                      times: 2,
                    ),
              (null != value.curEvening)
                  ? Tiles.filledRoutineTile(
                      context: context,
                      routine: value.curEvening!,
                      times: 4,
                    )
                  : Tiles.emptyRoutineTile(
                      context: context,
                      times: 4,
                    ),
            ]),
      );
    });
  }
}
