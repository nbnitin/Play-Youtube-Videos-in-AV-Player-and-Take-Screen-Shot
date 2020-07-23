# Play-Youtube-Videos-in-AV-Player-and-Take-Screen-Shot, How you tube extractor or downloader works

1. Hit the url with video id
https://www.youtube.com/get_video_info?video_id=YOUR_ID.
2. You will get this file or info in server (attached).
3. Now from info look for key "player_response" and get the value form this key.
4. Convert player_response value in data(with utf8) and after this convert it into json.
5. In new converted json look for streaming data.
6. Get format json for video's url from streaming data json.
7. Now extract key url from formats json, there will be lots of url with different quality either pick all and keep against the quality else pick one, you can save it into db and can return into json response of server.

