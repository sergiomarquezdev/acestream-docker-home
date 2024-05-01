# Acestream Dockerizado

[Read documentation in English](README.md)

Este proyecto despliega Acestream dentro de un contenedor Docker usando Ubuntu 22.04 y Python 3.10 para garantizar la
compatibilidad.

Acestream es una plataforma para streaming en vivo a través de redes peer-to-peer. Usar Docker para Acestream simplifica
su configuración y proporciona entornos aislados.

## Requisitos Previos

1. **Instalación de Docker**: Asegúrate de que Docker Desktop esté instalado en tu sistema.
   - [Página de productos de Docker](https://www.docker.com/products/docker-desktop)
   - [Documentación Oficial](https://docs.docker.com/get-docker/)

## Instalación Automática y Ejecución con `SetupAcestream.bat` (Windows)

1. **Descripción del Script**: El script `SetupAcestream.bat` automatiza:
   - Instalación de Docker (si es necesario)
   - Descarga de la imagen de Docker
   - Configuración del contenedor (puerto 6878 expuesto para acceso a la red)

2. **Uso**: Descarga y ejecuta el [SetupAcestream.bat](https://github.com/marquezpsergio/acestream-docker/releases) como
   Administrador.

> **Nota:** Esto garantiza la versión más reciente de la imagen Docker de Acestream y el manejo del contenedor.

## Construir la Imagen

Este proyecto usa la imagen base **ubuntu:22.04**. Debes clonar el proyecto completo primero.
Después, para construir tu imagen utiliza:

```bash
docker build --no-cache -t docker-acestream .
```

## Ejecutar el Contenedor

Para iniciar un contenedor y ejecutar Acestream:

```bash
docker run --name docker-acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped docker-acestream
```

## Docker Compose

1. **Iniciar el Contenedor**: Usa `docker-compose` para iniciar el contenedor:

   ```bash
   docker-compose up -d
   ```

2. **Actualizar la Imagen**: Para obtener la última versión de la imagen:

   ```bash
   docker-compose pull && docker-compose up -d
   ```

## Acceder a la Interfaz Web

Accede a Acestream a través de la interfaz web en `http://localhost:6878/webui/player/`. Carga enlaces de Acestream en
el campo superior izquierdo.

## Verificar la Salud del Contenedor

Verifica el estado de salud:

```bash
docker inspect --format='{{json .State.Health}}' docker-acestream
```

O a través de la interfaz web: `http://localhost:6878/webui/api/service?method=get_version`.

## Contribuciones

Agradecemos las contribuciones. Haz un fork, realiza cambios y envía un pull request para revisión.

## Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
