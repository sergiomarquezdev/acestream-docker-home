# Acestream en Docker

[![CI](https://github.com/sergiomarquezdev/acestream-docker-home/actions/workflows/ci.yml/badge.svg)](https://github.com/sergiomarquezdev/acestream-docker-home/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/sergiomarquezdev/acestream-docker-home)](https://github.com/sergiomarquezdev/acestream-docker-home/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/smarquezp/docker-acestream-ubuntu-home)](https://hub.docker.com/r/smarquezp/docker-acestream-ubuntu-home)

[Read documentation in English](README.md)

Ejecuta Acestream Engine 3.2.11 dentro de Docker y mira streams desde el navegador. En Windows, un solo script lo hace todo: arranca Docker, descarga la imagen, lanza el motor y abre el reproductor web.

## Novedades de v8.3.0

- **Apagado limpio y rápido**: `tini` pasa a ser el PID 1. El motor ignora SIGTERM cuando es él mismo el PID 1, así que cada `docker stop` esperaba al timeout y lo mataba (el cambio a `exec` de v8.2.0 no lo resolvía). Ahora se detiene en un segundo.
- **Imagen un 25 % más ligera**: de 730 MB a 541 MB (sin pip/setuptools/wheel/wget en runtime y sin el tarball del motor en ninguna capa).
- **El reproductor funciona sin internet y con cualquier IP o puerto**: video.js 8.24.1 va incluido en la imagen (sin CDN), las URLs del stream son del mismo origen, hay una Content-Security-Policy estricta y no se pide nada a terceros.
- **Mejor experiencia en el reproductor**: recuerda tu idioma (y lo detecta del navegador), controles de vídeo en español, enlaces para compartir (`/webui/player/?id=<ID de contenido>`), aviso claro de "pulsa play" cuando el navegador bloquea la reproducción automática y mensajes para campo vacío o enlace no válido.
- **Arreglos en el script de instalación**: elige tu IP real de la red local (ignora adaptadores de VirtualBox/Hyper-V/WSL/VPN), reutiliza el contenedor existente en vez de crear otro, arranca Docker Desktop si hace falta, `--lang` vuelve a funcionar, modo `--unattended`, tildes correctas en español y ya no sobrescribe el `docker-compose.yml` del repositorio.
- **Dependencias actualizadas**: apsw 3.53.4, lxml 6.1.3, pycryptodome 3.23.0, isodate 0.7.2.
- **CI**: cada push se valida, se construye y se prueba en GitHub Actions; Dependabot mantiene las dependencias al día.

## Requisitos

- **Docker Desktop** (Windows/macOS) o Docker Engine (Linux): <https://www.docker.com/products/docker-desktop/>
- Un equipo **x86_64 (amd64)**. El motor oficial no tiene versión ARM, así que Raspberry Pi y otras placas ARM no están soportadas.

## Inicio rápido en Windows (recomendado)

1. Descarga [**SetupAcestream.bat**](https://github.com/sergiomarquezdev/acestream-docker-home/releases/latest/download/SetupAcestream.bat) (siempre la última versión).
2. Haz doble clic. No necesita permisos de administrador.
3. Elige idioma (`1` español, `2` inglés; a los 5 s se usa español).
4. Confirma la IP detectada (pulsa ENTER).
5. El script arranca Docker Desktop si no está en marcha, descarga la imagen, inicia el motor y abre <http://localhost:6878/webui/player/>.

Si lo vuelves a ejecutar, actualiza a la última imagen y reutiliza el mismo contenedor y puerto. Si otro programa ocupa el puerto 6878, elige el siguiente libre (6880, 6882, ...).

### Opciones

| Opción | Efecto |
|--------|--------|
| `--lang=en` / `--lang=es` | Omite la pregunta de idioma |
| `--auto-clean` | Elimina sin preguntar las imágenes antiguas de Acestream |
| `--unattended` | Sin preguntas, sin pausas y sin abrir el navegador (acepta los valores detectados; incluye `--auto-clean`) |

Define la variable de entorno `ACESTREAM_IMAGE` para desplegar otra imagen (por ejemplo, una compilada en local).

## Ver un stream

Pega un enlace `acestream://...` o el ID de contenido de 40 caracteres en el reproductor y pulsa **Reproducir**. Conectar con otros usuarios puede tardar entre 10 y 30 segundos.

Los enlaces se pueden compartir o guardar en favoritos: `http://localhost:6878/webui/player/?id=<ID de contenido>`.

### Desde otros dispositivos (tele, móvil, tablet)

El motor escucha en tu red local. Abre `http://<IP-de-tu-PC>:6878/webui/player/` en otro dispositivo; el script de instalación muestra esta URL. La primera vez, el Firewall de Windows puede pedirte permiso para Docker. El reproductor no tiene autenticación, así que cualquiera en tu red puede usarlo. **No expongas el puerto a internet.**

## Ejecución manual (Linux / macOS / avanzado)

```bash
docker run -d --name acestream-engine -p 6878:6878 --restart unless-stopped \
  smarquezp/docker-acestream-ubuntu-home:latest
```

O con Docker Compose desde un clon de este repositorio:

```bash
docker compose up -d
```

Copia [`.env.example`](.env.example) a `.env` para cambiar la imagen, los puertos o flags extra del motor.

## Modos de caché

| Modo | Comando |
|------|---------|
| Disco (por defecto) | `docker compose up -d` |
| RAM (tmpfs, Linux/WSL2) | `docker compose --profile ram up -d acestream-ram` |
| Memoria (multiplataforma) | `docker compose --profile memory up -d acestream-memory` |

Indica siempre el servicio del perfil: si no, también arranca el servicio base y ambos compiten por el puerto 6878.

## Actualizar y desinstalar

- **Windows**: vuelve a ejecutar `SetupAcestream.bat` para actualizar. Para quitarlo: `docker compose -f acestream-compose.yml down` en la carpeta donde está el script (o `docker rm -f acestream-engine_6878`).
- **Compose**: `docker compose pull && docker compose up -d` para actualizar, `docker compose down` para quitarlo.

## Solución de problemas

| Problema | Qué hacer |
|----------|-----------|
| "No se encontraron peers" | Probablemente el stream no está emitiendo. Prueba otro enlace. |
| "Listo. Pulsa el botón de reproducción para empezar a ver." | El navegador bloqueó la reproducción automática: pulsa el botón de reproducción. |
| Docker no está en marcha | El script intenta arrancar Docker Desktop y espera hasta 2 minutos. Si sigue fallando, arráncalo a mano. |
| Puerto ocupado | El script elige automáticamente el siguiente puerto libre; con Compose, define `HTTP_PORT`/`HTTPS_PORT` en `.env`. |

Comprueba la salud del contenedor:

```bash
docker inspect --format='{{json .State.Health}}' acestream-engine
```

O abre `http://<HOST>:<PUERTO>/webui/api/service?method=get_version`.

## Documentación

- [docs/BUILD.md](docs/BUILD.md): cómo se construye la imagen, dependencias y restricciones de diseño
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): flujo de arranque y decisiones de diseño
- [docs/TESTING.md](docs/TESTING.md): smoke tests y CI

## Licencia

MIT. Consulta [LICENSE](LICENSE).
