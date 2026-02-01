// App initialization
document.addEventListener('DOMContentLoaded', function() {
    // Get configuration (injected at build time)
    const config = window.APP_CONFIG || {
        greetingName: 'World',
        environment: 'local',
        version: '1.0.0',
        deployTime: new Date().toISOString()
    };

    // Set the greeting
    const greetingEl = document.getElementById('greeting');
    greetingEl.textContent = `Hello, ${config.greetingName}! Welcome to the DevOps Journey 🎉`;

    // Set environment badge
    const envNameEl = document.getElementById('env-name');
    envNameEl.textContent = config.environment;
    envNameEl.classList.add(config.environment.toLowerCase());

    // Set deploy info
    document.getElementById('deploy-time').textContent = formatDate(config.deployTime);
    document.getElementById('version').textContent = config.version;
});

function formatDate(isoString) {
    try {
        const date = new Date(isoString);
        return date.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch {
        return isoString;
    }
}
