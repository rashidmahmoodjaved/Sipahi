import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final bool isGroupCall;

  const CallScreen({
    super.key,
    required this.channelName,
    this.isGroupCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    final callService = context.read<CallService>();
    await callService.initializeAgora();

    if (widget.isGroupCall) {
      await callService.startGroupCall(widget.channelName);
    } else {
      await callService.startOneToOneCall(widget.channelName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: SafeArea(
        child: Consumer<CallService>(
          builder: (context, callService, _) {
            return Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          child:
                              Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Voice Call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: () => callService.toggleMute(),
                        backgroundColor:
                            callService.isMuted ? Colors.red : Colors.white24,
                        child: Icon(
                          callService.isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () => callService.toggleSpeaker(),
                        backgroundColor: callService.isSpeakerOn
                            ? Colors.white24
                            : Colors.white10,
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () {
                          callService.endCall();
                          Navigator.pop(context);
                        },
                        backgroundColor: Colors.red,
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    context.read<CallService>().endCall();
    super.dispose();
  }
}
