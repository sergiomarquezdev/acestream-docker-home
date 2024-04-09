# Dockerized Acestream

[Read documentation in English](README_EN.md)

Este proyecto facilita el despliegue de Acestream en un contenedor Docker, basándose en Ubuntu 18.04 (Bionic Beaver)
para garantizar la compatibilidad con la versión de Acestream utilizada.

Acestream es una plataforma popular para streaming en vivo, que permite a los usuarios compartir y ver contenido de
video a través de redes peer-to-peer. Utilizar Acestream en un contenedor Docker ofrece una manera eficiente y aislada
de ejecutar Acestream, facilitando su instalación y configuración.

## Requisitos Previos

Antes de comenzar, necesitarás tener Docker instalado y ejecutándose en tu máquina. Esta guía asume que tienes una
comprensión básica de los contenedores Docker y el ecosistema de Docker.

Para instalar Docker, sigue las instrucciones de
la [documentación oficial de Docker](https://docs.docker.com/get-docker/) o visita
la [página de productos de Docker](https://www.docker.com/products/docker-desktop) para descargar la versión adecuada
para tu sistema operativo.

Para asegurarte de que Docker esté instalado correctamente y listo para usar, ejecuta:

```bash
docker --version
```

## Instalación y Ejecución Automática con Script `SetupAcestream.bat` (Windows)

Hemos proporcionado un script `.bat` denominado `SetupAcestream.bat` para simplificar todo el proceso de instalación,
configuración y ejecución de Acestream en contenedores Docker para usuarios de Windows. El script automatiza varios
pasos, incluyendo:

1. Verificación e instalación de Docker si es necesario.
2. Configuración automática del protocolo `acestream://` en Windows.
3. Descarga de la última imagen de Docker de `smarquezp/docker-acestream-ubuntu-home` desde Docker Hub.
4. Ejecución del contenedor, exponiendo el puerto 6878, lo cual permite el acceso al servicio Acestream desde cualquier
   dispositivo dentro de tu red local.

### Cómo Usar el Script `SetupAcestream.bat`

Para utilizar este script, simplemente descarga el
archivo [SetupAcestream.bat](https://github.com/marquezpsergio/acestream-docker/releases) y ejecútalo. Este script
prepara todo lo necesario para ejecutar Acestream en Docker y abre automáticamente la interfaz web donde podrás cargar
los enlaces de Acestream directamente sin necesidad de pasarlos como argumentos.

Recuerda que debes ejecutar el archivo en modo Administrador para configurar los registros para el protocolo Acestream.
Esto asocia todos los enlaces 'acestream://' a este script, automatizando el proceso de apertura de enlaces Acestream.

> **Nota:** Este proceso asegura que estés utilizando siempre la versión más reciente de la imagen de Docker de
> Acestream y te permite gestionar el contenedor de manera eficiente.

## Construcción de la Imagen

Este proyecto utiliza la imagen base **ubuntu:bionic** y es compatible con la versión de Acestream \*
\*acestream_3.1.74_ubuntu_18.04_x86_64.tar.gz\*\*.

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

Con la imagen Docker construida, puedes iniciar un contenedor para ejecutar Acestream de la siguiente manera:

```bash
docker run --name acestream -d -p 6878:6878 docker-acestream-ubuntu-home
```

Este comando ejecutará un contenedor llamado `acestream`, en modo desacoplado (`-d`), mapeando el puerto `6878` del host
al contenedor, permitiéndote acceder al servicio Acestream a través de este puerto.

## Acceso a Interfaz Web

Una vez que el contenedor esté en ejecución y no haya errores en los logs, puedes acceder a la interfaz web de Acestream
utilizando un navegador web y yendo a `http://localhost:6878/webui/player/`.
Aquí podrás cargar los enlaces de Acestream directamente en el campo situado en la parte superior izquierda de la
pantalla. Cuando desees, podrás ocultarlo/mostrarlo con el icono que aparece a su izquierda.

## Verificación Estado de Salud del Contenedor

Puedes verificar el estado de salud del contenedor con el siguiente comando:

```bash
docker inspect --format='{{json .State.Health}}' acestream
```

También se puede ver el estado de salud desde la propia interfaz web desplegada mediante el
enlace: `http://localhost:6878/webui/api/service?method=get_version`

## Contribuciones

Tu participación en el proyecto es altamente apreciada. Si tienes sugerencias de mejoras o correcciones y deseas
contribuir, sigue los pasos habituales de GitHub para hacer fork, realizar cambios y enviar un pull request para
revisión.

## Licencia

Este proyecto se distribuye bajo la Licencia MIT, lo que significa que puedes modificarlo, distribuirlo o utilizarlo
como quieras bajo los términos de esta licencia. Para más información, consulta el archivo [LICENSE](LICENSE) incluido
en este repositorio.
