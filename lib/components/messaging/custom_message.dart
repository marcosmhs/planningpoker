import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';

enum MessageType { info, sucess, error }

enum ModelType { dialog, toast, snackbar }

class CustomMessage {
  static CustomMessage error(BuildContext context, {required String message}) {
    return CustomMessage(context: context, messageText: message, messageType: MessageType.error);
  }

  static CustomMessage sucess(BuildContext context, {required String message}) {
    return CustomMessage(context: context, messageText: message, messageType: MessageType.sucess);
  }

  static CustomMessage errorToast(BuildContext context, {required String message}) {
    return CustomMessage(context: context, messageText: message, messageType: MessageType.error, modelType: ModelType.snackbar);
  }

  CustomMessage({
    ModelType modelType = ModelType.snackbar,
    required BuildContext context,
    required String messageText,
    required MessageType messageType,
    int durationInSeconds = 2,
    SnackBarAction? action,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double toastFixedHeight = 70,
    ToastGravity toastGravity = ToastGravity.BOTTOM,
  }) {
    IconData iconImage;
    Color bkgColor;
    Color txtColor;

    if (textColor != null) {
      txtColor = textColor;
    } else {
      txtColor = messageType == MessageType.error ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color!;
    }

    if (backgroundColor != null) {
      bkgColor = backgroundColor;
    } else {
      bkgColor = messageType == MessageType.error ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary;
    }

    if (icon != null) {
      iconImage = icon;
    } else {
      if (messageType == MessageType.info) {
        iconImage = Icons.info;
      } else if (messageType == MessageType.error) {
        iconImage = Icons.error_outline;
      } else {
        iconImage = Icons.check_circle_outline;
      }
    }

    if (modelType == ModelType.snackbar) {
      // remove o snackbar anterior
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Row(
              children: [
                Icon(iconImage, color: txtColor),
                const SizedBox(width: 5),
                Flexible(child: Text(messageText, style: TextStyle(color: txtColor))),
              ],
            ),
            duration: Duration(seconds: durationInSeconds),
            backgroundColor: bkgColor,
            action: action),
      );
    }

    if (modelType == ModelType.toast) {
      FToast toast = FToast();
      toast.init(context);
      toast.removeCustomToast();

      toast.showToast(
        toastDuration: Duration(seconds: durationInSeconds),
        gravity: toastGravity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: bkgColor,
          ),
          alignment: Alignment.center,
          constraints: BoxConstraints(
            minHeight: toastFixedHeight,
            maxHeight: toastFixedHeight,
            maxWidth: MediaQuery.of(context).size.width - 30,
            minWidth: MediaQuery.of(context).size.width - 30,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(iconImage, color: txtColor),
                const SizedBox(width: 5),
                Flexible(child: Text(messageText, style: TextStyle(color: txtColor))),
              ],
            ),
          ),
        ),
      );
    }
  }
}
