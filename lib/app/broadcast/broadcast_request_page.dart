import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/broadcast/broadcast_repo.dart';
import 'package:project1/utils/utils.dart';

class BroadcastRequestPage extends StatefulWidget {
  final int contentId;
  final String location;
  final double licenseFee;

  const BroadcastRequestPage({
    super.key,
    required this.contentId,
    required this.location,
    required this.licenseFee,
  });

  @override
  State<BroadcastRequestPage> createState() => _BroadcastRequestPageState();
}

class _BroadcastRequestPageState extends State<BroadcastRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = BroadcastRepo();

  final _broadcasterCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _broadcasterCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _purposeCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('방송 라이선스 신청'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 콘텐츠 정보
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 ${widget.location}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '라이선스 비용: ₩${widget.licenseFee.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _field('방송사명', '예: KBS, MBC', _broadcasterCtrl, required: true),
              _field('담당자 이메일', 'email@broadcaster.com', _emailCtrl,
                  required: true),
              _field('담당자 이름', '홍길동', _nameCtrl),
              _field('사용 목적', '예: 뉴스 날씨 코너 배경화면', _purposeCtrl, maxLines: 3),
              _field('사용 기간', '예: 2026-07-01 ~ 2026-07-31', _periodCtrl),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '라이선스 신청하기',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label을 입력해주세요' : null
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await _repo.requestLicense(
        contentId: widget.contentId,
        broadcasterNm: _broadcasterCtrl.text,
        contactEmail: _emailCtrl.text,
        contactNm: _nameCtrl.text,
        purpose: _purposeCtrl.text,
        usagePeriod: _periodCtrl.text,
      );
      if (res.code == '00') {
        Utils.alert('라이선스 신청이 완료됐습니다. 검토 후 이메일로 안내드립니다.');
        Get.back();
      } else {
        Utils.alert(res.msg ?? '신청 중 오류가 발생했습니다.');
      }
    } catch (e) {
      Utils.alert('신청 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
