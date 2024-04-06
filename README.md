# Dockerized Acestream x Ubuntu
Este proyecto facilita el despliegue de Acestream en un contenedor Docker, basándose en Ubuntu 18.04 (Bionic Beaver)
para garantizar la compatibilidad con la versión de Acestream utilizada.

Acestream es una plataforma popular para
streaming en vivo, que permite a los usuarios compartir y ver contenido de video a través de redes peer-to-peer.
Utilizar Acestream en un contenedor Docker ofrece una manera eficiente y aislada de ejecutar Acestream, facilitando su
instalación y configuración.

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


## Instalación y Ejecución Automática con Script `start_acestream.bat` (Windows)

Hemos proporcionado un script `.bat` para simplificar la instalación y ejecución de Acestream en contenedores Docker
para usuarios de Windows. El script `start_acestream.bat` automatiza varios pasos:

1. **Elimina cualquier contenedor Docker existente** llamado `acestream-container` para prevenir conflictos.
2. **Descarga la última imagen de Docker** de `smarquezp/docker-acestream-ubuntu` desde Docker Hub.
3. **Ejecuta el contenedor**, exponiendo el puerto 6878, lo cual permite el acceso al servicio Acestream.

### Cómo Usar el Script `start_acestream.bat`

Para ejecutar este script:

- Puedes ejecutarlo directamente descargando el script y ejecutándolo con doble click, o bien seguir los siguientes
  pasos para indicar un ID de stream Acestream:

1. Abre una consola de comandos (Command Prompt) o PowerShell con derechos de administrador.
2. Navega al directorio donde descargaste `start_acestream.bat`.
3. Ejecuta el script mediante el siguiente comando:
    ```bash
    start_acestream.bat <acestream_id>
    ```
   Sustituye `<acestream_id>` con el ID real de tu stream Acestream.

El contenedor ahora debería estar corriendo en segundo plano. Accede a `http://localhost:6878/webui/player/` y añade el
ID de tu stream Acestream al final de la URL, como en el siguiente
ejemplo:`http://localhost:6878/webui/player/1234567890abcdef`


> **Nota:** Este proceso reinicia el contenedor cada vez que se ejecuta el script, lo que asegura que estás corriendo la
> versión más reciente. Asegúrate de que Docker está instalado y operativo antes de ejecutar `start_acestream.bat`.

Para detener el contenedor, puedes usar Docker Desktop o ejecutar el siguiente comando en tu consola:
```bash
docker stop acestream-container
```

## Construcción de la Imagen

Este proyecto utiliza la imagen base **ubuntu:bionic** y es compatible con la versión de Acestream *
*acestream_3.1.74_ubuntu_18.04_x86_64.tar.gz**.

Para construir tu propia imagen Docker a partir de este Dockerfile, ejecuta el siguiente comando en la terminal,
asegurándote de estar en el mismo directorio que el Dockerfile:

```bash
docker build --no-cache -t docker-acestream-ubuntu .
```

Los argumentos `ACESTREAM_VERSION` y `ACESTREAM_SHA256` están predefinidos en el Dockerfile para coincidir con la
versión de Acestream y su hash SHA256 respectivamente:

- `ARG ACESTREAM_VERSION=3.1.74_ubuntu_18.04_x86_64`
- `ARG ACESTREAM_SHA256=87db34c1aedc55649a8f8f5f4b6794581510701fc7ffbd47aaec0e9a2de2b219`

Si necesitas utilizar una versión diferente de Acestream y su hash SHA256, puedes especificarlos al construir la imagen
con los siguientes argumentos:

```bash
docker build --no-cache --build-arg ACESTREAM_VERSION=tu_version_acestream --build-arg ACESTREAM_SHA256=tu_hash_sha256 -t docker-acestream-ubuntu .
```

Reemplaza `tu_version_acestream` y `tu_hash_sha256` con los valores específicos de la versión de Acestream que desees
utilizar. El comando anterior generará una imagen Docker con el nombre `docker-acestream-ubuntu` basada en el Dockerfile
proporcionado.

## Ejecución del Contenedor

Con la imagen Docker construida, puedes iniciar un contenedor para ejecutar Acestream de la siguiente manera:

```bash
docker run --name acestream -d -p 6878:6878 -p 8621:8621 docker-acestream-ubuntu
```

Este comando ejecutará un contenedor llamado `acestream`, en modo desacoplado (`-d`), mapeando los puertos `6878`
y `8621` del host al contenedor, permitiéndote acceder al servicio Acestream a través de estos puertos.

## Acceso a Interfaz Web

Una vez que el contenedor esté en ejecución y no haya errores en los logs, puedes acceder a la interfaz web de Acestream
utilizando un navegador web y yendo a `http://localhost:6878/webui/player/`.

Para probar el reproductor personalizado, reemplaza `<acestream_id>` en la
URL `http://localhost:6878/webui/player/<acestream_id>` con un ID de transmisión válido de Acestream.

## Verificación Estado de Salud del Contenedor

Puedes verificar el estado de salud del contenedor con el siguiente comando:

```bash
docker inspect --format='{{json .State.Health}}' acestream
```

También se puede ver el estado de salud desde la propia interfaz web desplegada mediante el enlace:
`http://localhost:6878/webui/api/service?method=get_version`

## Configuración del Protocolo Acestream en Windows

También puedes añadir por defecto que todos los enlances `acestream://` ejecuten automáticamente el archivo. 
Para asegurar que los enlaces `acestream://` ejecuten correctamente el script `start_acestream.bat` en Windows, es necesario registrar el protocolo en el Registro de Windows y apuntarlo al script. A continuación, se muestra cómo configurar el registro correctamente:

1. **Abre el Editor del Registro**:
   - Presiona `Win + R`, escribe `regedit` y presiona `Enter`.

2. **Navega a la clave del registro** `HKEY_CLASSES_ROOT\acestream` y asegúrate de que existan los siguientes valores:
   - **Clave**: `HKEY_CLASSES_ROOT\acestream`
     - **Valor**: (Predeterminado) = `URL:acestream Protocol`
     - **Valor**: `URL Protocol` = `""`

3. **En la misma clave**, asegúrate de que el comando para abrir los enlaces esté configurado correctamente:
   - **Clave**: `HKEY_CLASSES_ROOT\acestream\shell\open\command`
     - **Valor**: (Predeterminado) = `"C:\ruta\a\tu\start_acestream.bat" "%1"`

   Reemplaza `"C:\ruta\a\tu\start_acestream.bat"` con la ruta completa a tu script `start_acestream.bat`. Es importante incluir las comillas `" "` y el `%1` al final, ya que esto asegura que la URL se pase como argumento al script.

Por favor, ten en cuenta que modificar el registro de Windows puede afectar el funcionamiento de tu sistema. Es recomendable realizar estos cambios con precaución y solo si estás seguro de lo que estás haciendo.

Si estás en Windows 10 o versiones más recientes, es posible que necesites habilitar la ejecución de scripts. Esto se puede hacer ajustando la política de ejecución en PowerShell como administrador:
```powershell
Set-ExecutionPolicy RemoteSigned
```
Sin embargo, ten en cuenta que cambiar la política de ejecución puede tener implicaciones de seguridad, así que asegúrate de entender lo que esto implica.

## Uso de Acestream

Una vez que Acestream está operativo en el contenedor, puedes interactuar con él a través del puerto `6878`. Dependiendo
de cómo quieras utilizar Acestream (como para streaming en vivo, compartir contenido, etc.), tendrás que configurar tus
streams o clientes para conectarse a esta instancia de Acestream en la dirección IP de tu máquina Docker,
habitualmente `http://localhost:6878` para accesos locales.

## Contribuciones

Tu participación en el proyecto es altamente apreciada. Si tienes sugerencias de mejoras o correcciones y deseas
contribuir:

1. Realiza un fork del repositorio.
2. Crea una rama para tus cambios.
3. Haz tus modificaciones.
4. Envía un pull request para revisión.

Nos esforzamos por mantener un ambiente abierto y colaborativo. Antes de enviar tu pull request, por favor revisa las
pautas de contribución para asegurar un proceso de revisión y fusión eficiente.

## Licencia

Este proyecto se distribuye bajo la Licencia MIT, lo que significa que puedes modificarlo, distribuirlo o utilizarlo
como quieras bajo los términos de esta licencia. Para más información, consulta el archivo [LICENSE](LICENSE) incluido
en este repositorio.

