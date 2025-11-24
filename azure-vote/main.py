from flask import Flask, request, render_template
import os
import redis
import socket
import sys
import logging
from datetime import datetime

# Setup basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Load configurations from environment or config file
app.config.from_pyfile('config_file.cfg')

if ("VOTE1VALUE" in os.environ and os.environ['VOTE1VALUE']):
    button1 = os.environ['VOTE1VALUE']
else:
    button1 = app.config['VOTE1VALUE']

if ("VOTE2VALUE" in os.environ and os.environ['VOTE2VALUE']):
    button2 = os.environ['VOTE2VALUE']
else:
    button2 = app.config['VOTE2VALUE']

if ("TITLE" in os.environ and os.environ['TITLE']):
    title = os.environ['TITLE']
else:
    title = app.config['TITLE']

# Redis Connection - check for REDIS environment variable (Docker) or use localhost
redis_host = os.environ.get('REDIS', 'localhost')
redis_port = int(os.environ.get('REDIS_PORT', 6379))

try:
    r = redis.Redis(
        host=redis_host,
        port=redis_port,
        db=0,
        socket_connect_timeout=5,
        decode_responses=True  # Automatically decode responses to strings
    )
    # Test connection
    r.ping()
    logger.info(f"Connected to Redis at {redis_host}:{redis_port}")
except redis.ConnectionError as e:
    logger.error(f"Failed to connect to Redis at {redis_host}:{redis_port}: {e}")
    sys.exit(1)

# Change title to host name to demo NLB
if app.config['SHOWHOST'] == "true":
    title = socket.gethostname()

# Init Redis
if not r.get(button1): r.set(button1,0)
if not r.get(button2): r.set(button2,0)

@app.route('/', methods=['GET', 'POST'])
def index():

    if request.method == 'GET':

        # Get current values
        vote1 = r.get(button1)
        vote2 = r.get(button2)
        
        logger.info(f"Current votes - {button1}: {vote1}, {button2}: {vote2}")

        # Return index with values
        return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title)

    elif request.method == 'POST':

        if request.form['vote'] == 'reset':

            # Empty table and return results
            r.set(button1, 0)
            r.set(button2, 0)
            vote1 = r.get(button1)
            vote2 = r.get(button2)
            
            logger.info(f"Votes reset - {button1}: {vote1}, {button2}: {vote2}")

            return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title)

        else:

            # Insert vote result into DB
            vote = request.form['vote']
            r.incr(vote, 1)
            
            # Get current values
            vote1 = r.get(button1)
            vote2 = r.get(button2)
            
            logger.info(f"Vote recorded for {vote} - Current: {button1}: {vote1}, {button2}: {vote2}")

            # Return results
            return render_template("index.html", value1=int(vote1), value2=int(vote2), button1=button1, button2=button2, title=title)

if __name__ == "__main__":
    # For local development only
    app.run(host='0.0.0.0', port=80, debug=True)
