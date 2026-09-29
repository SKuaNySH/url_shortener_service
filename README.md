# URL Shortener Service

Сервис сокращения URL на Spring Boot. Он принимает длинную ссылку, сохраняет ее в PostgreSQL и возвращает короткий URL с уникальным Base62-хэшем. При переходе по короткому URL сервис находит исходную ссылку и выполняет HTTP-редирект.

## Возможности

- создание короткой ссылки по валидному HTTP/HTTPS URL;
- редирект на исходный URL по короткому хэшу;
- хранение ссылок и пула свободных хэшей в PostgreSQL;
- кэширование ссылок и свободных хэшей в Redis;
- асинхронное пополнение пула хэшей;
- автоматическое удаление ссылок старше одного года с возвратом их хэшей в пул;
- единый JSON-формат ошибок для ошибок валидации, отсутствующих ссылок и внутренних ошибок.

## Технологии

- Java 17;
- Spring Boot 3;
- PostgreSQL;
- Redis;
- Liquibase;
- Gradle.

## Требования

Для запуска нужны JDK 17, PostgreSQL и Redis. По умолчанию сервис использует:

| Параметр | Значение |
| --- | --- |
| HTTP-порт | `8095` |
| PostgreSQL | `localhost:5432`, база `postgres`, пользователь `user`, пароль `password` |
| Redis | `localhost:6379` |

Параметры можно изменить переменными окружения `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `REDIS_HOST`, `REDIS_PORT` и `URL_PREFIX`.

## Запуск локально

1. Запустите PostgreSQL и Redis.
2. Соберите приложение:

   ```bash
   .\gradlew.bat clean bootJar
   ```

3. Запустите сервис:

   ```bash
   java -jar build\libs\service.jar
   ```

Liquibase применит миграции к базе данных при старте приложения.

## API

### Создание короткой ссылки

```http
POST http://localhost:8095/url
Content-Type: application/json
```

Тело запроса:

```json
{
  "url": "https://example.com/page"
}
```

Успешный ответ имеет статус `201 Created`:

```json
{
  "shortUrl": "http://127.0.0.1:8095/1"
}
```

### Переход по короткой ссылке

```http
GET http://localhost:8095/{hash}
```

При существующем хэше сервис возвращает `302 Found` и заголовок `Location` с исходным URL. Если хэш не найден, возвращается `404 Not Found`.

## Запуск в Docker

Сначала соберите JAR-файл:

```bash
.\gradlew.bat clean bootJar
```

Затем соберите Docker-образ и запустите приложение:

```bash
docker build -t url-shortener-service .
docker run --name url-shortener-service `
  -p 8095:8095 `
  -e DB_HOST=host.docker.internal `
  -e REDIS_HOST=host.docker.internal `
  url-shortener-service
```

В этом варианте PostgreSQL и Redis должны быть запущены на хост-машине. Если зависимости работают в Docker, передайте приложению имена контейнеров или адрес хоста в `DB_HOST` и `REDIS_HOST`; контейнеры должны находиться в одной Docker-сети.

Пример запуска PostgreSQL и Redis:

```bash
docker network create url-shortener-network
docker run -d --name url-shortener-postgres --network url-shortener-network `
  -e POSTGRES_DB=postgres -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password `
  postgres:15
docker run -d --name url-shortener-redis --network url-shortener-network redis:7
docker run --name url-shortener-service --network url-shortener-network `
  -p 8095:8095 `
  -e DB_HOST=url-shortener-postgres `
  -e REDIS_HOST=url-shortener-redis `
  url-shortener-service
```
