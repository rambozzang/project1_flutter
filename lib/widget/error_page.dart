// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:project1/widget/custom_button.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({Key? key, required this.errorMessage, this.onRetryPressed}) : super(key: key);

  final String errorMessage;
  final Function()? onRetryPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const SizedBox(height: 28),
            // SvgPicture.asset('assets/mypage/empty_500_error_60_px.svg', width: 45, height: 45, fit: BoxFit.scaleDown),
            const Text(
              '다시 한번 확인해주세요!',
              textAlign: TextAlign.center,
              //  style: MTextStyles.bold16Grey06,
            ),
            const SizedBox(height: 8),
            const Text(
              '지금 서버와 연결이 원활하지 않습니다.\n문제를 해결하기 위해 열심히 노력하고 있습니다.\n잠시 후 다시 확인해주세요.',
              textAlign: TextAlign.center,
              //    style: MTextStyles.regular14WarmGrey,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 28),
            // TextButton(
            //   // color: Colors.red,
            //   // shape: RoundedRectangleBorder(
            //   //   borderRadius: BorderRadius.circular(29.0),
            //   // ),
            //   child: const Text(
            //     '홈화면으로 이동',
            //     style: TextStyle(
            //       color: Colors.white,
            //     ),
            //   ),
            //   onPressed: () {},
            // ),
            // ignore: unnecessary_null_comparison
            if (onRetryPressed != null)
              CustomButton(
                text: '새로고침',
                type: 'XS',
                isEnable: true,
                onPressed: onRetryPressed,
              )
            else
              const SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}

class ErrorNotFound extends StatelessWidget {
  const ErrorNotFound({
    Key? key,
    required this.errorMessage,
  }) : super(key: key);

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 28),
          //  SvgPicture.asset('assets/mypage/empty_400_error_60_px.svg',
          //      width: 45, height: 45, fit: BoxFit.scaleDown, color: Colors.deepOrange),
          const Text(
            '잠시 후 다시 확인해주세요!',
            textAlign: TextAlign.center,
            // style: MTextStyles.bold16Grey06,
          ),
          const SizedBox(height: 8),
          const Text(
            '요청하신 페이지가 사라졌거나,\n다른 페이지로 변경되었습니다.\n인기 있는 모임은 서두르셔야 신청할 수 있답니다!',
            textAlign: TextAlign.center,
            //style: MTextStyles.regular14WarmGrey,
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            // color: Colors.red,
            // shape: RoundedRectangleBorder(
            //   borderRadius: BorderRadius.circular(29.0),
            // ),
            child: const Text(
              '라운지로 이동',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () => Navigator.of(context).pushNamed('LoungePage'),
          ),
        ],
      ),
    );
  }
}
