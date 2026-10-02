import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../data/services/absen_service.dart';
import '../widgets/custom_button.dart';

class AbsenPage extends StatefulWidget {
  final String type; // "masuk" or "pulang"

  const AbsenPage({
    super.key,
    required this.type,
  });

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  GoogleMapController? _mapController;

  bool _isLoadingGps = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  Position? _currentPosition;
  String _currentAddress = "Mencari alamat...";

  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  bool get isMasuk => widget.type.toLowerCase() == "masuk";

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchLocationAndAddress();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndAddress() async {
    setState(() {
      _isLoadingGps = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              "Layanan GPS di perangkat belum aktif. Silakan aktifkan GPS Anda.";
          _isLoadingGps = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              "Izin lokasi ditolak permanen. Silakan berikan izin di Pengaturan aplikasi.";
          _isLoadingGps = false;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              "Izin akses lokasi diperlukan untuk validasi presensi.";
          _isLoadingGps = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String address = "Alamat tidak tersedia";
      try {
        final geocoding = geo.Geocoding();
        List<geo.Placemark> placemarks = await geocoding
            .placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = p.street ?? '';
          final subLocality = p.subLocality ?? '';
          final locality = p.locality ?? '';
          address = [street, subLocality, locality]
              .where((s) => s.isNotEmpty)
              .join(", ");
        }
      } catch (_) {
        address =
            "Titik koordinat: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
      }

      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _currentAddress = address.isEmpty ? "Lokasi terdeteksi" : address;
          _isLoadingGps = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pos.latitude, pos.longitude),
                zoom: 16.5,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal mendapatkan lokasi: ${e.toString()}";
          _isLoadingGps = false;
        });
      }
    }
  }

  Future<void> _submitAbsen() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Titik lokasi GPS belum terdeteksi."),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final address = _currentAddress;

      Map<String, dynamic> result;
      if (isMasuk) {
        result = await AbsenService().checkIn(
          latitude: lat,
          longitude: lng,
          address: address,
        );
      } else {
        result = await AbsenService().checkOut(
          latitude: lat,
          longitude: lng,
          address: address,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result["message"] ??
                      (isMasuk
                          ? "Absen masuk berhasil!"
                          : "Absen pulang berhasil!"),
                ),
              ),
            ],
          ),
          backgroundColor:
              isMasuk ? AppTheme.success : const Color(0xFFEA580C),
        ),
      );

      // Return true to Dashboard so it refreshes status
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception:", "").trim()),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isMasuk ? "Presensi Masuk" : "Presensi Pulang";
    final timeStr = DateFormat("HH:mm:ss", "id_ID").format(_currentTime);
    final dateStr =
        DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(_currentTime);

    LatLng userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2088, 106.8456); // Default Jakarta fallback

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            onPressed: _fetchLocationAndAddress,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // ===============================
          // MAP / RADAR VIEW
          // ===============================
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLatLng,
                zoom: 16.5,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId("current_pos"),
                  position: userLatLng,
                  infoWindow: InfoWindow(
                    title: "Lokasi Anda",
                    snippet: _currentAddress,
                  ),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId("radius_accuracy"),
                  center: userLatLng,
                  radius: 50,
                  fillColor: (isMasuk ? AppTheme.success : const Color(0xFFEA580C))
                      .withValues(alpha: 0.18),
                  strokeColor:
                      isMasuk ? AppTheme.success : const Color(0xFFEA580C),
                  strokeWidth: 2,
                ),
              },
            )
          else
            // Fallback animated radar when GPS is loading or map is pending
            Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingGps) ...[
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Mendeteksi Titik Lokasi GPS...",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Pastikan izin lokasi dan GPS Anda aktif",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ] else if (_errorMessage != null) ...[
                      const Icon(
                        Icons.location_off_rounded,
                        size: 60,
                        color: AppTheme.danger,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchLocationAndAddress,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Coba Deteksi Ulang"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(180, 46),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Re-center Floating Action Button
          if (_currentPosition != null)
            Positioned(
              right: 18,
              bottom: 275,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: userLatLng, zoom: 16.5),
                    ),
                  );
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),

          // ===============================
          // BOTTOM FLOATING CARD
          // ===============================
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTheme.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Clock & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isMasuk
                                  ? AppTheme.success
                                  : const Color(0xFFEA580C))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isMasuk
                                    ? AppTheme.success
                                    : const Color(0xFFEA580C))
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isMasuk
                                    ? AppTheme.success
                                    : const Color(0xFFEA580C),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isMasuk ? "Absen Masuk" : "Absen Pulang",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isMasuk
                                    ? AppTheme.success
                                    : const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Location Address Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lokasi Anda Terdeteksi:",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLoadingGps
                                    ? "Sedang memindai koordinat..."
                                    : _currentAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (_currentPosition != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)} • Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Submit Button
                  CustomButton(
                    text: isMasuk
                        ? "KONFIRMASI ABSEN MASUK"
                        : "KONFIRMASI ABSEN PULANG",
                    icon: isMasuk
                        ? Icons.check_circle_outline_rounded
                        : Icons.logout_rounded,
                    gradient: isMasuk
                        ? AppTheme.successGradient
                        : AppTheme.warningGradient,
                    isLoading: _isSubmitting || _isLoadingGps,
                    onPressed: _currentPosition == null ? null : _submitAbsen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
