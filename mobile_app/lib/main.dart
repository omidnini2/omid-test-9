import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:onnxruntime_flutter/onnxruntime_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Clone Offline',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final _player = AudioPlayer();
  OrtSession? _session;
  bool _busy = false;
  String? _embeddingPath;
  final _recorder = Record();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    final env = OrtEnvironment();
    final bytes = await DefaultAssetBundle.of(context)
        .load('assets/model.opt.onnx');
    _session = await OrtSession.fromBytes(env, bytes.buffer.asUint8List());
    setState(() {});
  }

  Future<void> _recordSample() async {
    if (!await Permission.microphone.request().isGranted) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/sample.wav';
    await _recorder.start(
      path: path,
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      samplingRate: 16000,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('در حال ضبط... برای توقف دکمه را مجدد بزنید'),
    ));
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return;
    setState(() => _embeddingPath = path);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('فایل ضبط شد: $path'),
    ));
    // TODO: pass to speaker encoder and save embedding.npy
  }

  Future<void> _synthesize() async {
    if (_controller.text.trim().isEmpty) return;
    if (_session == null) return;

    setState(() => _busy = true);

    // TODO: Convert Persian text → phoneme ids according to VITS tokenizer
    // For demo we send dummy tensor; real implementation requires tokenizer
    final textIds = Uint32List.fromList([1, 2, 3, 4]);
    final textTensor = OrtValue.tensorFromUint32List(textIds, shape: [1, textIds.length]);
    final lenTensor = OrtValue.tensorFromInt64List([textIds.length], shape: [1]);
    final sidTensor = OrtValue.tensorFromInt64List([0], shape: [1]);
    final spkEmbedTensor = OrtValue.tensorFromFloat32List(List.filled(256, 0), shape: [1, 256]);

    final outputs = await _session!.run(
      inputs: {
        'text': textTensor,
        'text_lengths': lenTensor,
        'sid': sidTensor,
        'spk_embed': spkEmbedTensor,
      },
      outputNames: ['wav'],
    );

    final wav = outputs['wav']?.floatData;
    if (wav != null && wav.isNotEmpty) {
      // Convert float pcm to bytes WAV (16kHz mono 16-bit)
      final bytes = _float32ToWav(Uint8List.view(Float32List.fromList(wav).buffer));
      await _player.play(BytesSource(bytes));
    }

    setState(() => _busy = false);
  }

  Uint8List _float32ToWav(Uint8List pcmBytes) {
    // Minimal WAV header (PCM 16-bit) writer for demo purposes
    final int sampleRate = 16000;
    final int numSamples = pcmBytes.length ~/ 4; // float32
    final int byteRate = sampleRate * 2; // 16-bit mono
    final wav = BytesBuilder();
    wav.add(ascii.encode('RIFF'));
    wav.add(_int32ToBytes(36 + numSamples * 2));
    wav.add(ascii.encode('WAVEfmt '));
    wav.add(_int32ToBytes(16));
    wav.add(_int16ToBytes(1));
    wav.add(_int16ToBytes(1));
    wav.add(_int32ToBytes(sampleRate));
    wav.add(_int32ToBytes(byteRate));
    wav.add(_int16ToBytes(2));
    wav.add(_int16ToBytes(16));
    wav.add(ascii.encode('data'));
    wav.add(_int32ToBytes(numSamples * 2));
    // Convert float32 [-1,1] to int16 PCM
    final floatBuffer = pcmBytes.buffer.asFloat32List();
    final int16Bytes = Int16List(floatBuffer.length);
    for (int i = 0; i < floatBuffer.length; i++) {
      final v = (floatBuffer[i].clamp(-1.0, 1.0) * 32767).round();
      int16Bytes[i] = v;
    }
    wav.add(int16Bytes.buffer.asUint8List());
    return wav.toBytes();
  }

  List<int> _int32ToBytes(int value) =>
      [value & 0xff, (value >> 8) & 0xff, (value >> 16) & 0xff, (value >> 24) & 0xff];
  List<int> _int16ToBytes(int value) => [value & 0xff, (value >> 8) & 0xff];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Clone Offline')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'متن فارسی را وارد کنید'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _synthesize,
                  child: _busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('گفتن'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _recorder.isRecording() ? _stopRecording : _recordSample,
                  child: Text(_recorder.isRecording() ? 'توقف ضبط' : 'ضبط نمونه صدا'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}