import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mb_uns/pages/detail_materi_page.dart';

class MateriEditPage extends StatefulWidget {
  final String? id, judul, deskripsi, link, thumbnail;

  const MateriEditPage({
    super.key,
    this.id,
    this.judul,
    this.deskripsi,
    this.link,
    this.thumbnail,
  });

  @override
  State<MateriEditPage> createState() => _MateriEditPageState();
}

class _MateriEditPageState extends State<MateriEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  String? _thumbnailUrl;

  // Future<void> _uploadImage() async {
  //   final imagePicker = ImagePicker();
  //   final pickedImage =
  //       await imagePicker.pickImage(source: ImageSource.gallery);

  //   if (pickedImage != null) {
  //     File imageFile = File(pickedImage.path);
  //     firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
  //         .ref()
  //         .child('materi_thumbnails/${pickedImage.name}');

  //     await ref.putFile(imageFile);
  //     final url = await ref.getDownloadURL();

  //     setState(() {
  //       _thumbnailUrl = url;
  //     });
  //   }
  // }
  Future<void> _uploadImage() async {
    final imagePicker = ImagePicker();
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Row(
            children: [
              const SizedBox(
                width: 15,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
                child: const Icon(
                  Icons.image_search,
                  size: 60,
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, ImageSource.camera);
                },
                child: const Icon(
                  Icons.camera_enhance_rounded,
                  size: 60,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (imageSource == null) {
      return; // User canceled
    }

    final pickedImage = await imagePicker.pickImage(source: imageSource);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('materi_thumbnails/${pickedImage.name}');

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      setState(() {
        _thumbnailUrl = url;
      });
    }
  }

  Future<void> _saveMateri() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    // Create a new document reference without specifying the ID
    CollectionReference materiCollection =
        FirebaseFirestore.instance.collection('materi');

    // DocumentReference documentRef = materiCollection.doc();

    DocumentReference documentRef;

    if (widget.id != null) {
      // If editing an existing materi, use the provided ID
      documentRef = materiCollection.doc(widget.id);
    } else {
      // If creating a new materi, Firestore will generate a new ID
      documentRef = materiCollection.doc();
    }

    print('Materi ID: ${documentRef.id}');
    final materiData = {
      'id': documentRef.id, // Include the ID in the data
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'link': _linkController.text,
      'thumbnail': _thumbnailUrl ?? widget.thumbnail,
    };

    await documentRef.set(materiData);
    Navigator.pop(context);
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => MateriDetailPage(
    //       id: documentRef.id, // Pass the generated ID
    //       judul: _judulController.text,
    //       deskripsi: _deskripsiController.text,
    //       link: _linkController.text,
    //       thumbnail: _thumbnailUrl ?? widget.thumbnail ?? '', key: null,
    //     ),
    //   ),
    // );
  }

  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      _judulController.text = widget.judul!;
      _deskripsiController.text = widget.deskripsi!;
      _linkController.text = widget.link!;
      _thumbnailUrl = widget.thumbnail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id != null ? 'Edit Materi' : 'Tambah Materi'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Materi',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul materi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _deskripsiController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Materi',
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link Materi',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: _uploadImage,
                      child: const Text('Upload Thumbnail'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _thumbnailUrl == null
                          ? const Icon(Icons.image)
                          : Image.network(_thumbnailUrl!),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveMateri,
                  child: Text(
                      widget.id != null ? 'Simpan Perubahan' : 'Tambah Materi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
