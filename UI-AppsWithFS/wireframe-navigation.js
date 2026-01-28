// Modal Navigation and Interaction Handler
const WireframeNav = {
    // Navigate to a specific wireframe page
    navigateTo: function(url) {
        const overlay = document.querySelector('.modal-overlay');
        if (overlay) {
            overlay.classList.add('fade-out');
            setTimeout(() => {
                window.location.href = url;
            }, 200);
        } else {
            window.location.href = url;
        }
    },

    // Resolve navigation target using WireframeConfig
    resolveNavigationTarget: function(target) {
        // If target is a function, execute it to get the actual URL
        if (typeof target === 'function') {
            return target();
        }
        // If WireframeConfig is available and target references a page key
        if (window.WireframeConfig && window.WireframeConfig.pages[target]) {
            return window.WireframeConfig.pages[target];
        }
        // Otherwise return the target as-is (it's already a URL)
        return target;
    },

    // Close modal and return to previous page
    closeModal: function(returnUrl = 'wireframe-index.html') {
        this.navigateTo(returnUrl);
    },

    // Initialize event listeners
    init: function() {
        // Close button handlers
        document.querySelectorAll('.modal-close, [data-action="close"]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.closeModal();
            });
        });

        // Navigation button handlers
        document.querySelectorAll('[data-navigate]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                const target = btn.getAttribute('data-navigate');
                const resolvedTarget = this.resolveNavigationTarget(target);
                this.navigateTo(resolvedTarget);
            });
        });

        // Radio option selection
        document.querySelectorAll('.radio-option').forEach(option => {
            option.addEventListener('click', () => {
                // Remove selected class from all options
                document.querySelectorAll('.radio-option').forEach(opt => {
                    opt.classList.remove('selected');
                });
                // Add selected class to clicked option
                option.classList.add('selected');
                // Check the radio input
                const radio = option.querySelector('input[type="radio"]');
                if (radio) {
                    radio.checked = true;
                }
                // Enable next button if disabled
                const nextBtn = document.querySelector('[data-navigate]');
                if (nextBtn && nextBtn.disabled) {
                    nextBtn.disabled = false;
                }
            });
        });

        // Handle ESC key to close modal
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                const overlay = document.querySelector('.modal-overlay');
                if (overlay) {
                    this.closeModal();
                }
            }
        });

        // Click outside modal to close
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    this.closeModal();
                }
            });
        });

        // Prevent modal dialog clicks from closing
        document.querySelectorAll('.modal-dialog').forEach(dialog => {
            dialog.addEventListener('click', (e) => {
                e.stopPropagation();
            });
        });
    },

    // Store selected option in session storage
    storeSelection: function(key, value) {
        sessionStorage.setItem(key, value);
    },

    // Retrieve stored selection
    getSelection: function(key) {
        return sessionStorage.getItem(key);
    },

    // Tooltip system
    initTooltips: function() {
        // Create tooltip container if it doesn't exist
        if (!document.getElementById('tooltip-container')) {
            const tooltipContainer = document.createElement('div');
            tooltipContainer.id = 'tooltip-container';
            tooltipContainer.style.cssText = `
                position: fixed;
                background: #333;
                color: #fff;
                padding: 8px 12px;
                border-radius: 4px;
                font-size: 13px;
                max-width: 300px;
                z-index: 10000;
                pointer-events: none;
                opacity: 0;
                transition: opacity 0.2s;
                box-shadow: 0 2px 8px rgba(0,0,0,0.2);
                line-height: 1.4;
            `;
            document.body.appendChild(tooltipContainer);
        }

        const tooltipContainer = document.getElementById('tooltip-container');
        const self = this; // Store reference to WireframeNav context

        // Add tooltip to all elements with data-tooltip attribute
        document.querySelectorAll('[data-tooltip]').forEach(element => {
            element.addEventListener('mouseenter', function(e) {
                const tooltipText = this.getAttribute('data-tooltip');
                if (tooltipText && !this.disabled) {
                    tooltipContainer.textContent = tooltipText;
                    tooltipContainer.style.opacity = '1';
                    self.positionTooltip(e, tooltipContainer);
                }
            });

            element.addEventListener('mousemove', function(e) {
                if (tooltipContainer.style.opacity === '1') {
                    self.positionTooltip(e, tooltipContainer);
                }
            });

            element.addEventListener('mouseleave', function() {
                tooltipContainer.style.opacity = '0';
            });
        });
    },

    // Position tooltip near cursor
    positionTooltip: function(event, tooltip) {
        const offset = 15;
        let x = event.clientX + offset;
        let y = event.clientY + offset;

        // Prevent tooltip from going off-screen
        const tooltipRect = tooltip.getBoundingClientRect();
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;

        if (x + tooltipRect.width > viewportWidth) {
            x = event.clientX - tooltipRect.width - offset;
        }

        if (y + tooltipRect.height > viewportHeight) {
            y = event.clientY - tooltipRect.height - offset;
        }

        tooltip.style.left = x + 'px';
        tooltip.style.top = y + 'px';
    }
};

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        WireframeNav.init();
        WireframeNav.initTooltips();
    });
} else {
    WireframeNav.init();
    WireframeNav.initTooltips();
}
