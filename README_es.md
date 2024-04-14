# Acestream Dockerizado

[Read documentation in English](README.md)

Este proyecto facilita el despliegue de Acestream en un contenedor Docker, utilizando Ubuntu 18.04 (Bionic Beaver) para
garantizar la compatibilidad con la versión de Acestream empleada.

Acestream es una plataforma popular para streaming en vivo que permite a los usuarios compartir y ver contenido de video
a través de redes peer-to-peer. Utilizar Acestream en un contenedor Docker ofrece una manera eficiente y aislada de
ejecutar Acestream, facilitando su instalación y configuración.

## Requisitos Previos

Antes de comenzar, necesitarás tener Docker instalado y en ejecución en tu máquina. Esta guía asume que tienes una
comprensión básica de los contenedores Docker y el ecosistema de Docker.

Para instalar Docker, sigue las instrucciones en
la [documentación oficial de Docker](https://docs.docker.com/get-docker/) o visita
la [página de productos de Docker](https://www.docker.com/products/docker-desktop) para descargar la versión adecuada
para tu sistema operativo.

Para asegurarte de que Docker está instalado correctamente y listo para usar, ejecuta:

```bash
docker --version
```

## Instalación y Ejecución Automática con Script `SetupAcestream.bat` (Windows)

Hemos proporcionado un script `.bat` denominado `SetupAcestream.bat` para simplificar todo el proceso de instalación,
configuración y ejecución de Acestream en contenedores Docker para usuarios de Windows. El script automatiza varios
pasos, incluyendo:

1. Verificación e instalación de Docker si es necesario.
2. Descarga de la última imagen de Docker de `smarquezp/docker-acestream-ubuntu-home` desde Docker Hub.
3. Ejecución del contenedor, exponiendo el puerto 6878, permitiendo el acceso al servicio Acestream desde cualquier
   dispositivo dentro de tu red local.

### Cómo Usar el Script `SetupAcestream.bat`

Simplemente descarga el archivo [SetupAcestream.bat](https://github.com/marquezpsergio/acestream-docker/releases) y
ejecútalo como Administrador. Este script prepara todo lo necesario para ejecutar Acestream en Docker y abre
automáticamente la interfaz web donde podrás cargar los enlaces de Acestream directamente.

> **Nota:** Este proceso asegura que estés utilizando siempre la versión más reciente de la imagen de Docker de
> Acestream y te permite gestionar el contenedor de manera eficiente.

## Construcción de la Imagen

Este proyecto utiliza la imagen base **ubuntu:bionic** y es compatible con la versión de Acestream *
*acestream_3.1.74_ubuntu_18.04_x86_64.tar.gz**.

Para construir tu propia imagen Docker a partir de este Dockerfile, ejecuta el siguiente comando en la terminal,
asegurándote de estar en el mismo directorio que el Dockerfile:

```bash
docker build --no-cache -t docker-acestream-ubuntu-home .
```

Si necesitas utilizar una versión diferente de Acestream y su hash SHA256, puedes especificarlos al construir la imagen
con los siguientes argumentos:

```bash
docker build --no-cache --build-arg ACESTREAM_VERSION=tu_version_acestream --build-arg ACESTREAM_SHA256=tu_hash_sha256 -t docker-acestream-ubuntu-home .
```

## Ejecución del Contenedor

Con la imagen Docker construida, puedes iniciar un contenedor para ejecutar Acestream de la siguiente manera. Puedes
indicar también la IP que quieras en el comando.

```bash
docker run --name acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped 
docker-acestream-ubuntu-home
```

## Ejecución del Contenedor con Docker Compose

Descarga o copia el contenido del fichero `docker-compose.yml`.

Desde la misma ruta donde se encuentra el archivo, ejecuta:

```bash
docker-compose up -d
```

### Actualización con Docker Compose

Para asegurarte de que estás utilizando la última versión de la imagen, ejecuta:

```bash
docker-compose pull && docker-compose up -d
```

## Acceso a la Interfaz Web

Una vez que el contenedor esté en ejecución y sin errores en los registros, puedes acceder a la interfaz web de
Acestream utilizando un navegador web y dirigiéndote a `http://localhost:6878/webui/player/`.
Aquí podrás cargar los enlaces de Acestream directamente en el campo situado en la parte superior izquierda de la
pantalla. Además, podrás ocultar o mostrar este campo utilizando el icono que aparece a su izquierda.

## Verificación del Estado de Salud del Contenedor

Puedes verificar el estado de salud del contenedor con el siguiente comando:

```bash
docker inspect --format='{{json .State.Health}}' acestream
```

El estado de salud también se puede verificar desde la propia interfaz web, a través del
enlace: `http://localhost:6878/webui/api/service?method=get_version`.

## Contribuciones

Tu participación en el proyecto es altamente apreciada. Si tienes sugerencias de mejoras o correcciones y deseas
contribuir, sigue los pasos estándar de GitHub para colaborar en proyectos.

## Licencia

Este proyecto se distribuye bajo la Licencia MIT, lo que significa que puedes modificarlo, distribuirlo o utilizarlo
como quieras bajo los términos de esta licencia. Para más información, consulta el archivo [LICENSE](LICENSE) incluido
en este repositorio.
