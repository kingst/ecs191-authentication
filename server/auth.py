import uuid
from flask import Blueprint, request, jsonify, abort


auth_api = Blueprint('auth_api', __name__)


@sign_url_api.route('/v1/send_sms_code', methods=['POST'])
def send_sms_code():
    # Get request data
    pass


@sign_url_api.route('/v1/verify_code', methods=['POST'])
def verify_code():
    # Get request data
    pass


@sign_url_api.route('/v1/user', methods=['GET'])
def user():
    # Get request data
    pass
