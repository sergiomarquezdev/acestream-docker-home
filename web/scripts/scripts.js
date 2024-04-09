// On initial load, load from the link if the parameter is provided
// Obtain the playerId from an external variable
let playerId = "{player_id}";
document.title = `${document.title} [${playerId.substr(0, 7)}]`;
let player = videojs("video");
player.src({
    src: `http://127.0.0.1:6878/ace/manifest.m3u8?id=${playerId}`,
    type: "application/x-mpegURL", // Adjustment for the correct MIME type for HLS streams.
});
player.play();

function loadAceStream() {
    let acestreamLink = document.getElementById("acestream-link-input").value;
    // Remove the 'acestream://' prefix if present
    acestreamLink = acestreamLink.replace("acestream://", "");
    // Check if the ID has more than 1 character
    if (acestreamLink.length > 1) {
        const playerId = acestreamLink;
        document.title = `Ace Link [${playerId.substr(0, 7)}]`;
        player.src({
            src: `http://127.0.0.1:6878/ace/manifest.m3u8?id=${playerId}`,
            type: "application/x-mpegURL",
        });
        player.play();
    } else {
        alert("Please insert a valid Acestream link.");
    }
}

function loadAcestreamUrl(link) {
    document.getElementById('acestream-link-input').value = link;
    loadAceStream();
}

// Functionality to show/hide input and adjust toggle icon
document.getElementById("toggle-view").addEventListener("click", function () {
    let inputDiv = document.getElementById("acestream-link");
    let icon = document.getElementById("toggle-icon");
    if (inputDiv.style.display === "none") {
        inputDiv.style.display = "flex";
        icon.className = "fas fa-eye-slash"; // Change to closed eye icon
    } else {
        inputDiv.style.display = "none";
        icon.className = "fas fa-eye"; // Change to open eye icon
    }
});

// Function to change the page language
function changeLanguage(lang) {
    // Update the input placeholder
    const acestreamLinkInput = document.getElementById("acestream-link-input");
    acestreamLinkInput.placeholder = lang === "es" ? "Insertar aquí el enlace Acestream" : "Insert Acestream link here";
    // Update the button text
    const loadButton = document.getElementById("load-button");
    loadButton.innerText = lang === "es" ? "Cargar" : "Load";
}

fetch('https://corsproxy.io/?https://hackmd.io/@67QuUe0VRy-nPCNoJwtsgQ/plan-d')
    .then(response => response.text())
    .then(html => {
        // Use DOMParser to parse the HTML string
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');

        // Extract the 'doc' div from the parsed HTML
        const docDiv = doc.querySelector('#doc'); // Use .querySelector if .getElementById does not work

        // Ensure docDiv is not null and has content
        if (docDiv) {
            const docHtml = docDiv.innerHTML; // Get the innerHTML of the doc div

            // Regex to match the content between the patterns
            const contentRegex = /---\s*##([\s\S]*?)&lt;style&gt;/;
            const match = docHtml.match(contentRegex);

            if (match && match[1]) {
                // The desired content is in the first capturing group
                const desiredContent = match[1].trim();

                console.log(desiredContent);

                // Ejecutar la función con el contenido deseado
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
            loadAcestreamUrl(acestreamLink);
        });
    });
}

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
