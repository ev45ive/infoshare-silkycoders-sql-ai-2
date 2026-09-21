# infoshare-silkycoders-sql-ai-2

# GIT

Ctrl+Shift+P -> Git: Clone -> PASTE url -> Clone from URL -> Select location -> open window

https://github.com/ev45ive/infoshare-silkycoders-sql-ai-2.git


# AI model
- Key Anthropic 

# Db connection string
Server=127.0.0.1,14330;Database=RetailDW;User Id=sa;Password=Workshop_Dev2026#;TrustServerCertificate=true;


# Load all seed data command:

./scripts/dw.sh seed 2 && ./scripts/dw.sh etl && \
./scripts/dw.sh seed 1 customers && ./scripts/dw.sh etl customers && \
./scripts/dw.sh seed 2 customers && ./scripts/dw.sh etl customers && \
./scripts/dw.sh seed 1 items && ./scripts/dw.sh etl items && \
./scripts/dw.sh seed 1 returns && ./scripts/dw.sh etl returns && \
./scripts/dw.sh seed 1 inventory && ./scripts/dw.sh etl inventory && \
./scripts/dw.sh seed 2 inventory && ./scripts/dw.sh etl inventory && \
./scripts/dw.sh seed 1 dataquality



