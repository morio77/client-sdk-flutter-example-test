import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/token_server_gateway.dart';
import 'package:livekit_example/widgets/text_field.dart';

import '../env/.env.dart';
import '../exts.dart';
import 'room.dart';

class ConnectPage extends StatefulWidget {
  //
  const ConnectPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _userNameCtrl = TextEditingController();
  static const _roomNameList = ['room1', 'room2', 'room3'];
  String _roomName = 'room1';

  // 接続オプション
  // https://blog.livekit.io/an-introduction-to-webrtc-simulcast-6c5f1f6402eb/
  bool _simulcast = true;
  // https://pub.dev/documentation/livekit_client/latest/livekit_client/RoomOptions/adaptiveStream.html
  bool _adaptiveStream = true;
  // https://pub.dev/documentation/livekit_client/latest/livekit_client/RoomOptions/dynacast.html
  bool _dynacast = true;

  // 接続中は接続ボタンを無効にするためのフラグ
  bool _busy = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    super.dispose();
  }

  /// ルームに接続する
  Future<void> _connect(BuildContext ctx, String token) async {
    try {
      final room = await LiveKitClient.connect(
        'http://${Env.livekitServerUrl}',
        token,
        roomOptions: RoomOptions(
          adaptiveStream: _adaptiveStream,
          dynacast: _dynacast,
          defaultVideoPublishOptions: VideoPublishOptions(
            simulcast: _simulcast,
          ),
        ),
      );

      await Navigator.push<void>(
        ctx,
        MaterialPageRoute(builder: (_) => RoomPage(room)),
      );
    } catch (error) {
      print('Could not connect $error');
      await ctx.showErrorDialog(error);
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _setSimulcast(bool? value) async {
    if (value == null || _simulcast == value) return;
    setState(() {
      _simulcast = value;
    });
  }

  void _setAdaptiveStream(bool? value) async {
    if (value == null || _adaptiveStream == value) return;
    setState(() {
      _adaptiveStream = value;
    });
  }

  void _setDynacast(bool? value) async {
    if (value == null || _dynacast == value) return;
    setState(() {
      _dynacast = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 70),
                  child: SvgPicture.asset('images/logo-dark.svg'),
                ),
                // ユーザ名入力部分
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: LKTextField(label: 'ユーザ名', ctrl: _userNameCtrl),
                ),

                // ルーム選択ボタン
                DropdownButton<String>(
                  value: _roomName,
                  onChanged: (String? value) {
                    setState(() {
                      if (value != null) _roomName = value;
                    });
                  },
                  items: _roomNameList
                      .map<DropdownMenuItem<String>>((String roomName) {
                    return DropdownMenuItem(
                      value: roomName,
                      child: Text(roomName),
                    );
                  }).toList(),
                ),

                // 接続オプション変更部分
                switchBooleanItemTile(
                  text: 'Simulcast',
                  value: _simulcast,
                  onChanged: _setSimulcast,
                ),
                switchBooleanItemTile(
                  text: 'Adaptive Stream',
                  value: _adaptiveStream,
                  onChanged: _setAdaptiveStream,
                ),
                switchBooleanItemTile(
                  text: 'Dynacast',
                  value: _dynacast,
                  onChanged: _setDynacast,
                ),

                // 接続ボタン
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                          });

                          // トークン取得
                          final token = await TokenServerGateway.generateToken(
                            _roomName,
                            _userNameCtrl.text,
                          );

                          // ルームに接続
                          await _connect(context, token);
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      const Text('CONNECT'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding switchBooleanItemTile({
    required String text,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
