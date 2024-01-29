import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mb_uns/pages/detail_materi_page.dart';
import 'package:mb_uns/pages/edit_materi_page.dart';

class Materi {
  late String id, judul, deskripsi, link, thumbnail;

  Materi({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.link,
    required this.thumbnail,
  });

  factory Materi.fromMap(Map<String, dynamic> map) {
    return Materi(
      id: map['id'] ?? '',
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      link: map['link'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
    );
  }
}

class MateriPage extends StatefulWidget {
  const MateriPage({super.key});

  @override
  State<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  Future<void> hapusMateri(String materiId) async {
    try {
      if (materiId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('materi')
            .doc(materiId)
            .delete();
      } else {
        print('Error deleting materi: materiId is empty or null');
      }
    } catch (e) {
      print('Error deleting materi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Materi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('materi').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final materiDocs = snapshot.data!.docs;
            return ListView.separated(
              itemCount: materiDocs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final Materi materi = Materi.fromMap(
                  materiDocs[index].data() as Map<String, dynamic>,
                );
                return ListTile(
                  title: Text(materi.judul),
                  subtitle: Text(materi.deskripsi),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  leading: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: materi.thumbnail.isNotEmpty
                          ? Image.network(materi.thumbnail, fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  trailing: SizedBox(
                    width: 35.0,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Konfirmasi Hapus'),
                              content: const Text(
                                  'Apakah Anda yakin ingin menghapus materi ini?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (materi.id.isNotEmpty) {
                                      hapusMateri(materi.id);
                                    } else {
                                      print(
                                          'Error deleting materi: materiId is empty or null');
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Hapus'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  onTap: () {
                    if (materi.id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MateriDetailPage(
                            id: materi.id,
                            judul: materi.judul,
                            deskripsi: materi.deskripsi,
                            link: materi.link,
                            thumbnail: materi.thumbnail,
                            key: null,
                          ),
                        ),
                      );
                    } else {
                      print('Error: Materi ID is empty or null');
                    }
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MateriEditPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
