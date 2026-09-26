document.addEventListener('DOMContentLoaded', () => {
    const LANG_STORAGE_KEY = 'ace-player-lang';

    const app = {
        // --- CONFIGURATION ---
        // Same-origin path: the engine serves this page, so it works for any host, IP or port.
        // content_id is the current parameter name per https://docs.acestream.net/developers/
        // ("id" is a deprecated alias); both work live but content_id is the documented one.
        BASE_STREAM_URL: '/ace/manifest.m3u8?transcode_audio=1&content_id=',
        ACESTREAM_PREFIX: "acestream://",
        HASH_RE: /^[a-f0-9]{40}$/,

        // --- STATE ---
        state: {
            currentLang: null,
            lastErrorType: null,
            panelVisible: true,
            awaitingFirstPlay: false,
            failureHandled: false,
        },
        t: null,
        loadTimer: null,

        // --- DOM ELEMENTS ---
        elements: {
            player: null,
            inputPanel: document.getElementById('input-panel'),
            toggleBtn: document.getElementById('toggle-panel-btn'),
            playBtn: document.getElementById('play-button'),
            linkInput: document.getElementById('acestream-link-input'),
            inputLabel: document.getElementById('input-label'),
            langControls: document.getElementById('lang-controls'),
            inputForm: document.getElementById('input-form'),
            errorMessage: document.getElementById('error-message'),
            loadingOverlay: document.getElementById('loading-overlay'),
            loadingText: document.getElementById('loading-text'),
            pressPlayHint: document.getElementById('press-play-hint'),
            pressPlayText: document.getElementById('press-play-text'),
            titleText: document.getElementById('title-text'),
            subtitleText: document.getElementById('subtitle-text'),
            helpLabel: document.getElementById('help-label'),
            helpBody: document.getElementById('help-body'),
            attributionLink: document.getElementById('attribution-link'),
        },

        // --- TRANSLATIONS ---
        // Every user-visible string must exist in both EN and ES.
        translations: {
            en: {
                lang: 'en',
                title: 'Ace Stream Player',
                subtitle: 'Paste an Ace Stream link or content ID below and press Play.',
                placeholder: 'acestream://... or 40-character ID',
                play: 'Play',
                inputLabel: 'Ace Stream link or content ID',
                helpLabel: 'Where do I get a link?',
                helpBody: 'A link looks like <code>acestream://&lt;40 characters&gt;</code> and comes from the channel list or community where you found the stream.',
                loading: 'Connecting to the stream... this can take 10-30 seconds.',
                noPeers: 'No peers found for this stream. It may be offline right now, or your network may be blocking Ace Stream. Try another link or try again later.',
                showPanel: 'Show panel',
                hidePanel: 'Hide panel',
                playbackFailed: 'Could not load the stream. The link may be offline or wrong. Try another one.',
                invalidFormat: 'That is not a valid Ace Stream link. It should be acestream:// followed by 40 characters (letters a-f and numbers).',
                emptyInput: 'Please enter an Ace Stream link or content ID first.',
                pressPlay: 'Ready. Press the play button to start watching.',
                githubTitle: 'View project on GitHub (opens in a new tab)',
            },
            es: {
                lang: 'es',
                title: 'Reproductor Ace Stream',
                subtitle: 'Pega abajo un enlace Ace Stream o un ID de contenido y pulsa Reproducir.',
                placeholder: 'acestream://... o ID de 40 caracteres',
                play: 'Reproducir',
                inputLabel: 'Enlace Ace Stream o ID de contenido',
                helpLabel: '¿De dónde saco un enlace?',
                helpBody: 'Un enlace tiene la forma <code>acestream://&lt;40 caracteres&gt;</code> y lo obtienes de la lista de canales o la comunidad donde encontraste el stream.',
                loading: 'Conectando con el stream... puede tardar entre 10 y 30 segundos.',
                noPeers: 'No se encontraron peers para este stream. Puede estar caído ahora mismo, o tu red podría estar bloqueando Ace Stream. Prueba otro enlace o inténtalo más tarde.',
                showPanel: 'Mostrar panel',
                hidePanel: 'Ocultar panel',
                playbackFailed: 'No se pudo cargar el stream. El enlace puede estar caído o ser incorrecto. Prueba con otro.',
                invalidFormat: 'Eso no es un enlace Ace Stream válido. Debe ser acestream:// seguido de 40 caracteres (letras a-f y números).',
                emptyInput: 'Introduce primero un enlace Ace Stream o un ID de contenido.',
                pressPlay: 'Listo. Pulsa el botón de reproducción para empezar a ver.',
                githubTitle: 'Ver proyecto en GitHub (se abre en una pestaña nueva)',
            }
        },

        // --- INITIALIZATION ---
        init() {
            this.elements.player = videojs("video", { fluid: true });
            this.addEventListeners();
            this.changeLanguage(this.detectLanguage());

            const deepLink = this.parseDeepLink();
            if (deepLink) {
                this.loadAceStream(deepLink);
            }
        },

        // Priority: an explicit earlier choice in localStorage, then the
        // browser's language, then English.
        detectLanguage() {
            const stored = localStorage.getItem(LANG_STORAGE_KEY);
            if (stored && this.translations[stored]) return stored;
            const nav = (navigator.language || '').toLowerCase();
            return nav.indexOf('es') === 0 ? 'es' : 'en';
        },

        // ?id=<40-hex> takes priority; otherwise accept acestream:// or a
        // bare 40-hex id in the URL hash (e.g. shared as #<id>).
        parseDeepLink() {
            const params = new URLSearchParams(location.search);
            const idParam = params.get('id');
            if (idParam) return idParam.trim();

            let hash = location.hash.replace(/^#/, '');
            if (!hash) return null;
            try {
                hash = decodeURIComponent(hash);
            } catch (e) {
                // Malformed percent-encoding: fall through with the raw value,
                // loadAceStream() will reject it as an invalid format anyway.
            }
            return hash.trim();
        },

        // --- EVENT LISTENERS ---
        addEventListeners() {
            this.elements.toggleBtn.addEventListener('click', () => this.togglePanel());
            this.elements.inputForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.loadAceStream(this.elements.linkInput.value.trim());
            });
            this.elements.linkInput.addEventListener('input', () => {
                this.hideError();
                this.clearInputInvalid();
            });
            this.elements.langControls.querySelectorAll('.lang-button').forEach(btn => {
                btn.addEventListener('click', () => this.selectLanguage(btn.dataset.lang));
            });
            // Drive UI from real playback events instead of guessing.
            this.elements.player.on('play', () => this.hidePressPlayHint());
            this.elements.player.on('playing', () => {
                this.clearLoadTimer();
                this.hideLoading();
                this.hidePressPlayHint();
                // A real 'playing' event means the stream is fine now, even if a
                // slow/flaky swarm made the safety-net timeout show "no peers"
                // earlier: clear that stale banner instead of leaving it stuck.
                if (this.state.lastErrorType) {
                    this.hideError();
                }
                // Auto-hide the panel only on the first successful play after a
                // load (possibly delayed past the safety-net timeout), not on
                // every buffer-resume 'playing' event.
                if (this.state.awaitingFirstPlay) {
                    this.state.awaitingFirstPlay = false;
                    this.togglePanel(false);
                }
            });
            this.elements.player.on('error', () => this.handleFailure());
        },

        // --- CORE LOGIC ---
        loadAceStream(link) {
            this.hideError();
            this.clearInputInvalid();

            if (!link) {
                this.showError('emptyInput');
                this.markInputInvalid();
                return;
            }

            const playerId = link.replace(this.ACESTREAM_PREFIX, '').toLowerCase();
            const isValidHash = this.HASH_RE.test(playerId);

            if (!isValidHash) {
                this.showError('invalidFormat');
                this.markInputInvalid();
                return;
            }

            this.elements.linkInput.value = link;
            document.title = `Ace Link [${playerId.substr(0, 7)}]`;

            // Bookmarkable/shareable URL for this stream.
            const shareUrl = `${location.pathname}?id=${playerId}`;
            history.replaceState(null, '', shareUrl);

            this.state.awaitingFirstPlay = true;
            this.state.failureHandled = false;
            this.hidePressPlayHint();
            this.showLoading();
            this.startLoadTimer();

            this.elements.player.src({
                src: this.BASE_STREAM_URL + playerId,
                type: 'application/x-mpegURL',
            });

            const playPromise = this.elements.player.play();

            if (playPromise !== undefined) {
                playPromise.catch((error) => {
                    if (error && error.name === 'NotAllowedError') {
                        // Not a real failure: the browser blocked autoplay because
                        // there was no user gesture (e.g. a deep link on page load).
                        // The stream keeps loading in the background; just prompt
                        // the user to press the (visible) big play button.
                        this.hideLoading();
                        this.showPressPlayHint();
                        return;
                    }
                    console.error('Video playback error:', error);
                    this.handleFailure();
                });
            }
        },

        // Single guarded failure path: the play() rejection and the video.js
        // 'error' event can both fire for one failure, so dedupe them here.
        handleFailure() {
            if (this.state.failureHandled) return;
            this.state.failureHandled = true;
            // Deliberately leave awaitingFirstPlay untouched: a genuine fatal
            // error rarely recovers, but if it does, 'playing' should still be
            // free to clear this message and hide the panel.
            this.clearLoadTimer();
            this.hideLoading();
            this.hidePressPlayHint();
            this.showError('playbackFailed');
            this.togglePanel(true);
        },

        // Safety net so the spinner can never get stuck: if nothing plays and
        // no error fires (e.g. peers never found), surface a clear message.
        startLoadTimer() {
            this.clearLoadTimer();
            this.loadTimer = setTimeout(() => {
                if (this.state.failureHandled) return;
                this.state.failureHandled = true;
                // Leave awaitingFirstPlay as-is: a slow swarm can still find
                // peers after this notice; 'playing' will clean up if it does.
                this.hideLoading();
                this.hidePressPlayHint();
                this.showError('noPeers');
                this.togglePanel(true);
            }, 45000);
        },

        clearLoadTimer() {
            if (this.loadTimer) {
                clearTimeout(this.loadTimer);
                this.loadTimer = null;
            }
        },

        showLoading() {
            this.elements.loadingOverlay.classList.add('visible');
        },

        hideLoading() {
            this.elements.loadingOverlay.classList.remove('visible');
        },

        showPressPlayHint() {
            this.elements.pressPlayText.innerText = this.t.pressPlay;
            this.elements.pressPlayHint.classList.add('visible');
        },

        hidePressPlayHint() {
            this.elements.pressPlayHint.classList.remove('visible');
        },

        togglePanel(forceState) {
            const show = forceState === true || (forceState === undefined && !this.state.panelVisible);
            this.state.panelVisible = show;

            this.elements.inputPanel.classList.toggle('hidden', !show);
            this.elements.toggleBtn.classList.toggle('panel-hidden', !show);

            const label = show ? this.t.hidePanel : this.t.showPanel;
            this.elements.toggleBtn.setAttribute('aria-label', label);
            this.elements.toggleBtn.setAttribute('aria-expanded', String(show));
        },

        showError(errorType) {
            this.state.lastErrorType = errorType;
            this.elements.errorMessage.innerText = this.t[errorType];
            this.elements.errorMessage.style.display = 'block';
        },

        hideError() {
            this.state.lastErrorType = null;
            this.elements.errorMessage.style.display = 'none';
            this.elements.errorMessage.innerText = '';
        },

        markInputInvalid() {
            this.elements.linkInput.setAttribute('aria-invalid', 'true');
            this.elements.linkInput.setAttribute('aria-describedby', 'error-message');
        },

        clearInputInvalid() {
            this.elements.linkInput.removeAttribute('aria-invalid');
            this.elements.linkInput.removeAttribute('aria-describedby');
        },

        // Persist an explicit user choice, then apply it.
        selectLanguage(lang) {
            localStorage.setItem(LANG_STORAGE_KEY, lang);
            this.changeLanguage(lang);
        },

        changeLanguage(lang) {
            const t = this.translations[lang] || this.translations.en;
            this.t = t;
            this.state.currentLang = t.lang;

            document.documentElement.lang = t.lang;
            this.elements.titleText.innerText = t.title;
            this.elements.subtitleText.innerText = t.subtitle;
            this.elements.linkInput.placeholder = t.placeholder;
            this.elements.inputLabel.innerText = t.inputLabel;
            this.elements.playBtn.innerText = t.play;
            this.elements.helpLabel.innerText = t.helpLabel;
            this.elements.helpBody.innerHTML = t.helpBody;
            this.elements.loadingText.innerText = t.loading;
            this.elements.attributionLink.setAttribute('aria-label', t.githubTitle);
            this.elements.attributionLink.setAttribute('title', t.githubTitle);

            if (this.elements.player && typeof this.elements.player.language === 'function') {
                this.elements.player.language(t.lang);
            }

            // Re-render a visible error or hint in the new language.
            if (this.state.lastErrorType) {
                this.elements.errorMessage.innerText = t[this.state.lastErrorType];
            }
            if (this.elements.pressPlayHint.classList.contains('visible')) {
                this.elements.pressPlayText.innerText = t.pressPlay;
            }

            // Keep the toggle button's accessible name in sync.
            const label = this.state.panelVisible ? t.hidePanel : t.showPanel;
            this.elements.toggleBtn.setAttribute('aria-label', label);

            // Highlight the active language button.
            this.elements.langControls.querySelectorAll('.lang-button').forEach(btn => {
                btn.classList.toggle('active', btn.dataset.lang === lang);
                btn.setAttribute('aria-pressed', String(btn.dataset.lang === lang));
            });
        }
    };

    // Expose for debugging/console use.
    window.app = app;
    app.init();
});
