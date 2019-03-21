# To run Flask app locally:
# >>> export FLASK_APP=server.py
# >>> flask run

# Currently deployed to Heroku
# To set Heroku S3 env credientials:

from flask import Flask, request, send_file
import asyncio
import aiohttp
import base64
import requests
import json
import time
import io
import glob
import os
from io import BytesIO
from PIL import Image
import binascii
from tempfile import NamedTemporaryFile
from shutil import copyfileobj
from os import remove
from operator import itemgetter

import boto3  # S3
import uuid


FPP_API = 'xxx'
API_KEY = 'xxx'                        # FREE API
API_SECRET = 'xxx'                     # FREE API
FRAME_WIDTH = 250

GIF_BUCKET_NAME = 'gifme'

loop = asyncio.get_event_loop()

app = Flask(__name__, static_url_path='/static/')

# replace keys with env variables
s3_resource = boto3.resource(
	's3',
	aws_access_key_id='xxx',
	aws_secret_access_key='xxx'
)

s3_client = boto3.client(
	's3',
	aws_access_key_id='xxx',
	aws_secret_access_key='xxx'
)

BUCKET_LOCATION = s3_client.get_bucket_location(Bucket='gifme')


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MARK : Amazon S3


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# MARK : Image Processing

async def segment(url, frame64, index):
	done = False
	data = {
		'api_key': API_KEY,
		'api_secret': API_SECRET,
		'image_base64': frame64
	}

	session = aiohttp.ClientSession()

	while not done:
		print('Sending Face++ request...')
		response = await session.post(url, data=data)
		print('Response: ', response.status)
		if response.status == 200:
			done = True

	session.close()
	return await response.text(), index

def resize64(image64, target_width=100):
	pil_image = Image.open(io.BytesIO(base64.b64decode(image64)))
	wpercent = (target_width / float(pil_image.size[0]))
	hsize = int((float(pil_image.size[1]) * float(wpercent)))
	img = pil_image.resize((target_width, hsize), Image.ANTIALIAS)

	buffered = BytesIO()
	img.save(buffered, format='PNG')
	img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')
	return img_str


def resize(pil_image, target_width=100):
	wpercent = (target_width / float(pil_image.size[0]))
	hsize = int((float(pil_image.size[1]) * float(wpercent)))
	img_resized = pil_image.resize((target_width, hsize), Image.ANTIALIAS)
	return img_resized


def makegif(frames):
	output = []

	for frame in frames:
		alpha = frame.getchannel('A')
		frame = frame.convert('P', palette=Image.ADAPTIVE, colors=256)
		mask = Image.eval(alpha, lambda a: 255 if a <=128 else 0)
		frame.paste(0, mask)
		output.append(frame)

	buffer = BytesIO()
	output[0].save(buffer, format='gif', save_all=True, append_images=output[1:], duration=120, loop=0, transparency=0, disposal=2)
	
	# OPTIONAL - SAVE GIF
	gif_id = binascii.b2a_hex(os.urandom(10)).decode('utf-8')
	output[0].save(gif_id + '.gif', format='gif', save_all=True, append_images=output[1:], duration=120, loop=0, transparency=0, disposal=2)

	return {'gif_id': gif_id, 'gif_data': buffer}


@app.route('/api/gifify', methods=['POST'])
def gifify():
	frames = []
	frames64 = json.loads(request.data.decode('utf-8'))['img_data']
	tasks = [segment(FPP_API, resize64(frame64, target_width=FRAME_WIDTH), index) for index, frame64 in enumerate(frames64)]

	results = loop.run_until_complete(asyncio.wait(tasks))

	cleaned_results = []
	for result in results[0]:
		cleaned_results.append(result.result())  # extracts just the (data,index) tuple

	sorted_results = sorted(cleaned_results, key=itemgetter(1))

	response_data, _ = zip(*sorted_results)

	for response_datum in response_data:
		frames.append(Image.open(io.BytesIO(base64.b64decode(json.loads(response_datum)["body_image"]))))

	response_data = None
	sorted_results = None
	frames64 = None
	# for result in results[0]:
	# 	frames.append(Image.open(io.BytesIO(base64.b64decode(json.loads(result.result())["body_image"]))))

	gif = makegif(frames)

	target_filename = gif['gif_id'] + '.gif'

	temp_file = NamedTemporaryFile(mode='w+b',suffix='gif')	
	pilImage = open(target_filename, 'rb')
	copyfileobj(pilImage, temp_file)
	pilImage.close()
	temp_file.seek(0,0)

	print(target_filename)
	
	s3_resource.Object(GIF_BUCKET_NAME, target_filename).put(Body=temp_file, ACL='public-read')

	object_url = "https://s3.{0}.amazonaws.com/{1}/{2}".format(
		BUCKET_LOCATION['LocationConstraint'],
		GIF_BUCKET_NAME,
		target_filename
	)

	# object_url = "https://s3.us-east-2.amazonaws.com/gifme/c165de49d713c4061760.gif"

	# temp_file.seek(0,0)

	print('Public GIF Url: ', object_url)

	response = app.response_class(
        response = json.dumps({
        	'gif_url' : object_url
        }),
        mimetype = 'application/json'
    )

	return response
	# return send_file(temp_file, as_attachment=True, attachment_filename=object_url)


@app.route('/', methods=['GET'])
def gif():

	return app.response_class(
		response='Welcome to the GIFME API!',
		mimetype='text',
		status=200
	)

if __name__ == '__main__':
	app.run(debug=False)