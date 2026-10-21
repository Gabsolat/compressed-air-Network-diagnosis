# KRR Mini-Project 31 - Prolog expert system (Render web service)
# Pin the tag once you know your local version (`swipl --version`), e.g. swipl:9.2.9,
# so the deployed environment matches what you report in the reproducibility section.
FROM swipl:10.0.0

WORKDIR /app
COPY . /app

# Render injects PORT at runtime; 10000 is Render's default.
ENV PORT=10000
EXPOSE 10000

# server.pl loads the expert system and starts the HTTP interface.
CMD ["swipl", "server.pl"]
