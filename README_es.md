# Acestream Dockerizado

[Read documentation in English](README.md)

Ejecuta Acestream dentro de un contenedor Docker sobre Ubuntu 22.04 + Python 3.10. Un solo script, un solo comando y tendrás un motor de streaming privado listo en tu máquina.

## Novedades en v8.2.0

- **Reproductor web rediseñado** — guía clara la primera vez (qué pegar y dónde conseguir un enlace), indicador de carga mientras conecta el stream y errores en lenguaje sencillo. Inglés/Español.
- **Mejoras de accesibilidad** — foco de teclado visible, controles etiquetados, contraste WCAG AA y viewport móvil.
- **Frontend reforzado** — video.js 8.23.7 vía jsDelivr con Subresource Integrity y favicon inline autocontenido (sin peticiones a terceros).
- **Apagado limpio** — el engine corre como PID 1 (`exec`), así `docker stop` lo termina correctamente.
- **Actualización de dependencias** — `PyNaCl` y `requests` al día.

## Requisitos previos

- **Docker Desktop** instalado y funcionando. <https://www.docker.com/products/docker-desktop>

## Inicio rápido en Windows (recomendado)

1. Descarga `SetupAcestream.bat` desde la [página de Releases](https://github.com/sergiomarquezdev/acestream-docker-home/releases).
2. Haz clic derecho → **Ejecutar como administrador**.
3. Elige tu idioma (`1` Español, `2` Inglés; espera 5s para el valor por defecto en español).
4. Confirma tu IP interna (pulsa ENTER para usar la detectada automáticamente).
5. El script descarga la imagen, arranca el contenedor y abre el reproductor web.

### Flags

| Flag | Efecto |
|------|--------|
| `--lang=en` | Fuerza interfaz en inglés |
| `--lang=es` | Fuerza interfaz en español |
| `--auto-clean` | Elimina imágenes obsoletas tras la descarga |

## Ejecución manual (Linux / macOS / avanzado)

```bash
docker build --no-cache -t acestream-engine .
docker run --name acestream-engine -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped acestream-engine
```

O usa Docker Compose:

```bash
docker-compose up -d
```

Consulta [`.env.example`](.env.example) para todas las variables de entorno.

## Modos de caché

| Modo | Comando |
|------|---------|
| Disco (por defecto) | `docker-compose up -d` |
| RAM (tmpfs, Linux/WSL2) | `docker-compose --profile ram up -d acestream-ram` |
| Memoria (multi-plataforma) | `docker-compose --profile memory up -d acestream-memory` |

## Documentación

- [docs/BUILD.md](docs/BUILD.md) — Cómo se construye la imagen
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Flujo de arranque y decisiones de diseño
- [docs/TESTING.md](docs/TESTING.md) — Cómo ejecutar los smoke tests

## Verificar la salud del contenedor

```bash
docker inspect --format='{{json .State.Health}}' acestream-engine
```

O vía web: `http://<INTERNAL_IP>:<PORT>/webui/api/service?method=get_version`

## Licencia

MIT. Consulta [LICENSE](LICENSE).
