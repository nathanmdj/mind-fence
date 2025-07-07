import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(BlocBase bloc, Object? event) {
    super.onEvent(bloc, event);
    log('BLoC Event: ${bloc.runtimeType}, Event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('BLoC Change: ${bloc.runtimeType}, Change: $change');
  }

  @override
  void onTransition(BlocBase bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log('BLoC Transition: ${bloc.runtimeType}, Transition: $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log('BLoC Error: ${bloc.runtimeType}, Error: $error, StackTrace: $stackTrace');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('BLoC Closed: ${bloc.runtimeType}');
  }
}