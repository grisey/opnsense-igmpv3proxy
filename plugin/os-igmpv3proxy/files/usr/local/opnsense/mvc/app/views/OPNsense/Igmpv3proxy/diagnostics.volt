<script>
$(document).ready(function() {
    function loadDiagnostic(endpoint, target) {
        ajaxCall(endpoint, {}, function(data, status) {
            if (status === "success" && data.status === "ok") {
                $(target).text(data.response || "");
            } else {
                $(target).text("No data returned.");
            }
        });
    }

    function loadIgmpv3proxyDiagnostics() {
        loadDiagnostic("/api/igmpv3proxy/diagnostics/config", "#igmpv3proxy_config");
        loadDiagnostic("/api/igmpv3proxy/diagnostics/routes", "#igmpv3proxy_routes");
        loadDiagnostic("/api/igmpv3proxy/diagnostics/interfaces", "#igmpv3proxy_interfaces");
        loadDiagnostic("/api/igmpv3proxy/diagnostics/filters", "#igmpv3proxy_filters");
    }

    $("#refreshDiagnosticsAct").click(function() {
        loadIgmpv3proxyDiagnostics();
    });

    loadIgmpv3proxyDiagnostics();
});
</script>

<section class="page-content-main">
    <div class="content-box">
        <div class="col-md-12">
            <br/>
            <button class="btn btn-default" id="refreshDiagnosticsAct" type="button">
                {{ lang._('Refresh diagnostics') }}
            </button>
            <br/><br/>

            <h2>{{ lang._('Generated configuration') }}</h2>
            <pre id="igmpv3proxy_config" style="white-space: pre; overflow-x: auto; font-family: Courier New, Courier, monospace; font-size: 12px; line-height: 1.2; font-variant-ligatures: none; tab-size: 8;"></pre>

            <h2>{{ lang._('Routes') }}</h2>
            <pre id="igmpv3proxy_routes" style="white-space: pre; overflow-x: auto; font-family: Courier New, Courier, monospace; font-size: 12px; line-height: 1.2; font-variant-ligatures: none; tab-size: 8;"></pre>

            <h2>{{ lang._('Interfaces') }}</h2>
            <pre id="igmpv3proxy_interfaces" style="white-space: pre; overflow-x: auto; font-family: Courier New, Courier, monospace; font-size: 12px; line-height: 1.2; font-variant-ligatures: none; tab-size: 8;"></pre>

            <h2>{{ lang._('Filters') }}</h2>
            <pre id="igmpv3proxy_filters" style="white-space: pre; overflow-x: auto; font-family: Courier New, Courier, monospace; font-size: 12px; line-height: 1.2; font-variant-ligatures: none; tab-size: 8;"></pre>
        </div>
    </div>
</section>
