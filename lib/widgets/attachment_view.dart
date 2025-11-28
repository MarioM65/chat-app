import 'package:flutter/material.dart';
import 'package:app/models/attachment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AttachmentView extends StatelessWidget {
  final Attachment attachment;

  const AttachmentView({Key? key, required this.attachment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String baseUrl = dotenv.env['BASE_URL'] ?? '';
    final String fullPath = '$baseUrl/${attachment.caminhoArquivo}';

    Widget attachmentWidget;

    if (attachment.tipo.startsWith('image/')) {
      attachmentWidget = Image.network(
        fullPath,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey,
            child: Icon(Icons.broken_image, color: Colors.white),
          );
        },
      );
    } else if (attachment.tipo.startsWith('video/')) {
      // For video, we'll just show a placeholder with a play icon for now.
      // Full video playback requires a video_player package and more complex implementation.
      attachmentWidget = Container(
        width: 200,
        height: 200,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
            Text(attachment.nomeArquivo, style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    } else if (attachment.tipo.startsWith('audio/')) {
      // For audio, show an audio icon and filename
      attachmentWidget = Container(
        width: 200,
        height: 50,
        color: Colors.blueGrey,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.audiotrack, color: Colors.white),
            ),
            Expanded(
              child: Text(
                attachment.nomeArquivo,
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else {
      // For documents and other types
      attachmentWidget = Container(
        width: 200,
        height: 50,
        color: Colors.brown,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.insert_drive_file, color: Colors.white),
            ),
            Expanded(
              child: Text(
                attachment.nomeArquivo,
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: attachmentWidget,
    );
  }
}
