document.addEventListener('DOMContentLoaded', function() {
    var containers = document.querySelectorAll('.tabs-container');

    containers.forEach(function(container) {
        var headerTabs = container.querySelectorAll('.tabs-header .tab');
        var contentTabs = container.querySelectorAll('.tabs-body .tab-content');

        headerTabs.forEach(function(tab) {
            tab.addEventListener('click', function() {
                var tabIndex = this.getAttribute('data-tab');

                // Remove active from all tabs in this container
                headerTabs.forEach(function(t) {
                    t.classList.remove('active');
                });
                contentTabs.forEach(function(c) {
                    c.classList.remove('active');
                });

                // Add active to clicked tab
                this.classList.add('active');
                container.querySelector('.tabs-body .tab-content[data-tab="' + tabIndex + '"]').classList.add('active');
            });
        });
    });
});
