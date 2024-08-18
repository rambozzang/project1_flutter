import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

class PrivacyPolicyDialog extends StatefulWidget {
  @override
  _PrivacyPolicyDialogState createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  final AuthCntr authCntr = Get.find<AuthCntr>();
  RxBool allAgreed = false.obs;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('개인정보 처리방침 및 서비스 이용약관'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAllAgreeCheckbox(),
            const Divider(),
            _buildAgreementTile(
              '개인정보 처리방침 (필수)',
              '개인정보 처리방침 내용...',
              authCntr.privacyPolicyAgreed,
              (value) => _updateAgreement(authCntr.privacyPolicyAgreed, value),
            ),
            _buildAgreementTile(
              '서비스 이용약관 (필수)',
              '서비스 이용약관 내용...',
              authCntr.termsOfServiceAgreed,
              (value) => _updateAgreement(authCntr.termsOfServiceAgreed, value),
            ),
            _buildAgreementTile(
              '위치기반 서비스 이용 동의 (선택)',
              '위치기반 서비스 이용 동의 내용...',
              authCntr.locationServiceAgreed,
              (value) => _updateAgreement(authCntr.locationServiceAgreed, value),
            ),
          ],
        ),
      ),
      actions: [
        CustomButton(
          text: '동의 확인',
          type: 'L',
          isEnable: true,
          onPressed: () {
            if (authCntr.privacyPolicyAgreed.value && authCntr.termsOfServiceAgreed.value) {
              Get.back(result: true);
            } else {
              Utils.alert('필수 항목에 모두 동의해야 합니다.');
            }
          },
        ),
      ],
    );
  }

  Widget _buildAllAgreeCheckbox() {
    return Obx(() => CheckboxListTile(
          title: const Text('전체 동의', style: TextStyle(fontWeight: FontWeight.bold)),
          value: allAgreed.value,
          onChanged: (value) {
            allAgreed.value = value!;
            authCntr.privacyPolicyAgreed.value = value;
            authCntr.termsOfServiceAgreed.value = value;
            authCntr.marketingAgreed.value = value;
            authCntr.locationServiceAgreed.value = value;
          },
        ));
  }

  Widget _buildAgreementTile(String title, String content, RxBool agreed, Function(bool) onChanged) {
    return Obx(() => ExpansionTile(
          title: Row(
            children: [
              Checkbox(
                value: agreed.value,
                onChanged: (value) => onChanged(value!),
              ),
              Expanded(child: Text(title)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(content, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ));
  }

  void _updateAgreement(RxBool agreement, bool value) {
    agreement.value = value;
    _updateAllAgreed();
  }

  void _updateAllAgreed() {
    allAgreed.value = authCntr.privacyPolicyAgreed.value &&
        authCntr.termsOfServiceAgreed.value &&
        authCntr.marketingAgreed.value &&
        authCntr.locationServiceAgreed.value;
  }
}
