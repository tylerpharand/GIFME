# GIFME
Companion app for Snapchat. Create animated GIFs of yourself and build up a collection.
Video Demo: https://tylerpharand.github.io/gifme/gifme_demo.mp4

# iOS Application
The iOS application was written in Swift. It contains two main screens: Camera View, and Sticker Collection.

In the Camera View, the shutter button can be held down to record up to 5 seconds of frames which are stiched into a GIF. Each GIF has its background removed using a deep learning API (Face++) for segmentation.

The Sticker Collection contains the user's GIFs ("Stickers"). From this view, users can hand off any of their GIFs into Snapchat via the Snapkit SDK. GIFs can also be saved to the user's Camera Roll.

![](GIFME_Demo.gif)

# API
The back end is a Flask API which is deployed to Heroku.

The API works as follows:
- POST request is recieved from the client, containing an array of Base64 encoded images.
- The background of each from is removed, leaving just the humans. This is achieved using Face++.
- The resulting frames are then downsampled, and converted into an animated GIF format.
- The GIF is stored on AWS S3 and a url with a unique identifier is generated.
- The URL to the GIF is returned to the client.
