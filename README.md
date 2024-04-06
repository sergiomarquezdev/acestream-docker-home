# Docker-Acestream-Linux

Este proyecto proporciona un Dockerfile para crear una imagen Docker que ejecuta Acestream en un contenedor, utilizando BusyBox para la descarga y configuración inicial, y Python Slim como imagen base. Está diseñado para ser ligero, eficiente y fácil de configurar.

## Requisitos Previos

Para usar este Dockerfile, necesitarás tener Docker instalado en tu sistema. Si no tienes Docker, puedes encontrar las instrucciones de instalación en la [documentación oficial de Docker](https://docs.docker.com/get-docker/).

## Instalación y Ejecución Automática con Script `setup_and_update_acestream.bat`

Hemos facilitado un proceso de instalación y ejecución más directo mediante un script de Windows `.bat` denominado `setup_and_update_acestream.bat`. Este script automatiza la creación y ejecución de la imagen y el contenedor Docker para el proyecto Acestream, siguiendo estos pasos:

1. **Elimina cualquier contenedor existente** llamado `acestream-container`. Esto asegura que no haya conflictos o errores debido a contenedores duplicados.
2. **Construye la imagen Docker** utilizando el Dockerfile proporcionado, con la etiqueta `docker-acestream-linux`. Se construye sin caché para asegurar que se utilicen las versiones más recientes de todas las dependencias.
3. **Ejecuta un nuevo contenedor Docker** basado en la imagen construida, exponiendo el puerto 6878 y asignándole el nombre `acestream-container`. Esto pone en marcha el servicio Acestream dentro del contenedor.

### Cómo Usar el Script `setup_and_update_acestream.bat`

Para ejecutar este script y configurar todo automáticamente, sigue estos pasos:

1. Asegúrate de que estás en una ventana de Símbolo del sistema o PowerShell con derechos de administrador.
2. Navega al directorio que contiene el script `setup_and_update_acestream.bat`.
3. Ejecuta el script con el siguiente comando:
```bash
setup_and_update_acestream.bat
```
4. Una vez ejecutado el script, el contenedor se estará ejecutando en segundo plano. El script te informará con el mensaje: "Contenedor ejecutándose en http://127.0.0.1:6878/webui/player/", indicando que Acestream está listo para ser utilizado a través de la interfaz web. Solamente deberás añadir el enlace de Acestream al final del enlace.

> Importante: Este proceso elimina el contenedor existente y crea uno nuevo cada vez que se ejecuta el script. Esto es ideal para una instalación fresca o actualizaciones mayores. Asegúrate de que Docker esté instalado en tu sistema y funcionando correctamente antes de ejecutar setup_and_update_acestream.bat.
          
5. Si quiere detener el proceso, puede hacerlo desde la interfaz de Docker 'Docker Desktop' o bien ejecutando el siguiente comando:
```bash
docker stop acestream-container
```

## Construcción de la Imagen

Utilizaremos la imagen **ubuntu:bionic** y la versión de Acestream **acestream_3.1.74_ubuntu_18.04_x86_64.tar.gz**.

Para construir la imagen Docker a partir de este Dockerfile, ejecuta el siguiente comando en la terminal desde el directorio donde se encuentra el Dockerfile:

```bash
docker build --no-cache -t docker-acestream-linux .
```

Al construir la imagen Docker, tienes la opción de especificar la versión de Acestream y su hash SHA256 correspondiente mediante los argumentos de construcción ACESTREAM_VERSION y ACESTREAM_SHA256. Estos valores por defecto en el Dockerfile son:
- *ARG ACESTREAM_VERSION=3.1.74_ubuntu_18.04_x86_64*
- *ARG ACESTREAM_SHA256=87db34c1aedc55649a8f8f5f4b6794581510701fc7ffbd47aaec0e9a2de2b219*

Para especificar una versión diferente y su correspondiente hash SHA256, utiliza el siguiente comando:
```bash
docker build --no-cache --build-arg ACESTREAM_VERSION=3.1.74_ubuntu_18.04_x86_64 --build-arg ACESTREAM_SHA256=87db34c1aedc55649a8f8f5f4b6794581510701fc7ffbd47aaec0e9a2de2b219 -t docker-acestream-linux .
```

Estos comandos construyen una nueva imagen Docker llamada docker-acestream-linux utilizando el Dockerfile en tu directorio actual.

## Ejecución del Contenedor

Una vez construida la imagen, puedes ejecutar Acestream en un contenedor Docker usando:

```bash
docker run --name acestream -d -p 6878:6878 -p 8621:8621 docker-acestream-linux
```

Este comando inicia un contenedor basado en la imagen docker-acestream-linux, expone el puerto 6878 para acceder a Acestream, y lo ejecuta en modo desacoplado.

## Acceso a Interfaz Web
Una vez que el contenedor esté en ejecución y no haya errores en los logs, puedes acceder a la interfaz web de Acestream utilizando un navegador web y yendo a http://localhost:6878/webui.

Para probar el reproductor personalizado, reemplaza <acestream_id> en la URL http://localhost:6878/webui/player/<acestream_id> con un ID de transmisión válido de Acestream.

## Verificación Estado de Salud del Contenedor
Puedes verificar el estado de salud del contenedor con
```bash
docker inspect --format='{{json .State.Health}}' acestream
```

También se puede ver este desde la propia interfaz web desplegada mediante el enlace:
http://127.0.0.1:6878/webui/api/service?method=get_version

## Uso de Acestream

Con Acestream ejecutándose en el contenedor, puedes acceder a él a través del puerto 6878 en la dirección IP de tu máquina Docker. La forma específica de usar Acestream dependerá de tus necesidades particulares.

## Contribuciones
Las contribuciones a este proyecto son bienvenidas. Si deseas contribuir, por favor, haz un fork del repositorio, realiza tus cambios y envía un pull request.

## Licencia
Este proyecto está licenciado bajo la MIT License - ve el archivo [LICENSE](LICENSE.md) para más detalles.
