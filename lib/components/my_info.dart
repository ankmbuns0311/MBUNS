import 'package:flutter/material.dart';
import 'package:mb_uns/components/style.dart';

class MyInfo extends StatelessWidget {
  final String infoTitle;
  final String infoSubtitle;
  final String infoImage;
  final VoidCallback? onTap;
  final bool isGallery;

  const MyInfo({
    super.key,
    required this.infoTitle,
    required this.infoSubtitle,
    this.onTap,
    this.isGallery = false,
    required this.infoImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: MyColor.nb,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  infoTitle,
                  style: const TextStyle(
                    color: MyColor.lb,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildImage(),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: Text(
                  isGallery ? 'Gallery' : 'Unknown',
                  style: const TextStyle(
                    color: MyColor.y,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              side: BorderSide(color: Colors.red)))),
                  onPressed: onTap,
                  child: Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (infoImage.startsWith('http')) {
      return Image.network(
        infoImage,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        infoImage,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
      );
    }
  }
}
