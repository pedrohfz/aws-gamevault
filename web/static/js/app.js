const API_URL = document.querySelector('meta[name="api-url"]').content.replace(/\/$/, '');

const els = {
    gameList: document.getElementById('gameList'),
    btnNew: document.getElementById('btnNew'),
    btnReport: document.getElementById('btnReport'),
    modalForm: document.getElementById('modalForm'),
    modalReport: document.getElementById('modalReport'),
    modalTitle: document.getElementById('modalTitle'),
    btnCloseForm: document.getElementById('btnCloseForm'),
    btnCancelForm: document.getElementById('btnCancelForm'),
    btnCloseReport: document.getElementById('btnCloseReport'),
    gameForm: document.getElementById('gameForm'),
    btnSubmit: document.getElementById('btnSubmit'),
    reportBody: document.getElementById('reportBody'),
    toast: document.getElementById('toast'),
    fields: {
        id: document.getElementById('gameId'),
        name: document.getElementById('name'),
        genre: document.getElementById('genre'),
        platform: document.getElementById('platform'),
        rating: document.getElementById('rating'),
        release_year: document.getElementById('release_year'),
    },
};

async function api(path, options = {}) {
    const res = await fetch(`${API_URL}${path}`, {
        headers: { 'Content-Type': 'application/json' },
        ...options,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
        throw new Error(data.error || `Erro ${res.status}`);
    }
    return data;
}

function showToast(msg, type = 'success') {
    els.toast.textContent = msg;
    els.toast.className = `toast ${type}`;
    els.toast.hidden = false;
    setTimeout(() => { els.toast.hidden = true; }, 3000);
}

function showModal(modal) { modal.hidden = false; }
function hideModal(modal) { modal.hidden = true; }

function escapeHtml(str) {
    return String(str).replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
}

function renderGameCard(game) {
    return `
        <article class="game-card" data-id="${game.id}">
            <div class="rating-box">
                <span class="star">★</span>
                <span class="value">${Number(game.rating).toFixed(1)}</span>
            </div>
            <div class="game-info">
                <h3 class="game-name">${escapeHtml(game.name)}</h3>
                <p class="game-meta">
                    ${escapeHtml(game.genre)} · ${escapeHtml(game.platform)} · ${game.release_year}
                </p>
                <div class="actions">
                    <button class="btn btn-edit" data-action="edit" data-id="${game.id}">Editar</button>
                    <button class="btn btn-danger btn-edit" data-action="delete" data-id="${game.id}">Excluir</button>
                </div>
            </div>
        </article>
    `;
}

async function loadGames() {
    els.gameList.innerHTML = '<div class="loader">Carregando catalogo...</div>';
    try {
        const games = await api('/games');
        if (!games || games.length === 0) {
            els.gameList.innerHTML = `
                <div class="empty-state">
                    <h3>Cofre vazio</h3>
                    <p>Adicione o primeiro jogo ao seu catalogo.</p>
                </div>
            `;
            return;
        }
        els.gameList.innerHTML = games.map(renderGameCard).join('');
    } catch (err) {
        els.gameList.innerHTML = `<div class="empty-state"><h3>Erro ao carregar</h3><p>${escapeHtml(err.message)}</p></div>`;
        showToast(err.message, 'error');
    }
}

function openCreateModal() {
    els.modalTitle.textContent = 'Novo Jogo';
    els.gameForm.reset();
    els.fields.id.value = '';
    showModal(els.modalForm);
    els.fields.name.focus();
}

async function openEditModal(id) {
    try {
        const game = await api(`/games/${id}`);
        els.modalTitle.textContent = 'Editar Jogo';
        els.fields.id.value = game.id;
        els.fields.name.value = game.name;
        els.fields.genre.value = game.genre;
        els.fields.platform.value = game.platform;
        els.fields.rating.value = game.rating;
        els.fields.release_year.value = game.release_year;
        showModal(els.modalForm);
        els.fields.name.focus();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function submitGame(event) {
    event.preventDefault();

    const id = els.fields.id.value;
    const payload = {
        name: els.fields.name.value.trim(),
        genre: els.fields.genre.value.trim(),
        platform: els.fields.platform.value.trim(),
        rating: parseFloat(els.fields.rating.value),
        release_year: parseInt(els.fields.release_year.value, 10),
    };

    els.btnSubmit.disabled = true;
    els.btnSubmit.textContent = 'Salvando...';

    try {
        if (id) {
            await api(`/games/${id}`, { method: 'PUT', body: JSON.stringify(payload) });
            showToast('Jogo atualizado');
        } else {
            await api('/games', { method: 'POST', body: JSON.stringify(payload) });
            showToast('Jogo adicionado');
        }
        hideModal(els.modalForm);
        await loadGames();
    } catch (err) {
        showToast(err.message, 'error');
    } finally {
        els.btnSubmit.disabled = false;
        els.btnSubmit.textContent = 'Salvar';
    }
}

async function deleteGame(id) {
    if (!confirm('Remover este jogo do catalogo?')) return;
    try {
        await api(`/games/${id}`, { method: 'DELETE' });
        showToast('Jogo removido');
        await loadGames();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function loadReport() {
    showModal(els.modalReport);
    els.reportBody.innerHTML = '<div class="loader">Calculando estatisticas...</div>';

    try {
        const r = await api('/report');

        const genreList = Object.entries(r.games_by_genre || {})
            .sort((a, b) => b[1] - a[1])
            .map(([k, v]) => `<li><span>${escapeHtml(k)}</span><span class="count">${v}</span></li>`)
            .join('');

        const platformList = Object.entries(r.games_by_platform || {})
            .sort((a, b) => b[1] - a[1])
            .map(([k, v]) => `<li><span>${escapeHtml(k)}</span><span class="count">${v}</span></li>`)
            .join('');

        const highest = r.highest_rated
            ? `<div class="value">${Number(r.highest_rated.rating).toFixed(1)}</div><div class="sub-value">${escapeHtml(r.highest_rated.name)}</div>`
            : '<div class="sub-value">—</div>';

        const lowest = r.lowest_rated
            ? `<div class="value">${Number(r.lowest_rated.rating).toFixed(1)}</div><div class="sub-value">${escapeHtml(r.lowest_rated.name)}</div>`
            : '<div class="sub-value">—</div>';

        els.reportBody.innerHTML = `
            <div class="report-card">
                <div class="label">Total de Jogos</div>
                <div class="value">${r.total_games || 0}</div>
            </div>
            <div class="report-card">
                <div class="label">Rating Medio</div>
                <div class="value">${Number(r.average_rating || 0).toFixed(2)}</div>
            </div>
            <div class="report-card">
                <div class="label">Maior Rating</div>
                ${highest}
            </div>
            <div class="report-card">
                <div class="label">Menor Rating</div>
                ${lowest}
            </div>
            <div class="report-card full-width">
                <div class="label">Por Genero</div>
                <ul>${genreList || '<li><span>Sem dados</span></li>'}</ul>
            </div>
            <div class="report-card full-width">
                <div class="label">Por Plataforma</div>
                <ul>${platformList || '<li><span>Sem dados</span></li>'}</ul>
            </div>
        `;
    } catch (err) {
        els.reportBody.innerHTML = `<div class="empty-state"><h3>Erro ao gerar relatorio</h3><p>${escapeHtml(err.message)}</p></div>`;
    }
}

els.btnNew.addEventListener('click', openCreateModal);
els.btnReport.addEventListener('click', loadReport);
els.btnCloseForm.addEventListener('click', () => hideModal(els.modalForm));
els.btnCancelForm.addEventListener('click', () => hideModal(els.modalForm));
els.btnCloseReport.addEventListener('click', () => hideModal(els.modalReport));
els.gameForm.addEventListener('submit', submitGame);

[els.modalForm, els.modalReport].forEach(modal => {
    modal.addEventListener('click', e => {
        if (e.target === modal) hideModal(modal);
    });
});

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        hideModal(els.modalForm);
        hideModal(els.modalReport);
    }
});

els.gameList.addEventListener('click', e => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const id = btn.dataset.id;
    if (btn.dataset.action === 'edit') openEditModal(id);
    else if (btn.dataset.action === 'delete') deleteGame(id);
});

loadGames();
