const BASE_STREAM_URL = 'http://127.0.0.1:6878/ace/manifest.m3u8?id=';
const ACESTREAM_PREFIX = 'acestream://';
const player = videojs("video");

// Carga inicial del video
function initialLoad(playerId) {
    document.title += `[${playerId.substr(0, 7)}]`;
    player.src({
        src: BASE_STREAM_URL + playerId,
        type: "application/x-mpegURL",
    });
    player.play();
}

// Carga del stream de AceStream
function loadAceStream(link) {
    const playerId = link.replace(ACESTREAM_PREFIX, '');
    if (playerId.length > 1) {
        document.title = `Ace Link [${playerId.substr(0, 7)}]`;
        player.src({
            src: BASE_STREAM_URL + playerId,
            type: 'application/x-mpegURL',
        });
        player.play();
    } else {
        alert('Please insert a valid Acestream link.');
    }
}

// Mostrar/ocultar input de Acestream
function toggleAcestreamInput() {
    const inputDiv = document.getElementById('acestream-link');
    const icon = document.getElementById('toggle-icon');
    inputDiv.style.display = inputDiv.style.display === 'none' ? 'flex' : 'none';
    icon.className = inputDiv.style.display === 'none' ? 'fas fa-eye' : 'fas fa-eye-slash';
}

// Cambiar idioma de la página

function changeLanguage(lang) {
    const acestreamLinkInput = document.getElementById('acestream-link-input');
    acestreamLinkInput.placeholder = lang === 'es' ? 'Insertar aquí el enlace Acestream' : 'Insert Acestream link here';
    const loadButton = document.getElementById('load-button');
    loadButton.innerText = lang === 'es' ? 'Cargar' : 'Load';
}

initialLoad("{player_id}");

document.getElementById('toggle-view').addEventListener('click', toggleAcestreamInput);

document.getElementById('load-button').addEventListener('click', function () {
    const acestreamLink = document.getElementById('acestream-link-input').value;
    loadAceStream(acestreamLink);
});

// Manejar el contenido obtenido
fetch('https://corsproxy.io/?https://hackmd.io/@67QuUe0VRy-nPCNoJwtsgQ/plan-d')
    .then(response => response.text())
    .then(html => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        const docDiv = doc.querySelector('#doc');
        if (docDiv) {
            const docHtml = docDiv.innerHTML;
            const contentRegex = /---\s*##([\s\S]*?)&lt;style&gt;/;
            const match = docHtml.match(contentRegex);
            if (match && match[1]) {
                const desiredContent = match[1].trim();
                processAndDisplayContent(desiredContent);
            } else {
                console.error('The pattern was not found in the HTML content');
            }
        } else {
            console.error('docDiv is null or does not contain any content');
        }
    })
    .catch(error => {
        console.error('Error fetching the Markdown content:', error);
    });

// Procesar y mostrar el contenido obtenido
function processAndDisplayContent(content) {
    const titleRegex = /==\*\*(.*?)\*\*==\s*([\s\S]*?)(?=(==\*\*|$))/g;
    let match;
    let htmlContent = '';
    while ((match = titleRegex.exec(content)) !== null) {
        const title = match[1];
        const body = match[2];
        let columnContent = `<div class="title"><h2>${title}</h2></div>`;
        const nameAndLinkRegex = /\*\*(.*?)\*\*\s*(?:\[:arrow_forward:\]\((acestream:\/\/.*?)\))+/g;
        let nameMatch;
        while ((nameMatch = nameAndLinkRegex.exec(body)) !== null) {
            const name = nameMatch[1];
            const links = nameMatch[0];
            columnContent += `<div class="name-with-links">`;
            columnContent += `<div class="name"><h3>${name}</h3></div>`;
            columnContent += `<div class="links">`;
            const linkRegex = /\[:arrow_forward:\]\((acestream:\/\/.*?)\)/g;
            let linkMatch;
            while ((linkMatch = linkRegex.exec(links)) !== null) {
                const link = linkMatch[1];
                columnContent += `<a href="${link}" class="link-button"><i class="fa-solid fa-play"></i></a>`;
            }
            columnContent += `</div>`;
            columnContent += `</div>`;
        }
        htmlContent += `<div class="column">${columnContent}</div>`;
    }
    let finalHtmlContent = postProcessContent(htmlContent);
    document.getElementById('links-list').innerHTML = finalHtmlContent;
    const linksList = document.getElementById('links-list');
    const links = linksList.querySelectorAll('a');
    links.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const acestreamLink = link.getAttribute('href');
            loadAceStream(acestreamLink);
        });
    });
}

// Procesar contenido obtenido
function postProcessContent(htmlContent) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(htmlContent, 'text/html');
    const allNameWithLinks = doc.querySelectorAll('.name-with-links');
    allNameWithLinks.forEach((div, index) => {
        if (div.querySelector('.name h3').textContent.trim() === '720p' && index > 0) {
            const previousDiv = allNameWithLinks[index - 1];
            const nameDiv = div.querySelector('.name');
            previousDiv.appendChild(nameDiv);
            const linksDiv = div.querySelector('.links');
            previousDiv.appendChild(linksDiv);
            div.remove();
        }
    });
    return doc.body.innerHTML;
}
