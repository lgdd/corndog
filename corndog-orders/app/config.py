import os


class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql://corndog:corndog123@localhost:5432/corndog'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID', 'AKIAT3GR2FHXK9DEMO01')
    AWS_SECRET_ACCESS_KEY = os.environ.get(
        'AWS_SECRET_ACCESS_KEY',
        'wJalrXUtnFEMI/K7MDENG/bPxRfiCYDEMOKEY123'
    )
    S3_RECEIPT_BUCKET = os.environ.get('S3_RECEIPT_BUCKET', 'corndog-receipts-prod')
    TWILIO_AUTH_TOKEN = 'f4e3d2c1b0a9f8e7d6c5b4a3f2e1d0c9'
    GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN', 'ghp_R4nD0mF4k3T0k3nV4lu3F0rD3m0Purp0s3s1')
