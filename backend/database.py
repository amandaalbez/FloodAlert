import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql+pymysql://root:senha@localhost:3306/floodalert",
)

# pool_pre_ping evita erros de "conexão perdida" quando o MySQL
# fica muito tempo ocioso (comum em ambiente de desenvolvimento).
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """Dependência do FastAPI: abre uma sessão por requisição e sempre fecha."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()