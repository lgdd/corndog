import os


class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL", "postgresql://corndog:corndog123@corndog-db:5432/corndog"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
