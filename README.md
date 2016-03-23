# VisageLog
Take a picture and let the cloud analyze your mood.

## Common Usage

Users can: 

- Take a picture with their phone or upload one from their library.
- Let Google's Cloud Vision API analyze the image and search for faces. 
- See what the API thinks of the face's representation of sorrow, anger, surprise or joy.
- Share the resulting analysis on social media.
- Save the photo and analysis and see their various visages in a collection view.
- Add a note to the analysis.
- Delete the analysis if the user so chooses.

## Installation
Install Xcode able to run iOS 9.2 and up. Clone or download the repository from GitHub. Add a valid Google Cloud Vision API key from [here](https://cloud.google.com/vision/) in the CloudVisionClient.swift file. Run with deployment target of 9.2 and run on the simulator or device.

##License

The MIT License (MIT)

Copyright (c) 2016 Matthew Waller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
