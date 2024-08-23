# Acestream Dockerizado

[Read documentation in English](README.md)

Este proyecto despliega Acestream dentro de un contenedor Docker usando Ubuntu 22.04 y Python 3.10 para garantizar la
compatibilidad.

Acestream es una plataforma para streaming en vivo a través de redes peer-to-peer. Dockerizar Acestream simplifica su
configuración y proporciona entornos aislados.

## Requisitos Previos

1. **Instalación de Docker**: Asegúrate de que Docker Desktop esté instalado en tu sistema.
   - [Página de productos de Docker](https://www.docker.com/products/docker-desktop)
   - [Documentación Oficial](https://docs.docker.com/get-docker/)

## Instalación Automática y Ejecución con `SetupAcestream.bat` (Windows)

1. **Descripción del Script**: El script `SetupAcestream.bat` automatiza las siguientes tareas:

   - Verificación de la instalación y estado operativo de Docker.
   - Descarga de la imagen Docker más reciente de Acestream.
   - Configuración del contenedor con asignación dinámica de puertos (para evitar conflictos).
   - Actualización del archivo `docker-compose.yml` de forma dinámica según los puertos disponibles.
   - Inicio del contenedor Acestream y apertura de la interfaz web.

2. **Uso**: Descarga y ejecuta el script `SetupAcestream.bat` como Administrador.

> **Nota:** El script garantiza que se utilice la imagen Docker más reciente de Acestream y que la gestión del
> contenedor se maneje de manera eficiente.

## Construir la Imagen

Este proyecto utiliza la imagen base **ubuntu:22.04**. Debes clonar el proyecto completo primero. Luego, para construir
la imagen, utiliza:

```bash
docker build --no-cache -t docker-acestream .
```

## Ejecutar el Contenedor

Para iniciar un contenedor y ejecutar Acestream con asignación dinámica de puertos:

```bash
docker run --name docker-acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped docker-acestream
```

El script `SetupAcestream.bat` maneja la asignación dinámica de puertos para evitar conflictos al ejecutar múltiples
instancias.

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

Accede a Acestream a través de la interfaz web. El script `SetupAcestream.bat` abre automáticamente la URL correcta
basada en el puerto asignado:

```plaintext
http://<INTERNAL_IP>:<PORT>/webui/player/
```

Puedes cargar enlaces de Acestream directamente en el campo de entrada proporcionado.

## Verificar la Salud del Contenedor

Verifica el estado de salud del contenedor de Acestream:

```bash
docker inspect --format='{{json .State.Health}}' docker-acestream
```

Alternativamente, utiliza la interfaz web:

```plaintext
http://<INTERNAL_IP>:<PORT>/webui/api/service?method=get_version
```

## Personalización

### Asignación Dinámica de Puertos

El proyecto incluye la asignación dinámica de puertos tanto para HTTP como para HTTPS para evitar conflictos al ejecutar
múltiples instancias. Esto se maneja en el script `SetupAcestream.bat`.

### Configuración de la Interfaz Web

El archivo `player.html` se actualiza dinámicamente con la dirección IP y el puerto correctos durante el proceso de
inicio del contenedor. Esto asegura que la interfaz web apunte a la instancia correcta del motor de Acestream.

## Contribuciones

Agradecemos las contribuciones. Haz un fork, realiza cambios y envía un pull request para revisión.

## Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
