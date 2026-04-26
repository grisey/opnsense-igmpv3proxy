<script>
$(document).ready(function() {
    function escapeHtml(value) {
        return String(value || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function cleanCell(value) {
        return String(value || "")
            .replace(/_/g, "")
            .trim();
    }

    function splitPipeLine(line) {
        const rawCells = String(line || "").split("|").map(cleanCell);

        while (rawCells.length > 0 && rawCells[rawCells.length - 1] === "") {
            rawCells.pop();
        }

        if (rawCells.length > 0 && rawCells[0] === "") {
            rawCells[0] = "#";
        }

        return rawCells;
    }

    function isSeparatorLine(line) {
        return String(line || "").replace(/[|_\-=\s]/g, "") === "";
    }

    function renderPre(target, text) {
        $(target).html('<pre class="igmpv3proxy-pre"></pre>');
        $(target).find("pre").text(text || "");
    }

    function renderPipeTable(target, text) {
        const lines = String(text || "").split(/\r?\n/);
        let title = "";
        let header = null;
        let rows = [];
        let total = "";

        $.each(lines, function(_, line) {
            const trimmed = String(line || "").trim();

            if (trimmed === "") {
                return;
            }

            if (line.indexOf("|") === -1) {
                if (title === "") {
                    title = trimmed.replace(/:$/, "");
                }
                return;
            }

            if (isSeparatorLine(line)) {
                return;
            }

            if (trimmed.toLowerCase().startsWith("total")) {
                total = trimmed;
                return;
            }

            const cells = splitPipeLine(line);

            if (cells.length < 2) {
                return;
            }

            if (header === null) {
                header = cells;
            } else {
                rows.push(cells);
            }
        });

        if (header === null || rows.length === 0) {
            renderPre(target, text);
            return;
        }

        let html = '<div class="igmpv3proxy-table-box">';

        if (title !== "") {
            html += '<div class="igmpv3proxy-table-title">' + escapeHtml(title) + '</div>';
        }

        html += '<div class="table-responsive">';
        html += '<table class="table table-condensed table-hover igmpv3proxy-table">';
        html += '<thead><tr>';

        $.each(header, function(_, cell) {
            html += '<th>' + escapeHtml(cell) + '</th>';
        });

        html += '</tr></thead><tbody>';

        $.each(rows, function(_, row) {
            html += '<tr>';
            for (let idx = 0; idx < header.length; idx++) {
                html += '<td>' + escapeHtml(row[idx] || "") + '</td>';
            }
            html += '</tr>';
        });

        html += '</tbody></table></div>';

        if (total !== "") {
            html += '<div class="igmpv3proxy-table-total">' + escapeHtml(total) + '</div>';
        }

        html += '</div>';
        $(target).html(html);
    }

    function loadDiagnostic(endpoint, target, renderer) {
        ajaxCall(endpoint, {}, function(data, status) {
            if (status === "success" && data.status === "ok") {
                renderer(target, data.response || "");
            } else {
                renderPre(target, "No data returned.");
            }
        });
    }

    function loadIgmpv3proxyDiagnostics() {
        loadDiagnostic("/api/igmpv3proxy/diagnostics/config", "#igmpv3proxy_config", renderPre);
        loadDiagnostic("/api/igmpv3proxy/diagnostics/routes", "#igmpv3proxy_routes", renderPipeTable);
        loadDiagnostic("/api/igmpv3proxy/diagnostics/interfaces", "#igmpv3proxy_interfaces", renderPipeTable);
        loadDiagnostic("/api/igmpv3proxy/diagnostics/filters", "#igmpv3proxy_filters", renderPipeTable);
    }

    $("#refreshDiagnosticsAct").click(function() {
        loadIgmpv3proxyDiagnostics();
    });

    loadIgmpv3proxyDiagnostics();
});
</script>

<style>
.igmpv3proxy-pre {
    white-space: pre-wrap;
}

.igmpv3proxy-table-box {
    border: 1px solid #555;
    border-radius: 3px;
    background: #252936;
    margin-bottom: 18px;
}

.igmpv3proxy-table-title {
    padding: 8px 10px;
    font-weight: 600;
    border-bottom: 1px solid #555;
}

.igmpv3proxy-table {
    margin-bottom: 0;
}

.igmpv3proxy-table th,
.igmpv3proxy-table td {
    white-space: nowrap;
    vertical-align: middle;
    padding: 5px 9px !important;
}

.igmpv3proxy-table th {
    font-weight: 600;
    border-bottom: 1px solid #666 !important;
}

.igmpv3proxy-table td:first-child,
.igmpv3proxy-table th:first-child {
    width: 42px;
    text-align: right;
    color: #ccc;
}

.igmpv3proxy-table-total {
    padding: 6px 10px;
    border-top: 1px solid #555;
    color: #ccc;
    font-family: monospace;
}
</style>

<section class="page-content-main">
    <div class="content-box">
        <div class="col-md-12">
            <br/>
            <button class="btn btn-default" id="refreshDiagnosticsAct" type="button">
                {{ lang._('Refresh diagnostics') }}
            </button>
            <br/><br/>

            <h2>{{ lang._('Generated configuration') }}</h2>
            <div id="igmpv3proxy_config"></div>

            <h2>{{ lang._('Routes') }}</h2>
            <div id="igmpv3proxy_routes"></div>

            <h2>{{ lang._('Interfaces') }}</h2>
            <div id="igmpv3proxy_interfaces"></div>

            <h2>{{ lang._('Filters') }}</h2>
            <div id="igmpv3proxy_filters"></div>
        </div>
    </div>
</section>
