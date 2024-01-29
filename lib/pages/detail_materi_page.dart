import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mb_uns/pages/edit_materi_page.dart';
// import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:url_launcher/url_launcher.dart';

class MateriDetailPage extends StatefulWidget {
  final String id, judul, deskripsi, link, thumbnail;

  const MateriDetailPage({
    super.key,
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.link,
    required this.thumbnail,
  });

  @override
  State<MateriDetailPage> createState() => _MateriDetailPageState();
}

class _MateriDetailPageState extends State<MateriDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Materi')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('materi')
            .doc(widget.id)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan.'));
          } else {
            final materiData = snapshot.data!.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    materiData['judul'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    materiData['deskripsi'] ?? 'Keterangan belum ditambahkan',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Image.network(materiData['thumbnail'] ?? ''),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MateriEditPage(
                                id: widget.id,
                                judul: widget.judul,
                                deskripsi: widget.deskripsi,
                                link: widget.link,
                                thumbnail: widget.thumbnail,
                              ),
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showMateriDetails(materiData);
                        },
                        child: const Text('Link Download'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _deleteMateri(widget.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Hapus Materi'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteMateri(String id) {
    FirebaseFirestore.instance.collection('materi').doc(id).delete().then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      print('Error: $error');
    });
  }

  Future<void> _downloadMateri(String link) async {
    link = link.replaceAll('/view?usp=sharing', '/view?usp=direct');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Buka link di aplikasi browser?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog
                await _launchURL(link);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $uri');
    }
  }

  void _showMateriDetails(Map<String, dynamic> materiData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Link Download'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('${materiData['link']}')],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _downloadMateri(materiData['link'] ?? '');
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }
}
