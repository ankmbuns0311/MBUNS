import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showErrorSnackbar('Could not launch URL: $url');
      }
    } on PlatformException catch (e) {
      print('Platform Exception: $e');
      _showErrorSnackbar('Error launching URL: $e');
    } catch (e) {
      print('Error: $e');
      _showErrorSnackbar('Error launching URL: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> _uploadImageToStorage(
    File imageFile,
    BuildContext context,
  ) async {
    try {
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('gallery_images/${DateTime.now()}.png');
      await storageReference.putFile(imageFile);
      String imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Gallery Page'),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: _firestore
              .collection('gallery')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const CircularProgressIndicator();
            }
            var docs = snapshot.data!.docs;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: docs.map((doc) {
                    DateTime date;
                    if (doc['date'] is String) {
                      date = DateTime.parse(doc['date']);
                    } else if (doc['date'] is Timestamp) {
                      date = (doc['date'] as Timestamp).toDate();
                    } else {
                      date = DateTime.now();
                    }
                    return GestureDetector(
                      onTap: () async {
                        if (doc['link'] != null && doc['link'].isNotEmpty) {
                          String url = doc['link'];

                          try {
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              _showErrorSnackbar('Could not launch URL: $url');
                            }
                          } on PlatformException catch (e) {
                            print('Platform Exception: $e');
                            _showErrorSnackbar('Error launching URL: $e');
                          } catch (e) {
                            print('Error: $e');
                            _showErrorSnackbar('Error launching URL: $e');
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link not available'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        _showEditDeleteDialog(doc);
                      },
                      child: Container(
                        width: 350,
                        height: 150,
                        margin: EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                          image: DecorationImage(
                            image:
                                CachedNetworkImageProvider(doc['thumbnailUrl']),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.2),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                const Color.fromARGB(255, 255, 255, 255)
                                    .withOpacity(0.2),
                                BlendMode.dstATop,
                              ),
                              child: Image.network(
                                doc['thumbnailUrl'],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    doc['title'],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "${doc['location']} - ${DateFormat('d MMMM yyyy').format(date)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDeleteDialog(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit or Delete Item'),
          content: const Text('Choose an action:'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditDialog(doc);
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteDialog(doc);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    String title = "";
    String date = "";
    String location = "";
    String link = "";
    String thumbnailUrl = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      date = pickedDate.toLocal().toString();
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (value) {
                    location = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Link'),
                  onChanged: (value) {
                    link = value;
                  },
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                        );
                        if (pickedFile != null) {
                          File imageFile = File(pickedFile.path);
                          String imageUrl = await _uploadImageToStorage(
                            imageFile,
                            context,
                          );
                          setState(() {
                            thumbnailUrl = imageUrl;
                          });
                        }
                      },
                      child: const Text('Camera'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          File imageFile = File(pickedFile.path);
                          String imageUrl = await _uploadImageToStorage(
                            imageFile,
                            context,
                          );
                          setState(() {
                            thumbnailUrl = imageUrl;
                          });
                        }
                      },
                      child: const Text('Gallery'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            String url = "";
                            return AlertDialog(
                              title: const Text('Enter URL'),
                              content: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'URL Thumbnail',
                                ),
                                onChanged: (value) {
                                  url = value;
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
                                    setState(() {
                                      thumbnailUrl = url;
                                    });
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_validateForm(title, date, location, thumbnailUrl)) {
                  _addItem(title, date, location, link, thumbnailUrl);
                  Navigator.of(context).pop();
                } else {
                  _showErrorSnackbar("Please fill all required fields");
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  bool _validateForm(
      String title, String date, String location, String thumbnailUrl) {
    return title.isNotEmpty &&
        date.isNotEmpty &&
        location.isNotEmpty &&
        thumbnailUrl.isNotEmpty;
  }

  void _addItem(String title, String? date, String location, String link,
      String thumbnailUrl) {
    String defaultImageUrl =
        'https://pbs.twimg.com/profile_images/780450299928424448/SeYDRjkZ_400x400.jpg';
    String finalThumbnailUrl =
        thumbnailUrl.isNotEmpty ? thumbnailUrl : defaultImageUrl;
    DateTime currentDate = DateTime.now();
    String formattedDate = date ?? currentDate.toLocal().toString();

    _firestore.collection('gallery').add({
      'title': title,
      'date': formattedDate,
      'location': location,
      'link': link,
      'thumbnailUrl': finalThumbnailUrl,
    });
  }

  void _showDeleteDialog(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteItem(doc);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(DocumentSnapshot doc) {
    _firestore.collection('gallery').doc(doc.id).delete();
  }

  void _showEditDialog(DocumentSnapshot doc) {
    String title = doc['title'] ?? "";
    String date = doc['date'] is Timestamp
        ? (doc['date'] as Timestamp).toDate().toString()
        : doc['date'] ?? "";
    String location = doc['location'] ?? "";
    String link = doc['link'] ?? "";
    String thumbnailUrl = doc['thumbnailUrl'] ?? "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                TextFormField(
                  initialValue: date,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      date = pickedDate.toLocal().toString();
                    }
                  },
                ),
                TextFormField(
                  initialValue: location,
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (value) {
                    location = value;
                  },
                ),
                TextFormField(
                  initialValue: link,
                  decoration: const InputDecoration(labelText: 'Link'),
                  onChanged: (value) {
                    link = value;
                  },
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                        );
                        if (pickedFile != null) {
                          File imageFile = File(pickedFile.path);
                          String imageUrl = await _uploadImageToStorage(
                            imageFile,
                            context,
                          );
                          setState(() {
                            thumbnailUrl = imageUrl;
                          });
                        }
                      },
                      child: const Text('Camera'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          File imageFile = File(pickedFile.path);
                          String imageUrl = await _uploadImageToStorage(
                            imageFile,
                            context,
                          );
                          setState(() {
                            thumbnailUrl = imageUrl;
                          });
                        }
                      },
                      child: const Text('Gallery'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            String url = "";

                            return AlertDialog(
                              title: const Text('Enter URL'),
                              content: TextFormField(
                                initialValue: thumbnailUrl,
                                decoration: const InputDecoration(
                                  labelText: 'URL Thumbnail',
                                ),
                                onChanged: (value) {
                                  url = value;
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
                                    setState(() {
                                      thumbnailUrl = url;
                                    });
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editItem(doc, title, date, location, link, thumbnailUrl);
                Navigator.of(context).pop();
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  void _editItem(
    DocumentSnapshot doc,
    String title,
    String date,
    String location,
    String link,
    String thumbnailUrl,
  ) {
    _firestore.collection('gallery').doc(doc.id).update({
      'title': title,
      'date': date,
      'location': location,
      'link': link,
      'thumbnailUrl': thumbnailUrl,
    });
  }
}
