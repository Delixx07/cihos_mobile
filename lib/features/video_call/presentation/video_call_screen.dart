import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Screen for live video teleconsultation between patient and doctor powered by Agora RTC.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    this.doctorName,
    this.specialty,
    this.doctorPhoto,
    this.channelName,
    this.token,
    this.appId,
  });

  final String? doctorName;
  final String? specialty;
  final String? doctorPhoto;
  final String? channelName;
  final String? token;
  final String? appId;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  bool _isInitializing = true;
  String? _errorMessage;
  int _localAudioVolume = 0;

  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  late String _activeChannel;
  late String _activeToken;
  late String _activeAppId;

  @override
  void initState() {
    super.initState();
    _activeAppId = widget.appId ?? AppConfig.agoraAppId;
    _activeChannel = (widget.channelName != null && widget.channelName!.isNotEmpty)
        ? widget.channelName!
        : AppConfig.agoraChannelName;
    _activeToken = widget.token ?? AppConfig.agoraTempToken;

    _requestPermissionsAndInit();
  }

  Future<void> _requestPermissionsAndInit() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    if (_activeAppId.trim().isEmpty) {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'AGORA_APP_ID belum diisi di file .env.json.\nSilakan masukkan App ID project Agora Anda.';
      });
      return;
    }

    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      if (!cameraGranted || !micGranted) {
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'Izin kamera dan mikrofon diperlukan untuk melakukan video call konsultasi dokter.';
        });
        return;
      }

      await _initAgora();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Gagal menginisialisasi panggilan: $e';
      });
    }
  }

  Future<void> _initAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: _activeAppId.trim(),
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('[Agora] onJoinChannelSuccess: ${connection.channelId}');
            if (mounted) {
              setState(() {
                _isJoined = true;
                _isInitializing = false;
              });
              _startTimer();
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('[Agora] onUserJoined remote doctor: $remoteUid');
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
            }
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            debugPrint('[Agora] onUserOffline remote doctor: $remoteUid ($reason)');
            if (mounted) {
              setState(() {
                _remoteUid = null;
              });
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('[Agora] onError: $err - $msg');
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('[Agora] Token will expire soon.');
          },
          onAudioVolumeIndication: (
            RtcConnection connection,
            List<AudioVolumeInfo> speakers,
            int speakerNumber,
            int totalVolume,
          ) {
            for (final speaker in speakers) {
              if (speaker.uid == 0) {
                if (mounted) {
                  setState(() {
                    _localAudioVolume = speaker.volume ?? 0;
                  });
                }
              }
            }
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );
      await _engine!.startPreview();

      final tokenToUse = _activeToken.trim().isEmpty ? '' : _activeToken.trim();

      await _engine!.joinChannel(
        token: tokenToUse,
        channelId: _activeChannel.trim(),
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Terjadi kesalahan saat menghubungkan ke Agora: $e';
        });
      }
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleMute() async {
    final newMute = !_isMuted;
    setState(() => _isMuted = newMute);
    await _engine?.muteLocalAudioStream(newMute);
  }

  Future<void> _toggleVideo() async {
    final newVideoOff = !_isVideoOff;
    setState(() => _isVideoOff = newVideoOff);
    await _engine?.muteLocalVideoStream(newVideoOff);
  }

  Future<void> _switchCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _engine?.switchCamera();
  }

  Future<void> _confirmAndEndCall() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Akhiri Video Call?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menyelesaikan sesi konsultasi video call ini?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Akhiri Panggilan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _leaveAndExit();
    }
  }

  void _leaveAndExit() {
    _durationTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorDisplayName = widget.doctorName ?? 'dr. Spesialis';
    final specialtyName = widget.specialty ?? 'Konsultasi Video Call';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmAndEndCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            // 1. Remote View (Doctor) or Waiting placeholder
            Positioned.fill(
              child: _buildRemoteVideoOrPlaceholder(doctorDisplayName, specialtyName),
            ),

            // 2. Top Bar (Header with Doctor details and timer)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(doctorDisplayName, specialtyName),
            ),

            // 3. Floating Local Video (Patient View)
            if (_isJoined && _engine != null)
              Positioned(
                top: 105,
                right: 16,
                child: _buildLocalPatientView(),
              ),

            // 4. Bottom Call Controls Bar
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildControlBar(),
            ),

            // 5. Error Overlay (if permission denied or Agora failure)
            if (_errorMessage != null)
              Positioned.fill(
                child: _buildErrorOverlay(),
              ),

            // 6. Loading Indicator
            if (_isInitializing && _errorMessage == null)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF38BDF8)),
                        SizedBox(height: 16),
                        Text(
                          'Menghubungkan ke ruang konsultasi...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String doctorName, String specialty) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _confirmAndEndCall,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Timer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideoOrPlaceholder(String doctorName, String specialty) {
    if (_remoteUid != null && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _activeChannel),
        ),
      );
    }

    // Waiting Screen when doctor hasn't joined yet
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: widget.doctorPhoto != null
                        ? Image.asset(
                            widget.doctorPhoto!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 54,
                            color: Color(0xFF94A3B8),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                doctorName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                specialty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Color(0xFF38BDF8),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Menunggu dokter masuk ke ruangan...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ruang: $_activeChannel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPatientView() {
    return Container(
      width: 110,
      height: 155,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Stack(
          children: [
            if (!_isVideoOff && _engine != null)
              AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            else
              Container(
                color: const Color(0xFF1E293B),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_off_rounded,
                        color: Color(0xFF94A3B8),
                        size: 26,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kamera Mati',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Patient "Anda" Badge + Live Mic Volume Indicator
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isMuted
                          ? const Color(0xFFDC2626).withValues(alpha: 0.85)
                          : (_localAudioVolume > 15
                              ? const Color(0xFF16A34A).withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.65)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMuted
                              ? Icons.mic_off_rounded
                              : (_localAudioVolume > 15
                                  ? Icons.graphic_eq_rounded
                                  : Icons.mic_rounded),
                          color: Colors.white,
                          size: 11,
                        ),
                        if (!_isMuted && _localAudioVolume > 15) ...[
                          const SizedBox(width: 3),
                          Text(
                            '$_localAudioVolume',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Mute Microphone
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: !_isMuted,
            activeColor: const Color(0xFF334155),
            inactiveColor: const Color(0xFFDC2626),
            onTap: _toggleMute,
          ),

          // 2. Video On / Off
          _buildControlButton(
            icon: _isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
            isActive: !_isVideoOff,
            activeColor: const Color(0xFF334155),
            inactiveColor: const Color(0xFFDC2626),
            onTap: _toggleVideo,
          ),

          // 3. Switch Camera
          _buildControlButton(
            icon: Icons.flip_camera_ios_rounded,
            isActive: true,
            activeColor: const Color(0xFF334155),
            onTap: _switchCamera,
          ),

          // 4. End Call Button
          _buildControlButton(
            icon: Icons.call_end_rounded,
            isActive: true,
            activeColor: const Color(0xFFDC2626),
            iconColor: Colors.white,
            onTap: _confirmAndEndCall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    Color inactiveColor = const Color(0xFFDC2626),
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tidak Dapat Memulai Video Call',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan tidak terduga.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _requestPermissionsAndInit,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
