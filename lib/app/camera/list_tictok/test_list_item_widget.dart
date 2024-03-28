import 'package:flutter/material.dart';

class ListItemWidget extends StatelessWidget {
  const ListItemWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F0F0F),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 12, bottom: 0, left: 10, right: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 5, right: 10),
                child: ClipOval(
                  child: Image.network(
                    "https://yt3.ggpht.com/yti/AJo0G0kUnHqoybmWPJG4GNm0G-lfCiCPbEP62v5tq9PZsA=s48-c-k-c0x00ffffff-no-rj",
                    width: 25,
                    height: 25,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Andrea Quintanilla * 3 tháng trước',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFFAEAEAE)),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        'Que buen trabajo, que buenos enganches, genial!!!!  MTV la tenes adentro, jajaja. Saludos cordiales desde Buenos Aires, Argentina, Argentina, Argentina!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFF6F6F6)),
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Icon(
                            Icons.thumb_down_alt_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.comment_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
