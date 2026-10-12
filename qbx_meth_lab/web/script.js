let labData = null;
let dealerChart = null;
let workerChart = null;

const ADDITIVES = [
    { name: 'weed_nutrition', label: 'Weed Nutrition' },
    { name: 'aluminumoxide', label: 'Aluminum Oxide' },
    { name: 'nitrous', label: 'Nitrous Oxide' },
    { name: 'jerry_can', label: 'Jerry Can' },
    { name: 'painkillers', label: 'Painkillers' },
    { name: 'saltsyre', label: 'Salt Syrup' },
    { name: 'efedrin', label: 'Ephedrine' },
    { name: 'bkr_prop_meth_lithium', label: 'Lithium' },
    { name: 'bkr_prop_meth_hcacid', label: 'HCl Acid' },
    { name: 'bkr_prop_meth_phosphorus', label: 'Phosphorus' },
    { name: 'bkr_prop_meth_ammonia', label: 'Ammonia' },
    { name: 'bkr_prop_meth_sacid', label: 'Sulfuric Acid' }
];

const SUPPLIES = [
    { item: 'bkr_prop_meth_sodium', label: 'Sodium', price: 100, amount: 10 },
    { item: 'bkr_prop_meth_acetone', label: 'Acetone', price: 80, amount: 10 },
    { item: 'bkr_prop_meth_toulene', label: 'Toluene', price: 80, amount: 5 },
    { item: 'bkr_prop_meth_hcacid', label: 'HCl Acid', price: 60, amount: 5 },
    { item: 'bkr_prop_meth_sacid', label: 'Sulfuric Acid', price: 80, amount: 5 },
    { item: 'bkr_prop_meth_lithium', label: 'Lithium', price: 170, amount: 5 },
    { item: 'bkr_prop_meth_phosphorus', label: 'Phosphorus', price: 165, amount: 5 },
    { item: 'bkr_prop_meth_ammonia', label: 'Ammonia', price: 55, amount: 5 },
    { item: 'efedrin', label: 'Ephedrine', price: 100, amount: 15 },
    { item: 'weed_nutrition', label: 'Weed Nutrition', price: 40, amount: 5 },
    { item: 'aluminumoxide', label: 'Alum. Oxide', price: 45, amount: 5 },
    { item: 'nitrous', label: 'Nitrous', price: 90, amount: 8 },
    { item: 'jerry_can', label: 'Jerry Can', price: 120, amount: 3 },
    { item: 'painkillers', label: 'Painkillers', price: 35, amount: 10 },
    { item: 'saltsyre', label: 'Salt Syrup', price: 30, amount: 10 }
];

const CHART_COLORS = ['#f472b6', '#a78bfa', '#60a5fa', '#34d399', '#fbbf24'];

// ============================================================
// NUI MESSAGE HANDLER
// ============================================================
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'open') {
        labData = data.data;
        document.getElementById('app').classList.remove('hidden');
        renderAll();
    }
    if (data.action === 'updateData') {
        labData = data.data;
        renderAll();
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        document.getElementById('app').classList.add('hidden');
        closeUI();
    }
});

// ============================================================
// TABS
// ============================================================
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        this.classList.add('active');
        document.getElementById('tab-' + this.dataset.tab).classList.add('active');
    });
});

// ============================================================
// RANGE SLIDERS
// ============================================================
document.querySelectorAll('input[type="range"]').forEach(slider => {
    slider.addEventListener('input', function() {
        const valEl = document.getElementById(this.id + '-val');
        if (valEl) {
            valEl.textContent = this.value + (this.id.includes('freezer') || this.id.includes('heater') ? '°C' : '');
        }
    });
});

// ============================================================
// RENDER ALL
// ============================================================
function renderAll() {
    renderBuyCard();
    renderWorkers();
    renderDealers();
    renderSupplies();
    renderStorage();
    renderAdditives('meth');
    renderAdditives('coke');
    renderAdditives('oxy');
    renderAdditives('pill');
    loadMachineConfigs();
    renderSavedConfigs();
    renderMachineStatus();
    renderBank();
    renderSettings();
    renderDoorPos();
    renderCharts();
    renderDashboard();
}

function renderDashboard() {
    let w = labData && labData.workers ? labData.workers : [];
    let d = labData && labData.dealers ? labData.dealers : [];
    if (!Array.isArray(w)) w = Object.values(w);
    if (!Array.isArray(d)) d = Object.values(d);
    const wEl = document.getElementById('dash-workers');
    const dEl = document.getElementById('dash-dealers');
    const cEl = document.getElementById('dash-cash');
    if (wEl) wEl.textContent = w.length;
    if (dEl) dEl.textContent = d.length;
    if (cEl && labData) cEl.textContent = '$' + (labData.lab_cash || 0).toLocaleString();
}   

// ============================================================
// RENDER: BUY LAB CARD
// ============================================================
function renderBuyCard() {
    const buyCard = document.getElementById('buy-lab-card');
    if (buyCard) {
        buyCard.style.display = (!labData || !labData.owned) ? 'block' : 'none';
    }
    const upgradeCard = document.getElementById('upgrade-card');
    if (upgradeCard) {
        upgradeCard.style.display = (labData && labData.owned && !labData.upgraded) ? 'block' : 'none';
    }
}

// ============================================================
// RENDER: WORKERS
// ============================================================
function renderWorkers() {
    const el = document.getElementById('workers-list');
    if (!el) return;
    let workers = labData && labData.workers ? labData.workers : [];
    if (!Array.isArray(workers)) workers = Object.values(workers);
    if (workers.length === 0) {
        el.innerHTML = '<p class="empty">No workers hired.</p>';
        return;
    }
    el.innerHTML = workers.map((w, i) => `
        <div class="list-item">
            <span class="item-name">👷 ${w.name || 'Worker ' + (i+1)} <small class="stat-badge">${w.unitsManufactured || 0} units</small></span>
            <button class="btn btn-danger btn-sm" onclick="fireWorker(${i + 1})">Fire</button>
        </div>
    `).join('');
}

function renderDealers() {
    const el = document.getElementById('dealers-list');
    if (!el) return;
    let dealers = labData && labData.dealers ? labData.dealers : [];
    if (!Array.isArray(dealers)) dealers = Object.values(dealers);
    if (dealers.length === 0) {
        el.innerHTML = '<p class="empty">No dealers hired.</p>';
        return;
    }
    el.innerHTML = dealers.map((d, i) => {
        let status = '💤 Idle in lab';
        if (d.selling) status = '💰 Out selling...';
        return `
        <div class="list-item">
            <span class="item-name">🧑‍💼 ${d.name || 'Dealer ' + (i+1)} <small class="stat-badge">${d.unitsSold || 0} sold</small> <small class="dealer-status">${status}</small></span>
            <span class="item-amount">$${(d.totalEarned || 0).toLocaleString()}</span>   
            <button class="btn btn-danger btn-sm" onclick="fireDealer(${i + 1})">Fire</button>
        </div>`;
    }).join('');
}

function renderDashboard() {
    let w = labData && labData.workers ? labData.workers : [];
    let d = labData && labData.dealers ? labData.dealers : [];
    if (!Array.isArray(w)) w = Object.values(w);
    if (!Array.isArray(d)) d = Object.values(d);
    const wEl = document.getElementById('dash-workers');
    const dEl = document.getElementById('dash-dealers');
    const cEl = document.getElementById('dash-cash');
    if (wEl) wEl.textContent = w.length;
    if (dEl) dEl.textContent = d.length;
    if (cEl && labData) cEl.textContent = '$' + (labData.lab_cash || 0).toLocaleString();
} 

// ============================================================
// RENDER: SUPPLIES
// ============================================================
function renderSupplies() {
    const el = document.getElementById('supplies-grid');
    if (!el) return;
    el.innerHTML = SUPPLIES.map((s, i) => `
        <div class="supply-item" onclick="buySupply(${i + 1})">
            <img src="images/${s.item}.png" alt="${s.label}" onerror="this.style.display='none'">
            <div class="name">${s.label}</div>
            <div class="price">$${s.price} / ${s.amount}x</div>
            <div class="stock">In storage: ${labData && labData.storage && labData.storage[s.item] ? labData.storage[s.item] : 0}</div>
        </div>
    `).join('');
}

// ============================================================
// RENDER: STORAGE
// ============================================================
function renderStorage() {
    const el = document.getElementById('storage-list');
    if (!el) return;
    if (!labData || !labData.storage) {
        el.innerHTML = '<p class="empty">Storage empty.</p>';
        return;
    }
    const items = Object.entries(labData.storage).filter(([k, v]) => v > 0);
    if (items.length === 0) {
        el.innerHTML = '<p class="empty">Storage empty.</p>';
        return;
    }
    el.innerHTML = items.map(([name, amount]) => `
        <div class="list-item">
            <span class="item-name">${name.replace('bkr_prop_meth_', '').replace('bkr_prop_', '').replace(/_/g, ' ')}</span>
            <span class="item-amount">x${amount}</span>
            <button class="btn btn-primary btn-sm" onclick="retrieveItem('${name}', 1)">Take 1</button>
            <button class="btn btn-primary btn-sm" onclick="retrieveItem('${name}', ${amount})">Take All</button>
        </div>
    `).join('');
}

// ============================================================
// RENDER: ADDITIVES
// ============================================================
function renderAdditives(prefix) {
    const el = document.getElementById(prefix + '-additives');
    if (!el) return;
    el.innerHTML = ADDITIVES.map(a => `
        <label class="additive-check">
            <input type="checkbox" value="${a.name}">
            <span>${a.label}</span>
        </label>
    `).join('');
}

// ============================================================
// RENDER: SAVED CONFIGS
// ============================================================
function renderSavedConfigs() {
    if (!labData || !labData.machines) return;
    const mapping = { meth: 'meth', cocaine: 'coke', oxy: 'oxy', pill: 'pill' };

    for (const [type, prefix] of Object.entries(mapping)) {
        const machine = labData.machines[type];
        if (!machine) continue;

        const selectEl = document.getElementById(prefix + '-saved-list');
        if (!selectEl) continue;

        const savedConfigs = machine.savedConfigs || [];
        const activeName = machine.config ? machine.config.name : null;

        selectEl.innerHTML = '<option value="">-- Select a saved config --</option>' +
            savedConfigs.map(cfg => `
                <option value="${cfg.name}" ${cfg.name === activeName ? 'selected' : ''}>${cfg.name}</option>
            `).join('');

        const delBtn = document.getElementById(prefix + '-del-config');
        if (delBtn) {
            delBtn.style.display = savedConfigs.length > 0 ? 'inline-block' : 'none';
        }
    }
}

// ============================================================
// RENDER: MACHINE CONFIGS
// ============================================================
function loadMachineConfigs() {
    if (!labData || !labData.machines) return;
    const types = ['meth', 'cocaine', 'oxy', 'pill'];
    types.forEach(type => {
        const machine = labData.machines[type];
        if (!machine || !machine.config) return;
        const prefix = type === 'cocaine' ? 'coke' : type;
        const config = machine.config;

        const nameEl = document.getElementById(prefix + '-config-name');
        const strainEl = document.getElementById(prefix + '-strain');
        const freezerEl = document.getElementById(prefix + '-freezer');
        const heaterEl = document.getElementById(prefix + '-heater');
        const qtyEl = document.getElementById(prefix + '-qty');

        if (nameEl) nameEl.value = config.name || '';
        if (strainEl) strainEl.value = config.strain || '';
        if (freezerEl && config.freezerTemp !== undefined) {
            freezerEl.value = config.freezerTemp;
            const valEl = document.getElementById(prefix + '-freezer-val');
            if (valEl) valEl.textContent = config.freezerTemp + '°C';
        }
        if (heaterEl && config.heaterTemp !== undefined) {
            heaterEl.value = config.heaterTemp;
            const valEl = document.getElementById(prefix + '-heater-val');
            if (valEl) valEl.textContent = config.heaterTemp + '°C';
        }
        if (qtyEl && config.quantity !== undefined) {
            qtyEl.value = config.quantity;
            const valEl = document.getElementById(prefix + '-qty-val');
            if (valEl) valEl.textContent = config.quantity;
        }

        if (config.additives && Array.isArray(config.additives)) {
            document.querySelectorAll(`#${prefix}-additives input`).forEach(input => {
                input.checked = config.additives.includes(input.value);
            });
        }
    });
}

// ============================================================
// RENDER: MACHINE STATUS
// ============================================================
function renderMachineStatus() {
    if (!labData || !labData.machines) return;
    const mapping = { meth: 'meth', cocaine: 'coke', oxy: 'oxy', pill: 'pill' };

    for (const [type, prefix] of Object.entries(mapping)) {
        const machine = labData.machines[type];
        if (!machine) continue;

        const statusEl = document.getElementById(prefix + '-status');
        const progressWrap = document.getElementById(prefix + '-progress-wrap');
        const progressFill = document.getElementById(prefix + '-progress');
        const progressText = document.getElementById(prefix + '-progress-text');
        const startBtn = document.getElementById(prefix + '-start-btn');
        const stopBtn = document.getElementById(prefix + '-stop-btn');

        if (machine.active) {
            if (statusEl) { statusEl.textContent = 'Running'; statusEl.classList.add('active'); }
            if (progressWrap) progressWrap.style.display = 'flex';
            if (machine.duration > 0) {
                const pct = Math.min(100, Math.floor((machine.progress / machine.duration) * 100));
                if (progressFill) progressFill.style.width = pct + '%';
                if (progressText) progressText.textContent = pct + '%';
            } else {
                if (progressFill) progressFill.style.width = '100%';
                if (progressText) progressText.textContent = 'Auto';
            }
            if (startBtn) startBtn.style.display = 'none';
            if (stopBtn) stopBtn.style.display = 'inline-block';
        } else {
            if (statusEl) { statusEl.textContent = 'Idle'; statusEl.classList.remove('active'); }
            if (progressWrap) progressWrap.style.display = 'none';
            if (startBtn) startBtn.style.display = 'inline-block';
            if (stopBtn) stopBtn.style.display = 'none';
        }
    }
}

// ============================================================
// RENDER: BANK
// ============================================================
function renderBank() {
    const amountEl = document.getElementById('bank-amount');
    if (amountEl && labData) {
        amountEl.textContent = '$' + (labData.lab_cash || 0).toLocaleString();
    }

    const earningsEl = document.getElementById('bank-dealer-earnings');
    if (earningsEl && labData && labData.dealers) {
        if (labData.dealers.length === 0) {
            earningsEl.innerHTML = '<p class="empty">No dealers.</p>';
        } else {
            earningsEl.innerHTML = labData.dealers.map(d => `
                <div class="list-item">
                    <span class="item-name">${d.name}</span>
                    <span class="item-amount">$${(d.moneyCollected || 0).toLocaleString()}</span>
                </div>
            `).join('');
        }
    }
}

// ============================================================
// RENDER: SETTINGS
// ============================================================
function renderSettings() {
    if (!labData || !labData.config) return;
    const c = labData.config;
    const map = {
        'set-workerSalary': c.WorkerSalary,
        'set-dealerSalary': c.DealerSalary,
        'set-transferMin': c.TransferMin,
        'set-maxWorkers': c.MaxWorkers,
        'set-maxDealers': c.MaxDealers,
        'set-manufactureTime': c.CookInterval,
        'set-dealerSellTime': c.SellInterval,
    };
    for (const [id, val] of Object.entries(map)) {
        const el = document.getElementById(id);
        if (el && val !== undefined) el.value = val;
    }
}

// ============================================================
// RENDER: DOOR POSITION
// ============================================================
function renderDoorPos() {
    if (!labData || !labData.doorPosition) return;
    const dx = document.getElementById('set-doorX');
    const dy = document.getElementById('set-doorY');
    const dz = document.getElementById('set-doorZ');
    if (dx) dx.value = labData.doorPosition.x;
    if (dy) dy.value = labData.doorPosition.y;
    if (dz) dz.value = labData.doorPosition.z;
}

// ============================================================
// RENDER: CHARTS
// ============================================================
function renderCharts() {
    if (!labData) return;

    const dealerCanvas = document.getElementById('dealer-chart');
    if (dealerCanvas) {
        const dealers = labData.dealers || [];
        const data = dealers.map((d, i) => ({
            x: d.unitsSold || 0,
            y: d.moneyCollected || 0,
            r: 8 + Math.min(20, (d.unitsSold || 0) * 0.5),
            label: d.name
        }));

        if (dealerChart) {
            dealerChart.data.datasets[0].data = data;
            dealerChart.data.datasets[0].backgroundColor = data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length] + '99');
            dealerChart.data.datasets[0].borderColor = data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length]);
            dealerChart.update('none');
        } else {
            dealerChart = new Chart(dealerCanvas, {
                type: 'bubble',
                data: { datasets: [{ data, backgroundColor: data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length] + '99'), borderColor: data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length]), borderWidth: 2 }] },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: true, position: 'left', labels: { color: '#ccc', generateLabels: (chart) => chart.data.datasets[0].data.map((d, i) => ({ text: d.label, fillStyle: CHART_COLORS[i % CHART_COLORS.length], strokeStyle: CHART_COLORS[i % CHART_COLORS.length], index: i })) } },
                        tooltip: { callbacks: { label: (ctx) => `${ctx.raw.label}: ${ctx.raw.x} units sold, $${ctx.raw.y.toLocaleString()}` } }
                    },
                    scales: {
                        x: { title: { display: true, text: 'Units Sold', color: '#999' }, grid: { color: '#2a2a3e' }, ticks: { color: '#999' } },
                        y: { title: { display: true, text: 'Revenue ($)', color: '#999' }, grid: { color: '#2a2a3e' }, ticks: { color: '#999' } }
                    }
                }
            });
        }
    }

    const workerCanvas = document.getElementById('worker-chart');
    if (workerCanvas) {
        const workers = labData.workers || [];
        const data = workers.map((w, i) => ({
            x: (i + 1),
            y: w.unitsManufactured || 0,
            r: 8 + Math.min(20, (w.unitsManufactured || 0) * 0.5),
            label: w.name
        }));

        if (workerChart) {
            workerChart.data.datasets[0].data = data;
            workerChart.data.datasets[0].backgroundColor = data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length] + '99');
            workerChart.data.datasets[0].borderColor = data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length]);
            workerChart.update('none');
        } else {
            workerChart = new Chart(workerCanvas, {
                type: 'bubble',
                data: { datasets: [{ data, backgroundColor: data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length] + '99'), borderColor: data.map((_, i) => CHART_COLORS[i % CHART_COLORS.length]), borderWidth: 2 }] },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: true, position: 'left', labels: { color: '#ccc', generateLabels: (chart) => chart.data.datasets[0].data.map((d, i) => ({ text: d.label, fillStyle: CHART_COLORS[i % CHART_COLORS.length], strokeStyle: CHART_COLORS[i % CHART_COLORS.length], index: i })) } },
                        tooltip: { callbacks: { label: (ctx) => `${ctx.raw.label}: ${ctx.raw.y} units manufactured` } }
                    },
                    scales: {
                        x: { title: { display: true, text: 'Worker #', color: '#999' }, grid: { color: '#2a2a3e' }, ticks: { color: '#999' } },
                        y: { title: { display: true, text: 'Units Manufactured', color: '#999' }, grid: { color: '#2a2a3e' }, ticks: { color: '#999' } }
                    }
                }
            });
        }
    }
}

// ============================================================
// ACTIONS
// ============================================================
function post(action, data = {}) {
    fetch(`https://qbx_meth_lab/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

function closeUI() {
    document.getElementById('app').classList.add('hidden');
    post('close');
}

function buyLab() { post('buyLab'); }
function hireWorker() { post('hireWorker'); }
function fireWorker(i) { post('fireWorker', { index: i }); }
function hireDealer() { post('hireDealer'); }
function fireDealer(i) { post('fireDealer', { index: i }); }
function refillDealer() { post('refillDealer'); }
function buySupply(i) { post('buySupply', { index: i }); }
function retrieveItem(item, amount) { post('retrieveItem', { item, amount }); }
function upgradeLab() { post('upgradeLab'); }
function startManufacturing(drugType) { post('startManufacturing', { drugType }); }
function stopManufacturing(drugType) { post('stopManufacturing', { drugType }); }

function saveConfig(drugType) {
    const prefix = drugType === 'cocaine' ? 'coke' : drugType;
    const name = document.getElementById(prefix + '-config-name').value.trim();
    if (!name) { alert('Enter a config name (e.g. "Blue Strain")'); return; }
    const config = {
        name: name,
        strain: document.getElementById(prefix + '-strain').value,
        freezerTemp: parseInt(document.getElementById(prefix + '-freezer').value),
        heaterTemp: parseInt(document.getElementById(prefix + '-heater').value),
        quantity: parseInt(document.getElementById(prefix + '-qty').value),
        additives: Array.from(document.querySelectorAll(`#${prefix}-additives input:checked`)).map(c => c.value)
    };
    post('saveConfig', { drugType, config });
}

function selectConfig(drugType, configName) {
    if (!configName) return;
    post('selectConfig', { drugType, configName });
}

function deleteConfig(drugType) {
    const prefix = drugType === 'cocaine' ? 'coke' : drugType;
    const selectEl = document.getElementById(prefix + '-saved-list');
    if (!selectEl || !selectEl.value) { alert('Select a config to delete.'); return; }
    if (!confirm(`Delete config "${selectEl.value}"?`)) return;
    post('deleteConfig', { drugType, configName: selectEl.value });
}

function saveDoorPos() {
    const x = parseFloat(document.getElementById('set-doorX').value);
    const y = parseFloat(document.getElementById('set-doorY').value);
    const z = parseFloat(document.getElementById('set-doorZ').value);
    if (isNaN(x) || isNaN(y) || isNaN(z)) { alert('Enter valid coordinates.'); return; }
    post('saveDoorPos', { x, y, z });
}

function transferToCash() {
    const amount = parseInt(document.getElementById('transfer-amount').value);
    if (!amount || amount < 100) { alert('Minimum $100'); return; }
    post('transferBank', { amount, toBank: false });
    document.getElementById('transfer-amount').value = '';
}

function transferToBank() {
    const amount = parseInt(document.getElementById('transfer-amount').value);
    if (!amount || amount < 100) { alert('Minimum $100'); return; }
    post('transferBank', { amount, toBank: true });
    document.getElementById('transfer-amount').value = '';
}

function saveSettings() {
    const settings = {
        workerSalary: parseInt(document.getElementById('set-workerSalary').value),
        dealerSalary: parseInt(document.getElementById('set-dealerSalary').value),
        transferMin: parseInt(document.getElementById('set-transferMin').value),
        maxWorkers: parseInt(document.getElementById('set-maxWorkers').value),
        maxDealers: parseInt(document.getElementById('set-maxDealers').value),
        manufactureTime: parseInt(document.getElementById('set-manufactureTime').value),
        dealerSellTime: parseInt(document.getElementById('set-dealerSellTime').value),
    };
    post('saveSettings', { settings });
}   