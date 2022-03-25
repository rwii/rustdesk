import 'package:flutter/material.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import '../models/server_model.dart';
import 'home_page.dart';
import '../models/model.dart';

class ServerPage extends StatelessWidget implements PageShape {
  @override
  final title = translate("Share Screen");

  @override
  final icon = Icon(Icons.mobile_screen_share);

  @override
  final appBarActions = [
    PopupMenuButton<String>(
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              child: Text(translate("Change ID")),
              value: "changeID",
              enabled: false,
            ),
            PopupMenuItem(
              child: Text(translate("Set your own password")),
              value: "changePW",
              enabled: false,
            )
          ];
        },
        onSelected: (value) => debugPrint("PopupMenuItem onSelected:$value"))
  ];

  @override
  Widget build(BuildContext context) {
    checkService();
    return ChangeNotifierProvider.value(
        value: FFI.serverModel,
        child: Consumer<ServerModel>(
            builder: (context, serverModel, child) => SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ServerInfo(),
                        PermissionChecker(),
                        ConnectionManager(),
                        SizedBox.fromSize(size: Size(0, 15.0)),
                      ],
                    ),
                  ),
                )));
  }
}

void checkService() {
  // 检测当前服务状态，若已存在服务则异步更新数据回来
  FFI.invokeMethod("check_service"); // jvm
}

class ServerInfo extends StatefulWidget {
  @override
  _ServerInfoState createState() => _ServerInfoState();
}

class _ServerInfoState extends State<ServerInfo> {
  final model = FFI.serverModel;
  var _passwdShow = false;

  @override
  Widget build(BuildContext context) {
    return model.isStart
        ? PaddingCard(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                readOnly: true,
                style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: MyTheme.accent),
                controller: model.serverId,
                decoration: InputDecoration(
                  icon: const Icon(Icons.perm_identity),
                  labelText: translate("ID"),
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold, color: MyTheme.accent50),
                ),
                onSaved: (String? value) {},
              ),
              TextFormField(
                readOnly: true,
                obscureText: !_passwdShow,
                style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: MyTheme.accent),
                controller: model.serverPasswd,
                decoration: InputDecoration(
                    icon: const Icon(Icons.lock),
                    labelText: translate("Password"),
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: MyTheme.accent50),
                    suffix: IconButton(
                        icon: Icon(Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _passwdShow = !_passwdShow;
                          });
                        })),
                onSaved: (String? value) {},
              ),
            ],
          ))
        : PaddingCard(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                  child: Row(
                children: [
                  Icon(Icons.warning_amber_sharp,
                      color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    translate("Service is not running"),
                    style: TextStyle(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: MyTheme.accent80,
                    ),
                  )
                ],
              )),
              SizedBox(height: 5),
              Center(
                  child: Text(
                translate("android_start_service_tip"),
                style: TextStyle(fontSize: 12, color: MyTheme.darkGray),
              ))
            ],
          ));
  }
}

class PermissionChecker extends StatefulWidget {
  @override
  _PermissionCheckerState createState() => _PermissionCheckerState();
}

class _PermissionCheckerState extends State<PermissionChecker> {
  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    final hasAudioPermission = androidVersion >= 30;
    return PaddingCard(
        title: translate("Configuration Permissions"),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PermissionRow(translate("Screen Capture"), serverModel.mediaOk,
                serverModel.toggleService),
            PermissionRow(translate("Mouse Control"), serverModel.inputOk,
                serverModel.toggleInput),
            PermissionRow(translate("File Transfer"), serverModel.fileOk,
                serverModel.toggleFile),
            hasAudioPermission
                ? PermissionRow(translate("Audio Capture"), serverModel.audioOk,
                    serverModel.toggleAudio)
                : Text(
                    "* ${translate("android_version_audio_tip")}",
                    style: TextStyle(color: MyTheme.darkGray),
                  ),
            SizedBox(height: 8),
            serverModel.mediaOk
                ? ElevatedButton.icon(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red)),
                    icon: Icon(Icons.stop),
                    onPressed: serverModel.toggleService,
                    label: Text(translate("Stop service")))
                : ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    onPressed: serverModel.toggleService,
                    label: Text(translate("Start Service"))),
          ],
        ));
  }
}

class PermissionRow extends StatelessWidget {
  PermissionRow(this.name, this.isOk, this.onPressed);

  final String name;
  final bool isOk;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
                width: 140,
                child: Text(name,
                    style: TextStyle(fontSize: 16.0, color: MyTheme.accent50))),
            SizedBox(
              width: 50,
              child: Text(isOk ? translate("ON") : translate("OFF"),
                  style: TextStyle(
                      fontSize: 16.0,
                      color: isOk ? Colors.green : Colors.grey)),
            )
          ],
        ),
        TextButton(
            onPressed: onPressed,
            child: Text(
              translate(isOk ? "CLOSE" : "OPEN"),
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        const Divider(height: 0)
      ],
    );
  }
}

class ConnectionManager extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    return Column(
        children: serverModel.clients.entries
            .map((entry) => PaddingCard(
                title: translate(entry.value.isFileTransfer
                    ? "File Connection"
                    : "Screen Connection"),
                titleIcon: entry.value.isFileTransfer
                    ? Icons.folder_outlined
                    : Icons.mobile_screen_share,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: clientInfo(entry.value),
                    ),
                    ElevatedButton.icon(
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.red)),
                        icon: Icon(Icons.close),
                        onPressed: () {
                          FFI.setByName("close_conn", entry.key.toString());
                        },
                        label: Text(translate("Close")))
                  ],
                )))
            .toList());
  }
}

class PaddingCard extends StatelessWidget {
  PaddingCard({required this.child, this.title, this.titleIcon});

  final String? title;
  final IconData? titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final children = [child];
    if (title != null) {
      children.insert(
          0,
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  titleIcon != null
                      ? Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(titleIcon,
                              color: MyTheme.accent80, size: 30))
                      : SizedBox.shrink(),
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: MyTheme.accent80,
                    ),
                  )
                ],
              )));
    }
    return Container(
        width: double.maxFinite,
        child: Card(
          margin: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ));
  }
}

Widget clientInfo(Client client) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(
      children: [
        CircleAvatar(
            child: Text(client.name[0]), backgroundColor: MyTheme.border),
        SizedBox(width: 12),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(client.name,
                  style: TextStyle(color: MyTheme.idColor, fontSize: 20)),
              SizedBox(width: 8),
              Text(client.peerId,
                  style: TextStyle(color: MyTheme.idColor, fontSize: 10))
            ])
      ],
    ),
  ]);
}

void toAndroidChannelInit() {
  FFI.setMethodCallHandler((method, arguments) {
    debugPrint("flutter got android msg,$method,$arguments");
    try {
      switch (method) {
        case "start_capture":
          {
            DialogManager.reset();
            FFI.serverModel.updateClientState();
            break;
          }
        case "on_permission_changed":
          {
            var name = arguments["name"] as String;
            var value = arguments["value"] as String == "true";
            debugPrint("from jvm:on_permission_changed,$name:$value");
            FFI.serverModel.changeStatue(name, value);
            break;
          }
      }
    } catch (e) {
      debugPrint("MethodCallHandler err:$e");
    }
    return "";
  });
}
