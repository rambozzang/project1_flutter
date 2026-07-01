import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/utils/utils.dart';

/// 모임 생성. (Spot 연결은 P4, 대표사진 업로드는 이후 확장)
class CommunityCreatePage extends StatefulWidget {
  const CommunityCreatePage({super.key});

  @override
  State<CommunityCreatePage> createState() => _CommunityCreatePageState();
}

class _CommunityCreatePageState extends State<CommunityCreatePage> {
  final CommunityRepo _repo = CommunityRepo();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  bool _isPublic = true;
  String _joinType = 'AUTO';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Utils.alert('모임 이름을 입력해주세요.');
      return;
    }
    setState(() => _saving = true);
    final (ok, msg, _) = await _repo.create(
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isPublic: _isPublic ? 'Y' : 'N',
      joinType: _joinType,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Utils.alert(msg.isEmpty ? (ok ? '모임이 생성되었습니다.' : '생성에 실패했습니다.') : msg);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('모임 만들기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _label('모임 이름'),
          const SizedBox(height: 6),
          _input(_nameCtrl, '예: 노을 사진 모임', maxLength: 30),
          const SizedBox(height: 20),
          _label('소개'),
          const SizedBox(height: 6),
          _input(_descCtrl, '어떤 모임인지 소개해주세요.', maxLines: 4, maxLength: 200),
          const SizedBox(height: 20),
          _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPublic,
              activeColor: const Color(0xFF3B6FE0),
              title: Text(_isPublic ? '공개 모임' : '비공개 모임', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              subtitle: Text(
                _isPublic ? '누구나 검색·가입하고 게시물을 볼 수 있어요.' : '멤버만 게시물을 볼 수 있어요.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A8291)),
              ),
              onChanged: (v) => setState(() => _isPublic = v),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가입 방식', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _joinChip('바로 가입', 'AUTO'),
                    const SizedBox(width: 8),
                    _joinChip('승인 후 가입', 'APPROVAL'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B6FE0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('모임 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14));

  Widget _input(TextEditingController c, String hint, {int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E8EF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E8EF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B6FE0), width: 1.5)),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6E8EF))),
      child: child,
    );
  }

  Widget _joinChip(String label, String value) {
    final selected = _joinType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _joinType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B6FE0) : const Color(0xFFF1F3F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF3B6FE0) : const Color(0xFFE6E8EF)),
          ),
          child: Text(label,
              style: TextStyle(color: selected ? Colors.white : const Color(0xFF7A8291), fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}
