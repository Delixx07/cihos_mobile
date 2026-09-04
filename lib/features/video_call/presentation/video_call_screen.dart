import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

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
    this.uid,
  });

  final String? doctorName;
  final String? specialty;
  final String? doctorPhoto;
  final String? channelName;
  final String? token;
  final String? appId;
  final int? uid;

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
        uid: widget.uid ?? 0,
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






// =============================================================================
// TELECONSULTATION TOKEN & LOBBY SUPPORT
// =============================================================================

/// Token data returned by the CMS API for an Agora teleconsultation session.
class AgoraTokenData {
  const AgoraTokenData({
    required this.appId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.expiresAt,
    required this.appointmentId,
    this.doctorName,
    this.doctorSpecialty,
    this.patientName,
    this.scheduledAt,
  });

  final String appId;
  final String channelName;
  final String token;
  final int uid;
  final int expiresAt;
  final String appointmentId;
  final String? doctorName;
  final String? doctorSpecialty;
  final String? patientName;
  final String? scheduledAt;

  factory AgoraTokenData.fromJson(Map<String, dynamic> json) {
    return AgoraTokenData(
      appId: json['app_id']?.toString() ?? AppConfig.agoraAppId,
      channelName: json['channel_name']?.toString() ?? AppConfig.agoraChannelName,
      token: json['token']?.toString() ?? '',
      uid: (json['uid'] as num?)?.toInt() ?? 20001,
      expiresAt: (json['expires_at'] as num?)?.toInt() ?? 0,
      appointmentId: json['appointment_id']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString(),
      doctorSpecialty: json['doctor_specialty']?.toString(),
      patientName: json['patient_name']?.toString(),
      scheduledAt: json['scheduled_at']?.toString(),
    );
  }
}

/// Service to fetch Agora RTC token from the CMS API for a given appointment.
///
/// Endpoint: GET {CMS_BASE_URL}/api/teleconsultation/token?id={appointmentId}
/// Auth:     x-api-key header
class TeleconsultationTokenService {
  TeleconsultationTokenService._();

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'x-api-key': AppConfig.cmsApiKey,
      },
    ),
  );

  /// Fetch Agora token for the patient side of a teleconsultation session.
  /// Uses query parameter `id` to avoid Apache blocking %2F in path.
  static Future<AgoraTokenData> fetchToken(String appointmentId) async {
    final url = '${AppConfig.cmsBaseUrl}/api/teleconsultation/token';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {'id': appointmentId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data as Map<String, dynamic>;
        if (body['ok'] == true && body['data'] != null) {
          return AgoraTokenData.fromJson(body['data'] as Map<String, dynamic>);
        }
        throw Exception(body['message']?.toString() ?? 'Respons API tidak valid');
      }

      throw Exception('HTTP ${response.statusCode}: Gagal mengambil token teleconsultasi');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Koneksi timeout. Pastikan perangkat terhubung ke jaringan yang sama dengan server.');
      }
      throw Exception('Gagal menghubungi server: ${e.message}');
    }
  }
}

/// Lobby/waiting screen shown before patient joins the teleconsultation video call.
///
/// Fetches Agora RTC token from CMS API, displays doctor info, and
/// navigates to [VideoCallScreen] once the token is ready.
class TeleconsultationLobbyScreen extends StatefulWidget {
  const TeleconsultationLobbyScreen({
    super.key,
    required this.appointmentId,
    this.doctorName,
    this.doctorSpecialty,
    this.patientName,
    this.scheduledAt,
  });

  final String appointmentId;
  final String? doctorName;
  final String? doctorSpecialty;
  final String? patientName;
  final String? scheduledAt;

  @override
  State<TeleconsultationLobbyScreen> createState() =>
      _TeleconsultationLobbyScreenState();
}

class _TeleconsultationLobbyScreenState
    extends State<TeleconsultationLobbyScreen>
    with SingleTickerProviderStateMixin {
  AgoraTokenData? _tokenData;
  String? _errorMessage;
  bool _isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchToken();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
          await TeleconsultationTokenService.fetchToken(widget.appointmentId);
      if (mounted) {
        setState(() {
          _tokenData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _joinVideoCall() {
    if (_tokenData == null) return;

    context.push(
      '/video-call/room',
      extra: {
        'channelName': _tokenData!.channelName,
        'token': _tokenData!.token,
        'appId': _tokenData!.appId,
        'uid': _tokenData!.uid,
        'doctorName': _tokenData!.doctorName ?? widget.doctorName ?? 'Dokter',
        'specialty': _tokenData!.doctorSpecialty ?? widget.doctorSpecialty ?? 'Spesialis',
      },
    );
  }

  String _formatScheduledAt(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("EEEE, d MMMM yyyy � HH:mm 'WIB'", 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDoctorName =
        _tokenData?.doctorName ?? widget.doctorName ?? 'dr. Dokter Spesialis';
    final effectiveSpecialty =
        _tokenData?.doctorSpecialty ?? widget.doctorSpecialty ?? 'Spesialis';
    final effectiveSchedule = _formatScheduledAt(
        _tokenData?.scheduledAt ?? widget.scheduledAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Masuk Teleconsultasi',
          style: AppTypography.headingMd.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Doctor Avatar / Pulse Animation
              ScaleTransition(
                scale: _isLoading ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Doctor Info
              Text(
                effectiveDoctorName,
                style: AppTypography.headingMd.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  effectiveSpecialty,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Session Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Jadwal Sesi',
                      value: effectiveSchedule,
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'ID Appointment',
                      value: widget.appointmentId,
                      mono: true,
                    ),
                    if (_tokenData?.channelName != null) ...[
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      _InfoRow(
                        icon: Icons.router_rounded,
                        label: 'Channel',
                        value: _tokenData!.channelName,
                        mono: true,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Status / Loading / Error
              if (_isLoading) ...[
                _StatusCard(
                  color: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  icon: Icons.cloud_sync_rounded,
                  iconColor: AppColors.primary,
                  title: 'Menyiapkan Sesi Video Call...',
                  subtitle: 'Sedang menghubungkan ke server dan menyiapkan token keamanan.',
                  trailing: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                _StatusCard(
                  color: const Color(0xFFFFF1F2),
                  borderColor: const Color(0xFFFECDD3),
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFE11D48),
                  title: 'Gagal Menyiapkan Sesi',
                  subtitle: _errorMessage!,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _fetchToken,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                _StatusCard(
                  color: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF16A34A),
                  title: 'Sesi Siap!',
                  subtitle:
                      'Token keamanan sudah disiapkan. Klik tombol di bawah untuk memulai video call dengan dokter.',
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // CTA Button
              AnimatedOpacity(
                opacity: (_tokenData != null && !_isLoading) ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_tokenData != null && !_isLoading) ? _joinVideoCall : null,
                    icon: const Icon(Icons.videocam_rounded, size: 22),
                    label: const Text(
                      'Mulai Video Call',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Disclaimer
              Text(
                'Pastikan kamera dan mikrofon diizinkan sebelum bergabung.\nVideo call menggunakan teknologi Agora RTC.',
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}
