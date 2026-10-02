import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../data/services/delete_absen_service.dart';
import '../../data/services/history_service.dart';
import '../widgets/status_badge.dart';
import 'map_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool loading = true;
  List<dynamic> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // ==========================
  // AMBIL HISTORY
  // ==========================
  Future<void> loadHistory() async {
    setState(() {
      loading = true;
    });

    try {
      final now = DateTime.now();
      final start =
          DateFormat("yyyy-MM-dd").format(DateTime(now.year, now.month, 1));
      final end = DateFormat("yyyy-MM-dd").format(now);

      final result = await HistoryService().getHistory(start: start, end: end);

      if (mounted) {
        setState(() {
          history = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "").trim()),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  // ==========================
  // DELETE ABSEN
  // ==========================
  Future<void> deleteAbsen(int id) async {
    try {
      final result = await DeleteAbsenService().deleteAbsen(id: id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result["message"] ?? "Data absensi berhasil dihapus"),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
        ),
      );

      loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception:", "").trim()),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  // ==========================
  // KONFIRMASI DELETE MODAL
  // ==========================
  Future<void> confirmDelete(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppTheme.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Hapus Catatan?",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            "Apakah Anda yakin ingin menghapus data absensi ini secara permanen?",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "BATAL",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("HAPUS"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      deleteAbsen(id);
    }
  }

  String formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return "-";
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat("EEEE, dd MMM yyyy", "id_ID").format(date);
    } catch (_) {
      return tanggal;
    }
  }

  String formatJam(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty || timestamp == "-") return "-";
    try {
      // If it's already HH:mm:ss format
      if (timestamp.length <= 8 && timestamp.contains(":")) {
        return timestamp.substring(0, 5);
      }
      final date = DateTime.parse(timestamp);
      return DateFormat("HH:mm", "id_ID").format(date);
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bulanIni = DateFormat("MMMM yyyy", "id_ID").format(now);

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
          "Riwayat Presensi",
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
                Icons.refresh_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            onPressed: loadHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadHistory,
          color: AppTheme.primary,
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    // Top Month Header & Counter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border, width: 1.2),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Periode $bulanIni",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Total ${history.length} catatan kehadiran",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Main Content / List
                    Expanded(
                      child: history.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.event_note_rounded,
                                          size: 64,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Belum Ada Riwayat",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Presensi yang Anda lakukan bulan ini akan tercatat dan ditampilkan di halaman ini.",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount: history.length,
                              itemBuilder: (context, index) {
                                final item = history[index];
                                final checkInDate = item["check_in"];
                                final checkInTime = item["check_in"] ?? "-";
                                final checkOutTime = item["check_out"] ?? "-";
                                final checkInAddress = item["check_in_address"] ??
                                    "Alamat tidak tersedia";
                                final checkOutAddress = item["check_out_address"];
                                final alasan = item["alasan_izin"];
                                final rawStatus = item["status"] ?? "Hadir";
                                final checkInLocation = item["check_in_location"];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: AppTheme.border,
                                      width: 1.2,
                                    ),
                                    boxShadow: AppTheme.softShadow,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header: Date & Status Badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              formatTanggal(checkInDate),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          StatusBadge(status: rawStatus),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // Time In & Time Out Cards
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.scaffoldBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          children: [
                                            // Check In Time
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.login_rounded,
                                                    size: 18,
                                                    color: AppTheme.success,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "Masuk",
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 10,
                                                          color: AppTheme
                                                              .textSecondary,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        formatJam(checkInTime),
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            Container(
                                              height: 24,
                                              width: 1,
                                              color: AppTheme.border,
                                            ),

                                            // Check Out Time
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.logout_rounded,
                                                      size: 18,
                                                      color: Color(0xFFEA580C),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Pulang",
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 10,
                                                            color: AppTheme
                                                                .textSecondary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                        ),
                                                        ),
                                                        Text(
                                                          formatJam(checkOutTime),
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppTheme
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Address In
                                      _buildAddressRow(
                                        icon: Icons.location_on_outlined,
                                        iconColor: AppTheme.primaryLight,
                                        label: "Lokasi Masuk",
                                        value: checkInAddress,
                                      ),

                                      // Address Out if available
                                      if (checkOutAddress != null &&
                                          checkOutAddress.isNotEmpty &&
                                          checkOutAddress != "-") ...[
                                        const SizedBox(height: 8),
                                        _buildAddressRow(
                                          icon: Icons.location_pin,
                                          iconColor: const Color(0xFFEA580C),
                                          label: "Lokasi Pulang",
                                          value: checkOutAddress,
                                        ),
                                      ],

                                      // Alasan Izin if present
                                      if (alasan != null &&
                                          alasan.isNotEmpty &&
                                          alasan != "-") ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.infoLight,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.info.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.info_outline_rounded,
                                                size: 16,
                                                color: AppTheme.info,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Alasan: $alasan",
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.info,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 14),

                                      // Action Buttons: Map & Delete
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                if (checkInLocation == null ||
                                                    checkInLocation.isEmpty) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Koordinat lokasi tidak tersedia untuk absensi ini.",
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.danger,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                try {
                                                  final koordinat =
                                                      checkInLocation.split(",");
                                                  final lat = double.parse(
                                                    koordinat[0].trim(),
                                                  );
                                                  final lng = double.parse(
                                                    koordinat[1].trim(),
                                                  );

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          MapPage(
                                                        latitude: lat,
                                                        longitude: lng,
                                                        address: checkInAddress,
                                                      ),
                                                    ),
                                                  );
                                                } catch (_) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Format koordinat tidak valid",
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.danger,
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.map_outlined,
                                                size: 16,
                                              ),
                                              label: const Text("Lihat di Peta"),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.primary,
                                                side: const BorderSide(
                                                  color: AppTheme.primary,
                                                ),
                                                minimumSize: const Size(0, 40),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            onPressed: () {
                                              confirmDelete(item["id"]);
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppTheme.danger,
                                              size: 20,
                                            ),
                                            tooltip: "Hapus Absen",
                                            style: IconButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.dangerLight,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
