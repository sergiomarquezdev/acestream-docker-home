// Obtener el playerId de la variable externa
let playerId = "${player_id}";

// Verificar si el playerId comienza con 'acestream://'
if (playerId.startsWith('acestream://')) {
    // Eliminar 'acestream://' del playerId
    playerId = playerId.replace('acestream://', '');
}

document.title = `${document.title} [${playerId.substr(0, 7)}]`;
const player = videojs(document.querySelector('video'));
player.src(`http://127.0.0.1:6878/ace/manifest.m3u8?id=${playerId}`);
player.play();