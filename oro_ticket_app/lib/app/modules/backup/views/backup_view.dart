import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oro_ticket_app/core/constants/colors.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';
import 'package:oro_ticket_app/widgets/app_scafold.dart';

import '../controllers/backup_controller.dart';

class BackupView extends StatelessWidget {
  final BackupController controller = Get.put(BackupController());

  BackupView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.04;
    final paddingVertical = size.height * 0.02;

    return AppScaffold(
      title: 'Data Backup',
      userName: 'Employee Name',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(paddingHorizontal),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.backup, color: AppColors.primary, size: 32),
                  SizedBox(width: paddingHorizontal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Data Backup',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Export and share your unsynced trip and service charge data',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: paddingVertical * 2),

            // Data Summary Card
            Obx(() {
              final hasData = controller.hasUnsyncedData.value;
              final counts = controller.unsyncedCounts;

              return Container(
                padding: EdgeInsets.all(paddingHorizontal),
                decoration: BoxDecoration(
                  color: hasData ? AppColors.success.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasData ? AppColors.success : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasData ? Icons.check_circle : Icons.info_outline,
                          color: hasData ? AppColors.success : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          hasData ? 'Data Available' : 'No Data',
                          style: AppTextStyles.subtitle1,
                        ),
                      ],
                    ),
                    SizedBox(height: paddingVertical),
                    Text(
                      controller.getDataSummaryText(),
                      style: AppTextStyles.body2,
                    ),
                    if (hasData) ...[
                      SizedBox(height: paddingVertical),
                      Row(
                        children: [
                          _buildDataChip('Trips', counts['trips'] ?? 0),
                          SizedBox(width: 8),
                          _buildDataChip('Service Charges', counts['serviceCharges'] ?? 0),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),

            SizedBox(height: paddingVertical * 2),

            // Action Buttons
            Obx(() {
              final isLoading = controller.isLoading.value;
              final hasData = controller.hasUnsyncedData.value;

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading || !hasData
                          ? null
                          : controller.exportAndShareBackup,
                      icon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.share),
                      label: Text(
                        isLoading
                            ? 'Creating Backup...'
                            : 'Export & Share Backup',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: paddingVertical * 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyles.button,
                      ),
                    ),
                  ),

                  SizedBox(height: paddingVertical),

                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.loadUnsyncedDataCounts,
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh Data Count'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: paddingVertical * 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: AppTextStyles.button,
                      ),
                    ),
                  ),
                ],
              );
            }),

            SizedBox(height: paddingVertical * 2),

            // Information Section
            Container(
              padding: EdgeInsets.all(paddingHorizontal),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                      SizedBox(width: 8),
                      Text(
                        'About Data Backup',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: paddingVertical),
                  Text(
                    '• Backup includes all unsynced trips and service charges\n'
                    '• Data is exported as JSON and can be shared via email, messaging apps, etc.\n'
                    '• Use this feature to transfer data between devices or keep offline backups\n'
                    '• Exported data does not include synced records (already on server)',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.blue[800],
                      height: 1.5,
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

  Widget _buildDataChip(String label, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}