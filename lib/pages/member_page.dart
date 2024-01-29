import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'package:intl/intl.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  List<Map<String, dynamic>> members = [];

  final CollectionReference membersCollection =
      FirebaseFirestore.instance.collection('members');
  Future<void> addMember(Map<String, dynamic> memberData) async {
    try {
      await membersCollection.add(memberData);
      print('Member added successfully');
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  Stream<QuerySnapshot> getMembersSortedByName() {
    return membersCollection.orderBy('Nama').snapshots();
  }

  Future<void> updateMember(
      String memberId, Map<String, dynamic> memberData) async {
    await membersCollection.doc(memberId).update(memberData);
  }

  Future<void> deleteMember(String memberId) async {
    await membersCollection.doc(memberId).delete();
  }

  Future<void> _confirmDeleteMember(String memberId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Member'),
          content: const Text('Are you sure you want to delete this member?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deleteMember(memberId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs(Map<String, dynamic> memberData) {
    String name = memberData['Nama'] ?? '';
    String section = memberData['Section'] ?? '';
    if (name.isEmpty || section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and NIM are required fields.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Anggota MB UNS'),
        actions: [
          ElevatedButton(
            onPressed: () async {},
            child: const Icon(Icons.file_open),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getMembersSortedByName(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> memberData =
                  document.data() as Map<String, dynamic>;
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: memberData['Foto'] != null &&
                                memberData['Foto'] != ''
                            ? CachedNetworkImageProvider(memberData['Foto'])
                            : null),
                    title: Text(memberData['Nama'] ?? 'No Name'),
                    subtitle: Text(memberData['Section'] ?? 'No Section'),
                    onTap: () {
                      _showMemberDetails(document);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _confirmDeleteMember(document.id);
                      },
                    ),
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addMemberDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String> _uploadImageToStorage(File imageFile, BuildContext context,
      Map<String, dynamic> memberData) async {
    try {
      String fileName = '${memberData['Nama']}_${memberData['Section']}';
      firebase_storage.Reference storageReference = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('members/$fileName');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading photo...'),
          duration: Duration(minutes: 1),
        ),
      );

      if (imageFile.path.startsWith('http') ||
          imageFile.path.startsWith('https')) {
        await storageReference.putFile(imageFile);
      } else {
        List<int> imageBytes = await imageFile.readAsBytes();
        Uint8List uint8List = Uint8List.fromList(imageBytes);

        var uploadTask = storageReference.putData(uint8List);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Uploading: ${(progress * 100).toStringAsFixed(2)}%'),
              duration: const Duration(milliseconds: 500),
            ),
          );
        });
        await uploadTask.whenComplete(() => print('Upload complete'));
      }

      String downloadURL = await storageReference.getDownloadURL();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      return downloadURL;
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return '';
    }
  }

  Future<void> _addMemberDialog() async {
    ImagePicker imagePicker = ImagePicker();
    String _capitalize(String s) {
      return s[0].toUpperCase() + s.substring(1);
    }

    Map<String, dynamic> newMemberData = {
      'Nama': '',
      'Section': '',
      'NIM': '',
      'Tempat Lahir': '',
      'Tanggal Lahir': '',
      'Alamat Rumah': '',
      'Nomor Telepon': '',
      'Foto': '',
    };

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Anggota Baru'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await imagePicker.pickImage(
                            source: ImageSource.camera);
                        if (pickedFile != null) {
                          File imageFile = File(pickedFile.path);
                          String imageUrl = await _uploadImageToStorage(
                              imageFile, context, newMemberData);
                          setState(() {
                            newMemberData['Foto'] = imageUrl;
                          });
                        }
                      },
                      child: const Text('Kamera'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await imagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (pickedFile != null) {
                          try {
                            File imageFile = File(pickedFile.path);
                            String imageUrl = await _uploadImageToStorage(
                                imageFile, context, newMemberData);
                            setState(() {
                              newMemberData['Foto'] = imageUrl;
                            });
                          } catch (e) {
                            print('Error uploading image: $e');
                          }
                        }
                      },
                      child: const Text('Galeri'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Enter URL'),
                              content: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'URL Gambar',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    newMemberData['Foto'] = value;
                                  });
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('URL'),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nama'),
                  onChanged: (value) {
                    newMemberData['Nama'] = _capitalize(value);
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Section'),
                  onChanged: (value) {
                    newMemberData['Section'] = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'NIM'),
                  onChanged: (value) {
                    newMemberData['NIM'] = value;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  onChanged: (value) {
                    newMemberData['Nomor Telepon'] = value;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Tanggal Lahir'),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            String formattedDate =
                                DateFormat('d MMMM yyyy').format(pickedDate);
                            setState(() {
                              newMemberData['Tanggal Lahir'] = formattedDate;
                            });
                          }
                        },
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                  onChanged: (value) {
                    newMemberData['Tempat Lahir'] = _capitalize(value);
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Alamat Rumah'),
                  onChanged: (value) {
                    newMemberData['Alamat Rumah'] = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (_validateInputs(newMemberData)) {
                  addMember(newMemberData);
                  setState(() {
                    members.add(newMemberData);
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMemberDetails(DocumentSnapshot document) async {
    Map<String, dynamic> memberData = document.data() as Map<String, dynamic>;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detail Anggota'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 200,
                    child:
                        memberData['Foto'] != null && memberData['Foto'] != ''
                            ? Image.network(
                                memberData['Foto']!,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object error, StackTrace? stackTrace) {
                                  return Image.network(
                                    'https://pbs.twimg.com/profile_images/780450299928424448/SeYDRjkZ_400x400.jpg',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.network(
                                'https://pbs.twimg.com/profile_images/780450299928424448/SeYDRjkZ_400x400.jpg',
                                fit: BoxFit.cover,
                              ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Center(
                  child: Column(
                    children: [
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'Nama',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['Nama']}'),
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'NIM',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['NIM']}'),
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'Section',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['Section']}'),
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'Tempat Lahir',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['Tempat Lahir']}'),
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'Tanggal Lahir',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['Tanggal Lahir']}'),
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'Alamat Rumah',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['Alamat Rumah']}'),
                      const Divider(
                        height: 5,
                      ),
                      const Text(
                        'Nomor Telepon',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${memberData['Nomor Telepon']}'),
                      const Divider(
                        height: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Edit'),
              onPressed: () {
                Navigator.of(context).pop();
                _editMemberDialog(document);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editMemberDialog(DocumentSnapshot memberSnapshot) async {
    String memberId = memberSnapshot.id;
    Map<String, dynamic> memberData =
        memberSnapshot.data() as Map<String, dynamic>;
    String Nama = memberData['Nama'] ?? '';
    String Section = memberData['Section'] ?? '';
    String NIM = memberData['NIM'] ?? '';
    String TempatLahir = memberData['Tempat Lahir'] ?? '';
    String TanggalLahir = memberData['Tanggal Lahir'] ?? '';
    String AlamatRumah = memberData['Alamat Rumah'] ?? '';
    String NomorTelepon = memberData['Nomor Telepon'] ?? '';
    String Foto = memberData['Foto'] ?? '';
    ImagePicker imagePicker = ImagePicker();
    File? imageFile0;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Anggota'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                imageFile0 != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(imageFile0!),
                      )
                    : CircleAvatar(
                        radius: 50,
                        backgroundImage: Foto != '' ? NetworkImage(Foto) : null,
                      ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await imagePicker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (pickedFile != null) {
                          File imageFile = File(pickedFile.path);
                          String imageUrl = await _uploadImageToStorage(
                              imageFile, context, memberData);
                          setState(() {
                            imageFile0 = imageFile;
                            memberData['Foto'] = imageUrl;
                          });
                        }
                      },
                      child: const Text('Kamera'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await imagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (pickedFile != null) {
                          try {
                            File imageFile = File(pickedFile.path);
                            String imageUrl = await _uploadImageToStorage(
                                imageFile, context, memberData);
                            setState(() {
                              imageFile0 = imageFile;
                              memberData['Foto'] = imageUrl;
                            });
                          } catch (e) {
                            print('Error uploading image: $e');
                          }
                        }
                      },
                      child: const Text('Galeri'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        String? newImageUrl = await _showUrlInputDialog(Foto);
                        if (newImageUrl != null) {
                          setState(() {
                            imageFile0 = null;
                            memberData['Foto'] = newImageUrl;
                          });
                        }
                      },
                      child: const Text('URL'),
                    ),
                  ],
                ),
                TextFormField(
                  initialValue: Nama,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  onChanged: (value) {
                    memberData['Nama'] = value;
                  },
                ),
                TextFormField(
                  initialValue: Section,
                  decoration: const InputDecoration(labelText: 'Section'),
                  onChanged: (value) {
                    memberData['Section'] = value;
                  },
                ),
                TextFormField(
                  initialValue: NIM,
                  decoration: const InputDecoration(labelText: 'NIM'),
                  onChanged: (value) {
                    memberData['NIM'] = value;
                  },
                ),
                TextFormField(
                  initialValue: TempatLahir,
                  decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                  onChanged: (value) {
                    memberData['Tempat Lahir'] = value;
                  },
                ),
                TextFormField(
                  initialValue: TanggalLahir,
                  decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
                  onChanged: (value) {
                    memberData['Tanggal Lahir'] = value;
                  },
                ),
                TextFormField(
                  initialValue: AlamatRumah,
                  decoration: const InputDecoration(labelText: 'Alamat Rumah'),
                  onChanged: (value) {
                    memberData['Alamat Rumah'] = value;
                  },
                ),
                TextFormField(
                  initialValue: NomorTelepon,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  onChanged: (value) {
                    memberData['Nomor Telepon'] = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () async {
                if (_validateInputs(memberData)) {
                  await updateMember(memberId, memberData);
                  int index = members
                      .indexWhere((element) => element['ID'] == memberId);
                  if (index != -1) {
                    setState(() {
                      members[index] = memberData;
                    });
                  }
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showUrlInputDialog(String initialValue) async {
    String? newUrl;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input URL Gambar'),
          content: TextFormField(
            initialValue: initialValue,
            onChanged: (value) {
              newUrl = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return newUrl;
  }
}
