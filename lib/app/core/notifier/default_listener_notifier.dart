import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';

import '../ui/messages.dart';
import 'default_change_notifier.dart';

class DefaultListenerNotifier {
  final DefaultChangeNotifier changeNotifier;

  DefaultListenerNotifier({required this.changeNotifier});

  void listener(
      {required BuildContext context,
      required SuccessVoidCallback successCallback,
      ErrorVoidCallback? errorCallback}) {
    changeNotifier.addListener(() {
      // loader
      if (changeNotifier.loading) {
        Loader.show(context);
      } else {
        Loader.hide();
      }

      // error
      if (changeNotifier.hasError) {
        if (errorCallback != null) {
          errorCallback(changeNotifier, this);
        }
        Messages.of(context).showError(changeNotifier.error ?? 'Erro interno');
        // success
      } else if (changeNotifier.isSuccess) {
        successCallback(changeNotifier, this);
      }
    });
  }

  void dispose() {
    changeNotifier.removeListener(() {});
  }
}

typedef SuccessVoidCallback = void Function(
    DefaultChangeNotifier notifier, DefaultListenerNotifier listenerInstance);

typedef ErrorVoidCallback = void Function(
    DefaultChangeNotifier notifier, DefaultListenerNotifier listenerInstance);
